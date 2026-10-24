# Financial Operations API Contract

**Feature**: [spec.md](../spec.md)

All endpoints are under `/api`. The API derives actor identity and role from authentication;
clients cannot provide or override them. Amounts are integer CFA francs. Error responses must use
the existing API error shape and must never be interpreted as successful writes by Flutter.

## Role Matrix

| Operation | Director | Assistant | Field manager |
|---|---:|---:|---:|
| Read global/field balances and expense reports | Yes | Yes | No |
| Change global operating-funds limit | Yes | No | No |
| Allocate funds to a field | No | Yes | No |
| Create a budgeted expense | No | Yes | No |
| Create existing non-budgeted field expense | No | No | Own field only |
| Create/edit stock unit price | No | Yes | No |
| Submit stock request | No | No | Own field only |
| Dispatch/validate request | No | Yes | No |
| Confirm receipt | No | No | Own field only |

Server authorization is mandatory even when an action is hidden in Flutter.

## Budget

### `GET /api/budgets`

Director and assistant only. Returns the global funding limit, confirmed and pending spend, total
remaining, unallocated amount, and each field's allocation, remaining amount and reconciliation
status.

### `PUT /api/budgets/limit`

Director only.

Request: `{ "fundingLimit": 500000 }`

Reject non-integer/negative values and reductions below confirmed expenses plus remaining field
allocations. Record the authenticated actor, server time and immutable funding-limit ledger entry.
Perform the check and update atomically.

### `POST /api/budgets/allocations`

Assistant only.

Request: `{ "fieldId": 12, "amount": 25000, "note": "Avance champ nord" }`

Require a positive amount within current unallocated funds. Lock the budget and target allocation,
append a ledger entry, update the allocation projection and attempt to post any now-funded pending
offline expenses for that field in the same transaction.

## Expenses and Offline Synchronization

### `GET /api/expenses`

Existing director/assistant/field-manager access remains field-scoped. Director and assistant
responses include reconciliation state for assistant expenses. A field manager only receives
their own field's records and no budget fields.

### `POST /api/expenses`

Assistant expenses must name a field with sufficient available allocation; the server atomically
debits the global and field remaining amounts, writes the expense and appends a ledger entry.
Insufficient online funds return a conflict without writing any record. Existing field-manager
expense behavior remains unchanged and does not consume the assistant budget.

### `POST /api/expenses/offline-sync`

Assistant only. Receives a queued expense with `idempotencyKey` (UUID), `fieldId`, `description`,
positive integer `amount`, and original `occurredAt`.

- A new key with sufficient funds is committed once and returned as `CONFIRMED`.
- A repeated key returns the original record/status and creates no additional ledger entry.
- If funds changed since offline capture, retain one `PENDING_RECONCILIATION` expense, return the
  record with an explicit pending state, and freeze further assistant spending against that field.
- When funding/allocation changes make the pending amount affordable, commit it once and clear the
  field's blocked state when no other pending expense remains.
- Validation errors must not delete the local queued operation.

## Product Price and Stock Request

### `POST /api/stock/items` and `PUT /api/stock/items/{id}/price`

Only the assistant may set/change `unitPrice`; it must be a positive integer CFA amount. Existing
stock-item creation by a field manager remains allowed without a price. Every assistant price
change appends an audit record. Legacy unpriced items cannot be dispatched until the assistant
sets a price.

### `PUT /api/stock/orders/{id}/send`

Assistant only. Request: `{ "sentQuantity": 4.5 }`; the client does not send a price or total.

Require request status `ORDERED`, quantity greater than zero and no greater than requested, and a
positive current item unit price. Under the existing order/item locks, copy the unit price to the
shipment, calculate `paidAmount = round(unitPrice * sentQuantity)`, set authenticated sender/time,
and change status to `SENT`. Repeated dispatches return a conflict and create no duplicate movement.
Flutter displays field, product, requested quantity, unit price and calculated total before
confirmation, and presents success/error feedback.

### Receipt

`PUT /api/stock/orders/{id}/receive` remains field-manager-only and limited to the manager's own
field. It transitions one `SENT` request to `RECEIVED` once, recording receipt actor/time and
creating exactly one stock receipt movement.

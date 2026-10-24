# Data Model: Field Budgets and Stock Pricing

**Feature**: [spec.md](spec.md)

All monetary amounts are non-negative integer CFA francs. Existing stock quantities remain
positive decimals. Financial writes and ledger updates occur in one database transaction.

## Entities

### OperatingBudget

One global record for the assistant operating-funds limit.

| Field | Type | Rules |
|---|---|---|
| id | fixed singleton key | Exactly one current operating budget |
| fundingLimit | integer CFA | Non-negative; director-controlled |
| updatedAt | instant | Server timestamp |
| updatedBy | account identity | Authenticated director |
| version | integer | Optimistic or lock version for consistent updates |

The limit cannot be reduced below confirmed expenses plus the current remaining allocations.
Remaining global funds equal the current funding limit minus confirmed and pending expenses.
Unallocated funds equal remaining global funds minus remaining field allocations.

### FieldBudgetAllocation

Current allocation projection for one plantation field. The ledger is the audit source.

| Field | Type | Rules |
|---|---|---|
| id | generated identifier | Stable |
| fieldId | relation | Required, one current projection per field |
| allocatedAmount | integer CFA | Cumulative net allocation, never negative |
| remainingAmount | integer CFA | Allocation less posted expenses; derived or transactionally updated |
| updatedAt / updatedBy | instant / account | Last allocation change |
| blocked | boolean | True while an expense conflict for this field awaits reconciliation |

### BudgetLedgerEntry

Immutable, append-only financial audit entry.

| Field | Type | Rules |
|---|---|---|
| id | generated identifier | Stable |
| kind | enum | `FUNDING_LIMIT_CHANGE`, `ALLOCATION`, `EXPENSE`, `RECONCILIATION` |
| amount | signed integer CFA | Direction is explicit and documented by `kind` |
| fieldId | optional relation | Required for field allocations and expenses |
| expenseId | optional relation | Unique when the entry represents an expense |
| requestId | optional UUID | Stable client-generated idempotency key for synchronized operations |
| actor | account identity | Set from authenticated principal, never trusted from request body |
| occurredAt | instant | Action time, preserving client occurrence time for queued offline expenses |
| recordedAt | instant | Server persistence time |
| note | optional text | Correction/reconciliation explanation |

Ledger entries are not updated or deleted. Corrections append compensating entries and retain the
original actor, amount, time and reference.

### Expense

Existing `Expense` records remain compatible. Assistant-created budget expenses reference their
ledger entry and carry synchronization status; field-manager expenses remain outside the assistant
budget.

| Field | Type | Rules |
|---|---|---|
| description | text | Required, existing 240-character limit |
| amount | integer CFA | Positive |
| fieldId | relation | Required for budgeted assistant expenses |
| recordedBy | account identity | Authenticated actor |
| occurredAt / recordedAt | instant | Expense occurrence and server persistence times |
| budgetLedgerEntryId | optional relation | Required for confirmed budgeted assistant expenses |
| idempotencyKey | optional UUID | Unique per assistant account for offline retries |
| reconciliationStatus | enum | `CONFIRMED`, `PENDING_RECONCILIATION`; existing rows are treated as confirmed |

Pending records remain visible but do not appear as confirmed expenses or confirmed available
balance deductions until reconciled. A field with a pending reconciliation record cannot accept
another assistant budget expense.

### StockItem

Existing per-field stock item with an editable assistant-managed unit price.

| Field | Type | Rules |
|---|---|---|
| id, name, unit, quantity, fieldId | existing fields | Existing uniqueness and quantity behavior retained |
| unitPrice | nullable integer CFA | Positive before dispatch; legacy and manager-created items may remain unpriced until assistant sets a price |

Every price change appends an attributed price-history entry; it does not rewrite historical
shipment values.

### StockItemPriceChange

Immutable unit-price audit record.

| Field | Type | Rules |
|---|---|---|
| id | generated identifier | Stable |
| stockItemId | relation | Required |
| previousUnitPrice / newUnitPrice | nullable/integer CFA | New price must be positive |
| changedAt / changedBy | instant / account | Server timestamp and authenticated assistant |

### StockOrder and FieldShipment

Retain the existing request lifecycle `ORDERED -> SENT -> RECEIVED`. The `SENT` transition becomes
the assistant validation/dispatch action; it captures the item price and calculated amount.

| Field | Type | Rules |
|---|---|---|
| orderedQuantity | positive decimal | Existing requested quantity |
| receivedQuantity | positive decimal | Sent amount, must not exceed ordered amount |
| unitPriceAtDispatch | positive integer CFA | Immutable price snapshot |
| paidAmount | integer CFA | `round(unitPriceAtDispatch * receivedQuantity)` |
| orderedAt / sentAt / receivedAt | instants | Existing and new server timestamps |
| orderedBy / sentBy / receivedBy | account identities | Set from authentication |
| itemId / fieldId | relations | Field is derived from the requested item's field |

## Relationships and Derived Values

- One operating budget governs allocations to many fields.
- Each field allocation belongs to exactly one field; field expenses debit that allocation.
- A confirmed assistant expense references exactly one budget-ledger entry; field-manager expenses
  remain unbudgeted.
- An offline expense's client UUID is unique per assistant account and maps retries to one
  server-side expense.
- Remaining global funds = funding limit - confirmed expenses.
- Remaining field funds = allocated amount - confirmed field expenses.
- Unallocated funds = remaining global funds - sum of remaining field funds.
- A shipment's historical price/value is independent of later product-price changes.

# Feature Specification: Field Budgets and Stock Pricing

**Feature Branch**: `002-field-funds-stock-pricing`

**Created**: 2026-10-16

**Status**: Draft — clarifications complete

**Input**: User description: "Ajouter des prix unitaires modifiables pour les produits gérés par l’assistant, avec une trace du produit, de la quantité et de la date lors des envois aux responsables de champ. Permettre au directeur de mettre une somme à disposition de l’assistant, que seul l’assistant peut consulter, puis à l’assistant d’allouer une partie de cette somme à chaque champ pour les dépenses du champ. Chaque dépense doit être retranchée du budget du champ, visible par l’assistant et rapportée au directeur. Corriger également le bouton qui sert à valider les demandes des responsables de champ."

## Clarifications

### Session 2026-10-16

- Q: Le directeur peut-il consulter les soldes de l’enveloppe et des champs ? → A: Oui, le directeur peut consulter tous les soldes, globaux et par champ.
- Q: Comment le prix des articles et le total d’un envoi sont-ils déterminés ? → A: L’assistant saisit et peut modifier le prix unitaire de l’article ; lors de la validation de l’envoi, le total est calculé automatiquement à partir de la quantité envoyée et de ce prix.
- Q: Comment l’assistant doit-il enregistrer une dépense lorsqu’il est hors connexion ? → A: La dépense est saisie selon le dernier solde synchronisé, conservée pour synchronisation et signalée si le solde a changé ; elle ne doit pas être supprimée.

## User Scenarios & Testing

### User Story 1 - Fund and allocate field budgets (Priority: P1)

As the director, I want to set aside operating funds for the assistant, and as the assistant I
want to allocate those funds to individual fields and pay field expenses from their allocations,
so that spending is controlled and can be reconciled.

**Why this priority**: Field spending cannot be safely recorded against budgets until balances,
allocations and spending rules are explicit.

**Independent Test**: The director funds the assistant's operating balance; the assistant allocates
part of it to a field, records an expense, and verifies both applicable balances decrease by that
expense while the director can review its report.

**Acceptance Scenarios**:

1. **Given** the director is authenticated, **When** they set or change the operating funds made
   available to the assistant, **Then** the amount is recorded and visible to the director and
   assistant.
2. **Given** the assistant has available operating funds, **When** they allocate an amount to a
   field, **Then** that amount is reserved for the selected field and cannot also be allocated to
   another field.
3. **Given** a field has an available allocation, **When** the assistant records an expense for
   that field, **Then** the expense is attributed to the assistant and field and deducted from the
   field allocation and the assistant's remaining funds.
4. **Given** the director opens the expense report, **When** assistant expenses exist, **Then** the
   director can review their date, field, reason, amount, responsible assistant and current
   operating and field balances.
5. **Given** an expense or allocation exceeds its available funds, **When** the assistant attempts
   to record it, **Then** the operation is rejected and no balance or expense is changed.
6. **Given** the assistant records an expense offline using the last synchronized balance,
   **When** synchronization finds that the balance has changed, **Then** the expense is preserved
   and flagged for reconciliation rather than silently discarded.

### User Story 2 - Record unit prices and trace field deliveries (Priority: P1)

As the assistant, I want to maintain product unit prices and record the quantity and date of each
shipment sent to a field manager, so the director can review what was sent and its value.

**Why this priority**: Pricing and delivery history provide the source detail needed to verify
stock-related spending and field receipts.

**Independent Test**: The assistant sets an item's unit price, dispatches a requested quantity to a
field, and the director views the resulting dated line item with its product, quantity and unit
price.

**Acceptance Scenarios**:

1. **Given** the assistant creates or edits a stock product, **When** they set a positive unit
   price, **Then** that price is saved with the product.
2. **Given** a product has a saved unit price, **When** the assistant prepares a shipment to a
   field, **Then** the shipment total is calculated automatically as sent quantity times unit
   price, and the shipment records the quantity, unit price, total value, date, product,
   destination field and responsible assistant.
3. **Given** the unit price changes after a shipment, **When** a director reviews that past
   shipment, **Then** its recorded unit price and total remain unchanged.
4. **Given** a field manager receives a shipment, **When** they confirm the actual receipt,
   **Then** the received quantity and date are recorded against that field and shipment.
5. **Given** the director reviews stock deliveries, **When** they select a field or date range,
   **Then** only matching, completed shipment details are presented with attributable totals.

### User Story 3 - Validate field requests (Priority: P1)

As the assistant, I want to process field managers' stock requests from the request list so the
requested quantity and dispatch decision are saved and visible to the requester.

**Why this priority**: The user reports that the existing validation action is not working; requests
must be actionable for field operations and must not be silently lost.

**Independent Test**: A field manager submits a stock request, the assistant processes it using the
validation action, and both roles see the persisted resulting status and quantities.

**Acceptance Scenarios**:

1. **Given** a field manager submits a request, **When** the assistant opens pending requests,
   **Then** the request's field, product, quantity, note and submission date are visible.
2. **Given** a pending request and a product with a saved unit price, **When** the assistant
   validates it by entering the dispatched quantity, **Then** the shipment total is calculated
   automatically from the unit price and quantity, and the request cannot be processed a second
   time.
3. **Given** a request has already been processed, **When** a user attempts to process it again,
   **Then** the system prevents duplicate shipment and spending records and explains the current
   status.

### Edge Cases

- An allocation or expense is zero, negative, malformed, or larger than the available funds.
- The director reduces the operating funds below the amount already spent or allocated.
- Several expense or allocation actions occur at the same time and could overspend one balance.
- A field has no allocation, has an insufficient balance, or has been renamed after transactions.
- A product unit price changes while a request is pending or after a shipment is sent.
- The assistant attempts to send more than requested or records a shipment with missing price.
- The manager confirms less than the sent quantity or tries to confirm the same shipment twice.
- A request's validation call fails because of connectivity; retrying must not create a duplicate.
- The director reviews reports while an allocation or expense is being synchronized.
- An offline expense conflicts with a balance change made since the last synchronization.

## Requirements

### Functional Requirements

- **FR-001**: The director MUST be able to record the amount of operating funds made available to
  the assistant.
- **FR-002**: The director and assistant MUST be able to view the available operating balance and
  each field's allocated and remaining balance. Field managers MUST NOT be able to view these
  balances.
- **FR-003**: The assistant MUST be able to allocate available operating funds to a specific field
  and view each field's remaining budget.
- **FR-004**: An assistant expense MUST be linked to a field, date, description, amount and
  responsible account. Recording an expense MUST reduce the field's available allocation and the
  assistant's remaining operating balance by the same amount.
- **FR-005**: The system MUST prevent allocations and expenses from exceeding the relevant
  available balances, including when concurrent requests occur.
- **FR-006**: The director MUST be able to review and filter assistant expense records by field and
  date, including the responsible account, amount and reconciliation status. An expense awaiting
  reconciliation MUST be clearly distinguished from a confirmed expense.
- **FR-007**: The assistant MUST be able to create and update each product's unit price. Prices
  MUST be positive, denominated in the project's CFA currency, and restricted to appropriate
  roles.
- **FR-008**: Each shipment to a field MUST retain an immutable record of product, sent quantity,
  unit price, total value, date, destination, sender and receiving/confirmation details when
  available.
- **FR-009**: Directors MUST be able to review completed shipment records and filter them by field
  and date.
- **FR-010**: Field managers MUST be able to submit stock requests that include the product,
  requested quantity and a note; those requests MUST be attributed to their assigned field and
  submission date.
- **FR-011**: The assistant MUST be able to process each pending field request once by recording
  the sent quantity. The system MUST calculate the shipment total from the saved product unit
  price, and the shipment action MUST NOT require the assistant to re-enter that price.
- **FR-012**: Field managers MUST be able to see the current status of their own requests and
  confirm receipt of dispatched quantities; they MUST NOT see another field's requests or
  operating and field budget balances.
- **FR-013**: Material financial and request corrections MUST preserve a traceable history of the
  original value, change, date and responsible account.
- **FR-014**: All balance, price and request permissions MUST be enforced by the application
  regardless of interface visibility.
- **FR-015**: The validation action MUST provide visible success or error feedback; failures and
  retries MUST NOT leave a request in a misleading success state or create duplicate movements.
- **FR-016**: The request validation action MUST prepare and record the shipment using the entered
  sent quantity and the product's saved unit price.
- **FR-017**: The assistant MUST be able to record an expense offline against the last synchronized
  field balance. The expense MUST be retained and synchronized idempotently. If synchronization
  detects insufficient funds or a conflicting balance change, it MUST preserve and flag the
  expense for reconciliation, show the conflict to the director and assistant, and prevent further
  spending against the conflicting field budget until it is resolved. The expense MUST be posted
  once sufficient funds are made available by a director funding change or assistant allocation;
  the assistant and director MUST be able to see whether it is pending or confirmed.
- **FR-018**: Shipment totals MUST be calculated as unit price multiplied by sent quantity and
  rounded to the nearest whole CFA franc.
- **FR-019**: A director MUST NOT be able to reduce the operating-funds limit below the total
  already spent or currently allocated to fields.

### Key Entities

- **Assistant operating funds**: The amount made available by the director and its remaining,
  unallocated and allocated portions; the director and assistant can view its balances.
- **Field budget allocation**: An assistant-created allocation from operating funds to one field,
  with amount, date, creator and remaining balance.
- **Assistant expense**: A dated and attributed outgoing expense attached to one field and charged
  to that field's allocation.
- **Stock product price**: The current positive unit price maintained and editable by the
  assistant for a product, used to calculate each shipment total.
- **Field stock request**: A product and quantity requested by a field manager, with field,
  submission date, note and decision history.
- **Field shipment**: A product, sent quantity, unit price, total value, destination, sent date,
  sender and receipt confirmation, preserving the price at dispatch.

## Success Criteria

### Measurable Outcomes

- **SC-001**: In all tested role scenarios, the director and assistant can access operating and
  field balances; field managers cannot.
- **SC-002**: For every recorded expense, the field allocation and assistant operating balance
  decrease by exactly the expense amount, with no overspend in concurrent boundary tests.
- **SC-003**: Every completed shipment displays its product, field, sent quantity, unit price,
  total, date and responsible assistant to the director, and historical prices remain unchanged
  after a product price update.
- **SC-004**: A field request can be processed only once; its requester sees the final status and
  any failed attempt produces an explicit error without duplicate records.
- **SC-005**: A user can locate a field's expenses and completed shipments by field and date and
  reconcile each displayed total to its itemized records.
- **SC-006**: Offline expenses survive reconnection without loss or duplication; any balance
  conflict is visible to the director and assistant and blocks further spending on that field
  until reconciliation.

## Assumptions

- The existing roles remain: the director funds and reviews operating funds, the assistant views
  and allocates those funds and records assistant-paid expenses, and a field manager can
  request/receive stock only for their assigned field.
- CFA francs are the currency, consistent with existing Inventa screens and records.
- Allocating funds transfers them from the assistant's unallocated amount to a field allocation
  without changing total remaining funds. An expense reduces both the relevant field balance and
  the total remaining operating funds exactly once.
- A shipment's price is a snapshot at dispatch and is not retroactively changed by later product
  price updates.
- The existing reporting and authorization model remains in use; no online payment processor or
  worker-facing account is introduced.

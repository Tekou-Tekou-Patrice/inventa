# Feature Specification: Field Payroll and Assistant Spending

**Feature Branch**: `003-field-payroll-budget`

**Created**: 2026-10-16

**Status**: Draft

**Input**: User description: "Le directeur configure les heures mensuelles et les salaires des ouvriers et des responsables de champ, par champ. L’assistant effectue les paiements. Tous les paiements et achats réalisés par l’assistant (salaires, stock, matériel et approvisionnement des champs) sont déduits de l’argent mis à sa disposition par le directeur. Les responsables de terrain ne doivent pas voir les salaires des ouvriers."

## User Scenarios & Testing

### User Story 1 - Configure monthly pay by field (Priority: P1)

As the director, I want to set monthly required hours and the salary amounts that apply to
workers and the responsible manager in each field, so payroll reflects the staffing and rules
of that field.

**Why this priority**: Accurate, field-specific pay rules are required before payroll can be
calculated or paid.

**Independent Test**: The director sets different monthly worker and field-manager salary amounts
for two fields and verifies that each field's payroll uses its own saved values and the configured
monthly hours.

**Acceptance Scenarios**:

1. **Given** the director is authenticated, **When** they set the monthly required hours and the
   worker and field-manager salary amounts for a field, **Then** those values are saved for that
   field and used for its payroll.
2. **Given** two fields have different salary settings, **When** payroll is viewed for either
   field, **Then** calculations use only the selected field's settings.
3. **Given** an assistant opens payroll, **When** payroll is prepared, **Then** the assistant can
   see the applicable amounts needed to pay workers and the responsible manager.
4. **Given** a field manager opens any worker, attendance, or payroll view, **When** the view is
   displayed, **Then** no worker salary, salary rate, or payroll amount is exposed.

### User Story 2 - Pay field staff from funded balances (Priority: P1)

As the assistant, I want to pay workers and field managers from the funds the director made
available, so salary payments are traceable and cannot be made from unavailable money.

**Why this priority**: Payroll is a major assistant-managed outflow and must reduce the same
controlled funds as other expenses.

**Independent Test**: The director funds the assistant and an amount is allocated to a field; the
assistant records an approved worker or field-manager payment and verifies the field balance and
remaining operating funds are each reduced exactly once.

**Acceptance Scenarios**:

1. **Given** a field has a configured monthly salary and sufficient available funds, **When** the
   assistant pays a worker or the field manager, **Then** the payment is recorded with the person,
   field, period, amount, date and assistant, and the amount is deducted from the field allocation
   and the assistant's remaining funds.
2. **Given** the field allocation or operating balance is insufficient, **When** the assistant
   attempts a salary payment, **Then** the payment is rejected and no payment record or balance
   change is committed.
3. **Given** a payment has already been recorded, **When** the assistant retries the same payment,
   **Then** it is not deducted or recorded a second time.
4. **Given** the director reviews financial activity, **When** salary payments exist, **Then** the
   director can identify them separately from purchases and review the affected field and
   remaining balances.

### User Story 3 - Charge assistant purchases and field supplies (Priority: P1)

As the assistant, I want purchases of stock and materials and other paid field supplies charged
to the director-funded balance, so all assistant-managed cash outflows are accounted for.

**Why this priority**: Salary tracking alone is insufficient if other assistant spending can bypass
the director's funding limit.

**Independent Test**: The assistant records a paid material purchase and a field supply operation
against funded field balances, then verifies each cash outflow appears in the report and is
deducted exactly once.

**Acceptance Scenarios**:

1. **Given** an assistant makes a stock or material purchase for a field, **When** the purchase is
   recorded, **Then** the paid amount, item, quantity, date, field and assistant are recorded and
   deducted from that field's available allocation and the assistant's remaining funds.
2. **Given** already-paid stock is later transferred to a field, **When** the transfer is recorded,
   **Then** the shipment and its value are traceable without charging the same purchase a second
   time.
3. **Given** an assistant records any other paid field supply, **When** the outflow is saved,
   **Then** it is classified and deducted from the same funded balance as other assistant
   expenses.
4. **Given** a purchase or supply operation exceeds the available funds, **When** the assistant
   attempts to save it, **Then** the operation is rejected without a partial stock, expense, or
   balance update.
5. **Given** the director reviews the assistant's financial activity, **When** salary and purchase
   records exist, **Then** they can filter and reconcile them by field, date and expense category.

### Edge Cases

- The director has not configured pay for a field, or changes a field's pay settings after a
  payroll period has begun.
- A responsible field manager is replaced, disabled, or assigned to a different field.
- The assistant attempts to pay a person who is inactive, belongs to another field, or has already
  been paid for the same period.
- The configured monthly hours or salary amount is zero, negative, missing, or invalid.
- Concurrent salary and purchase payments could exceed the same field allocation or operating
  balance.
- A purchase is recorded offline and the balance has changed before synchronization.
- A field supply shipment represents stock that was already paid for, creating a risk of
  double-charging.
- A field manager tries to retrieve salary information through a screen, report, or direct
  request.

## Requirements

### Functional Requirements

- **FR-001**: The director MUST be able to configure monthly required hours and monthly salary
  amounts for workers and the responsible manager separately for each field.
- **FR-002**: Payroll calculations MUST use the selected field's current configuration and
  attendance for the relevant period; a field's settings MUST NOT affect another field.
- **FR-003**: The assistant MUST be able to view the payroll information needed to make payments
  and MUST be the only role that records completed salary payments.
- **FR-004**: Field managers MUST NOT be able to view worker salary amounts, salary rates,
  estimated payroll, or salary payment amounts in screens, reports, or data responses.
- **FR-005**: The assistant MUST be able to record salary payments for workers and responsible
  field managers with the payee, field, pay period, amount, date and responsible assistant.
- **FR-006**: Every assistant-managed cash outflow, including salaries, stock or material
  purchases, and paid field supplies, MUST be recorded against the director-funded operating
  balance and the applicable field allocation.
- **FR-007**: A successful assistant outflow MUST reduce the applicable field allocation and the
  assistant's remaining operating funds by the same amount exactly once.
- **FR-008**: The system MUST reject an outflow that exceeds the available field allocation or
  operating balance without partially saving the associated payment, purchase, stock movement or
  balance change.
- **FR-009**: Each assistant outflow MUST retain its category, amount, date, field, description or
  payee, and responsible assistant so the director can review and reconcile it.
- **FR-010**: A transfer of stock already purchased and paid for MUST retain its product,
  quantity, destination and date without charging the purchase value to the operating balance a
  second time.
- **FR-011**: The director MUST be able to review assistant spending by field, date and category,
  including salary payments, stock and material purchases, and field supplies.
- **FR-012**: Salary settings, salary details, payments and balance changes MUST be restricted
  according to role permissions regardless of interface visibility.
- **FR-013**: Retrying an assistant payment or purchase after an uncertain response MUST NOT create
  a duplicate record or duplicate deduction.
- **FR-014**: If an offline outflow cannot be confirmed against the latest available balance, it
  MUST be retained as pending reconciliation and MUST NOT be presented as a confirmed payment.

### Key Entities

- **Field payroll settings**: Monthly required hours and salary amounts for workers and the
  responsible manager in one field, maintained by the director.
- **Salary payment**: A dated, attributed payment to a worker or field manager for a specific pay
  period and field.
- **Assistant-funded outflow**: A categorized amount paid by the assistant and charged to the
  director-funded operating balance and a field allocation.
- **Field purchase**: A paid stock or material purchase with item, quantity, price, date,
  destination field and responsible assistant.
- **Field stock transfer**: A traceable movement of stock to a field that distinguishes a
  non-cash transfer from the original paid purchase.
- **Operating balance and field allocation**: Director-funded available money and the portion
  reserved for each field, reduced by confirmed assistant outflows.

## Success Criteria

### Measurable Outcomes

- **SC-001**: In all tested field combinations, payroll uses the monthly hours and salary settings
  configured for that field, with no values leaking across fields.
- **SC-002**: Field managers receive no worker salary or payroll amounts in any tested screen,
  report, or data response.
- **SC-003**: Every confirmed assistant salary payment or purchase reduces the applicable field
  allocation and remaining operating funds by exactly its recorded amount, once and only once.
- **SC-004**: Insufficient-fund and concurrent-spending tests produce no overspend and no partial
  payment, purchase, stock movement, or balance change.
- **SC-005**: The director can reconcile all recorded assistant outflows to the itemized
  salary, purchase and field-supply records by field and date.
- **SC-006**: A previously paid stock purchase transferred to a field is counted as one cash
  outflow, while its transfer remains fully traceable.

## Assumptions

- CFA francs remain the currency, and the existing director-funded operating envelope and
  assistant-controlled field allocations remain the source of available money.
- Each assistant-paid outflow is assigned to the field it serves; an outflow without an applicable
  field allocation cannot be confirmed.
- The responsible field manager receives a monthly salary associated with their assigned field;
  worker pay continues to use attendance and the field's configured monthly hours.
- The existing director review/approval step for payroll requests remains in place; the assistant
  records the actual completed payment.
- Salary configuration applies prospectively to payroll not yet paid. Existing payment records
  remain unchanged when the director updates a field's salary settings.
- A cash purchase is charged when paid. Later movement of the already-paid stock is a traceable
  transfer and does not create a second cash expense.
- Offline assistant outflows remain pending until the server confirms the balance deduction.

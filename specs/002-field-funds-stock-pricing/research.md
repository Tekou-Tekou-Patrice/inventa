# Research: Field Budgets and Stock Pricing

**Feature**: [spec.md](spec.md)

## Decisions

### Treat the API as the financial source of truth

- **Decision**: Calculate balances and approve financial mutations only on the Spring Boot API.
- **Rationale**: The current client already sends expense and stock operations to the API; Spring
  transactions and JPA locks are used by adjacent stock and payroll flows. This keeps separate
  clients from independently approving the same funds.
- **Alternatives considered**: Client-calculated balances as authoritative (rejected because stale
  clients can overspend); an external accounting/payment service (out of scope).

### Represent money as whole CFA francs and quantities as their existing decimal values

- **Decision**: Store money in integer CFA francs (`long`/Dart `int`), retain stock quantities as
  positive decimal quantities, and round calculated shipment totals to the nearest CFA franc.
- **Rationale**: Existing expense, payment and stock-order totals use integer amounts while stock
  quantities already use decimal values.
- **Alternatives considered**: Floating-point currency (rejected because it introduces monetary
  precision errors); changing all existing quantity semantics (unnecessary).

### Use an immutable financial ledger with derived balances

- **Decision**: Record director funding-limit changes, assistant field allocations, confirmed
  expenses and reconciliation adjustments as attributed ledger entries. Keep any current
  per-field allocation projection transactionally synchronized with that ledger.
- **Rationale**: The constitution requires auditable corrections; derived balances can be
  reconciled to their underlying transactions and should not be silently overwritten.
- **Alternatives considered**: Store only mutable wallet counters (rejected because they lose
  history); rely on the general expense list alone (insufficient to audit allocations and funding).

### Serialize server financial mutations with database transactions and locks

- **Decision**: Apply the existing `@Transactional` and pessimistic-lock pattern to the singleton
  operating budget and affected field allocation before testing available funds and writing ledger
  entries.
- **Rationale**: `PlantationController` is transactional and repositories already use
  `PESSIMISTIC_WRITE` for stock items/orders, payroll requests and attendance-related records.
- **Alternatives considered**: Read-then-save without locking (rejected because concurrent
  expenses/allocations could both pass a stale balance check); client-side locks (not authoritative).

### Persist an offline expense outbox on every supported Flutter platform

- **Decision**: Add a small Sembast-backed local store, using its native file backend on mobile and
  IndexedDB backend on Web. Store budget snapshots and queued expense payloads with client UUIDs;
  do not store account passwords.
- **Rationale**: No durable offline database is present in `pubspec.yaml`. The app is documented
  for Android/iOS and Web, and an outbox must survive process restart and synchronize across
  supported platforms. A serial queue around local writes prevents lost append/update operations.
- **Alternatives considered**: In-memory state (rejected because records are lost on restart);
  `shared_preferences` JSON (rejected for critical mutable queue data); mobile-only SQLite
  (rejected because it excludes the documented Web client).

### Make offline synchronization idempotent and preserve conflicts

- **Decision**: Generate a stable UUID when an expense is first queued. The API stores the UUID
  uniquely per account; repeats return the existing result. If a queued expense no longer fits the
  current balance, persist it as requiring reconciliation, display it to the director and
  assistant, and freeze further assistant spending against that field until funds cover the pending
  record.
- **Rationale**: Network retries must not duplicate real-world expenses, and a legitimate offline
  expense must not disappear when another device changed the balance.
- **Alternatives considered**: Delete/deny the queued entry (rejected because a real expense could
  be lost); accept unlimited negative balances (rejected because it bypasses budget control);
  silently retry (rejected because it hides a financial conflict).

### Keep field-manager expense behavior distinct from assistant-funded expenses

- **Decision**: Existing field-manager expense records remain supported and are not charged against
  the assistant's budget. Every new assistant expense must reference a field allocation.
- **Rationale**: The current API and `RolePermissions` allow both the assistant and field manager
  to record expenses; the requested envelope applies to assistant spending and should not silently
  remove existing manager workflows.
- **Alternatives considered**: Charge all roles to the assistant envelope (rejected because it
  misattributes who spent those funds); remove manager expense entry (unrequested regression).

## Repository Evidence

- `src\main\java\com\onescompany\Inventa\api\PlantationController.java` is class-level
  `@Transactional` and uses repository locks for stock dispatch/receipt and expense-affecting
  workflows.
- `src\main\java\com\onescompany\Inventa\domain\StockMovementRepository.java`,
  `StockOrderRepository.java` and payroll repositories use `PESSIMISTIC_WRITE`.
- `src\main\java\com\onescompany\Inventa\domain\Expense.java` stores CFA amounts as `long`, and
  current expense creation is server-attributed.
- `lib\src\state\plantation_state.dart` owns client-side operations and refreshes after API writes;
  `lib\src\data\plantation_api.dart` provides HTTP access.
- `pubspec.yaml` contains Flutter, `http` and UI/test dependencies but no durable local database.
- Existing Flutter stock tests exercise the complete manager-request/assistant-dispatch/manager-
  receipt flow; backend MockMvc tests cover stock and expense authorization.

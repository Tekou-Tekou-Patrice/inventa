---
description: "Implementation tasks for field budgets, stock prices and request dispatch"
---

# Tasks: Field Budgets and Stock Pricing

**Input**: Design documents from `specs\002-field-funds-stock-pricing\`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts\financial-operations.md`

**Organization**: Tasks are grouped by user story so each increment can be implemented and
verified independently. Tests are included because the constitution requires financial, role,
offline and boundary behavior to be verified.

## Phase 1: Setup

**Purpose**: Add the cross-platform durable local-store dependency required by offline expenses.

- [x] T001 Add Sembast and its Web IndexedDB adapter to `C:\Users\patri\Desktop\flutter\inventa\pubspec.yaml`

---

## Phase 2: Foundational

**Purpose**: Establish durable offline storage and the backend financial persistence primitives
required before implementing the user journeys.

- [x] T002 Create a serialized, restart-safe native/Web outbox store for queued expenses and cached budget snapshots in `C:\Users\patri\Desktop\flutter\inventa\lib\src\data\offline_operation_store.dart`
- [x] T003 Create the singleton operating-budget, field-allocation and immutable budget-ledger JPA entities and repositories in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\domain\`
- [x] T004 Add a unique per-assistant offline expense idempotency key and explicit reconciliation state to the expense persistence model in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\domain\Expense.java`

**Checkpoint**: Local operations persist across restart; backend budget and expense records can
represent immutable financial actions and duplicate-safe offline requests.

---

## Phase 3: User Story 1 - Fund and allocate field budgets (Priority: P1) 🎯 MVP

**Goal**: The director sets the operating-funds limit; the assistant allocates it to fields and
records budget-backed expenses; both can reconcile balances and offline conflicts.

**Independent Test**: Fund an empty database, allocate part of the total, record a field expense,
and verify global, unallocated and field balances, role restrictions and an offline retry/conflict.

### Tests for User Story 1

- [ ] T005 [P] [US1] Add API tests for role permissions, funding limits, atomic allocation/expense balances, concurrent overspend and offline idempotency/reconciliation in `C:\Users\patri\Desktop\spring boot\Inventa\src\test\java\com\onescompany\Inventa\PlantationApiTests.java`
- [ ] T006 [P] [US1] Add Flutter tests for director/assistant/manager balance visibility, expense outbox persistence, retry deduplication and pending-conflict feedback in `C:\Users\patri\Desktop\flutter\inventa\test\features\expenses\expenses_budget_test.dart`
- [ ] T007 [P] [US1] Add local outbox persistence and serialized-write tests for native and Web stores in `C:\Users\patri\Desktop\flutter\inventa\test\data\offline_operation_store_test.dart`

### Implementation for User Story 1

- [x] T008 [US1] Implement lock-protected funding, allocation, spend, reconciliation and balance calculations in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\domain\BudgetLedgerService.java`
- [x] T009 [US1] Add director funding-limit and director/assistant budget-read endpoints plus assistant allocation and idempotent offline expense synchronization in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\api\PlantationController.java`
- [x] T010 [US1] Extend expense and budget request/response DTOs with balances, client idempotency, occurrence time and reconciliation status in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\api\ApiDtos.java`
- [x] T011 [US1] Add budget/ledger/expense models, response parsing, cached snapshot loading and pending-expense sync to `C:\Users\patri\Desktop\flutter\inventa\lib\src\state\plantation_state.dart`
- [x] T012 [US1] Add budget operation methods and offline expense queue requests to `C:\Users\patri\Desktop\flutter\inventa\lib\src\data\plantation_api.dart`
- [x] T013 [US1] Add the assistant budget allocation view, director/assistant balance summaries and clearly marked pending reconciliation expenses to `C:\Users\patri\Desktop\flutter\inventa\lib\src\features\expenses\expenses_screen.dart`
- [x] T014 [US1] Enforce and test budget-view/funding/allocation/expense role permissions in `C:\Users\patri\Desktop\flutter\inventa\lib\src\state\role_permissions.dart` and `C:\Users\patri\Desktop\flutter\inventa\test\state\role_permissions_test.dart`

**Checkpoint**: Story 1 passes its independent API and Flutter tests; no online or concurrent
expense can exceed available funds, and an offline conflict remains visible without duplication.

---

## Phase 4: User Story 2 - Record unit prices and trace field deliveries (Priority: P1)

**Goal**: The assistant sets/edit product prices and records shipments with an immutable price
snapshot; the director can reconcile completed deliveries by field and date.

**Independent Test**: Set a product's unit price, dispatch a decimal quantity, change the product
price, and verify the shipment's calculated whole-CFA total and historical unit price are unchanged.

### Tests for User Story 2

- [x] T015 [P] [US2] Add API tests for assistant-only product pricing, positive price validation, immutable price history, automatic shipment total and director shipment visibility in `C:\Users\patri\Desktop\spring boot\Inventa\src\test\java\com\onescompany\Inventa\PlantationApiTests.java`
- [x] T016 [P] [US2] Add Flutter widget/state tests for price entry/editing, auto-calculated dispatch total and historical shipment display in `C:\Users\patri\Desktop\flutter\inventa\test\features\stock\stock_expenses_test.dart`

### Implementation for User Story 2

- [x] T017 [US2] Add a nullable legacy-compatible unit price to stock items and append-only attributed stock-price change records in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\domain\StockItem.java`
- [x] T018 [US2] Add unit-price update validation/authorization, price-history responses and immutable unit-price/total snapshots on dispatch in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\api\PlantationController.java` and `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\domain\StockOrder.java`
- [x] T019 [US2] Extend stock item and shipment API DTOs with editable unit price and dispatch price snapshots in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\api\ApiDtos.java`
- [x] T020 [US2] Add unit-price and immutable shipment-price fields plus calculated totals to Flutter stock models/state in `C:\Users\patri\Desktop\flutter\inventa\lib\src\models\plantation_models.dart` and `C:\Users\patri\Desktop\flutter\inventa\lib\src\state\plantation_state.dart`
- [x] T021 [US2] Add assistant product price create/edit fields and director shipment price/date/quantity details in `C:\Users\patri\Desktop\flutter\inventa\lib\src\features\stock\stock_screen.dart`

**Checkpoint**: Story 2 passes independently; a later product-price change never alters a
previously dispatched or received shipment.

---

## Phase 5: User Story 3 - Validate field requests (Priority: P1)

**Goal**: Repair and verify the assistant's request-validation action so it dispatches once using
the product's saved price and provides explicit success/error feedback.

**Independent Test**: Submit a field-manager request, validate it as assistant using a sent
quantity, confirm the price-derived shipment appears to the manager, then retry and verify no
duplicate dispatch is created.

### Tests for User Story 3

- [x] T022 [P] [US3] Extend backend request tests for assistant authorization, valid dispatch, invalid quantity/price, repeated validation and receipt history in `C:\Users\patri\Desktop\spring boot\Inventa\src\test\java\com\onescompany\Inventa\PlantationApiTests.java`
- [ ] T023 [P] [US3] Add a widget regression test proving the assistant can validate a pending request and sees explicit API failure feedback without a false success state in `C:\Users\patri\Desktop\flutter\inventa\test\features\stock\stock_expenses_test.dart`

### Implementation for User Story 3

- [x] T024 [US3] Make the validation dialog submit only the sent quantity, display the saved unit price/calculated total and preserve server error feedback in `C:\Users\patri\Desktop\flutter\inventa\lib\src\features\stock\stock_screen.dart`
- [x] T025 [US3] Make the dispatch state method enforce pending status/quantity, call the matching API contract and refresh from the server only after success in `C:\Users\patri\Desktop\flutter\inventa\lib\src\state\plantation_state.dart`
- [x] T026 [US3] Return stable, explicit conflict and validation responses for already processed, over-quantity and unpriced product requests in `C:\Users\patri\Desktop\spring boot\Inventa\src\main\java\com\onescompany\Inventa\api\PlantationController.java`

**Checkpoint**: Story 3 passes through the actual UI, API and manager receipt flow; failed requests
remain pending and retries never duplicate shipments or stock movements.

---

## Phase 6: Polish and Cross-Cutting Concerns

**Purpose**: Document the changes and run the complete feature verification.

- [x] T027 [P] Document budget visibility, assistant expense rules, product prices and shipment totals in `C:\Users\patri\Desktop\spring boot\Inventa\README.md` and `C:\Users\patri\Desktop\flutter\inventa\README.md`
- [ ] T028 Verify non-destructive H2/MySQL schema updates preserve existing expenses, stock items and stock orders in `C:\Users\patri\Desktop\spring boot\Inventa\src\test\java\com\onescompany\Inventa\PlantationApiTests.java`
- [x] T029 Run the backend test suite and Flutter targeted/full tests and analysis in `C:\Users\patri\Desktop\flutter\inventa\specs\002-field-funds-stock-pricing\quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Add the cross-platform offline-store dependency.
- **Foundational (Phase 2)**: Depends on Setup; creates the durable client outbox and server-side
  budget/idempotency persistence needed by US1.
- **US1 (Phase 3)**: Depends on Foundational; delivers the budget controls and offline expense flow.
- **US2 (Phase 4)**: Can start after Foundational and is independent of US1's budget calculations.
- **US3 (Phase 5)**: Depends on US2 because validation must use the product's saved unit price and
  immutable shipment snapshot.
- **Polish (Phase 6)**: Depends on all three user stories.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational; independent of stock-price work.
- **US2 (P1)**: Starts after Foundational; independent of budget screens and ledger service.
- **US3 (P1)**: Starts after US2; depends on product pricing and dispatch snapshot behavior.

### Parallel Opportunities

- T003 and T004 can be implemented in parallel because their persistence types are separate.
- T005, T006 and T007 can be written in parallel in separate test files.
- T015 and T016 can be written in parallel.
- T022 and T023 can be written in parallel.
- T027 can be done independently once the final behavior names/routes are stable.
- Work in `PlantationController.java`, `plantation_state.dart` and `stock_screen.dart` is deliberately
  serialized between stories to avoid overlapping edits.

## Implementation Strategy

### MVP

Deliver US1 first: funding limits, allocations, budget-backed expenses and persistent offline
synchronization. It establishes the financial safety rules that subsequent stock reporting can
reuse. Then deliver US2 pricing and immutable delivery records, followed by US3's dispatch
validation regression fix.

### Incremental Verification

After each story, run its specific backend and Flutter tests. After US3, run the full backend suite,
Flutter analyzer, Flutter tests and manual quickstart scenarios, including native/Web outbox
restart and offline-conflict cases.

## Format Validation

All executable tasks use the required `- [ ] Tnnn` format. User-story tasks include `[US1]`,
`[US2]` or `[US3]`; `[P]` is reserved for tasks in distinct files that can be done independently.
Every task names one or more concrete project file paths.

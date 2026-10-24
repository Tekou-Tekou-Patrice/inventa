# Tasks: Plantation Management Frontend

**Input**: Design documents from `specs/001-plantation-management-ui/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included because the specification and constitution require verification of role permissions and core workflows.

**Organization**: Tasks are grouped by user story for incremental, independently testable delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other tasks in the same phase (different files, no incomplete dependencies)
- **[Story]**: User story identifier from `spec.md`
- Task descriptions specify concrete project paths

## Phase 1: Setup

**Purpose**: Replace the generated Flutter starter and establish the shared UI shell.

- [X] T001 Create the Inventa application entry point, Material theme, and app shell in `lib/main.dart`, `lib/src/app.dart`, and `lib/src/theme/app_theme.dart`.
- [X] T002 [P] Add a reusable role selector, section navigation, and demonstration-data notice in `lib/src/app.dart`.

## Phase 2: Foundational

**Purpose**: Define the session-local data and role capabilities required by every workflow.

- [X] T003 Create role, worker, attendance, task, stock, expense, and payment models in `lib/src/models/plantation_models.dart`.
- [X] T004 Implement seeded demonstration records and session-local state mutations in `lib/src/state/plantation_state.dart`.
- [X] T005 Implement centralized role capability checks and navigation visibility in `lib/src/state/role_permissions.dart`.
- [X] T006 [P] Add foundational role-permission tests in `test/state/role_permissions_test.dart`.

## Phase 3: User Story 1 - Review plantation activity (Priority: P1) 🎯 MVP

**Goal**: Provide navigation and an overview of attendance, workers, stock, and finances with director read-only boundaries.

**Independent Test**: Open the app, review summary cards and recent activity, navigate among sections, then verify the director has no payment or overtime action.

### Tests for User Story 1

- [X] T007 [P] [US1] Add dashboard and section-navigation widget tests in `test/features/dashboard/dashboard_test.dart`.

### Implementation for User Story 1

- [X] T008 [P] [US1] Implement responsive dashboard summary cards and recent activity in `lib/src/features/dashboard/dashboard_screen.dart`.
- [X] T009 [US1] Connect the dashboard and available sections to the application shell in `lib/src/app.dart`.

**Checkpoint**: The overview works independently and navigation updates the selected section.

## Phase 4: User Story 2 - Record the morning attendance (Priority: P1)

**Goal**: Let a field manager select a date and mark workers present or absent with visible check-in times.

**Independent Test**: In the field manager role, mark one worker present and another absent; verify statuses and totals.

### Tests for User Story 2

- [X] T010 [P] [US2] Add attendance date, status, timestamp, and summary widget tests in `test/features/attendance/attendance_test.dart`.

### Implementation for User Story 2

- [X] T011 [P] [US2] Implement date selection, worker attendance controls, and summary in `lib/src/features/attendance/attendance_screen.dart`.
- [X] T012 [US2] Connect attendance UI to session-local state and field-manager permissions in `lib/src/app.dart`.

**Checkpoint**: Attendance can be recorded for a selected day and visibly updates its count and check-in time.

## Phase 5: User Story 3 - Manage workers and field tasks (Priority: P2)

**Goal**: Let field managers search and add workers, create tasks, and assign workers.

**Independent Test**: Search the worker list, add a worker, then create a task with at least one assignee.

### Tests for User Story 3

- [X] T013 [P] [US3] Add worker search, worker creation, and task creation widget tests in `test/features/workers/workers_tasks_test.dart`.

### Implementation for User Story 3

- [X] T014 [P] [US3] Implement searchable worker list and validated worker form in `lib/src/features/workers/workers_screen.dart`.
- [X] T015 [P] [US3] Implement task list and validated task/assignee form in `lib/src/features/tasks/tasks_screen.dart`.
- [X] T016 [US3] Connect worker and task screens to session-local state and role permissions in `lib/src/app.dart`.

**Checkpoint**: The user can create and immediately view workers and assigned field tasks.

## Phase 6: User Story 4 - Review purchases, stock, and expenses (Priority: P2)

**Goal**: Show stock and movements and allow permitted staff to record stock usage, purchase receipts, and daily expenses.

**Independent Test**: Record a purchase receipt, a stock usage entry, and a daily expense; verify quantities and expense lists update.

### Tests for User Story 4

- [X] T017 [P] [US4] Add stock receipt/usage and expense form widget tests in `test/features/stock/stock_expenses_test.dart`.

### Implementation for User Story 4

- [X] T018 [P] [US4] Implement stock items, movement history, and validated receipt/usage forms in `lib/src/features/stock/stock_screen.dart`.
- [X] T019 [P] [US4] Implement validated daily expense entry and recent expense list in `lib/src/features/expenses/expenses_screen.dart`.
- [X] T020 [US4] Connect stock and expense screens to session-local state and role permissions in `lib/src/app.dart`.

**Checkpoint**: Valid entries update the displayed stock quantities, movements, and expense history.

## Phase 7: User Story 5 - Review and record payments (Priority: P2)

**Goal**: Show sample payroll and allow only the assistant to record timestamped payments.

**Independent Test**: Record a payment as assistant, verify its time and amount, then switch to director and confirm the action is unavailable.

### Tests for User Story 5

- [X] T021 [P] [US5] Add assistant payment, director read-only, and overtime visibility tests in `test/features/payroll/payroll_test.dart`.

### Implementation for User Story 5

- [X] T022 [P] [US5] Implement payroll summary, worker payment status, and assistant-only payment form in `lib/src/features/payroll/payroll_screen.dart`.
- [X] T023 [US5] Add field-manager-only overtime entry and connect payroll actions to session-local state in `lib/src/app.dart`.

**Checkpoint**: Payment and overtime controls are role-gated and recorded items show their entry time.

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Verify responsive use, form feedback, and that delivered behavior matches the specification.

- [X] T024 [P] Add shared empty states, form validation feedback, and layout responsiveness in `lib/src/features/shared/` and affected feature screens.
- [X] T025 Run `flutter analyze` and `flutter test`; resolve issues in affected `lib/` and `test/` files.
- [X] T026 Run the walkthrough scenarios in `specs/001-plantation-management-ui/quickstart.md` and update the guide if needed.

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 1) precedes the foundational state and permission layer.
- Foundational (Phase 2) blocks all user stories.
- User stories follow the priority sequence; after Phase 2 they can be developed independently, subject to the shared shell integration task in each story.
- Polish (Phase 8) follows the desired user stories.

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2; no other story dependency. MVP.
- **US2 (P1)**: Depends on Phase 2; no other story dependency.
- **US3 (P2)**: Depends on Phase 2; no other story dependency.
- **US4 (P2)**: Depends on Phase 2; no other story dependency.
- **US5 (P2)**: Depends on Phase 2; no other story dependency.

### Parallel Opportunities

- T003, T005, and T006 operate in distinct files after the shell setup and can be parallelized where model imports are coordinated.
- Within each story, widget tests and feature-screen files can be authored independently; shell integration tasks follow them.
- Independent feature-screen files for US3, US4, and US5 can be built in parallel after the shared state contract is stable.

## Parallel Example: User Story 4

```text
Task: T017 stock and expense widget tests in test/features/stock/stock_expenses_test.dart
Task: T018 stock screen in lib/src/features/stock/stock_screen.dart
Task: T019 expense screen in lib/src/features/expenses/expenses_screen.dart
```

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Setup and Foundational phases.
2. Implement the overview and role-aware navigation.
3. Verify dashboard content and director read-only restrictions.

### Incremental Delivery

1. Add attendance and verify daily field recording.
2. Add workers and tasks.
3. Add stock, purchases, and expenses.
4. Add payroll and overtime under role-specific controls.
5. Complete responsive and form validation checks.

## Notes

- All app data is session-local demonstration data and resets on restart.
- The clarified payroll workflow uses director-configured monthly salary/full-month hours and
  completed attendance time; connected deployments must implement the API expectations in
  `contracts/ui-workflows.md`.
- [P] marks work that touches separate files and has no dependency on incomplete tasks.

# Feature Specification: Plantation Management Frontend

**Feature Branch**: `001-plantation-management-ui`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Build the Inventa mobile frontend for cocoa plantation management, based on the supplied requirements. Prioritize attendance, workers, tasks, purchases, stock, expenses, payments, and role-appropriate views. Frontend only for now."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review plantation activity (Priority: P1)

As the director, I want to see a concise overview of plantation activity so I can monitor attendance, payroll, stock, expenses, and recent operations without performing payments.

**Why this priority**: The director needs the broadest overview and the dashboard is the primary entry point.

**Independent Test**: Open the dashboard in the director role and confirm that summary metrics and recent activity are visible while payment actions are absent.

**Acceptance Scenarios**:

1. **Given** the director is viewing the dashboard, **When** the page loads, **Then** attendance, workforce, stock, and financial summary cards are displayed.
2. **Given** the director is viewing the dashboard, **When** payment actions are considered, **Then** the director can review payment information but cannot initiate a payment.
3. **Given** the user selects another application section, **When** navigation completes, **Then** the selected section is shown and the navigation state updates.

---

### User Story 2 - Record the morning attendance (Priority: P1)

As a field manager, I want to mark workers present or absent for a selected day so attendance is recorded by staff even when workers do not have phones.

**Why this priority**: Attendance is a daily operation and the central field workflow in the supplied brief.

**Independent Test**: Open attendance, mark a listed worker present or absent, and verify the visible count and worker status update.

**Acceptance Scenarios**:

1. **Given** the attendance screen is open, **When** the manager selects a date, **Then** the worker list and attendance totals correspond to that selected date.
2. **Given** a worker is unmarked, **When** the manager marks them present or absent, **Then** the status and attendance summary update immediately.
3. **Given** a worker is marked present, **When** the manager records the check-in, **Then** the interface displays a recorded time.
4. **Given** a worker has checked in, **When** the manager records the check-out, **Then** both times are displayed and the completed hours contribute to monthly pay.

---

### User Story 3 - Manage workers and field tasks (Priority: P2)

As a field manager, I want to review workers, create a task, and assign it to workers so that the day's field work is organized.

**Why this priority**: Worker and task workflows enable managers to operate the field team.

**Independent Test**: Navigate to workers or tasks and confirm worker information, task assignment, and creation feedback are usable.

**Acceptance Scenarios**:

1. **Given** the worker list is open, **When** the manager searches for a worker, **Then** only matching workers remain visible.
2. **Given** the tasks screen is open, **When** the manager creates a task with a title and assignees, **Then** the new task appears in the list.
3. **Given** the manager creates a worker, **When** the required contact details are entered, **Then** the worker's phone number is saved and displayed.

---

### User Story 4 - Review purchases, stock, and expenses (Priority: P2)

As the assistant or field manager, I want to review stock, purchases, and daily expenses so that inputs and spending are visible and can be entered by the appropriate staff member.

**Why this priority**: These workflows replace existing operational spreadsheets and support daily plantation management.

**Independent Test**: Navigate to stock and expenses, submit a representative entry, and confirm a visible item or transaction is added.

**Acceptance Scenarios**:

1. **Given** the stock screen is open, **When** the user selects an item, **Then** current quantity and recent movements are shown.
2. **Given** the assistant records a received purchase, **When** the item, quantity, and paid price are entered, **Then** a receipt is shown and stock quantity increases in the frontend state.
3. **Given** a field manager records a daily expense, **When** the amount and reason are entered, **Then** the expense is shown in the expense list.

### User Story 6 - Report field operations to the director (Priority: P1)

As a field manager, I want to report missing material and arrived deliveries so the assistant can
validate receipts; as the assistant, I want to review attendance, tasks and material alerts and
compile a complete report for the director.

**Independent Test**: Report a missing item and an arrived delivery as field manager, switch to
assistant, validate the delivery by checkbox, and confirm the stock quantity and report are updated.

**Acceptance Scenarios**:

1. **Given** the field manager reports an item shortage or delivery, **When** the alert is saved,
   **Then** it appears for the assistant with its item, quantity and note.
2. **Given** the assistant reviews an arrived delivery, **When** its checkbox is selected,
   **Then** the alert is marked handled and the delivered quantity is added to stock once.
3. **Given** the assistant opens the report, **When** the report is copied, **Then** it includes
   attendance arrival/departure times, task status, stock alerts/movements and expenses for the
   selected field and date.

---

### User Story 5 - Review and record payments (Priority: P2)

As the assistant, I want to review amounts due and record worker payments so that salary payouts are attributable and visibly timestamped.

**Why this priority**: Payment execution belongs to the assistant and must remain separate from director oversight.

**Independent Test**: In the assistant role, open payroll, record a payment for a worker, and verify that the payment appears with its amount and time.

**Acceptance Scenarios**:

1. **Given** the assistant opens payroll, **When** the worker list loads, **Then** outstanding amounts and payment status are visible.
2. **Given** the assistant records a payment, **When** a valid amount is submitted, **Then** the payment appears in recent activity with a recorded time.
3. **Given** the director opens payroll, **When** payment information is viewed, **Then** it is read-only and no payment action is available.
4. **Given** the field manager opens payroll, **When** the assigned field's payments are viewed, **Then** payment amounts and history are visible without a payment action.
5. **Given** the director configures payroll, **When** a monthly salary and complete-month hours are saved, **Then** every worker's estimate is prorated by completed attendance hours.

### Edge Cases

- An empty worker or transaction list displays a helpful empty state rather than a blank screen.
- A search with no matches displays a clear no-results message.
- Forms reject missing required text, quantities, or non-positive amounts and keep the user on the form with a useful message.
- Narrow mobile screens and larger tablet layouts remain readable and navigable.
- Changing the selected role updates the visible navigation and permitted actions consistently.
- Until a backend exists, entries are demonstration data held in frontend state and are not represented as synchronized or durable records.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST present a French-language, mobile-first interface for plantation operations.
- **FR-002**: The application MUST provide navigation for overview, attendance, workers, tasks, stock and purchases, expenses, and payroll.
- **FR-003**: The application MUST show role-appropriate activity and actions for director, assistant, and field manager views.
- **FR-004**: The director view MUST provide read-only access to activity and financial summaries and MUST NOT expose payment execution actions.
- **FR-005**: The attendance view MUST allow a field manager to record worker arrival and departure times, and to mark a worker absent.
- **FR-006**: The workers view MUST show a searchable worker list and require a phone number when adding a worker.
- **FR-007**: The tasks view MUST allow a field manager to create a task and choose worker assignees.
- **FR-008**: The stock view MUST display quantities and recent movements and provide role-appropriate frontend actions to record stock use or received purchases.
- **FR-009**: The expenses view MUST allow permitted staff to enter a daily expense with a description and amount and show recent expenses.
- **FR-010**: The payroll view MUST show monthly salary estimates derived from completed work hours; the director alone configures the shared monthly salary and full-month hours.
- **FR-015**: The field manager MUST be able to view payment amounts and history for the assigned field, without permission to record a payment.
- **FR-016**: Assistant accounts and field-manager accounts MUST require a phone number; the number MUST be visible to the director.
- **FR-017**: The assistant and director MUST be able to review attendance and tasks, while only the field manager can record attendance or manage tasks.
- **FR-018**: The field manager MUST be able to report missing material and an arrived delivery; the assistant MUST be able to validate a delivery with a checkbox, and validation MUST add the delivered quantity to stock exactly once.
- **FR-019**: The assistant MUST be able to compile and copy an operational report containing attendance, tasks, material movements and alerts, and expenses for the selected field.
- **FR-011**: The field manager view MUST include the authorized overtime entry action; other roles MUST NOT see that action.
- **FR-012**: Forms MUST validate required values and show success or validation feedback without silently discarding entered values.
- **FR-013**: Frontend interactions MUST update the displayed demonstration state during the current app session.
- **FR-014**: The interface MUST identify demonstration data and MUST NOT imply that frontend-only data is persisted or synchronized.

### Key Entities *(include if data involved)*

- **Worker**: Plantation worker with a name, phone number, field group, and employment status.
- **Material alert**: A field-reported shortage or arrived delivery with item, quantity, note, and assistant validation state.
- **Attendance record**: A worker's attendance status for a selected date, including arrival and departure times.
- **Task**: A field activity with a title, status, and one or more worker assignees.
- **Stock item**: An input or supply with a name, unit, current quantity, and movements.
- **Stock movement**: A receipt or usage entry with a quantity, responsible user, and time.
- **Expense**: A daily cost with a description, amount, and time.
- **Payment**: A worker salary payout with an amount, responsible assistant, and time.
- **User role**: Director, assistant, or field manager, determining visible sections and allowed actions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can open the daily attendance list and mark one worker in no more than three interactions after entering the attendance section.
- **SC-002**: Every section permitted for the selected role is reachable from the application navigation without returning to the home screen.
- **SC-003**: In role-based walkthroughs, 100% of tested restricted actions (director payment, non-field-manager overtime) are unavailable.
- **SC-004**: A user can create a demonstration task, expense, stock movement, and payment and see each result reflected immediately in its list.
- **SC-005**: Primary screens remain usable at common phone and tablet widths without clipped primary actions or horizontal overflow.
- **SC-006**: A field delivery is added to stock only after assistant validation, and each delivery is counted once.
- **SC-007**: The assistant can copy an operational report containing attendance, tasks, material alerts/movements, and expenses.

## Assumptions

- This delivery is a frontend prototype only; authentication, backend APIs, durable storage, and true offline synchronization are outside scope.
- A role selector provides a way to preview role-based experiences until real authentication is available.
- Demonstration data is localized, representative, and clearly labeled as non-persistent.
- Salary due is the shared monthly salary multiplied by completed attendance hours divided by the configured complete-month hours. Overtime remains separate.
- The brief is incomplete after the heading for attendance, so the frontend scope is limited to the explicit actors and capabilities described in the supplied text.

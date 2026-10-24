# Feature Specification: Offline Field Operations and Synchronization

**Feature Branch**: `004-offline-field-work`

**Created**: 2026-10-18

**Status**: Draft

**Input**: User description: "L’application doit servir à des gens qui sont constamment hors réseau. Les responsables de champ doivent pouvoir remplir les présences, ventes, demandes, tâches, stocks, achats et autres données de terrain hors ligne ; une fois la connexion rétablie, les données doivent être envoyées automatiquement, comme un message WhatsApp en attente."

## User Scenarios & Testing

### User Story 1 - Continue field work without a network (Priority: P1)

As a field manager, I want to open Inventa and enter daily field information without an internet connection, so that work can continue in areas with unreliable coverage.

**Why this priority**: If the application cannot start or save field records offline, the principal field workflow is blocked.

**Independent Test**: Sign in while online, load the assigned field, go offline, reopen the app, and record attendance, a task, a harvest sale, a material request, and stock usage. Verify each entry remains available after restarting the app.

**Acceptance Scenarios**:

1. **Given** a field manager has previously signed in successfully and has cached data for their assigned field, **When** the app is opened with no network, **Then** the manager can resume the session and use the last available field data without seeing data for another role or field.
2. **Given** the field manager is offline, **When** they record attendance, a harvest sale, a task or task-status change, a material request, stock usage, or a delivery receipt, **Then** the operation is durably saved with its original details and is clearly marked as waiting to synchronize.
3. **Given** the app is closed or the device restarts while operations are waiting, **When** the manager opens the app again, **Then** all waiting operations and their order are preserved.
4. **Given** field data has not yet been cached on the device, **When** the manager is offline, **Then** the app identifies which information is unavailable and does not imply that an operation requiring missing data has been saved.

### User Story 2 - Synchronize queued work automatically (Priority: P1)

As a field manager, I want records created offline to be sent automatically when the connection returns, so that the assistant and director can see the field's work without re-entering it.

**Why this priority**: Offline entry has little value unless confirmed records reach the shared system reliably.

**Independent Test**: Create several distinct field operations offline, restore connectivity, and verify each appears on the server once, retains its recorded time and actor, and changes from waiting to synchronized.

**Acceptance Scenarios**:

1. **Given** saved operations are waiting and network access becomes available, **When** synchronization runs, **Then** the operations are submitted automatically in their recorded order and the app shows which have been confirmed.
2. **Given** a connection drops during synchronization or the server response is uncertain, **When** the app retries, **Then** the operation is not lost or duplicated and remains visibly pending until its result is known.
3. **Given** the user returns to the app after connectivity is restored, **When** synchronization has not yet run, **Then** the app starts synchronization without requiring the user to recreate or manually resend each operation.
4. **Given** an operation is rejected because the server's current stock, budget, or business state no longer permits it, **When** synchronization reports the rejection, **Then** the operation is retained as requiring attention and is not shown as a confirmed server record.

### User Story 3 - Review pending work and resolve conflicts safely (Priority: P2)

As a field manager or assistant, I want to see which operations are waiting, synchronized, or blocked, so that I can correct genuine conflicts without losing the original record.

**Why this priority**: Clear status and conflict handling prevent users from mistaking a local entry for a confirmed shared record.

**Independent Test**: Queue an operation, force a business-rule rejection during synchronization, and verify its details and reason remain visible until it is corrected or otherwise resolved.

**Acceptance Scenarios**:

1. **Given** the device has queued, synchronized, or blocked operations, **When** an authorized user reviews synchronization status, **Then** each operation shows its outcome and relevant reason without exposing another account's operations.
2. **Given** a blocked operation requires correction, **When** an authorized user reviews it, **Then** the original details remain available and the user can make a deliberate correction or retry without creating a duplicate.
3. **Given** a user signs out or another account signs in, **When** that account accesses the device, **Then** the previous account's cached field data and pending operation details are not exposed or attributed to the new account.
4. **Given** an offline operation contains salary or other restricted financial information, **When** a field manager uses the offline app or reviews synchronization status, **Then** that restricted information is not disclosed.

### Edge Cases

- The app has never completed an online sign-in on this device, or the saved account is disabled or its password has changed while offline.
- Cached data is missing, outdated, partially written, or belongs to a different account or field.
- Connectivity changes repeatedly, the app is suspended, or the device restarts during synchronization.
- The server accepts an operation but its confirmation response is lost.
- A task, order, worker, or stock item was changed or removed on the server while the device was offline.
- Available stock or budget has changed before an offline use or expense is synchronized.
- Two devices record the same real-world event while offline.
- The user switches accounts or signs out while operations remain pending.
- A locally recorded timestamp crosses a day or month boundary before synchronization.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST let a user who has previously authenticated successfully resume access without a network connection using only the identity, role, and field assignment last confirmed for that account.
- **FR-002**: Offline access MUST be limited to information previously available to that account and MUST preserve role and field permissions, including the restriction against field managers seeing salary information.
- **FR-003**: The system MUST retain an offline copy of the authorized data needed for field work and MUST identify when required data is unavailable or too old to safely support an operation.
- **FR-004**: A field manager MUST be able to record attendance and checkout, harvest sales, tasks and task-status changes, material requests or alerts, stock usage, delivery receipts, and other currently available field operations without an active network connection.
- **FR-005**: Any operation accepted for offline recording MUST be saved durably with its account, assigned field, actor, original event time, operation details, and synchronization status.
- **FR-006**: The system MUST preserve the order in which offline operations were recorded when sending dependent operations for synchronization.
- **FR-007**: The system MUST automatically attempt to synchronize pending operations when connectivity returns and when the app resumes with a working connection.
- **FR-008**: The system MUST retain operations after timeouts, connection loss, app termination, or device restart until the server confirms them or an authorized user resolves a reported conflict.
- **FR-009**: Retrying an operation whose server response was lost MUST NOT create duplicate attendance, sales, tasks, requests, stock movements, expenses, or delivery receipts.
- **FR-010**: The system MUST distinguish operations waiting to synchronize, confirmed by the server, and blocked or requiring reconciliation; locally queued operations MUST NOT be presented as server-confirmed.
- **FR-011**: When current server state prevents an operation from being accepted, the system MUST retain its details, show an actionable explanation, and avoid silently discarding it or changing it into a successful record.
- **FR-012**: An authorized user MUST be able to review pending and blocked operations scoped to their account and permitted field, and resolve or retry them without losing the original operation details.
- **FR-013**: Cached data and pending operations MUST remain isolated by account and field when users switch accounts on the same device.
- **FR-014**: Signing out MUST prevent access to the signed-out account's cached data and operation details by the next user; pending operations MUST remain safely attributable to their original account until synchronized or explicitly resolved.
- **FR-015**: The existing assistant offline expense workflow MUST continue to synchronize and reconcile correctly alongside the additional offline field operations.
- **FR-016**: Server-confirmed timestamps, attribution, role authorization, field assignment, budget rules, and stock rules MUST be validated when offline operations are synchronized.

### Key Entities

- **Cached field workspace**: The last authorized view of workers, fields, tasks, stock, and other information needed for that user's permitted field workflows.
- **Offline operation**: A locally recorded field or expense action with its account, field, actor, event time, operation details, and synchronization outcome.
- **Synchronization outcome**: Whether an operation is waiting, confirmed by the server, or blocked and requires review, together with the relevant server result or reason.
- **Account scope**: The identity, role, and field assignment that determine which cached data and operations a user may access.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A previously signed-in field manager can reopen the app without connectivity and access the last cached, authorized field workspace in all tested offline-start cases.
- **SC-002**: Every supported field operation created offline remains available after app termination and device restart in all persistence tests.
- **SC-003**: In synchronization tests covering successful responses, lost responses, retries, and reconnects, every accepted operation appears on the server exactly once.
- **SC-004**: With a working connection, pending operations begin synchronization automatically within 60 seconds or immediately when the app resumes, and their confirmed or blocked outcome is visible to the user.
- **SC-005**: In all tested account-switch and role-permission cases, users cannot access another account's cached operations or restricted salary information.
- **SC-006**: In conflict tests involving changed stock, budget, or server records, no operation is silently discarded or displayed as confirmed before server acceptance.

## Assumptions

- Offline session resumption is available only on a device where that account previously completed a successful online sign-in; first-time sign-in still requires connectivity.
- The app can use previously cached information offline, but cannot guarantee that it includes changes made on the server after the last successful refresh.
- The event time recorded on the device is preserved; the server remains authoritative for accepting operations, permissions, available stock, and budget balances.
- Operations are synchronized automatically when possible. A user-facing status is required because server confirmation may be delayed or require conflict resolution.
- Pending records remain associated with their original account after sign-out and are not transferred to another account.
- Offline sales and purchases capture the reported transaction details; any server-side stock or budget checks are applied when those records synchronize.
- The scope covers existing field-manager daily operations and the existing assistant expense queue; it does not promise full offline access to director-only administration or first-time account registration.

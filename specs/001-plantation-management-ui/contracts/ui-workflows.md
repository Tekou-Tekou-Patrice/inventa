# UI Workflow Contracts

This document defines user-visible behavior for the frontend prototype. It is not an API contract.

## Role access

| Role | Read access | Available actions |
|------|-------------|-------------------|
| Director | Overview, attendance, workers, tasks, stock, expenses, payroll, report and recent activity | Review only; no payment action and no paid-overtime action |
| Assistant | Overview, attendance, workers, tasks, stock, expenses, payroll, report and recent activity | Review field operations, compile/copy the report for the director, validate material deliveries, record purchases, expenses, harvest sales, and worker payments |
| Field manager | Overview, attendance, workers, tasks, stock, expenses, payroll and recent activity; payment amounts/history for assigned field | Mark arrival/departure, add workers with phone numbers, create/assign tasks, record stock usage and expenses, report missing material or an arrived delivery, record harvest sales; no payment, delivery-validation, or salary-configuration action |

## Attendance

- Selecting a date shows its attendance list.
- Recording arrival marks a worker present and records the arrival time.
- Recording departure records the departure time; it is available only after arrival.
- Marking a worker absent updates the count and does not show arrival/departure times.
- Invalid or unmarked records are not counted as present.

## Workers and tasks

- Search filters the visible worker list by name.
- Worker creation requires a name and phone number.
- A field-manager account must be assigned to an existing field. It can access only field-related
  sections and records belonging to that assigned field; field selection is unavailable to it.
- The director configures the shared monthly salary reference and number of complete monthly hours.
  Updating the reference changes workers who have no individual salary adjustment; individual amounts
  remain unchanged.
- The assistant can set an individual worker's salary when instructed by the director. No messaging
  or request channel is part of this workflow.
- Estimated salary is the worker's effective monthly salary multiplied by completed attendance
  minutes divided by required monthly minutes. An attendance day without both arrival and departure
  does not contribute time.
- Task creation requires a title and at least one assignee.
- Successful creation updates the current screen and provides visible confirmation.
- Creating an assistant or field-manager account requires a contact phone number; that number is
  visible alongside the account's role and field.

## Stock, expenses, and payments

- Stock receipts require an item and positive quantity; assistant purchase entries may include a
  positive paid amount. A receipt increases displayed quantity.
- Stock usage requires an item and positive quantity no greater than the current quantity.
- A field manager can report a shortage or signal that a delivery arrived. These alerts appear in
  the assistant's stock screen; a checkbox validates the delivery and only then adds its quantity
  to stock. The director can review the alerts and their validation state.
- The assistant's report summarizes attendance times, task status, stock movements and alerts,
  expenses, and harvest sales (product, quantity, and total sale price) for the selected field/date;
  the assistant can copy it for transmission to the director.
- Assistants and field managers can report a harvest sale with its product, quantity, and total
  price. The sale appears in the recent sales list and in the daily report.
- Expense creation requires a description and positive amount.
- Payment recording requires the assistant role, a worker, and a positive amount. The resulting
  entry shows its time. The director and field manager can view payment records but cannot add them.
- Director payroll is read-only. Restricted roles do not see the corresponding action controls.

## API expectations for connected deployments

- `GET /api/payroll/settings` returns `monthlySalary` and `monthlyRequiredHours`; `PUT` accepts
  those same positive integer fields and is director-only. Updating `monthlySalary` changes workers
  without an individual salary adjustment.
- Worker records include `salaryIsIndividual`. `PUT /api/workers/{id}/salary` sets that flag when
  the assistant or director updates a worker's individual salary; new workers use the shared
  monthly salary reference.
- `GET /api/sales` returns field-scoped harvest sales. `POST /api/sales` accepts a non-empty
  `product`, positive `quantity`, positive integer `totalPrice`, and `fieldId`; assistants and field
  managers may create a sale.
- `GET /api/reports/daily` includes a `sales` list with each sale's product, quantity, total price,
  timestamp, reporter, and field.
- Attendance records returned by `/api/attendance` and `/api/attendance/month` include optional
  `checkIn` and `checkOut` timestamps. `PUT /api/attendance/{workerId}?date=YYYY-MM-DD` accepts
  `status` and the timestamp being recorded.
- Worker records include `phoneNumber`; `POST /api/workers` accepts it as a required field.
- `POST /api/accounts` accepts a required `phoneNumber`; account records include it.
- `GET /api/stock/alerts` returns field-scoped material alerts. `POST /api/stock/alerts` accepts
  `itemId`, `kind` (`MISSING` or `DELIVERY`), positive `quantity`, and a required `description`.
  `PUT /api/stock/alerts/{id}/resolve` is assistant-only; resolving a `DELIVERY` alert records the
  corresponding stock receipt exactly once.
- Assistants and directors can read `/api/attendance` and `/api/tasks`; only field managers can
  mutate attendance and tasks.
- Field managers can read `/api/payments` scoped to their assigned field but cannot post payments.

## Feedback and persistence

- Invalid forms remain open, retain entered values, and identify the invalid field.
- Successful demonstration entries appear immediately in the relevant list.
- The app visibly indicates that the records are demonstration data and may reset on restart.

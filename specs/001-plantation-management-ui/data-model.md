# Data Model: Plantation Management Frontend

These entities describe frontend demonstration state. They do not define durable storage or a
backend contract.

## UserRole

- `director`
- `assistant`
- `fieldManager`

Role determines visible actions and sections. Workers do not sign in.

## ManagedAccount

- `username`: login identifier
- `role`: assistant or field manager
- `phoneNumber`: required contact number
- `fieldId`: required for field managers
- `enabled`: whether the account can sign in

## Worker

- `id`: stable identifier within the demonstration session
- `name`: required display name
- `phoneNumber`: required contact number
- `group`: optional field/team label
- `active`: whether the worker appears in current operational lists

All workers share the monthly salary configured by the director.

## AttendanceRecord

- `workerId`: reference to a Worker
- `date`: selected work date
- `status`: unmarked, present, or absent
- `checkInTime`: optional local time, present only for a recorded check-in
- `checkOutTime`: optional local time, present only after a recorded departure

One worker has at most one visible attendance status for a selected date in the prototype.

## Payroll settings

- `monthlySalary`: common salary amount for one worker completing all required hours
- `monthlyRequiredHours`: the number of completed hours in the selected month
- Estimated pay is `monthlySalary × workedMinutes / (monthlyRequiredHours × 60)`.
- Worked time includes only attendance records with both arrival and departure times.

## FieldTask

- `id`: session-local identifier
- `title`: required task description
- `assigneeIds`: one or more Worker identifiers
- `status`: planned, in progress, or complete
- `createdAt`: local creation time

## StockItem

- `id`: session-local identifier
- `name`: supply name
- `unit`: display unit
- `quantity`: current demonstration quantity
- `movements`: ordered StockMovement records

## StockMovement

- `kind`: receipt or usage
- `quantity`: positive quantity moved
- `description`: related purchase or field-use note
- `recordedAt`: local entry time
- `recordedBy`: active demonstration role
- `paidAmount`: optional amount for purchase receipts

## MaterialAlert

- `itemId`: referenced stock item
- `kind`: shortage or arrived delivery
- `quantity`: positive quantity reported
- `description`: required field note
- `recordedAt` / `recordedBy`: reporting time and field manager
- `resolved`: assistant processing state; resolving a delivery adds one stock receipt

## Expense

- `description`: required reason
- `amount`: positive sample amount
- `recordedAt`: local entry time
- `recordedBy`: active demonstration role

## Payment

- `workerId`: reference to a Worker
- `amount`: positive payout amount
- `recordedAt`: local entry time
- `recordedBy`: assistant role only

## Validation and state transitions

- Names/descriptions required by a form cannot be blank.
- Amounts and quantities must be greater than zero.
- Attendance status changes from unmarked to present or absent; present has a visible check-in
  time and can receive one check-out time, while absent has neither time.
- Only the director can change the common monthly salary and required monthly hours.
- A worker cannot be recruited without a phone number.
- Assistant and field-manager accounts cannot be created without a phone number.
- Stock receipts increase and usage decreases the displayed demonstration quantity; usage cannot
  make the quantity negative.
- A payment can be added only when the assistant role is active; the field manager can view payment
  amounts and history for the assigned field without recording payments.
- All changes are session-local and reset when the app restarts.

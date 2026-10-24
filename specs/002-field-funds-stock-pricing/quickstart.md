# Quickstart: Budget and Stock Verification

**Feature**: [spec.md](spec.md)

## Prerequisites

- Java 17 and the Flutter SDK version required by `pubspec.yaml`.
- The backend project at `C:\Users\patri\Desktop\spring boot\Inventa`.
- The Flutter project at `C:\Users\patri\Desktop\flutter\inventa`.
- A test database or disposable local H2 database and director, assistant and field-manager test
  accounts.

## Automated Checks

Run the backend suite from the API directory:

```powershell
.\mvnw.cmd test
```

Run focused Flutter tests and static analysis from the Flutter directory:

```powershell
flutter test test\features\stock\stock_expenses_test.dart test\features\expenses\expenses_budget_test.dart
flutter analyze
```

The focused tests must cover:

- Director/assistant balance read, director-only funding limit changes, assistant-only allocations
  and budgeted expenses, and field-manager denial.
- Exact allocation, expense, unallocated and global balance calculations; boundary and concurrent
  overspend attempts.
- Offline expense persistence across app restart, idempotent retries, retained reconciliation
  conflicts and resolution after additional funds become available.
- Product-price input/edit permissions, shipment total calculation and stable historical unit-price
  snapshots.
- Manager request submission, assistant dispatch with automatic price calculation, duplicate
  dispatch prevention, and manager receipt confirmation.

## Manual End-to-End Scenario

1. Start the backend once with the local H2 profile and launch Flutter against
   `http://localhost:8006` (Chrome) or `http://10.0.2.2:8006` (Android emulator).
2. As director, set an operating-funds limit and verify the director can see the global and
   per-field balances but cannot allocate funds or create an assistant expense.
3. As assistant, allocate part of the funds to a field. Record an expense and verify both global
   remaining funds and that field's remaining allocation decrease by exactly the expense.
4. As field manager, request a stock product. As assistant, add or edit its positive CFA unit price,
   enter only the quantity being sent, inspect the automatically calculated total, and dispatch.
5. As the field manager, confirm receipt. As director, confirm the dated product, quantity, unit
   price and total appear in the field's completed shipment report.
6. With an assistant session loaded, disconnect the network, record an expense within the last
   synchronized balance, close/reopen the app and verify the queued item remains pending. Reconnect
   and verify one server record is created. Repeat after reducing the available balance on the
   server: the item must remain visible as pending reconciliation, not be discarded or duplicated.

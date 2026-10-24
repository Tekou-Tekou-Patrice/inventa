# Implementation Plan: Field Budgets and Stock Pricing

**Branch**: `002-field-funds-stock-pricing` | **Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

**Input**: [Feature specification](spec.md)

## Summary

Add an auditable operating-funds limit, per-field allocations and budget-backed assistant expenses;
allow the assistant to maintain stock unit prices and calculate immutable shipment values; repair
the assistant's field-request dispatch workflow; and queue offline expenses for idempotent
synchronization and reconciliation. Implement the rules in Spring Boot as the authority for
balances and role access, then expose the matching workflows in Flutter.

## Technical Context

**Language/Version**: Dart 3.12.2; Java 17

**Primary Dependencies**: Flutter Material, `http`; Spring Boot 4.1.1, Spring MVC, Spring Data JPA,
Spring Security, Jakarta Bean Validation; add a small durable Flutter outbox store supporting
Android/iOS and Web.

**Storage**: Existing H2/MySQL JPA database on the API; a local durable Flutter database for cached
budget snapshots and the pending-expense outbox. Use Sembast with its native file store and Web
IndexedDB store, and never persist authentication credentials.

**Testing**: Flutter `flutter test` and `flutter analyze`; backend `.\mvnw.cmd test` with focused
MockMvc/JPA coverage for role access, balance calculations, transaction races, idempotent retries,
legacy rows and dispatch calculations.

**Target Platform**: Flutter Android/iOS and Web clients; Spring Boot API on Java 17.

**Project Type**: Mobile/Web client plus REST API. The source projects are sibling directories:
`C:\Users\patri\Desktop\flutter\inventa` and `C:\Users\patri\Desktop\spring boot\Inventa`.

**Performance Goals**: Reuse the existing API response patterns and 100-record operational
history limits. No stricter latency or throughput target is specified.

**Constraints**: Role checks must be enforced by the API. Financial mutations must be transactional,
audited and safe under concurrent requests. Offline expenses must survive restart, retry without
duplicates, and remain visible as pending reconciliation rather than being discarded. Amounts are
whole CFA francs; shipment totals round to the nearest CFA franc.

**Scale/Scope**: One plantation, the existing director/assistant/field-manager roles, and the
existing field/product/expense/request flows. No external payment provider or worker accounts.

## Constitution Check

| Principle | Gate | Plan |
|-----------|------|------|
| Offline-first field operation | PASS | Persist a client outbox and cached budget snapshot; sync with stable operation IDs; preserve conflicts and expose pending state. |
| Least-privilege access | PASS | API authorization is authoritative; directors and assistants read balances, only directors change the global limit, only assistants allocate and spend, and managers remain scoped to their field. |
| Traceable work and money | PASS | Record actor, date, amount/quantity, price snapshots and immutable financial/request history; corrections are auditable. |
| Field-ready workflows | PASS | Keep current French workflows and the selected field visible; calculate shipment totals rather than requiring duplicate amount entry. |
| Verifiable correctness | PASS | Add boundary, authorization, offline/retry, concurrency and client action tests in both projects. |

**Gate result**: PASS. Product decisions are recorded in `spec.md`; no unresolved clarification
markers remain. Phase 1 design retains all gates.

## Phase 0: Research

See [research.md](research.md). Existing server transaction/locking patterns and client state/API
patterns are sufficient; no external service or new protocol is required.

## Phase 1: Design and Contracts

- [Data model](data-model.md): budget limit, field allocations, immutable ledger, expenses, product
  price history, stock request/shipment snapshots and offline reconciliation state.
- [API and client contract](contracts/financial-operations.md): role matrix, budget, expense,
  product-price and stock-dispatch operations, including idempotent offline synchronization.
- [Quickstart](quickstart.md): focused automated and manual end-to-end verification.

### Design Gate

- Server transactions serialize limit, allocation and expense mutations; any operation that would
  overspend an online balance is rejected without partial updates.
- Product price at dispatch is copied onto the shipment and used to compute its whole-CFA total.
- Offline expense IDs are stable across retries. Conflicts are retained, shown to both authorized
  reviewers and block additional spending on the affected field until funds are available and the
  pending expense can be posted.
- Existing field-manager expense entry and pre-existing records remain usable; only assistant
  expenses created under the new budget flow consume assistant operating funds.
- PASS; no unjustified constitution exception.

## Project Structure

### Documentation (this feature)

```text
specs\002-field-funds-stock-pricing\
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts\financial-operations.md
├── checklists\requirements.md
└── tasks.md
```

### Source Code

```text
Flutter: C:\Users\patri\Desktop\flutter\inventa\
├── lib\src\data\plantation_api.dart
├── lib\src\data\offline_operation_store.dart
├── lib\src\models\plantation_models.dart
├── lib\src\state\plantation_state.dart
├── lib\src\state\role_permissions.dart
├── lib\src\features\expenses\expenses_screen.dart
├── lib\src\features\stock\stock_screen.dart
└── test\features\ and test\state\

Spring Boot: C:\Users\patri\Desktop\spring boot\Inventa\
├── src\main\java\com\onescompany\Inventa\api\
│   ├── PlantationController.java
│   └── ApiDtos.java
├── src\main\java\com\onescompany\Inventa\domain\
│   ├── Expense.java / ExpenseRepository.java
│   ├── StockItem.java / StockOrder.java / repositories
│   └── budget entities, repositories and ledger service
└── src\test\java\com\onescompany\Inventa\PlantationApiTests.java
```

**Structure Decision**: Keep the established Flutter feature/state/API organization and Spring
Boot controller/domain organization in their two existing project roots; do not create a third
project or bypass the backend for financial decisions.

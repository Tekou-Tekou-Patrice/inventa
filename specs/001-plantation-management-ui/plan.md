# Implementation Plan: Plantation Management Frontend

**Branch**: `001-plantation-management-ui` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-plantation-management-ui/spec.md`

## Summary

Replace the Flutter starter counter with a French-language, responsive plantation-management
prototype. Provide navigation and stateful screens for overview, attendance, workers, field tasks,
stock and purchases, daily expenses, and payroll. Role selection controls visible actions for the
director, assistant, and field manager. Seeded demonstration data is held in frontend state only;
no authentication service, backend, or durable synchronization is introduced.

## Technical Context

**Language/Version**: Dart 3.12.2 (project SDK constraint `^3.12.2`)

**Primary Dependencies**: Flutter SDK and existing `cupertino_icons`; no additional packages

**Storage**: In-memory demonstration state for the active app session

**Testing**: `flutter test` and `flutter analyze`

**Target Platform**: Android and iOS phones, with responsive tablet and existing Flutter desktop/web targets

**Project Type**: Flutter mobile application

**Performance Goals**: Primary screens remain responsive during local state updates and usable at phone/tablet widths

**Constraints**: French UI; role-gated frontend actions; no backend, login, persistent storage, or real payroll calculations; adhere to existing dependency set

**Scale/Scope**: One prototype app with seven main sections and three selectable staff roles

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Assessment |
|-----------|------|------------|
| Offline-First Field Operation | Core field actions must work without a network. | Pass for the prototype: all demonstration interactions are local. Durable offline storage and synchronization are explicitly deferred with backend scope. |
| Least-Privilege Access | Role-specific actions must not appear for unauthorized roles. | Pass: role-specific navigation and action availability are defined and tested in frontend workflows. |
| Traceable Work and Money | Operational entries show date/time and distinguish amounts and quantities. | Pass for demonstration entries; the UI labels the data as non-persistent. |
| Field-Ready Workflows | Common field tasks must be direct and clear. | Pass: attendance is a primary section with worker-level quick controls. |
| Verifiable Correctness | Permission rules and affected behaviors have focused tests. | Pass: widget tests cover role restrictions, attendance actions, and representative form updates. |

No constitution violations require an exception. Authoritative payroll, authenticated authorization,
and persistent audit history remain outside this frontend-only delivery and must be added before
operational deployment.

## Project Structure

### Documentation (this feature)

```text
specs/001-plantation-management-ui/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-workflows.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── main.dart
└── src/
    ├── app.dart
    ├── models/
    ├── data/
    ├── state/
    ├── theme/
    └── features/
        ├── dashboard/
        ├── attendance/
        ├── workers/
        ├── tasks/
        ├── stock/
        ├── expenses/
        └── payroll/

test/
├── widget_test.dart
└── features/
```

**Structure Decision**: Extend the existing single Flutter application under `lib/`, grouping UI by
feature and keeping mock state/models local to the app. Retain Flutter's existing `test/` location.
Do not introduce a backend or another project boundary for this frontend prototype.

## Phase 0: Research

See [research.md](research.md). The repository already provides Flutter, Material icons, and widget
testing support; the design uses those dependencies and avoids introducing state-management or UI
packages for a small prototype.

## Phase 1: Design & Contracts

- [Data model](data-model.md) specifies the demonstration records and their relationships.
- [UI workflow contracts](contracts/ui-workflows.md) define role access and key interaction results.
- [Quickstart](quickstart.md) documents focused validation and run scenarios.

## Complexity Tracking

No constitution violations.

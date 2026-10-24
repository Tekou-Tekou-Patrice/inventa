<!--
Sync Impact Report
- Version change: unversioned scaffold -> 1.0.0 (initial project constitution).
- Modified principles: template placeholders -> Offline-first operation; Least-privilege access;
  Traceable work and money; Field-ready workflows; Verifiable correctness.
- Added sections: Product and Data Constraints; Delivery and Quality Workflow.
- Removed sections: none.
- Follow-up TODO: confirm the constitution's original ratification date.
-->
# Inventa Constitution

## Core Principles

### I. Offline-First Field Operation
Core field workflows MUST remain usable without network access, including recording attendance,
tasks, stock usage, purchases, and daily expenses. Locally recorded changes MUST be retained until
they can be synchronized, and synchronization MUST avoid silently losing or duplicating records.
This is required because field work takes place where connectivity is unreliable.

### II. Least-Privilege Access
Every authenticated role MUST see and change only the information and actions assigned to that
role. The director has read access to the full activity and financial overview but MUST NOT execute
payments. The assistant handles purchases, stock intake, and payments; field managers handle field
operations and may record paid overtime; workers are recorded by staff and do not require accounts.
Authorization MUST be enforced in application workflows, not only hidden in the interface, so
financial and personnel actions remain attributable and appropriately restricted.

### III. Traceable Work and Money
Attendance, payments, purchases, stock movements, expenses, and overtime MUST be recorded with
their relevant date and time, responsible actor, and amount or quantity. Payment records MUST be
distinguishable from salary calculations, and stock intake MUST be distinguishable from stock
usage. Corrections MUST preserve an intelligible history rather than silently overwriting material
financial or operational records. This enables reconciliation and accountability.

### IV. Field-Ready Workflows
The interface MUST prioritize fast, clear use by directors, assistants, and field managers, who
enter data on behalf of workers. Common daily field actions MUST minimize unnecessary navigation
and make the selected date, worker, quantity, and action clear before saving. French is the
product's working language unless a later approved product decision changes it.

### V. Verifiable Correctness
Salary, attendance, payment, stock, and reporting rules MUST be explicit and tested at their
boundaries. Tests MUST cover role permissions and offline recording/synchronization for affected
workflows. Totals shown in reports MUST be reconcilable to their underlying records; ambiguous or
incomplete values MUST NOT be presented as confirmed results.

## Product and Data Constraints

The product is a Flutter mobile application replacing the plantation's Excel/ODS workflows.
Workers generally do not have phones or accounts, so authorized staff record worker attendance,
tasks, salary changes, and payments on their behalf. Salary-setting authority and payment authority
are separate: the director sets salaries for managers and the assistant and can set or change
worker salaries; field managers can recruit workers and set worker salaries; the assistant fixes
worker salaries and performs all payments. The director reviews activity but does not pay workers.

The application MUST represent the plantation's operational records consistently across online
and offline use. Any later server or synchronization implementation MUST preserve role
authorization, attribution, timestamps, and the history of consequential corrections.

## Delivery and Quality Workflow

Feature work MUST begin with an approved specification, followed by a plan and dependency-ordered
tasks before implementation. Changes MUST follow the assigned roles and business rules in those
artifacts. Each behavior change MUST include focused verification for its affected calculations,
permissions, and offline behavior. A feature is complete only when its implementation, tests, and
directly related documentation agree with the specification and plan.

## Governance

This constitution takes precedence over conflicting project practices. Amendments MUST document
the reason for the change, update the version and amendment date, and include a Sync Impact Report.
Versioning follows semantic versioning: MAJOR for incompatible governance changes, MINOR for new
principles or materially expanded requirements, and PATCH for clarifications that do not change
requirements.

Specifications, plans, and task lists MUST be checked against these principles before implementation
and during review. Reviews MUST verify role boundaries, auditability, offline behavior, and
calculation correctness whenever those concerns are affected. Exceptions require an explicit,
documented rationale and approval from the product owner.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): confirm original adoption date | **Last Amended**: 2026-10-02

# Research: Plantation Management Frontend

## Decision: Use the existing Flutter Material stack

- **Rationale**: The repository is a clean Flutter application with Material icons already enabled.
  Flutter's built-in widgets support responsive mobile interfaces and widget-level verification
  without increasing dependency or maintenance cost.
- **Alternatives considered**: Add a third-party component library or custom UI framework. Rejected
  because no existing need justifies the added dependency for this prototype.

## Decision: Keep demonstration data in simple in-memory app state

- **Rationale**: The request is explicitly frontend-only. Session-local state enables the user to
  demonstrate create/mark/record workflows without implying persistence or requiring a service.
- **Alternatives considered**: Add local database storage or connect to a remote API. Rejected
  because both exceed current scope and require durable data and synchronization decisions.

## Decision: Provide a role preview selector and central role capability rules

- **Rationale**: Real authentication is not available, while role boundaries are essential to the
  screens. A selector allows the prototype to demonstrate three role-specific experiences and
  central capability checks keep actions consistent.
- **Alternatives considered**: Show every action and rely on users to infer role behavior. Rejected
  because that would contradict the specified access boundaries.

## Decision: Calculate monthly salary from completed attendance hours

- **Rationale**: The director configures one shared monthly salary and the number of full-month
  hours. Completed check-in/check-out time is prorated against that hour target. Unclosed
  attendance records do not count toward salary.
- **Alternatives considered**: Estimate salary from attended days or give each worker a different
  amount. Rejected because the clarified requirement is hour-based and uses a shared monthly base.

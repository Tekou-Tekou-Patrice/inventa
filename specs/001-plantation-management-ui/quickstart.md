# Quickstart: Plantation Management Frontend

## Prerequisites

- Flutter SDK compatible with the `^3.12.2` Dart constraint in `pubspec.yaml`.
- Dependencies resolved from the existing `pubspec.yaml`.
- An available Android/iOS emulator, connected device, or supported desktop/web target.

## Validate

From the repository root:

```powershell
flutter analyze
flutter test
```

Both commands should complete without analyzer errors or failed tests.

## Run

```powershell
flutter run
```

The app opens to the overview with demonstration data and a visible non-persistence notice.

## Walkthrough scenarios

1. Select **Responsable de champ**, open **Présences**, record a worker's arrival and departure,
   then verify both times appear.
2. Create a field task with a title and worker assignees; verify it appears in the task list.
3. Record a daily expense or stock movement; verify the row and displayed total/quantity update.
4. Select **Assistant**, open **Paie**, record a payment, and verify the timestamped item appears.
5. Select **Responsable de champ**, open **Paie**, and verify payment details are visible while the
   payment action is unavailable.
6. Select **Directeur**, open **Paie**, configure the common monthly salary and full-month hours,
   and verify the field manager sees the updated prorated estimates.

See [UI workflow contracts](contracts/ui-workflows.md) for role and validation expectations.

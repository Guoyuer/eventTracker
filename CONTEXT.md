# Context

## Product

`event_tracker` is a personal activity tracker. The app lets a user define activities, record occurrences, track optional duration and optional units, and inspect summaries through lists, charts, heatmaps, and detail views.

## Domain Terms

- **Activity**: A user-defined thing to track, currently stored in the `events` table and displayed as a project in the UI.
- **Activity Snapshot**: An immutable Activity read model. Plain, inactive Timed, and active Timed states are separate types; state and totals are derived directly from Records.
- **Calendar Date Range**: A user-selected inclusive set of whole local calendar days.
- **Date Interval**: A timestamp interval with explicit half-open semantics: start included, end excluded.
- **Record**: One occurrence of an activity. A record can have an `endTime`, optional `startTime`, and optional numeric `value`.
- **Timed Activity**: An activity where duration matters. It creates an active record at start and completes that record at stop.
- **Plain Activity**: An activity where only occurrence time matters. It creates a completed record immediately.
- **Unit**: A user-managed label for numeric values, such as kilometers, pages, or questions.
- **Record History**: The single source of truth for an Activity's occurrence count, total duration, total value, and active state. `ActivityRecordHistory` validates every Record before producing a summary.
- **Record Lifecycle**: Transactional persistence workflow for creating, stopping, or canceling Records while enforcing Activity type and active-record invariants.
- **Canceled Timed Record**: An active Timed Activity Record removed before completion, used for accidental short starts and excluded from history totals.
- **Legacy Step Schema**: Retired historical step-count tables and sentinel records from an inactive prototype. ADR 0001 removes them from the active Drift schema through the v3 migration.

## Current Architecture

- Flutter app entrypoint: `lib/main.dart`
- Repository Interfaces and read models: `lib/domain/`
- Application interaction policy: `lib/application/`
- Local persistence: Drift over sqflite in `lib/persistence/database/`
- Drift repository Adapters: `lib/persistence/drift_*_repository.dart`
- Activity Snapshot query and validation: `lib/persistence/activity_snapshot_store.dart`
- Activity list and recording flow: `lib/EventsList/`
- Activity detail analytics: `lib/EventsDetails/`
- Cross-activity statistics: `lib/Statistics/`
- Unit management: `lib/UnitManager/`

## Quality Direction

Prefer explicit domain names at new seams. Keep Repository Interfaces in the domain Module and Drift Adapters in persistence, keep UI widgets focused on rendering and interaction, and keep Records as the only source of Activity state and totals.

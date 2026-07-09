# Context

## Product

`event_tracker` is a personal activity tracker. The app lets a user define activities, record occurrences, track optional duration and optional units, and inspect summaries through lists, charts, heatmaps, and detail views.

## Domain Terms

- **Activity**: A user-defined thing to track, currently stored in the `events` table and displayed as a project in the UI.
- **Record**: One occurrence of an activity. A record can have an `endTime`, optional `startTime`, and optional numeric `value`.
- **Timed Activity**: An activity where duration matters. It creates an active record at start and completes that record at stop.
- **Plain Activity**: An activity where only occurrence time matters. It creates a completed record immediately.
- **Unit**: A user-managed label for numeric values, such as kilometers, pages, or questions.
- **Aggregate Totals**: Cached totals stored on an activity, currently `sumTime`, `sumVal`, and `lastRecordId`.
- **Record Lifecycle**: Persistence workflow for creating, stopping, or canceling records while keeping Aggregate Totals consistent.
- **Canceled Timed Record**: An active Timed Activity record removed before completion, used for accidental short starts and not counted in Aggregate Totals.
- **Legacy Step Schema**: Retired historical step-count tables and sentinel records from an inactive prototype. ADR 0001 removes them from the active Drift schema through the v3 migration.

## Current Architecture

- Flutter app entrypoint: `lib/main.dart`
- Local persistence: Drift over sqflite in `lib/persistence/database/`
- Activity list and recording flow: `lib/EventsList/`
- Activity detail analytics: `lib/EventsDetails/`
- Cross-activity statistics: `lib/Statistics/`
- Unit management: `lib/UnitManager/`

## Quality Direction

Prefer explicit domain names at new seams. Keep persistence concerns behind a small module interface, keep UI widgets focused on rendering and interaction, and move record aggregation into testable modules.

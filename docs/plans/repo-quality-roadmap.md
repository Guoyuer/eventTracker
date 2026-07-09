# Repo Quality Roadmap

## Goal

Bring this repo from a working prototype to a maintainable Flutter app that can be built, tested, and refactored safely. Windows desktop is the immediate development target; Android/iOS/web should not be made worse without an explicit ADR.

## Current Baseline

- Windows release build works.
- `flutter analyze` is green under the initial legacy lint profile.
- `flutter test` is green with bootstrap and persistence lifecycle tests.
- Persistence is tightly coupled to UI and uses cached aggregate fields that can drift from records.
- Platform support is Windows-first with sqflite FFI; unused Firebase configuration has been removed.
- `windows/` and `pubspec.lock` are tracked for reproducible desktop development.

## Quality Gates

Every completed slice should preserve or improve these commands:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
```

Use the local verification script for repeatability:

```powershell
.\tool\check.ps1
.\tool\check.ps1 -WindowsBuild
```

If a gate is temporarily red, document the exact failure in this file before moving on.

## Fast Windows Iteration Loop

`flutter build windows` is the final runtime gate for completed slices, but it is too slow for every small edit. Use this loop while actively developing:

```powershell
flutter run -d windows
```

Keep that process alive and use Flutter hot reload from the terminal:

```text
r
```

For Dart-only logic or UI refactors, prefer a tighter check before the final Windows build:

```powershell
flutter analyze
flutter test test\<relevant_test_file>.dart
flutter test --plain-name "<matching test name>"
```

Run the full gate before claiming a slice is complete, before committing a runtime fix, or after touching Windows runner files, CMake, plugin registration, startup/bootstrap code, native dependencies, or database initialization:

```powershell
flutter test
flutter build windows
```

Avoid `flutter clean` during normal iteration because it discards incremental build caches and makes the next Windows build much slower.

## Phase 1: Baseline Tooling and Runtime

Status: completed

- Tracked required platform files and lockfile.
- Made Windows startup deterministic.
- Added missing lint dependency and a legacy lint profile.
- Replaced the stale template test with platform bootstrap tests.
- Added persistence lifecycle tests for plain and timed records.
- Made empty-database startup a first-class state.
- Isolated debug-only UI actions that can delete data.

## Phase 2: Persistence Module

Status: in progress

- Renamed `DAO` to the lower-case `lib/persistence/database/` module path.
- Replaced ad hoc string SQL updates in record lifecycle and latest-step reads with typed Drift operations.
- Continue making record lifecycle operations transactional. Completed for plain record add, timed record start, timed record stop, active timed record cancel, and event delete.
- Moved record lifecycle writes and Aggregate Totals updates out of `AppDatabase` into `RecordLifecycleStore` plus the pure `ActivityAggregateTotals` rule object.
- Replaced the short timed-record delete prompt with a cancel policy for accidental starts under five seconds.
- Introduced `ActivityRepository` and migrated activity creation plus the activity-list recording flow to it.
- Migrated activity detail record reads, deletion, and description edits to `ActivityRepository`.
- Introduced `UnitRepository` and migrated unit management plus unit-list loading to it.
- Mapped unit UI data through a domain `ActivityUnit` read model so unit screens no longer import the Drift database module.
- Introduced `StatisticsRepository` and migrated statistics range reads to it.
- Move desktop sqflite setup behind a database bootstrap module.
- Added tests around record lifecycle, aggregate totals, latest step lookup, repository activity creation, and repository activity recording.
- Added tests for unit add/list/delete and duplicate-name protection through the repository.
- Removed inactive step-count and debug/fake-data database methods from the active persistence API.
- Retired the legacy step schema in ADR 0001 and schema v3 migration, including sentinel record cleanup.

Remaining:

- Continue migrating UI callers from `AppDatabase` to repository-style modules.
- Move details and statistics reads behind persistence interfaces.

## Phase 3: Domain Model and Aggregation

Status: in progress

- Extract activity display models and event status logic out of generated persistence files.
- Moved activity detail heatmap and time-slot aggregation out of Widgets into `activity_detail_analytics.dart`.
- Moved statistics activity-count and time-slot aggregation out of Widgets into `statistics_analytics.dart`.
- Dropped legacy step tables and record sentinel assumptions from the active schema through a tested v3 migration.
- Moved activity display models and analytics read models into `lib/domain/` so analytics no longer imports Drift generated row types.
- Added explicit `ActivityAggregateTotals` invariants for plain and timed record accumulation.
- Define invariants for timed records, plain records, values, and units.

## Phase 4: UI Composition

Status: in progress

- Split large widgets into route, view model, and small render widgets.
- Make loading, empty, and error states consistent across list/detail/statistics views.
- Replaced the route pop/push activity-list refresh hack with `activityListProvider` invalidation.
- Moved activity description editing out of shared common widgets and behind `activityDescriptionProvider`.
- Removed the old settings-page DB viewer, delete-all-data button, fake-data generator, and inactive step-count route.

## Phase 5: Dependency and Platform Modernization

Status: pending

- Removed unused Firebase dependency, generated options, and stale Firestore configuration.
- Upgrade dependencies in small batches with tests between batches.
- Then evaluate Flutter SDK upgrade separately.
- Removed unused `share` and discontinued `moor_db_viewer`.

## First Execution Slice

The first slice should make the quality gates meaningful without changing product behavior:

1. Fix lint/test configuration.
2. Add app startup smoke tests.
3. Move platform bootstrap out of `main.dart`.
4. Keep Windows build green.

## Architecture Candidates

### Strong: Persistence Module

Files: `lib/persistence/database/app_database.dart`, `lib/persistence/database/tables.dart`, `lib/main.dart`, callers in list/detail/statistics pages.

Problem: UI modules know too much about the database implementation and persistence setup. Record lifecycle methods update multiple tables with manual ordering requirements.

Solution: Make persistence a deeper module with a small interface for activity, record, unit, and step operations. Hide platform bootstrap and transaction details inside the module.

Benefits: Higher locality for data bugs, better leverage for tests, and less database knowledge leaking into UI widgets.

### Strong: Analytics Module

Files: `lib/EventsDetails/eventDetails.dart`, `lib/analytics/activity_detail_analytics.dart`, `lib/Statistics/statistics.dart`, `lib/heatmap_calendar/`.

Problem: Widgets compute domain aggregates directly, so chart bugs require widget tests and UI files are hard to understand.

Solution: Extract pure aggregation functions for daily totals, time-slot distributions, and cross-activity summaries.

Benefits: Fast unit tests, smaller Widgets, and a reusable interface for future analytics views.

### Completed: Debug Surface

Files: `lib/settingPage.dart`, deleted `lib/addFakeData.dart`, deleted `lib/StepCount/stepStatistics.dart`, removed `moor_db_viewer` dependency.

Problem: Development-only actions are visible in the product UI and can delete all local data.

Solution: Removed the inactive debug tools and discontinued viewer dependency instead of preserving another developer-only route.

Benefits: Lower product risk with minimal behavioral change for developers.

# Repo Quality Roadmap

## Goal

Bring this repo from a working prototype to a maintainable Flutter app that can be built, tested, and refactored safely. Windows desktop is the immediate development target; Android/iOS/web should not be made worse without an explicit ADR.

## Current Baseline

- Windows release build works.
- `flutter analyze` is green under Flutter 3.44 / Dart 3.12 with `flutter_lints` 6.
- `flutter test` is green with bootstrap, repository, persistence lifecycle, analytics, and structural cleanup tests.
- Persistence is mostly behind repository Modules; cached aggregate fields remain and are protected by record lifecycle tests.
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
.\tool\check.ps1 -Codegen
.\tool\check.ps1 -WindowsBuild
```

Use `.\tool\check.ps1 -Codegen` after changing Drift tables, `.drift` files,
repository query shapes, or dependency versions that affect code generation.
The current `build_runner` no longer accepts `--delete-conflicting-outputs`;
run `dart run build_runner build` directly.

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
- Made Record Lifecycle writes rebuild Aggregate Totals snapshots from completed records after plain add, timed stop, and active timed-record cancel, so drifted cached totals self-heal on the next lifecycle write.
- Centralized Aggregate Totals snapshot repair in `ActivityAggregateStore` and exposed `ActivityRepository.repairAggregateTotals()` as the explicit rebuild command while keeping cached totals in the schema.
- Made Aggregate Totals repair preserve an active Timed Activity `lastRecordId` while recomputing `sumTime` and `sumVal` only from completed records.
- Replaced the short timed-record delete prompt with a cancel policy for accidental starts under five seconds.
- Introduced `ActivityRepository` and migrated activity creation plus the activity-list recording flow to it.
- Migrated activity detail record reads, deletion, and description edits to `ActivityRepository`.
- Introduced `UnitRepository` and migrated unit management plus unit-list loading to it.
- Mapped unit UI data through a domain `ActivityUnit` read model so unit screens no longer import the Drift database module.
- Introduced `StatisticsRepository` and migrated statistics range reads to it.
- Moved production `AppDatabase` construction and repository adapter wiring behind Riverpod persistence providers.
- Moved Activity, Unit, and Statistics Repository Interfaces into `lib/domain/`, renamed concrete persistence Adapters to `drift_*_repository.dart`, and exposed narrow Activity read/write/Record Lifecycle providers instead of the broad repository Interface.
- Moved platform-specific sqflite executor setup out of `app_database.dart` and into a database bootstrap module.
- Moved activity display-model shaping out of `AppDatabase` and into `ActivityRepository`.
- Moved unit and statistics table-specific query helpers out of `AppDatabase` and into their repositories.
- Moved remaining activity-specific table helpers out of `AppDatabase` and into `ActivityRepository` / `RecordLifecycleStore`.
- Added tests around record lifecycle, aggregate totals, latest step lookup, repository activity creation, and repository activity recording.
- Added tests for unit add/list/delete and duplicate-name protection through the repository.
- Removed inactive step-count and debug/fake-data database methods from the active persistence API.
- Retired the legacy step schema in ADR 0001 and schema v3 migration, including sentinel record cleanup.

Remaining:

- Continue migrating UI callers from `AppDatabase` to repository-style modules.
- Keep `AppDatabase` limited to schema, migrations, generated Drift access, and bootstrap wiring.

## Phase 3: Domain Model and Aggregation

Status: in progress

- Extract activity display models and event status logic out of generated persistence files.
- Moved activity display-model shaping from `AppDatabase` into `ActivityRepository`.
- Moved activity detail heatmap and time-slot aggregation out of Widgets into `activity_detail_analytics.dart`.
- Extracted activity detail chart rendering and heatmap adapters out of the detail route.
- Moved statistics activity-count and time-slot aggregation out of Widgets into `statistics_analytics.dart`.
- Dropped legacy step tables and record sentinel assumptions from the active schema through a tested v3 migration.
- Moved activity display models and analytics read models into `lib/domain/` so analytics no longer imports Drift generated row types.
- Replaced mutable activity models plus `EventStatus` with immutable sealed `PlainActivity`, `InactiveTimedActivity`, and `ActiveTimedActivity` snapshots, making an active Timed Activity's start time non-null by construction.
- Added a pure `DateRange` value object so persistence and analytics modules no longer depend on Flutter `DateTimeRange`.
- Extracted statistics chart rendering and `fl_chart` adapters out of the statistics page route.
- Moved activity-detail and statistics chart view-model construction out of chart adapters and into tested analytics modules.
- Moved heatmap calendar date geometry, placeholder cells, month spacer weeks, and value-to-level mapping out of Widgets into `heatmap_calendar_model.dart`.
- Added explicit `ActivityAggregateTotals` invariants for plain and timed record accumulation.
- Added `ActivityAggregateSnapshot` rebuild rules for cached `lastRecordId`, `sumTime`, and `sumVal`.
- Added active Timed Activity snapshot rules so Aggregate Totals repair keeps the active record as `lastRecordId` without counting it in completed totals.
- Added `ActivitySnapshotStore`: activity list reads now use one Events-to-active-Records join instead of N+1 last-record queries, fail fast on malformed active histories, and do not expose `lastRecordId` outside persistence.
- Changed Activity detail navigation to pass only an Activity ID and reload a fresh Activity Snapshot, removing the stale list-snapshot contract.
- Define invariants for timed records, plain records, values, and units.

## Phase 4: UI Composition

Status: in progress

- Split large widgets into route, view model, and small render widgets.
- Make loading, empty, and error states consistent across list/detail/statistics views.
- Replaced the route pop/push activity-list refresh hack with `activityListProvider` invalidation.
- Moved activity description editing out of shared common widgets and behind `activityDescriptionProvider`.
- Moved activity description edit-mode state behind `activityDescriptionEditingProvider`.
- Moved add-activity draft choices behind `activityEditorCareTimeProvider` and `activityEditorSelectedUnitProvider`.
- Moved unit input controller ownership into the shared dialog so `UnitsManager` is stateless.
- Moved activity list mutations, activity creation, and unit management from repository factory calls to Riverpod repository providers.
- Removed incomplete long-press manual time entry controls that opened a picker without applying the selected time.
- Moved active-timer ticking state out of the whole activity tile and behind `elapsedDurationProvider`.
- Replaced shared text-input dialog `StatefulBuilder` state with controller-driven rebuilds.
- Moved the statistics date range into Riverpod state and kept chart data loading behind `statisticsProvider`.
- Moved activity recording decisions out of `EventsList/util.dart` and into a tested application Module.
- Folded the shallow `ActivityRecordingController` and `ActivityRecordingActions` chain into `ActivityListController`, removing the internal outcome protocol while preserving prompts, refresh, short-start cancellation, and notifications behind one Interface.
- Split broad Riverpod state ownership out of `stateProviders.dart` into focused modules under `lib/state/`, then removed the compatibility facade after active imports were migrated.
- Made activity detail deletion return a route result so `EventList` is the single owner of activity-list refresh after deletion.
- Migrated small mutable UI state from legacy Riverpod `StateProvider` to Riverpod 3 `NotifierProvider` through `MutableState`.
- Migrated unit selection to Flutter's current `RadioGroup` Interface.
- Standardized async loading, empty, error, and retry states behind `AsyncStateView`.
- Moved add-activity, activity-detail deletion/description-save, and unit-management mutation/refresh/notification policy behind tested application controllers.
- Deepened `ActivityListController` so activity-list recording and detail-route refresh policy sit behind one application Module, leaving `EventList` to supply UI adapters for prompts, navigation, notifications, and provider invalidation.
- Removed the pass-through `EventDataHolder` inherited widget and passed activity models directly to list tiles.
- Removed unused long-press callback surface from shared button helpers after the incomplete manual-time-entry controls were retired.
- Moved activity-detail delete-and-exit policy behind `ActivityDetailController`, leaving the route to provide only the confirmation dialog and navigation adapter.
- Moved unit delete confirmation and dismiss permission behind `UnitManagementController`, so failed deletes no longer dismiss the unit tile before refresh repairs the list.
- Moved add-activity create-and-exit policy behind `ActivityEditorController`, leaving `EventEditor` to provide form validation, draft values, notifications, and the navigation adapter.
- Replaced the heatmap calendar's global empty-date sentinel with typed placeholder cells produced by the calendar model.
- Removed the old settings-page DB viewer, delete-all-data button, fake-data generator, and inactive step-count route.
- Replaced broad Activity Repository test fakes with narrow `ActivityReader`, `ActivityWriter`, and `RecordLifecycle` Adapters; recording behavior tests now cover the exact five-second cancellation threshold.

## Phase 5: Dependency and Platform Modernization

Status: in progress

- Removed unused Firebase dependency, generated options, and stale Firestore configuration.
- Removed the single-use `sprintf` dependency after replacing it with Dart string interpolation.
- Before the SDK upgrade, upgraded the last Flutter-3.10-compatible dependency batch: Drift 2.14, drift_sqflite 2.0, build_runner 2.4, Riverpod 2.4, sqflite/path_provider/sqlite libraries, and fluttertoast.
- Removed unused `cupertino_icons` and stale launcher-icon config.
- Renamed legacy `sql.moor` to `sql.drift` and regenerated Drift code with the Drift 2 generator.
- Then evaluate Flutter SDK upgrade separately.
- Removed unused `share` and discontinued `moor_db_viewer`.
- Upgraded the local development toolchain to Flutter 3.44.5 / Dart 3.12.2 and raised the repo SDK constraint to Dart 3.12.
- Upgraded previously SDK-blocked packages: Riverpod 3.3, fl_chart 1.2, fluttertoast 9.1, flutter_lints 6, Drift 2.34, build_runner 2.15, and current sqflite/path_provider stacks.
- Kept `sqlite3_flutter_libs` on the Windows-compatible 0.5.x line; `0.6.0+eol` removes the Windows sqlite bundle and causes startup to fail before the first Flutter frame.
- Regenerated Drift outputs with the current build_runner command and removed discontinued transitive packages from the lockfile, including `js`, `build_resolvers`, and `build_runner_core`.

Remaining:

- Android SDK is not installed on this workstation, so Android runtime verification remains unavailable locally.
- Revisit any remaining outdated transitive versions only when a direct dependency or Flutter SDK release makes them resolvable.

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

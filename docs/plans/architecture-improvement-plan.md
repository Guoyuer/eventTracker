# Architecture Improvement Plan

## Purpose

This plan describes how to move `event_tracker` from a working prototype toward a maintainable Flutter app. The main strategy is to deepen the important modules: persistence first, analytics second, UI composition third, and dependency modernization last.

The goal is not a cosmetic refactor. Each slice should improve locality, testability, or runtime safety while keeping these gates green:

```powershell
flutter analyze
flutter test
flutter build windows
```

During active Windows development, use the faster loop documented in `docs/plans/repo-quality-roadmap.md`: keep `flutter run -d windows` alive, hot reload Dart/UI edits with `r`, run targeted tests while iterating, and reserve `flutter build windows` for completed slices or startup/native/runtime changes.

## Architectural Direction

### 1. Deepen the Persistence Module

Current problem: `AppDatabase` is too broad. It owns schema, platform persistence behavior, record lifecycle operations, unit operations, and display model shaping.

Target shape:

- `ActivityRepository`: activity and record lifecycle operations.
- `UnitRepository`: unit list, create, delete.
- `DatabaseBootstrap`: platform-specific database setup.
- `AppDatabase`: Drift tables, generated accessors, and low-level persistence only.

Rules:

- UI modules should not create `RecordsCompanion` or `EventsCompanion`.
- UI modules should not create or access `AppDatabase` directly once a repository seam exists.
- Record lifecycle changes must be transactional.
- Records are the only persisted source of Activity state and totals.

Completed slice:

- Moved unit management behind `UnitRepository`.
- Migrated `UnitManager` and unit loading in `EventEditor` to `UnitRepository`.
- Mapped unit UI data through a domain `ActivityUnit` read model instead of generated Drift rows.
- Added tests for add/delete/list unit behavior and duplicate-name protection.
- Moved activity creation behind `ActivityRepository`.
- Migrated `EventEditor` so it no longer creates `EventsCompanion` or writes through `AppDatabase` directly.
- Added tests for activity creation and duplicate-name protection through the repository.
- Removed inactive step-count UI, fake-data generation, debug DB viewer, and their direct database helper methods.
- Removed unused/discontinued dependencies `share` and `moor_db_viewer`.
- Moved activity detail record reads, activity deletion, and description reads/writes behind `ActivityRepository`.
- Moved Record Lifecycle writes into `RecordLifecycleStore` and validation/summary rules into pure `ActivityRecordHistory`.
- Renamed accidental short-start cleanup from delete semantics to `cancelActiveTimedRecord`.
- Retired the legacy step schema via ADR 0001 and schema v3 migration.
- Renamed the uppercase `DAO` module path to `lib/persistence/database/`.
- Kept `flutter analyze`, `flutter test`, and `flutter build windows` green.

Next slice:

1. Extract cross-activity summary aggregation used by `Statistics`.
2. Move statistics time-slot stacking into a pure analytics module.
3. Add tests for multi-activity counts and stacked time slots.
4. Keep `flutter analyze`, `flutter test`, and `flutter build windows` green.

### 2. Keep Records as the Single Source of Truth

Current status: completed.

- Schema v4 removed `lastRecordId`, `sumTime`, and `sumVal` from Events.
- `ActivityRecordHistory` validates Plain and Timed Record shapes and computes occurrence count, duration, value, and active state.
- `ActivitySnapshotStore` loads Events and Records in one join and produces immutable Activity Snapshots from the validated history.
- `RecordLifecycleStore` rejects missing Activities, wrong-type operations, duplicate starts, and stops before start.
- The Records table enforces Event foreign keys with cascade deletion, valid timestamp/value shapes, and one active Record per Activity.
- Migration validates existing histories before rebuilding tables and fails instead of guessing how to repair corrupt data.
- Schema v5 and domain input validation canonicalize Activity/Unit names and reject non-finite Record values at both application and database boundaries.
- Schema v6 stores Activity-to-Unit references as `unitId`, maps legacy labels during migration, and prevents deletion of Units still in use.
- Repository and Record History rules now prevent dangling Unit writes/deletes and enforce the same Unit/value contract used by the UI.
- `ActivityAggregateStore`, cached-total repair, and their duplicate incremental rules were deleted.

Future rule:

- Do not add Activity summary caches without a measured performance problem, an invalidation owner, and an ADR.

### 3. Extract Analytics from Widgets

Current problem: `EventDetails` and `Statistics` compute chart and heatmap data inside Widgets. That makes chart bugs hard to test and makes the UI files large.

Current status:

- Extracted activity detail heatmap daily totals into `activity_detail_analytics.dart`.
- Extracted activity detail time-slot distribution into `activity_detail_analytics.dart`.
- Extracted activity detail chart rendering, heatmap wiring, and `fl_chart` adapters into `EventsDetails/activity_detail_charts.dart`.
- Removed the old `EventsDetails/util.dart` helper after moving its behavior behind typed analytics results.
- Added tests for timed duration, plain counts, plain values, record filtering, and adjacent-hour grouping.
- Extracted statistics activity counts and hourly slot aggregation into `statistics_analytics.dart`.
- Added tests for multi-activity statistics counts, hourly buckets, dangling activity references, and adjacent-hour grouping.
- Added `docs/architecture/module-flow.md` with Mermaid diagrams for the active module flow and remaining seams.
- Moved statistics range-record and activity-map reads behind `StatisticsRepository`.
- Moved activity display models plus analytics record/activity read models into `lib/domain/`, with repositories mapping from Drift rows.
- Moved activity display-model shaping out of `AppDatabase` and into `ActivityRepository`.
- Extracted statistics chart rendering and `fl_chart` adapters into `Statistics/statistics_charts.dart`.
- Extracted activity-detail and statistics chart view-model construction into pure analytics modules, leaving chart widgets as rendering adapters.
- Extracted heatmap calendar geometry and value-to-level mapping into `heatmap_calendar_model.dart`, leaving heatmap widgets as rendering adapters.
- Introduced a pure `DateRange` domain value object so persistence and analytics seams no longer expose Flutter `DateTimeRange`.
- Moved production `AppDatabase` construction and repository adapter wiring into Riverpod persistence providers, removing the old `DBHandle` singleton and no-argument repository factories.
- Moved platform-specific sqflite executor setup into `database_bootstrap.dart`, leaving `AppDatabase` focused on Drift schema, migrations, and low-level queries.
- Moved unit and statistics table-specific query helpers into `UnitRepository` and `StatisticsRepository`.
- Moved remaining activity-specific table helpers into `ActivityRepository` and `RecordLifecycleStore`, leaving `AppDatabase` to expose generated Drift access, schema, migrations, and bootstrap wiring.
- Moved Repository Interfaces to `lib/domain/` and kept concrete Drift Adapters in explicitly named `lib/persistence/drift_*_repository.dart` files.
- Split the broad Activity Repository seam into `ActivityReader`, `ActivityWriter`, and `RecordLifecycle` Interfaces for application/state callers while retaining one composite production Adapter internally.
- Added `ActivitySnapshotStore`, which reads Events and active Records in one joined query and is the single owner of Activity read-model validation.
- Replaced mutable activity models and `EventStatus` with immutable sealed Activity Snapshot types, so active Timed Activities always have a start time.
- Activity detail routes now carry an Activity ID and reload through `activitySnapshotProvider` instead of receiving a stale list snapshot.
- Replaced ambiguous date ranges with `CalendarDateRange` and half-open `DateInterval` Modules; Statistics no longer leaks `+1 day` compensation from the Widget into persistence.
- Statistics reads Records and Activities in one transaction and uses `>= start AND < endExclusive`, eliminating the next-day-midnight inclusion bug.
- Architecture tests parse Dart import directives with analyzer and enforce durable layer boundaries; the old source-string implementation checks have been deleted.

Target modules:

- `activity_detail_analytics.dart`
- `statistics_analytics.dart`
- `activity_summary.dart`
- `heatmap_series.dart`

Rules:

- Analytics modules should be pure Dart where possible.
- Inputs should be domain models or simple value objects, not Widgets.
- Tests should assert chart input data without rendering Flutter charts.

Remaining analytics slice:

1. Replace Widget-local calculation with calls into analytics modules where more remain.
2. Split chart rendering further if future chart types add more adapter complexity.

### 4. Retired Legacy Step Schema

Current status: completed.

Completed direction:

- ADR 0001 records that step tracking is out of scope for the active product.
- Schema v3 deletes legacy `records.event_id = -1` sentinel rows.
- Schema v3 drops `steps`, `step_offset`, and the `step_time` index.
- Migration tests cover an old v2 database with step tables and sentinel records.

Future rule:

- Step tracking can return only as a new explicit module with its own product decision and schema.

### 5. Move UI Refresh to Riverpod

Current problem: list refresh uses notifications plus route pop/push. This makes UI state hard to reason about.

Current status:

- Added `activityListProvider`.
- `EventList` watches the provider instead of owning a one-shot future.
- `ReloadEventsN` now invalidates `activityListProvider` instead of popping and pushing `MainPage`.
- `ActivityDescriptionEditor` reads and writes descriptions through `activityDescriptionProvider` instead of creating repositories inside shared common widgets.
- `ActivityDescriptionEditor` keeps edit-mode state in `activityDescriptionEditingProvider` instead of local widget state.
- `EventEditor` keeps add-activity draft choices in Riverpod providers instead of local widget state.
- `UnitsManager` no longer owns a text input controller; the shared dialog owns and disposes it.
- Activity list mutations, activity creation, and unit management now read repositories through Riverpod providers instead of calling repository factories in widgets.
- Incomplete long-press manual time entry controls were removed because they displayed a picker without applying the selected time.
- `StatisticPage` now keeps the selected date range in `selectedStatisticsRangeProvider` and loads chart data through `statisticsProvider`.
- `EventTile` is now stateless; active-timer blinking is isolated in `ActiveTimingHighlight`, and elapsed-time text is driven by `elapsedDurationProvider`.
- Activity recording, value prompts, the five-second accidental-start rule, refresh, and notification policy now live behind `ActivityListController`.
- Deleted the shallow `ActivityRecordingController` and `ActivityRecordingActions` Modules plus their private outcome protocol after behavior tests moved to the deeper activity-list Interface.
- Activity detail deletion now returns a route result; `EventList` owns the single `activityListProvider` invalidation after deletion.
- Feature state providers now live under `lib/state/`, and the old `stateProviders.dart` compatibility facade has been removed.
- Small mutable UI state now uses Riverpod 3 `NotifierProvider` through `MutableState` instead of legacy `StateProvider`.
- Async loading, empty, error, and retry rendering now goes through `AsyncStateView` instead of page-local `.when` branches.
- Add-activity, activity-detail deletion/description-save, and unit-management mutation policy now lives behind small application controllers, leaving route Widgets as UI Adapters for forms, dialogs, and navigation.
- Activity-list recording and detail-route refresh policy now live behind `ActivityListController`; `EventList` supplies UI adapters for value prompts, route navigation, notifications, and provider invalidation.
- `EventList` no longer uses the pass-through `EventDataHolder` inherited widget, and shared button helpers no longer expose unused long-press callbacks from retired manual-time-entry controls.
- Activity-detail deletion now exits the route through `ActivityDetailController`, with the Widget only providing confirmation and navigation adapters.
- Unit deletion now runs confirmation, repository mutation, refresh, notification, and Dismissible permission through `UnitManagementController`, preventing failed deletes from visually dismissing rows before refresh.
- Add-activity creation now exits through `ActivityEditorController`, with `EventEditor` limited to form validation, draft values, notification, and navigation adapters.

Target shape:

- `activityListProvider`
- `unitListProvider`
- `statisticsProvider`

Rules:

- Repository mutations should invalidate relevant providers.
- Routes should not be rebuilt just to refresh data.
- Loading, empty, and error states should be shared and consistent.

Next UI state slice:

1. Continue extracting route interaction coordinators where Widgets still combine prompts, navigation, mutation, refresh, and notification policy.
2. Keep Widgets as UI Adapters and move reusable interaction policy behind tested application Modules.
3. Delete compatibility files as soon as active imports have moved.

### 6. Keep Debug Tools Out of Release UI

Current status: DB viewer, delete-all-data, and fake-data generation were removed from the settings page.

Target shape:

- Avoid importing debug-only packages from production routes.
- Reintroduce developer tooling only when it has a maintained dependency and an explicit owner.

Next slice:

1. Keep `SettingPage` focused on user settings.
2. Add developer tooling only after repository seams can support it safely.

### 7. Modernize Dependencies Last

Current problem: dependency drift can hide platform breakage and leave the app on APIs that are already deprecated or moved to compatibility layers.

Current status:

- Local development SDK is Flutter 3.44.5 / Dart 3.12.2.
- The repo SDK constraint is Dart 3.12.
- Previously SDK-blocked packages have been upgraded: Riverpod 3.3, fl_chart 1.2, fluttertoast 9.1, flutter_lints 6, Drift 2.34, build_runner 2.15, and current sqflite/path_provider stacks.
- `sqlite3_flutter_libs` stays pinned to the Windows-compatible 0.5.x line because `0.6.0+eol` no longer bundles the sqlite runtime needed by `sqflite_common_ffi` on Windows.
- Riverpod legacy `StateProvider` was replaced with `NotifierProvider`-based state Modules.
- fl_chart tooltip adapters and Flutter Radio selection were migrated to their current Interfaces.
- Removed unused `cupertino_icons` and stale `flutter_icons` configuration.
- Migrated the Drift SQL include from `sql.moor` to `sql.drift` and regenerated `app_database.g.dart`.

Order:

1. Keep tests green while finishing route interaction and aggregate seams.
2. Revisit remaining outdated transitive versions only when a direct dependency or Flutter SDK release makes them resolvable.
3. Keep Android/iOS/web compatibility practical, but treat Windows as the verified runtime until Android SDK is installed locally.

Rule:

- One dependency family per slice. Run all quality gates after each slice.

## Execution Order

Recommended order from here:

1. Keep the Unit deletion workflow explicit; do not weaken the RESTRICT boundary with silent nulling.
2. Audit platform support after Android SDK installation or CI coverage is available.

## Definition of Done for Each Slice

- Relevant UI code no longer crosses the old persistence seam directly.
- New or changed business behavior has a test.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build windows` passes.
- `docs/plans/repo-quality-roadmap.md` is updated if phase status changes.

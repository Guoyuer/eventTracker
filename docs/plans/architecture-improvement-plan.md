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
- Cached aggregate totals must be updated in one place.

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
- Moved record lifecycle writes and Aggregate Totals updates into `RecordLifecycleStore` and the pure `ActivityAggregateTotals` rule object.
- Renamed accidental short-start cleanup from delete semantics to `cancelActiveTimedRecord`.
- Retired the legacy step schema via ADR 0001 and schema v3 migration.
- Renamed the uppercase `DAO` module path to `lib/persistence/database/`.
- Kept `flutter analyze`, `flutter test`, and `flutter build windows` green.

Next slice:

1. Extract cross-activity summary aggregation used by `Statistics`.
2. Move statistics time-slot stacking into a pure analytics module.
3. Add tests for multi-activity counts and stacked time slots.
4. Keep `flutter analyze`, `flutter test`, and `flutter build windows` green.

### 2. Make Aggregate Totals an Explicit Rule

Current problem: `sumTime`, `sumVal`, and `lastRecordId` are cached on activities and can drift from records if updates happen in multiple places.

Current status:

- `RecordLifecycleStore` owns plain record add, timed record start, timed record stop, and active timed record cancel writes.
- `ActivityAggregateTotals` owns plain and timed accumulation rules and fails fast on negative timed durations.
- Accidental timed starts under five seconds now cancel directly instead of asking the user to delete or continue.

Target shape:

- Introduce a small lifecycle module or internal repository helper for aggregate updates.
- Keep all aggregate mutations behind repository methods.
- Add tests for every lifecycle transition:
  - plain record add
  - timed record start
  - timed record stop
  - active timed record cancel
  - event delete
  - value and duration accumulation

Short-term approach:

- Keep the current schema.
- Keep cached totals.
- Concentrate update rules and keep tests thick around them.

Longer-term option:

- Recompute aggregate totals from records for some views, or add a repair/rebuild command if cached totals remain.

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
- Activity recording actions now live in `ActivityRecordingActions`, so add/start/stop/cancel and value-prompt decisions can be tested without widget plumbing.
- Feature state providers now live under `lib/state/`, with `stateProviders.dart` kept as a compatibility facade instead of the active owner module.
- Async loading, empty, error, and retry rendering now goes through `AsyncStateView` instead of page-local `.when` branches.

Target shape:

- `activityListProvider`
- `unitListProvider`
- `statisticsProvider`

Rules:

- Repository mutations should invalidate relevant providers.
- Routes should not be rebuilt just to refresh data.
- Loading, empty, and error states should be shared and consistent.

Next UI state slice:

1. Replace `ReloadEventsN` dispatches with direct provider invalidation where `WidgetRef` is available.
2. Make loading, empty, and error states consistent across activity, detail, and statistics views.

### 6. Keep Debug Tools Out of Release UI

Current status: DB viewer, delete-all-data, and fake-data generation were removed from the settings page.

Target shape:

- Avoid importing debug-only packages from production routes.
- Reintroduce developer tooling only when it has a maintained dependency and an explicit owner.

Next slice:

1. Keep `SettingPage` focused on user settings.
2. Add developer tooling only after repository seams can support it safely.

### 7. Modernize Dependencies Last

Current problem: several packages are old or discontinued, but upgrading before architecture/test coverage would mix migration bugs with existing design debt.

Current status:

- Current local SDK is Flutter 3.10 / Dart 3.0, so most latest 2026 package versions are SDK-blocked.
- Upgraded the dependency batch that builds on the current SDK: Drift 2.14, drift_sqflite 2.0, build_runner 2.4, Riverpod 2.4, sqflite/path_provider/sqlite packages, and fluttertoast. Kept `fl_chart` pinned at 0.63 because 0.65 resolves but fails Windows build on Flutter 3.10 due to `TextScaler`.
- Removed unused `cupertino_icons` and stale `flutter_icons` configuration.
- Migrated the Drift SQL include from `sql.moor` to `sql.drift` and regenerated `app_database.g.dart`.

Order:

1. Keep tests green while finishing persistence and analytics seams.
2. Upgrade Flutter and Dart SDK in a dedicated platform slice.
3. After SDK upgrade, revisit the packages still SDK-blocked by Flutter 3.10 / Dart 3.0.

Rule:

- One dependency family per slice. Run all quality gates after each slice.

## Execution Order

Recommended order from here:

1. Upgrade Flutter and Dart SDK in a dedicated platform slice.
2. Continue shrinking route Widgets by extracting remaining interaction coordinators.
3. Revisit cached aggregate repair/rebuild options if product usage expands.

## Definition of Done for Each Slice

- Relevant UI code no longer crosses the old persistence seam directly.
- New or changed business behavior has a test.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build windows` passes.
- `docs/plans/repo-quality-roadmap.md` is updated if phase status changes.

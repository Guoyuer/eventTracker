# Architecture Improvement Plan

## Purpose

This plan describes how to move `event_tracker` from a working prototype toward a maintainable Flutter app. The main strategy is to deepen the important modules: persistence first, analytics second, UI composition third, and dependency modernization last.

The goal is not a cosmetic refactor. Each slice should improve locality, testability, or runtime safety while keeping these gates green:

```powershell
flutter analyze
flutter test
flutter build windows
```

## Architectural Direction

### 1. Deepen the Persistence Module

Current problem: `AppDatabase` is too broad. It owns schema, platform persistence behavior, record lifecycle operations, unit operations, step data, display model shaping, and debug utilities.

Target shape:

- `ActivityRepository`: activity and record lifecycle operations.
- `UnitRepository`: unit list, create, delete.
- `StepRepository`: step data reads/writes.
- `DatabaseBootstrap`: platform-specific database setup.
- `AppDatabase`: Drift tables, generated accessors, and low-level persistence only.

Rules:

- UI modules should not create `RecordsCompanion` or `EventsCompanion`.
- UI modules should not call `DBHandle().db` directly once a repository seam exists.
- Record lifecycle changes must be transactional.
- Cached aggregate totals must be updated in one place.

Completed slice:

- Moved unit management behind `UnitRepository`.
- Migrated `UnitManager` and unit loading in `EventEditor` to `UnitRepository`.
- Added tests for add/delete/list unit behavior and duplicate-name protection.
- Moved activity creation behind `ActivityRepository`.
- Migrated `EventEditor` so it no longer creates `EventsCompanion` or calls `DBHandle().db.addEventInDB`.
- Added tests for activity creation and duplicate-name protection through the repository.
- Kept `flutter analyze`, `flutter test`, and `flutter build windows` green.

Next slice:

1. Extract daily totals used by activity detail heatmaps.
2. Extract time-slot distribution used by activity detail bar charts.
3. Add tests for timed and plain activities, with and without units.
4. Keep `flutter analyze`, `flutter test`, and `flutter build windows` green.

### 2. Make Aggregate Totals an Explicit Rule

Current problem: `sumTime`, `sumVal`, and `lastRecordId` are cached on activities and can drift from records if updates happen in multiple places.

Target shape:

- Introduce a small lifecycle module or internal repository helper for aggregate updates.
- Keep all aggregate mutations behind repository methods.
- Add tests for every lifecycle transition:
  - plain record add
  - timed record start
  - timed record stop
  - active timed record delete
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

Target modules:

- `daily_activity_totals.dart`
- `time_slot_distribution.dart`
- `activity_summary.dart`
- `heatmap_series.dart`

Rules:

- Analytics modules should be pure Dart where possible.
- Inputs should be domain models or simple value objects, not Widgets.
- Tests should assert chart input data without rendering Flutter charts.

Next analytics slice:

1. Extract daily totals used by activity detail heatmaps.
2. Extract time-slot distribution used by activity detail bar charts.
3. Add tests for timed and plain activities, with and without units.
4. Replace Widget-local calculation with calls into analytics modules.

### 4. Fix Step Record Design

Current problem: step data is partly modeled as `records.eventId = -1`, which leaks a sentinel into normal activity queries.

Preferred direction:

- Treat step data as its own persistence model through `StepRepository`.
- Stop exposing `eventId = -1` outside the persistence module.

Decision needed:

- Either migrate step records out of `records`, or write an ADR documenting why the sentinel remains.

Minimal next step:

- Introduce a named constant or repository method for step records so `-1` does not spread further.

### 5. Move UI Refresh to Riverpod

Current problem: list refresh uses notifications plus route pop/push. This makes UI state hard to reason about.

Target shape:

- `activityListProvider`
- `unitListProvider`
- `statisticsProvider`

Rules:

- Repository mutations should invalidate relevant providers.
- Routes should not be rebuilt just to refresh data.
- Loading, empty, and error states should be shared and consistent.

Next UI state slice:

1. Add an activity list provider.
2. Use it in `EventList`.
3. Replace `ReloadEventsN` in the activity list flow.
4. Keep old notification behavior only where not yet migrated.

### 6. Keep Debug Tools Out of Release UI

Current status: DB viewer, delete-all-data, and fake-data generation are gated by `kDebugMode`.

Target shape:

- Move debug tools into a dedicated developer route.
- Avoid importing debug-only packages from production routes if possible.
- Keep destructive debug actions explicit and isolated.

Next slice:

1. Create `DeveloperPage`.
2. Move DB viewer, delete-all-data, and fake-data actions there.
3. Keep `SettingPage` focused on user settings.

### 7. Modernize Dependencies Last

Current problem: several packages are old or discontinued, but upgrading before architecture/test coverage would mix migration bugs with existing design debt.

Order:

1. Keep tests green while finishing persistence and analytics seams.
2. Remove Firebase if cloud sync is not planned.
3. Replace discontinued packages:
   - `share` -> `share_plus`, or remove if unused.
   - `moor_db_viewer` -> debug-only replacement or removal.
4. Upgrade Drift in a dedicated branch/slice.
5. Upgrade Riverpod separately.
6. Upgrade Flutter SDK separately.

Rule:

- One dependency family per slice. Run all quality gates after each slice.

## Execution Order

Recommended order from here:

1. Activity detail analytics extraction.
2. Step repository and sentinel containment.
3. Riverpod activity list provider.
4. Developer page split.
5. Dependency cleanup and upgrade batches.

## Definition of Done for Each Slice

- Relevant UI code no longer crosses the old persistence seam directly.
- New or changed business behavior has a test.
- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build windows` passes.
- `docs/plans/repo-quality-roadmap.md` is updated if phase status changes.

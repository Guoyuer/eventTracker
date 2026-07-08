# Repo Quality Roadmap

## Goal

Bring this repo from a working prototype to a maintainable Flutter app that can be built, tested, and refactored safely. Windows desktop is the immediate development target; Android/iOS/web should not be made worse without an explicit ADR.

## Current Baseline

- Windows release build works.
- `flutter analyze` is green under the initial legacy lint profile.
- `flutter test` is green with bootstrap and persistence lifecycle tests.
- Persistence is tightly coupled to UI and uses cached aggregate fields that can drift from records.
- Platform support is uneven: Firebase is configured only for Web/Android/iOS, while Windows needs sqflite FFI.
- `windows/` and `pubspec.lock` are tracked for reproducible desktop development.

## Quality Gates

Every completed slice should preserve or improve these commands:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
```

If a gate is temporarily red, document the exact failure in this file before moving on.

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

- Rename `DAO` to a lower-case persistence module path.
- Replaced ad hoc string SQL updates in record lifecycle and latest-step reads with typed Drift operations.
- Continue making record lifecycle operations transactional. Completed for plain record add, timed record start, timed record stop, active timed record delete, and event delete.
- Introduced `ActivityRepository` and migrated activity creation plus the activity-list recording flow to it.
- Introduced `UnitRepository` and migrated unit management plus unit-list loading to it.
- Move desktop sqflite setup behind a database bootstrap module.
- Added tests around record lifecycle, aggregate totals, latest step lookup, repository activity creation, and repository activity recording.
- Added tests for unit add/list/delete and duplicate-name protection through the repository.

Remaining:

- Rename `DAO` to a lower-case persistence module path.
- Continue migrating UI callers from `AppDatabase` to repository-style modules.
- Move details and statistics reads behind persistence interfaces.
- Decide whether debug fake-data generation should use repositories or remain a database-only developer tool.

## Phase 3: Domain Model and Aggregation

Status: pending

- Extract activity display models and event status logic out of generated persistence files.
- Move heatmap and time-slot aggregation out of Widgets into pure Dart modules.
- Replace `eventId = -1` step records with a clearer step-specific persistence model or document an ADR if retained.
- Define invariants for timed records, plain records, values, and units.

## Phase 4: UI Composition

Status: pending

- Split large widgets into route, view model, and small render widgets.
- Make loading, empty, and error states consistent across list/detail/statistics views.
- Replace route-refresh hacks with provider-driven refresh.
- Hide developer tools behind debug mode or remove them from production UI.

## Phase 5: Dependency and Platform Modernization

Status: pending

- Decide whether Firebase is needed. Remove it if cloud sync is out of scope.
- Upgrade dependencies in small batches with tests between batches.
- Then evaluate Flutter SDK upgrade separately.
- Replace discontinued packages (`share`, `moor_db_viewer`) or isolate them behind debug-only code.

## First Execution Slice

The first slice should make the quality gates meaningful without changing product behavior:

1. Fix lint/test configuration.
2. Add app startup smoke tests.
3. Move platform bootstrap out of `main.dart`.
4. Keep Windows build green.

## Architecture Candidates

### Strong: Persistence Module

Files: `lib/DAO/base.dart`, `lib/DAO/tables.dart`, `lib/main.dart`, callers in list/detail/statistics pages.

Problem: UI modules know too much about the database implementation and persistence setup. Record lifecycle methods update multiple tables with manual ordering requirements.

Solution: Make persistence a deeper module with a small interface for activity, record, unit, and step operations. Hide platform bootstrap and transaction details inside the module.

Benefits: Higher locality for data bugs, better leverage for tests, and less database knowledge leaking into UI widgets.

### Strong: Analytics Module

Files: `lib/EventsDetails/eventDetails.dart`, `lib/EventsDetails/util.dart`, `lib/Statistics/statistics.dart`, `lib/heatmap_calendar/`.

Problem: Widgets compute domain aggregates directly, so chart bugs require widget tests and UI files are hard to understand.

Solution: Extract pure aggregation functions for daily totals, time-slot distributions, and cross-activity summaries.

Benefits: Fast unit tests, smaller Widgets, and a reusable interface for future analytics views.

### Worth Exploring: Debug Surface

Files: `lib/settingPage.dart`, `lib/addFakeData.dart`, `moor_db_viewer` dependency.

Problem: Development-only actions are visible in the product UI and can delete all local data.

Solution: Hide debug tools behind `kDebugMode` or move them to a developer-only route.

Benefits: Lower product risk with minimal behavioral change for developers.

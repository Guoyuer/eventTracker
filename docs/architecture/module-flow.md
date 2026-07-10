# Module Flow

This document keeps the current architecture visible while the repo is being refactored. It should change when module ownership changes.

## Current Shape

```mermaid
flowchart LR
  subgraph UI["UI routes and widgets"]
    EventList["EventList"]
    EventDetails["EventDetails"]
    Statistics["Statistics"]
    EventEditor["EventEditor"]
    UnitManager["UnitManager"]
  end

  subgraph Application["Application modules"]
    ActivityListController["ActivityListController"]
    ActivityEditorController["ActivityEditorController"]
    ActivityDetailController["ActivityDetailController"]
    UnitManagementController["UnitManagementController"]
  end

  subgraph Domain["Domain interfaces and rules"]
    ActivityReader["ActivityReader"]
    ActivityWriter["ActivityWriter"]
    RecordLifecycle["RecordLifecycle"]
    UnitRepository["UnitRepository"]
    StatisticsRepository["StatisticsRepository"]
    RecordHistory["ActivityRecordHistory"]
    CalendarDateRange["CalendarDateRange"]
    DateInterval["DateInterval"]
  end

  subgraph State["Riverpod state and adapter wiring"]
    ActivityListProvider["activityListProvider"]
    ActivitySnapshotProvider["activitySnapshotProvider"]
    ActivityRecordsProvider["activityRecordsProvider"]
    ActivityReaderProvider["activityReaderProvider"]
    ActivityWriterProvider["activityWriterProvider"]
    RecordLifecycleProvider["recordLifecycleProvider"]
    UnitListProvider["unitListProvider"]
    StatisticsProvider["statisticsProvider"]
    AppDatabaseProvider["appDatabaseProvider"]
  end

  subgraph Persistence["Persistence implementation"]
    DriftActivityRepository["DriftActivityRepository"]
    ActivitySnapshotStore["ActivitySnapshotStore"]
    DriftUnitRepository["DriftUnitRepository"]
    DriftStatisticsRepository["DriftStatisticsRepository"]
    RecordLifecycleStore["RecordLifecycleStore"]
    AppDatabase["AppDatabase / Drift"]
    DatabaseBootstrap["DatabaseBootstrap"]
  end

  EventList --> ActivityListProvider
  EventList --> ActivityListController
  EventEditor --> ActivityEditorController
  EventDetails --> ActivityDetailController
  EventDetails --> ActivitySnapshotProvider
  UnitManager --> UnitManagementController
  Statistics --> StatisticsProvider

  ActivityListController --> RecordLifecycle
  ActivityEditorController --> ActivityWriter
  ActivityDetailController --> ActivityWriter
  UnitManagementController --> UnitRepository

  ActivityListProvider --> ActivityReaderProvider
  ActivitySnapshotProvider --> ActivityReaderProvider
  ActivityRecordsProvider --> ActivityReaderProvider
  ActivityReaderProvider --> ActivityReader
  ActivityWriterProvider --> ActivityWriter
  RecordLifecycleProvider --> RecordLifecycle
  UnitListProvider --> UnitRepository
  StatisticsProvider --> StatisticsRepository
  StatisticsProvider --> CalendarDateRange

  ActivityReader --> DriftActivityRepository
  ActivityWriter --> DriftActivityRepository
  RecordLifecycle --> DriftActivityRepository
  UnitRepository --> DriftUnitRepository
  StatisticsRepository --> DriftStatisticsRepository
  CalendarDateRange --> DateInterval
  DriftActivityRepository --> RecordLifecycleStore
  DriftActivityRepository --> ActivitySnapshotStore
  ActivitySnapshotStore --> RecordHistory
  ActivitySnapshotStore --> AppDatabase
  DriftActivityRepository --> AppDatabase
  DriftUnitRepository --> AppDatabase
  DriftStatisticsRepository --> AppDatabase
  AppDatabaseProvider --> AppDatabase
  AppDatabase --> DatabaseBootstrap
```

## Deepened Activity Recording

```mermaid
flowchart LR
  subgraph Before["Before: shallow call chain"]
    B1["EventTile"] --> B2["ActivityListController"]
    B2 --> B3["ActivityRecordingController"]
    B3 --> B4["ActivityRecordingActions"]
    B4 --> B5["broad ActivityRepository"]
  end

  subgraph After["After: one application interface"]
    A1["EventTile UI Adapter"] --> A2["ActivityListController"]
    A2 --> A3["RecordLifecycle"]
    A3 --> A4["DriftActivityRepository"]
  end
```

`ActivityListController` now owns type dispatch, optional value prompts, the five-second accidental-start rule, refresh, and notification policy. The deleted outcome enum and pass-through controller no longer form part of the Interface.

## Repository Seams

```mermaid
flowchart TB
  Broad["Before: every caller learns 11 methods"]
  Broad --> Fake1["recording fake: 7 unused methods"]
  Broad --> Fake2["detail fake: 8 unused methods"]
  Broad --> Fake3["description fake: 5 unused methods"]

  Narrow["After: domain-owned interfaces"]
  Narrow --> Reader["ActivityReader: 4 methods"]
  Narrow --> Writer["ActivityWriter: 3 methods"]
  Narrow --> Lifecycle["RecordLifecycle: 4 methods"]
  Reader --> Drift["one Drift adapter"]
  Writer --> Drift
  Lifecycle --> Drift
```

Production wiring projects one `DriftActivityRepository` Adapter through three narrow Interfaces. Tests use purpose-built in-memory Adapters without unrelated `UnimplementedError` methods.

## Deepened Activity Snapshot

```mermaid
flowchart LR
  Before["Events query"] --> N1["N last-record queries"]
  N1 --> Mutable["mutable model + EventStatus"]
  Mutable --> Stale["detail receives stale snapshot"]

  After["one Events / all Records join"] --> Snapshot["ActivitySnapshotStore"]
  Snapshot --> Sealed["sealed immutable Activity types"]
  Sealed --> Route["detail route passes ID and reloads"]
```

Active state and totals now come from Records through `ActivityRecordHistory`. Schema v4 removed `lastRecordId`, `sumTime`, and `sumVal`; malformed histories fail at one Interface, and the domain model cannot represent an active Timed Activity without a start time.

## Deepened Statistics Range

```mermaid
flowchart LR
  Before["Widget adds one day"] --> Between["inclusive SQL BETWEEN"]
  Between --> Bug["next-day 00:00 included"]

  After["CalendarDateRange"] --> Interval["DateInterval [start, endExclusive)"]
  Interval --> Query[">= start AND < endExclusive"]
  Query --> Transaction["Records + Activities transaction"]
```

Calendar-day selection and timestamp interval semantics now have separate Interfaces. The Widget displays inclusive days; persistence receives one half-open interval and reads a consistent snapshot.

## Current Enforcement And Next Work

```mermaid
flowchart LR
  Lifecycle["RecordLifecycleStore"] --> TypeRules["Activity type validation"]
  Database["schema v7"] --> Shape["FK + CHECK + triggers + one-active index"]
  Snapshot["ActivitySnapshotStore"] --> History["ActivityRecordHistory"]
  ParsedImports["parsed import directives"] --> Boundaries["durable layer boundaries"]
  RecordTypes["sealed ActivityRecord shapes"] --> Next["Next: directory terminology and chart theme cleanup"]
```

Records are the sole persisted fact for Activity state and totals. The first four
nodes are already enforced. The remaining work is constrained by the scope and
acceptance criteria in `docs/plans/2026-07-10-unified-quality-execution.md`.
Product behavior stays protected by unit, persistence, migration, and widget
tests. The architecture suite checks only dependency direction from parsed Dart
syntax, so internal renames and implementation changes do not create false
regressions.

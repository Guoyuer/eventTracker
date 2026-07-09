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
    AggregateRules["ActivityAggregateSnapshot"]
    DateRange["DateRange"]
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
    AggregateStore["ActivityAggregateStore"]
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
  StatisticsProvider --> DateRange

  ActivityReader --> DriftActivityRepository
  ActivityWriter --> DriftActivityRepository
  RecordLifecycle --> DriftActivityRepository
  UnitRepository --> DriftUnitRepository
  StatisticsRepository --> DriftStatisticsRepository
  DriftActivityRepository --> RecordLifecycleStore
  DriftActivityRepository --> ActivitySnapshotStore
  RecordLifecycleStore --> AggregateStore
  AggregateStore --> AggregateRules
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

  After["one Events / active Records join"] --> Snapshot["ActivitySnapshotStore"]
  Snapshot --> Sealed["sealed immutable Activity types"]
  Sealed --> Route["detail route passes ID and reloads"]
```

Active state now comes from active Records rather than cached `lastRecordId`, malformed histories fail at one Interface, and the domain model cannot represent an active Timed Activity without a start time.

## Next Deepening

```mermaid
flowchart LR
  StatisticsRange["Statistics date selection"] --> Inclusive["inclusive next-day midnight"]
  Inclusive --> HalfOpen["half-open DateRange"]
```

The next slice should make Statistics interval semantics explicit and keep its Records/Activities read consistent.

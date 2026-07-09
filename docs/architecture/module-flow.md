# Module Flow

This document keeps the current architecture visible while the repo is being refactored. It should change when module ownership changes.

## Current Target Shape

```mermaid
flowchart LR
  subgraph UI["UI routes and widgets"]
    EventList["EventList"]
    EventDetails["EventDetails"]
    Statistics["Statistics"]
    EventEditor["EventEditor"]
    UnitManager["UnitManager"]
    Settings["SettingPage"]
  end

  subgraph Analytics["Pure analytics modules"]
    ActivityDetailAnalytics["activity_detail_analytics.dart"]
    StatisticsAnalytics["statistics_analytics.dart"]
  end

  subgraph State["Riverpod state"]
    AppDatabaseProvider["appDatabaseProvider"]
    ActivityRepositoryProvider["activityRepositoryProvider"]
    UnitRepositoryProvider["unitRepositoryProvider"]
    StatisticsRepositoryProvider["statisticsRepositoryProvider"]
    ActivityListProvider["activityListProvider"]
    ActivityRecordsProvider["activityRecordsProvider"]
    UnitListProvider["unitListProvider"]
    StatisticsProvider["statisticsProvider"]
  end

  subgraph Persistence["Persistence module"]
    DatabaseBootstrap["DatabaseBootstrap"]
    ActivityRepository["ActivityRepository"]
    RecordLifecycleStore["RecordLifecycleStore"]
    UnitRepository["UnitRepository"]
    StatisticsRepository["StatisticsRepository"]
    AppDatabase["AppDatabase / Drift"]
  end

  EventList --> ActivityListProvider
  ActivityListProvider --> ActivityRepositoryProvider
  EventDetails --> ActivityRecordsProvider
  ActivityRecordsProvider --> ActivityRepositoryProvider
  EventEditor --> UnitListProvider
  UnitManager --> UnitListProvider
  UnitListProvider --> UnitRepositoryProvider
  Statistics --> StatisticsProvider
  StatisticsProvider --> StatisticsRepositoryProvider
  EventEditor --> ActivityRepositoryProvider
  EventDetails --> ActivityDetailAnalytics
  EventDetails --> ActivityRepositoryProvider
  Statistics --> StatisticsAnalytics
  ActivityRepositoryProvider --> ActivityRepository
  ActivityRepository --> RecordLifecycleStore
  RecordLifecycleStore --> AppDatabase
  UnitRepositoryProvider --> UnitRepository
  StatisticsRepositoryProvider --> StatisticsRepository
  ActivityRepositoryProvider --> AppDatabaseProvider
  UnitRepositoryProvider --> AppDatabaseProvider
  StatisticsRepositoryProvider --> AppDatabaseProvider
  AppDatabaseProvider --> AppDatabase
  AppDatabase --> DatabaseBootstrap
```

## What Changed

### Statistics

```mermaid
flowchart TB
  Before["Before: Statistics widget"]
  Before --> B1["Fetch records and activities"]
  Before --> B2["Count records per activity"]
  Before --> B3["Build hourly time-slot buckets"]
  Before --> B4["Create pie chart sections"]
  Before --> B5["Create stacked bar rods"]

  After["After: split responsibilities"]
  After --> A1["StatisticsRepository fetches records and activities"]
  A1 --> A2["statistics_analytics.dart builds summary"]
  A2 --> A3["Statistics widget adapts summary to fl_chart"]
```

### Activity List Refresh

```mermaid
flowchart LR
  Before["Before"]
  Before --> B1["ReloadEventsN"]
  B1 --> B2["Navigator.pop(MainPage)"]
  B2 --> B3["Navigator.push(MainPage)"]

  After["After"]
  After --> A1["ref.invalidate(activityListProvider)"]
  A1 --> A2["EventList reloads activity list"]
```

### Activity Details Heatmap

```mermaid
flowchart LR
  Before["Before"]
  Before --> B1["MonthTouchedN / DayTouchedN"]
  B1 --> B2["NotificationListener in EventDetails"]

  After["After"]
  After --> A1["HeatMapCalendar callbacks"]
  A1 --> A2["EventDetails handles month/day directly"]
  EventDetails["EventDetails"] --> Records["activityRecordsProvider"]
```

The direction is to keep record and activity rules in pure modules or repositories, and keep widgets focused on rendering and interaction.

## Still To Improve

```mermaid
flowchart LR
  RecordingFlow["Shallow activity recording flow"]
  RecordingFlow --> Persistence["Keep product actions behind testable modules"]

  Next["Next deepening candidates"]
  Next --> Recording["Extract activity recording actions from EventsList util"]
  Next --> Providers["Split broad feature providers out of stateProviders.dart"]
```

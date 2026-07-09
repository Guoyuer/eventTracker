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

  subgraph Logic["Pure logic modules"]
    ActivityDetailAnalytics["activity_detail_analytics.dart"]
    StatisticsAnalytics["statistics_analytics.dart"]
    ActivityDetailChartModels["activity_detail_chart_models.dart"]
    StatisticsChartModels["statistics_chart_models.dart"]
    DateRange["DateRange"]
    ActivityRecordingController["ActivityRecordingController"]
    ActivityRecordingActions["ActivityRecordingActions"]
    AsyncStateView["AsyncStateView"]
  end

  subgraph State["Riverpod state"]
    AppNavigationProviders["app_navigation_providers.dart"]
    ActivityListProviders["activity_list_providers.dart"]
    ActivityDetailProviders["activity_detail_providers.dart"]
    ActivityEditorProviders["activity_editor_providers.dart"]
    UnitProviders["unit_providers.dart"]
    StatisticsProviders["statistics_providers.dart"]
    MutableState["MutableState"]
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
  EventList --> ActivityRecordingController
  EventList --> AsyncStateView
  ActivityListProviders --> MutableState
  ActivityDetailProviders --> MutableState
  ActivityEditorProviders --> MutableState
  AppNavigationProviders --> MutableState
  StatisticsProviders --> MutableState
  ActivityRecordingController --> ActivityRecordingActions
  ActivityRecordingActions --> ActivityRepository
  ActivityListProvider --> ActivityRepositoryProvider
  EventDetails --> ActivityRecordsProvider
  EventDetails --> AsyncStateView
  ActivityRecordsProvider --> ActivityRepositoryProvider
  EventEditor --> UnitListProvider
  UnitManager --> UnitListProvider
  UnitListProvider --> UnitRepositoryProvider
  Statistics --> StatisticsProvider
  Statistics --> AsyncStateView
  Statistics --> DateRange
  StatisticsProvider --> StatisticsRepositoryProvider
  StatisticsProvider --> DateRange
  EventEditor --> ActivityRepositoryProvider
  EventDetails --> ActivityDetailAnalytics
  EventDetails --> ActivityDetailChartModels
  EventDetails --> ActivityRepositoryProvider
  Statistics --> StatisticsAnalytics
  Statistics --> StatisticsChartModels
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

### Activity Recording Interaction

```mermaid
flowchart LR
  Before["Before"]
  Before --> B1["EventTileButton"]
  B1 --> B2["Prompt for value"]
  B1 --> B3["Call repository mutation policy"]
  B1 --> B4["Switch on changed/canceled/unchanged outcome"]
  B1 --> B5["Refresh list and show toast"]

  After["After"]
  After --> A1["EventTileButton UI Adapter"]
  A1 --> A2["ActivityRecordingController"]
  A2 --> A3["ActivityRecordingActions"]
  A2 --> A4["Refresh and notify outcome policy"]
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
  HeatMapModel["HeatMapCalendarModel"]
  HeatMapModel --> Calendar["HeatMapCalendar render widgets"]
```

The direction is to keep record and activity rules in pure modules or repositories, and keep widgets focused on rendering and interaction.

## Still To Improve

```mermaid
flowchart LR
  HeatmapCalendar["Heatmap calendar render widgets"]
  HeatmapCalendar --> Logic["Consume pure HeatMapCalendarModel"]

  Next["Next deepening candidates"]
  Next --> DependencyBatches["Modernize dependencies in focused batches"]
  Next --> RouteCoordinators["Extract remaining route interaction coordinators"]
```

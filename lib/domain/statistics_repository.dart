import 'activity_models.dart';
import 'date_range.dart';

class StatisticsData {
  StatisticsData({required this.records, required this.activitiesById});

  final List<ActivityRecord> records;
  final Map<int, StatisticsActivity> activitiesById;
}

abstract interface class StatisticsRepository {
  Future<StatisticsData> getStatisticsData(DateRange range);
}

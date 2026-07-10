// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Activity Tracker';

  @override
  String appTitleWithSection(String section) {
    return 'Activity Tracker - $section';
  }

  @override
  String get tabActivities => 'Activities';

  @override
  String get tabStatistics => 'Statistics';

  @override
  String get tabSettings => 'Settings';

  @override
  String get timingCancelled => 'Timing cancelled';

  @override
  String get activityBusy => 'This activity is already being timed';

  @override
  String duplicateActivityName(String name) {
    return 'An activity named \"$name\" already exists';
  }

  @override
  String duplicateUnitName(String name) {
    return 'A unit named \"$name\" already exists';
  }

  @override
  String unitInUse(String name) {
    return '\"$name\" is used by an activity and cannot be deleted';
  }

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loadActivitiesFailed => 'Could not load activities';

  @override
  String get loadUnitsFailed => 'Could not load units';

  @override
  String get loadRecordsFailed => 'Could not load records';

  @override
  String get loadDescriptionFailed => 'Could not load description';

  @override
  String get loadStatisticsFailed => 'Could not load statistics';

  @override
  String get noActivities => 'No activities yet';

  @override
  String get noRecords => 'No records yet';

  @override
  String get noDescription => 'No description';

  @override
  String get activityEditorTitle => 'New activity';

  @override
  String get activityNameRequired => 'Activity name is required';

  @override
  String get activityNameHint => 'Activity name';

  @override
  String get activityDescriptionHint => 'Description';

  @override
  String get trackDuration => 'Track duration';

  @override
  String get save => 'Save';

  @override
  String get noUnitsAvailable => 'No units yet. Add one from Unit Management.';

  @override
  String get availableUnits => 'Available units:';

  @override
  String get addUnit => 'Add unit';

  @override
  String get enterUnit => 'Enter a unit';

  @override
  String get deleteUnitPrompt => 'Delete this unit?';

  @override
  String get unitManagement => 'Unit Management';

  @override
  String get recordValueTitle => 'Enter value';

  @override
  String get recordValuePrefix => 'Completed';

  @override
  String get recordValueInvalid => 'Enter a finite value greater than zero';

  @override
  String get newRecord => 'New record';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get notStarted => 'Not started';

  @override
  String completedDuration(String duration) {
    return 'Completed$duration';
  }

  @override
  String completedCount(int count) {
    return 'Completed $count times';
  }

  @override
  String totalValue(String value, String unit) {
    return 'Total: $value $unit';
  }

  @override
  String elapsedDuration(String duration) {
    return 'Elapsed$duration';
  }

  @override
  String get elapsed => 'Elapsed';

  @override
  String durationHours(int count) {
    return ' ${count}h';
  }

  @override
  String durationMinutes(int count) {
    return ' ${count}m';
  }

  @override
  String durationSeconds(int count) {
    return ' ${count}s';
  }

  @override
  String activityDetailTitle(String name) {
    return '$name - Activity details';
  }

  @override
  String get activityDescription => 'Description';

  @override
  String get deleteActivityPrompt =>
      'Delete this activity and all its records?';

  @override
  String statisticsForMetric(String metric) {
    return 'Statistics - $metric';
  }

  @override
  String recordCountHeading(String month) {
    return 'Completed $month';
  }

  @override
  String get recordCountSuffix => ' times';

  @override
  String get metricDuration => 'Duration';

  @override
  String get metricCount => 'Count';

  @override
  String get timeSlotActivity => 'Activity by time of day';

  @override
  String recordsOnDay(String date) {
    return 'Records on $date';
  }

  @override
  String get noRecordsOnDay => 'No records on this day';

  @override
  String statisticsRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get changeRange => 'Change range';

  @override
  String get countStatistics => 'Count statistics';

  @override
  String totalCount(int count) {
    return '$count total';
  }

  @override
  String get dismissDialog => 'Dismiss';
}

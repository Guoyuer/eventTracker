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
}

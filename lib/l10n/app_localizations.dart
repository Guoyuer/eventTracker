import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Tracker'**
  String get appTitle;

  /// No description provided for @appTitleWithSection.
  ///
  /// In en, this message translates to:
  /// **'Activity Tracker - {section}'**
  String appTitleWithSection(String section);

  /// No description provided for @tabActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get tabActivities;

  /// No description provided for @tabStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tabStatistics;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @timingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Timing cancelled'**
  String get timingCancelled;

  /// No description provided for @activityBusy.
  ///
  /// In en, this message translates to:
  /// **'This activity is already being timed'**
  String get activityBusy;

  /// No description provided for @duplicateActivityName.
  ///
  /// In en, this message translates to:
  /// **'An activity named \"{name}\" already exists'**
  String duplicateActivityName(String name);

  /// No description provided for @duplicateUnitName.
  ///
  /// In en, this message translates to:
  /// **'A unit named \"{name}\" already exists'**
  String duplicateUnitName(String name);

  /// No description provided for @unitInUse.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is used by an activity and cannot be deleted'**
  String unitInUse(String name);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loadActivitiesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load activities'**
  String get loadActivitiesFailed;

  /// No description provided for @loadUnitsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load units'**
  String get loadUnitsFailed;

  /// No description provided for @loadRecordsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load records'**
  String get loadRecordsFailed;

  /// No description provided for @loadDescriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load description'**
  String get loadDescriptionFailed;

  /// No description provided for @loadStatisticsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load statistics'**
  String get loadStatisticsFailed;

  /// No description provided for @noActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivities;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecords;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @activityEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get activityEditorTitle;

  /// No description provided for @activityNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Activity name is required'**
  String get activityNameRequired;

  /// No description provided for @activityNameHint.
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get activityNameHint;

  /// No description provided for @activityDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get activityDescriptionHint;

  /// No description provided for @trackDuration.
  ///
  /// In en, this message translates to:
  /// **'Track duration'**
  String get trackDuration;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noUnitsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No units yet. Add one from Unit Management.'**
  String get noUnitsAvailable;

  /// No description provided for @availableUnits.
  ///
  /// In en, this message translates to:
  /// **'Available units:'**
  String get availableUnits;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add unit'**
  String get addUnit;

  /// No description provided for @enterUnit.
  ///
  /// In en, this message translates to:
  /// **'Enter a unit'**
  String get enterUnit;

  /// No description provided for @deleteUnitPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete this unit?'**
  String get deleteUnitPrompt;

  /// No description provided for @unitManagement.
  ///
  /// In en, this message translates to:
  /// **'Unit Management'**
  String get unitManagement;

  /// No description provided for @recordValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter value'**
  String get recordValueTitle;

  /// No description provided for @recordValuePrefix.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get recordValuePrefix;

  /// No description provided for @recordValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a finite value greater than zero'**
  String get recordValueInvalid;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get newRecord;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @completedDuration.
  ///
  /// In en, this message translates to:
  /// **'Completed{duration}'**
  String completedDuration(String duration);

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed {count} times'**
  String completedCount(int count);

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total: {value} {unit}'**
  String totalValue(String value, String unit);

  /// No description provided for @elapsedDuration.
  ///
  /// In en, this message translates to:
  /// **'Elapsed{duration}'**
  String elapsedDuration(String duration);

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get elapsed;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **' {count}h'**
  String durationHours(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **' {count}m'**
  String durationMinutes(int count);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **' {count}s'**
  String durationSeconds(int count);

  /// No description provided for @activityDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} - Activity details'**
  String activityDetailTitle(String name);

  /// No description provided for @activityDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get activityDescription;

  /// No description provided for @deleteActivityPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete this activity and all its records?'**
  String get deleteActivityPrompt;

  /// No description provided for @statisticsForMetric.
  ///
  /// In en, this message translates to:
  /// **'Statistics - {metric}'**
  String statisticsForMetric(String metric);

  /// No description provided for @recordCountHeading.
  ///
  /// In en, this message translates to:
  /// **'Completed {month}'**
  String recordCountHeading(String month);

  /// No description provided for @recordCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' times'**
  String get recordCountSuffix;

  /// No description provided for @metricDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get metricDuration;

  /// No description provided for @metricCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get metricCount;

  /// No description provided for @timeSlotActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity by time of day'**
  String get timeSlotActivity;

  /// No description provided for @recordsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Records on {date}'**
  String recordsOnDay(String date);

  /// No description provided for @noRecordsOnDay.
  ///
  /// In en, this message translates to:
  /// **'No records on this day'**
  String get noRecordsOnDay;

  /// No description provided for @unitSeconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get unitSeconds;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get unitMinutes;

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get unitHours;

  /// No description provided for @statisticsRange.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String statisticsRange(String start, String end);

  /// No description provided for @changeRange.
  ///
  /// In en, this message translates to:
  /// **'Change range'**
  String get changeRange;

  /// No description provided for @countStatistics.
  ///
  /// In en, this message translates to:
  /// **'Count statistics'**
  String get countStatistics;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalCount(int count);

  /// No description provided for @dismissDialog.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissDialog;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

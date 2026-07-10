import '../application/activity_messages.dart';
import '../l10n/app_localizations.dart';

ActivityMessages localizedActivityMessages(AppLocalizations localizations) {
  return ActivityMessages(
    timingCancelled: localizations.timingCancelled,
    activityBusy: localizations.activityBusy,
    duplicateActivityName: localizations.duplicateActivityName,
    duplicateUnitName: localizations.duplicateUnitName,
    unitInUse: localizations.unitInUse,
  );
}

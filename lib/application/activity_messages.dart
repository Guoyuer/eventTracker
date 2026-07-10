typedef ActivityNameMessage = String Function(String name);

/// Localized messages required by application interaction policies.
///
/// UI adapters create this value from AppLocalizations. Keeping it as pure Dart
/// prevents the application layer from depending on Flutter.
class ActivityMessages {
  const ActivityMessages({
    required this.timingCancelled,
    required this.activityBusy,
    required this.duplicateActivityName,
    required this.duplicateUnitName,
    required this.unitInUse,
  });

  final String timingCancelled;
  final String activityBusy;
  final ActivityNameMessage duplicateActivityName;
  final ActivityNameMessage duplicateUnitName;
  final ActivityNameMessage unitInUse;
}

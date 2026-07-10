/// A failure caused by a valid user action that the UI can explain.
///
/// Unexpected exceptions are defects or infrastructure failures and must reach
/// the application error boundary instead of being converted into a guess.
sealed class ActivityFailure implements Exception {
  const ActivityFailure();
}

final class DuplicateActivityName extends ActivityFailure {
  const DuplicateActivityName(this.name);

  final String name;
}

final class DuplicateUnitName extends ActivityFailure {
  const DuplicateUnitName(this.name);

  final String name;
}

final class UnitInUse extends ActivityFailure {
  const UnitInUse(this.name);

  final String name;
}

final class ActivityBusy extends ActivityFailure {
  const ActivityBusy(this.activityId);

  final int activityId;
}

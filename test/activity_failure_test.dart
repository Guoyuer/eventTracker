import 'package:event_tracker/domain/activity_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user-facing activity failures preserve their contextual value', () {
    const failures = <ActivityFailure>[
      DuplicateActivityName('Read'),
      DuplicateUnitName('pages'),
      UnitInUse('pages'),
      ActivityBusy(7),
    ];

    expect(failures[0], isA<DuplicateActivityName>());
    expect((failures[0] as DuplicateActivityName).name, 'Read');
    expect((failures[1] as DuplicateUnitName).name, 'pages');
    expect((failures[2] as UnitInUse).name, 'pages');
    expect((failures[3] as ActivityBusy).activityId, 7);
  });
}

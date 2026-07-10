import 'package:event_tracker/application/activity_detail_controller.dart';
import 'package:event_tracker/application/activity_editor_controller.dart';
import 'package:event_tracker/application/activity_messages.dart';
import 'package:event_tracker/application/unit_management_controller.dart';
import 'package:event_tracker/domain/activity_failure.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:event_tracker/domain/unit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _messages = ActivityMessages(
  timingCancelled: '已取消本次计时',
  activityBusy: '该项目正在计时中',
  duplicateActivityName: _duplicateActivityName,
  duplicateUnitName: _duplicateUnitName,
  unitInUse: _unitInUse,
);

String _duplicateActivityName(String name) => '已存在名为「$name」的项目';
String _duplicateUnitName(String name) => '已存在名为「$name」的单位';
String _unitInUse(String name) => '「$name」正被某个项目使用，无法删除';

void main() {
  test('activity editor creates an activity and reports success', () async {
    final repository = _FakeActivityWriter();
    final notifications = <String>[];
    final controller = ActivityEditorController(
      repository: repository,
      messages: _messages,
      notify: notifications.add,
    );

    final created = await controller.createActivity(
      name: 'Read',
      unit: 'pages',
      description: 'Books',
      careTime: false,
    );

    expect(created, isTrue);
    expect(repository.createdActivities, [
      _CreatedActivity(
        name: 'Read',
        unit: 'pages',
        description: 'Books',
        careTime: false,
      ),
    ]);
    expect(notifications, isEmpty);
  });

  test('activity editor reports duplicate-name failures', () async {
    final repository = _FakeActivityWriter()
      ..createActivityError = const DuplicateActivityName('Read');
    final notifications = <String>[];
    final controller = ActivityEditorController(
      repository: repository,
      messages: _messages,
      notify: notifications.add,
    );

    final created = await controller.createActivity(
      name: 'Read',
      careTime: true,
    );

    expect(created, isFalse);
    expect(notifications, ['已存在名为「Read」的项目']);
  });

  test('activity editor lets unexpected failures reach the error boundary', () {
    final repository = _FakeActivityWriter()
      ..createActivityError = StateError('storage unavailable');
    final controller = ActivityEditorController(
      repository: repository,
      messages: _messages,
      notify: (_) {},
    );

    expect(
      controller.createActivity(name: 'Read', careTime: true),
      throwsStateError,
    );
  });

  test('activity detail delegates deletion to the repository', () async {
    final repository = _FakeActivityWriter();
    final controller = ActivityDetailController(repository);

    await controller.deleteActivity(12);

    expect(repository.deletedActivityIds, [12]);
  });

  test(
    'activity detail delegates description updates to the repository',
    () async {
      final repository = _FakeActivityWriter();
      final controller = ActivityDetailController(repository);

      await controller.saveDescription(12, 'Updated');

      expect(repository.updatedDescriptions, {12: 'Updated'});
    },
  );

  test('unit add refreshes the unit list after success', () async {
    final repository = _FakeUnitRepository();
    final harness = _UnitControllerHarness(repository);

    final added = await harness.controller.addUnit('km');

    expect(added, isTrue);
    expect(repository.addedUnitNames, ['km']);
    expect(harness.refreshCount, 1);
    expect(harness.notifications, isEmpty);
  });

  test('unit add reports duplicates without refreshing stale data', () async {
    final repository = _FakeUnitRepository()
      ..addUnitError = const DuplicateUnitName('km');
    final harness = _UnitControllerHarness(repository);

    final added = await harness.controller.addUnit('km');

    expect(added, isFalse);
    expect(harness.refreshCount, 0);
    expect(harness.notifications, ['已存在名为「km」的单位']);
  });

  test('unit add lets unexpected failures reach the error boundary', () {
    final repository = _FakeUnitRepository()
      ..addUnitError = StateError('storage unavailable');
    final harness = _UnitControllerHarness(repository);

    expect(harness.controller.addUnit('km'), throwsStateError);
  });

  test('unit delete skips repository when unconfirmed', () async {
    final repository = _FakeUnitRepository();
    final harness = _UnitControllerHarness(repository);

    final deleted = await harness.controller.deleteUnit(
      'km',
      confirmDelete: () async => false,
    );

    expect(deleted, isFalse);
    expect(repository.deletedUnitNames, isEmpty);
    expect(harness.refreshCount, 0);
    expect(harness.notifications, isEmpty);
  });

  test('unit delete refreshes and allows dismiss after success', () async {
    final repository = _FakeUnitRepository();
    final harness = _UnitControllerHarness(repository);

    final deleted = await harness.controller.deleteUnit(
      'km',
      confirmDelete: () async => true,
    );

    expect(deleted, isTrue);
    expect(repository.deletedUnitNames, ['km']);
    expect(harness.refreshCount, 1);
    expect(harness.notifications, isEmpty);
  });

  test(
    'unit delete reports failure and keeps the dismissed item visible',
    () async {
      final repository = _FakeUnitRepository()
        ..deleteUnitError = const UnitInUse('km');
      final harness = _UnitControllerHarness(repository);

      final deleted = await harness.controller.deleteUnit(
        'km',
        confirmDelete: () async => true,
      );

      expect(deleted, isFalse);
      expect(harness.refreshCount, 1);
      expect(harness.notifications, ['「km」正被某个项目使用，无法删除']);
    },
  );
}

class _UnitControllerHarness {
  _UnitControllerHarness(_FakeUnitRepository repository) {
    controller = UnitManagementController(
      repository: repository,
      messages: _messages,
      refresh: () => refreshCount++,
      notify: notifications.add,
    );
  }

  late final UnitManagementController controller;
  var refreshCount = 0;
  final notifications = <String>[];
}

class _FakeActivityWriter implements ActivityWriter {
  final createdActivities = <_CreatedActivity>[];
  final deletedActivityIds = <int>[];
  final updatedDescriptions = <int, String>{};
  Object? createActivityError;

  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) async {
    final error = createActivityError;
    if (error != null) {
      throw error;
    }
    createdActivities.add(
      _CreatedActivity(
        name: name,
        careTime: careTime,
        unit: unit,
        description: description,
      ),
    );
    return createdActivities.length;
  }

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) async {
    updatedDescriptions[activityId] = description;
  }

  @override
  Future<void> deleteActivity(int activityId) async {
    deletedActivityIds.add(activityId);
  }
}

class _FakeUnitRepository implements UnitRepository {
  final addedUnitNames = <String>[];
  final deletedUnitNames = <String>[];
  Object? addUnitError;
  Object? deleteUnitError;

  @override
  Future<List<ActivityUnit>> getUnits() async => [];

  @override
  Future<int> addUnit(String name) async {
    final error = addUnitError;
    if (error != null) {
      throw error;
    }
    addedUnitNames.add(name);
    return addedUnitNames.length;
  }

  @override
  Future<void> deleteUnit(String name) async {
    final error = deleteUnitError;
    if (error != null) {
      throw error;
    }
    deletedUnitNames.add(name);
  }
}

class _CreatedActivity {
  const _CreatedActivity({
    required this.name,
    required this.careTime,
    this.unit,
    this.description,
  });

  final String name;
  final bool careTime;
  final String? unit;
  final String? description;

  @override
  bool operator ==(Object other) {
    return other is _CreatedActivity &&
        other.name == name &&
        other.careTime == careTime &&
        other.unit == unit &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(name, careTime, unit, description);
}

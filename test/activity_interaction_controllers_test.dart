import 'package:event_tracker/application/activity_list_controller.dart';
import 'package:event_tracker/application/activity_detail_controller.dart';
import 'package:event_tracker/application/activity_editor_controller.dart';
import 'package:event_tracker/application/unit_management_controller.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/persistence/activity_repository.dart';
import 'package:event_tracker/persistence/unit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity editor creates an activity and reports success', () async {
    final repository = _FakeActivityRepository();
    final notifications = <String>[];
    final controller = ActivityEditorController(
      repository: repository,
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
    final repository = _FakeActivityRepository()
      ..createActivityError = StateError('duplicate');
    final notifications = <String>[];
    final controller = ActivityEditorController(
      repository: repository,
      notify: notifications.add,
    );

    final created = await controller.createActivity(
      name: 'Read',
      careTime: true,
    );

    expect(created, isFalse);
    expect(notifications, ['添加失败，可能是因为项目名重复！']);
  });

  test('activity editor exits only after create succeeds', () async {
    final repository = _FakeActivityRepository();
    final exits = <bool>[];
    final controller = ActivityEditorController(
      repository: repository,
      notify: (_) {},
    );

    await controller.createActivityAndExit(
      name: 'Read',
      unit: 'pages',
      description: 'Books',
      careTime: false,
      exitEditor: exits.add,
    );

    expect(repository.createdActivities, [
      _CreatedActivity(
        name: 'Read',
        unit: 'pages',
        description: 'Books',
        careTime: false,
      ),
    ]);
    expect(exits, [true]);
  });

  test('activity editor stays open when create fails', () async {
    final repository = _FakeActivityRepository()
      ..createActivityError = StateError('duplicate');
    final notifications = <String>[];
    final exits = <bool>[];
    final controller = ActivityEditorController(
      repository: repository,
      notify: notifications.add,
    );

    await controller.createActivityAndExit(
      name: 'Read',
      careTime: true,
      exitEditor: exits.add,
    );

    expect(exits, isEmpty);
    expect(notifications, ['添加失败，可能是因为项目名重复！']);
  });

  test(
    'activity detail deletion returns success after repository delete',
    () async {
      final repository = _FakeActivityRepository();
      final controller = ActivityDetailController(repository: repository);

      final deleted = await controller.deleteActivity(
        12,
        confirmDelete: () async => true,
      );

      expect(deleted, isTrue);
      expect(repository.deletedActivityIds, [12]);
    },
  );

  test('activity detail deletion skips repository when unconfirmed', () async {
    final repository = _FakeActivityRepository();
    final controller = ActivityDetailController(repository: repository);

    final deleted = await controller.deleteActivity(
      12,
      confirmDelete: () async => false,
    );

    expect(deleted, isFalse);
    expect(repository.deletedActivityIds, isEmpty);
  });

  test(
    'activity detail exits only after a confirmed delete succeeds',
    () async {
      final repository = _FakeActivityRepository();
      final exits = <bool>[];
      final controller = ActivityDetailController(repository: repository);

      await controller.deleteActivityAndExit(
        12,
        confirmDelete: () async => true,
        exitDetail: exits.add,
      );

      expect(repository.deletedActivityIds, [12]);
      expect(exits, [true]);
    },
  );

  test('activity detail stays open when delete is unconfirmed', () async {
    final repository = _FakeActivityRepository();
    final exits = <bool>[];
    final controller = ActivityDetailController(repository: repository);

    await controller.deleteActivityAndExit(
      12,
      confirmDelete: () async => false,
      exitDetail: exits.add,
    );

    expect(repository.deletedActivityIds, isEmpty);
    expect(exits, isEmpty);
  });

  test(
    'activity detail saves descriptions before refreshing edit state',
    () async {
      final repository = _FakeActivityRepository();
      final controller = ActivityDetailController(repository: repository);
      var refreshCount = 0;
      var exitEditingCount = 0;

      await controller.saveDescription(
        12,
        'Updated',
        refresh: () => refreshCount++,
        exitEditing: () => exitEditingCount++,
      );

      expect(repository.updatedDescriptions, {12: 'Updated'});
      expect(refreshCount, 1);
      expect(exitEditingCount, 1);
    },
  );

  test(
    'activity list refreshes after a detail route deletes activity',
    () async {
      final activity = PlainEventModel(7, 'Read', null, 0);
      var refreshCount = 0;
      final shownActivities = <BaseEventModel>[];
      final controller = ActivityListController(
        repository: _FakeActivityRepository(),
        refresh: () => refreshCount++,
        notify: (_) {},
      );

      await controller.showActivityDetail(
        activity,
        showDetail: (activity) async {
          shownActivities.add(activity);
          return true;
        },
      );

      expect(shownActivities, [activity]);
      expect(refreshCount, 1);
    },
  );

  test('activity list ignores non-delete detail route results', () async {
    final activity = PlainEventModel(7, 'Read', null, 0);
    var refreshCount = 0;
    final controller = ActivityListController(
      repository: _FakeActivityRepository(),
      refresh: () => refreshCount++,
      notify: (_) {},
    );

    await controller.showActivityDetail(
      activity,
      showDetail: (_) async => null,
    );
    await controller.showActivityDetail(
      activity,
      showDetail: (_) async => false,
    );

    expect(refreshCount, 0);
  });

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
      ..addUnitError = StateError('duplicate');
    final harness = _UnitControllerHarness(repository);

    final added = await harness.controller.addUnit('km');

    expect(added, isFalse);
    expect(harness.refreshCount, 0);
    expect(harness.notifications, ['添加失败，可能是因为重复']);
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
        ..deleteUnitError = StateError('still used');
      final harness = _UnitControllerHarness(repository);

      final deleted = await harness.controller.deleteUnit(
        'km',
        confirmDelete: () async => true,
      );

      expect(deleted, isFalse);
      expect(harness.refreshCount, 1);
      expect(harness.notifications, ['删除失败']);
    },
  );
}

class _UnitControllerHarness {
  _UnitControllerHarness(_FakeUnitRepository repository) {
    controller = UnitManagementController(
      repository: repository,
      refresh: () => refreshCount++,
      notify: notifications.add,
    );
  }

  late final UnitManagementController controller;
  var refreshCount = 0;
  final notifications = <String>[];
}

class _FakeActivityRepository implements ActivityRepository {
  final createdActivities = <_CreatedActivity>[];
  final deletedActivityIds = <int>[];
  final updatedDescriptions = <int, String>{};
  Object? createActivityError;

  @override
  Future<List<BaseEventModel>> getActivities() {
    throw UnimplementedError();
  }

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) {
    throw UnimplementedError();
  }

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
  Future<String?> getActivityDescription(int activityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) async {
    updatedDescriptions[activityId] = description;
  }

  @override
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    throw UnimplementedError();
  }

  @override
  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelActiveTimedRecord(int activityId) {
    throw UnimplementedError();
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
  Future<List<ActivityUnit>> getUnits() {
    throw UnimplementedError();
  }

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

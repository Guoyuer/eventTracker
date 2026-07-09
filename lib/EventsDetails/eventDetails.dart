import 'package:event_tracker/common/async_state.dart';
import 'package:event_tracker/common/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/activity_detail_controller.dart';
import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_detail_providers.dart';
import 'activity_description_editor.dart';
import 'activity_detail_charts.dart';

class EventDetailsWrapper extends StatelessWidget {
  const EventDetailsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! int) {
      throw StateError('EventDetails requires an Activity id');
    }
    return EventDetails(activityId: arguments);
  }
}

class EventDetails extends ConsumerWidget {
  const EventDetails({super.key, required this.activityId});

  final int activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(activitySnapshotProvider(activityId));
    return AsyncStateView<Activity>(
      value: snapshot,
      data: (activity) => _buildPage(context, ref, activity),
      errorMessage: '加载项目失败',
      onRetry: () => ref.invalidate(activitySnapshotProvider(activityId)),
    );
  }

  Widget _buildPage(BuildContext context, WidgetRef ref, Activity activity) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _deleteActivity(context, ref, activity.id),
            icon: const Icon(Icons.delete),
          ),
        ],
        title: Text('${activity.name} - 项目详细'),
      ),
      body: ListView(
        children: [
          _buildDescriptionCard(activity.id),
          _buildCharts(ref, activity),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(int activityId) {
    return Card(
      elevation: 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text('项目描述', style: chartTitleStyle),
          ),
          Align(
            alignment: Alignment.center,
            child: ActivityDescriptionEditor(activityId: activityId),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(WidgetRef ref, Activity activity) {
    final records = ref.watch(activityRecordsProvider(activity.id));
    return AsyncStateView<List<ActivityRecord>>(
      value: records,
      data: (records) =>
          ActivityDetailCharts(activity: activity, records: records),
      errorMessage: '加载记录失败',
      emptyMessage: '暂无记录',
      isEmpty: (records) => records.isEmpty,
      layout: AsyncStateLayout.card,
      onRetry: () => ref.invalidate(activityRecordsProvider(activity.id)),
    );
  }

  Future<void> _deleteActivity(
    BuildContext context,
    WidgetRef ref,
    int activityId,
  ) {
    return ActivityDetailController(
      repository: ref.read(activityWriterProvider),
    ).deleteActivityAndExit(
      activityId,
      confirmDelete: () => _confirmDelete(context),
      exitDetail: (deleted) {
        if (context.mounted) {
          Navigator.of(context).pop(deleted);
        }
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('是否删除该项目及所有记录？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('否'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('是'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

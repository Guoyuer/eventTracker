import 'package:event_tracker/common/async_state.dart';
import 'package:event_tracker/common/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/activity_detail_controller.dart';
import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_detail_providers.dart';
import '../l10n/app_localizations.dart';
import 'activity_description_editor.dart';
import 'activity_detail_charts.dart';

class ActivityDetailRoute extends StatelessWidget {
  const ActivityDetailRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! int) {
      throw StateError('ActivityDetailRoute requires an Activity id');
    }
    return ActivityDetailPage(activityId: arguments);
  }
}

class ActivityDetailPage extends ConsumerWidget {
  const ActivityDetailPage({super.key, required this.activityId});

  final int activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(activitySnapshotProvider(activityId));
    return AsyncStateView<Activity>(
      value: snapshot,
      data: (activity) => _buildPage(context, ref, activity),
      errorMessage: AppLocalizations.of(context)!.loadActivitiesFailed,
      onRetry: () => ref.invalidate(activitySnapshotProvider(activityId)),
      retryLabel: AppLocalizations.of(context)!.retry,
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
        title: Text(
          AppLocalizations.of(context)!.activityDetailTitle(activity.name),
        ),
      ),
      body: ListView(
        children: [
          _buildDescriptionCard(context, activity.id),
          _buildCharts(context, ref, activity),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, int activityId) {
    return Card(
      elevation: 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)!.activityDescription,
              style: AppChartTheme.of(context).titleStyle,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ActivityDescriptionEditor(activityId: activityId),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context, WidgetRef ref, Activity activity) {
    final records = ref.watch(activityRecordsProvider(activity.id));
    return AsyncStateView<List<ActivityRecord>>(
      value: records,
      data: (records) =>
          ActivityDetailCharts(activity: activity, records: records),
      errorMessage: AppLocalizations.of(context)!.loadRecordsFailed,
      emptyMessage: AppLocalizations.of(context)!.noRecords,
      isEmpty: (records) => records.isEmpty,
      layout: AsyncStateLayout.card,
      onRetry: () => ref.invalidate(activityRecordsProvider(activity.id)),
      retryLabel: AppLocalizations.of(context)!.retry,
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
              title: Text(AppLocalizations.of(context)!.deleteActivityPrompt),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.no),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(AppLocalizations.of(context)!.yes),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

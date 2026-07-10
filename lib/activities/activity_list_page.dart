import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/activity_list_controller.dart';
import '../common/async_state.dart';
import '../common/common_widgets.dart';
import '../common/localized_activity_messages.dart';
import '../domain/activity_models.dart';
import '../l10n/app_localizations.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_list_providers.dart';

import 'activity_list_helpers.dart';
import 'activity_routes.dart';

class ActivityListPage extends ConsumerWidget {
  const ActivityListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityListProvider);
    final localizations = AppLocalizations.of(context)!;
    return AsyncStateView<List<Activity>>(
      value: activities,
      data: (activities) => ActivityListView(
        activities: activities,
        onScrollDirectionChanged: (direction) {
          ref.read(activityListScrollDirectionProvider.notifier).set(direction);
        },
      ),
      errorMessage: localizations.loadActivitiesFailed,
      emptyMessage: localizations.noActivities,
      isEmpty: (activities) => activities.isEmpty,
      onRetry: () => ref.invalidate(activityListProvider),
      retryLabel: localizations.retry,
    );
  }
}

class ActivityListView extends StatefulWidget {
  const ActivityListView({
    super.key,
    required this.activities,
    required this.onScrollDirectionChanged,
  });

  final List<Activity> activities;
  final ValueChanged<ScrollDirection> onScrollDirectionChanged;

  @override
  State<ActivityListView> createState() => _ActivityListViewState();
}

class _ActivityListViewState extends State<ActivityListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollDirection);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollDirection);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollDirection() {
    widget.onScrollDirectionChanged(
      _scrollController.position.userScrollDirection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.activities.length,
      itemBuilder: (ctx, idx) {
        return ActivityTile(activity: widget.activities[idx]);
      },
    );
  }
}

class ActivityTileAction extends ConsumerWidget {
  const ActivityTileAction({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final (icon, label) = switch (activity) {
      PlainActivity() => (Icons.add_rounded, localizations.newRecord),
      InactiveTimedActivity() => (
        Icons.play_arrow_outlined,
        localizations.start,
      ),
      ActiveTimedActivity() => (Icons.stop_circle_outlined, localizations.stop),
    };
    return activityActionButton(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () => _submitRecording(context, ref, activity, DateTime.now()),
    );
  }

  Future<void> _submitRecording(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
    DateTime recordedAt,
  ) {
    final controller = ActivityListController(
      recordLifecycle: ref.read(recordLifecycleProvider),
      messages: localizedActivityMessages(AppLocalizations.of(context)!),
      refresh: () => ref.invalidate(activityListProvider),
      notify: showToast,
    );

    return controller.recordActivity(
      activity,
      recordedAt,
      requestValue: (unit) => inputValDialog(context, unit),
    );
  }
}

class ActivityTile extends ConsumerWidget {
  const ActivityTile({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = this.activity;
    final activityInfo = ActivityTileInfo(activity);
    final isActive = activity is ActiveTimedActivity;

    return Card(
      elevation: 8,
      child: Stack(
        children: [
          if (isActive) Positioned.fill(child: ActiveTimingHighlight()),
          InkWell(
            onTap: () async {
              final controller = ActivityListController(
                recordLifecycle: ref.read(recordLifecycleProvider),
                messages: localizedActivityMessages(
                  AppLocalizations.of(context)!,
                ),
                refresh: () => ref.invalidate(activityListProvider),
                notify: showToast,
              );
              await controller.showActivityDetail(
                activity.id,
                showDetail: (activityId) async {
                  return await Navigator.of(
                        context,
                      ).pushNamed(ActivityRoutes.detail, arguments: activityId)
                      as bool?;
                },
              );
            },
            child: Container(
              margin: EdgeInsets.only(left: 10, top: 10),
              height: 68,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(activity.name, style: TextStyle(fontSize: 17)),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 5),
                      child: activityInfo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              child: ActivityTileAction(activity: activity),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveTimingHighlight extends StatefulWidget {
  const ActiveTimingHighlight({super.key});

  @override
  State<ActiveTimingHighlight> createState() => _ActiveTimingHighlightState();
}

class _ActiveTimingHighlightState extends State<ActiveTimingHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      reverseDuration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(color: const Color(0xaabeddf5)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ActivityTileInfo extends StatelessWidget {
  final Activity activity;

  const ActivityTileInfo(this.activity, {super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return switch (activity) {
      ActiveTimedActivity active => LapsedTimeStr(startTime: active.startedAt),
      TimedActivity timed => _timingInfo(localizations, timed),
      PlainActivity plain => _plainInfo(localizations, plain),
    };
  }

  Widget _timingInfo(AppLocalizations localizations, TimedActivity activity) {
    var summary = localizations.notStarted;
    if (activity.totalDuration.inMicroseconds != 0) {
      summary = localizations.completedDuration(
        formatDuration(localizations, activity.totalDuration),
      );
    }

    return _summaryInfo(
      localizations,
      summary,
      activity.unit,
      activity.totalValue,
    );
  }

  Widget _plainInfo(AppLocalizations localizations, PlainActivity activity) {
    final summary = activity.occurrenceCount == 0
        ? localizations.notStarted
        : localizations.completedCount(activity.occurrenceCount);
    return _summaryInfo(
      localizations,
      summary,
      activity.unit,
      activity.totalValue,
    );
  }

  Widget _summaryInfo(
    AppLocalizations localizations,
    String summary,
    String? unit,
    double? value,
  ) {
    final summaryText = _mutedText(summary);
    if (unit == null || value == null || value == 0) {
      return Align(alignment: Alignment.centerLeft, child: summaryText);
    }

    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: summaryText),
        Align(
          alignment: Alignment.centerLeft,
          child: _mutedText(
            localizations.totalValue(value.toInt().toString(), unit),
          ),
        ),
      ],
    );
  }

  Widget _mutedText(String text) {
    return Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 14));
  }
}

class LapsedTimeStr extends ConsumerWidget {
  final DateTime startTime;

  const LapsedTimeStr({super.key, required this.startTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final duration = ref.watch(elapsedDurationProvider(startTime));
    final text = duration.maybeWhen(
      data: (timePassed) => localizations.elapsedDuration(
        formatDuration(localizations, timePassed),
      ),
      orElse: () => localizations.elapsed,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(color: Colors.grey)),
    );
  }
}

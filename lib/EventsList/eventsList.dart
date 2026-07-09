import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/activity_list_controller.dart';
import '../common/async_state.dart';
import '../common/commonWidget.dart';
import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_list_providers.dart';

import 'events_list_helpers.dart';

class EventList extends ConsumerWidget {
  EventList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(activityListProvider);
    return AsyncStateView<List<Activity>>(
      value: events,
      data: (events) => ActivityListView(
        activities: events,
        onScrollDirectionChanged: (direction) {
          ref.read(eventListScrollDirProvider.notifier).set(direction);
        },
      ),
      errorMessage: '加载项目失败',
      emptyMessage: '暂无项目',
      isEmpty: (events) => events.isEmpty,
      onRetry: () => ref.invalidate(activityListProvider),
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
        return EventTile(activity: widget.activities[idx]);
      },
    );
  }
}

class EventTileButton extends ConsumerWidget {
  const EventTileButton({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, label) = switch (activity) {
      PlainActivity() => (Icons.add_rounded, '新记录'),
      InactiveTimedActivity() => (Icons.play_arrow_outlined, '开始'),
      ActiveTimedActivity() => (Icons.stop_circle_outlined, '停止'),
    };
    return eventListButton(Icon(icon), Text(label), () {
      _submitRecording(context, ref, activity, DateTime.now());
    });
  }

  Future<void> _submitRecording(
    BuildContext context,
    WidgetRef ref,
    Activity event,
    DateTime recordedAt,
  ) {
    final controller = ActivityListController(
      recordLifecycle: ref.read(recordLifecycleProvider),
      refresh: () => ref.invalidate(activityListProvider),
      notify: showToast,
    );

    return controller.recordActivity(
      event,
      recordedAt,
      requestValue: (unit) => inputValDialog(context, unit),
    );
  }
}

class EventTile extends ConsumerWidget {
  const EventTile({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = this.activity;
    final eventInfo = EventTileInfo(activity);
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
                refresh: () => ref.invalidate(activityListProvider),
                notify: showToast,
              );
              await controller.showActivityDetail(
                activity.id,
                showDetail: (activityId) async {
                  return await Navigator.of(
                        context,
                      ).pushNamed("EventDetails", arguments: activityId)
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
                      child: eventInfo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              child: EventTileButton(activity: activity),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveTimingHighlight extends StatefulWidget {
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

class EventTileInfo extends StatelessWidget {
  final Activity event;

  EventTileInfo(this.event);

  @override
  Widget build(BuildContext context) {
    return switch (event) {
      ActiveTimedActivity active => LapsedTimeStr(startTime: active.startedAt),
      TimedActivity timed => _timingInfo(timed),
      PlainActivity plain => _plainInfo(plain),
    };
  }

  Widget _timingInfo(TimedActivity event) {
    var summary = "尚未开始";
    if (event.totalDuration.inMicroseconds != 0) {
      summary = "共进行${formatDuration(event.totalDuration)}";
    }

    return _summaryInfo(summary, event.unit, event.totalValue);
  }

  Widget _plainInfo(PlainActivity event) {
    final summary = event.occurrenceCount == 0
        ? "尚未开始"
        : "已进行 ${event.occurrenceCount} 次";
    return _summaryInfo(summary, event.unit, event.totalValue);
  }

  Widget _summaryInfo(String summary, String? unit, double? value) {
    final summaryText = _mutedText(summary);
    if (unit == null || value == null || value == 0) {
      return Align(alignment: Alignment.centerLeft, child: summaryText);
    }

    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: summaryText),
        Align(
          alignment: Alignment.centerLeft,
          child: _mutedText("累计：${value.toInt()} $unit"),
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

  LapsedTimeStr({Key? key, required this.startTime}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(elapsedDurationProvider(startTime));
    final text = duration.maybeWhen(
      data: (timePassed) => "已进行${formatDuration(timePassed)}",
      orElse: () => "已进行",
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(color: Colors.grey)),
    );
  }
}

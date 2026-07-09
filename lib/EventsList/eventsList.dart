import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/activity_recording_controller.dart';
import '../application/activity_recording_actions.dart';
import '../common/async_state.dart';
import '../common/commonWidget.dart';
import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_list_providers.dart';

import 'events_list_helpers.dart';

class EventList extends ConsumerStatefulWidget {
  EventList({Key? key}) : super(key: key);

  @override
  ConsumerState<EventList> createState() => _EventListState();
}

class _EventListState extends ConsumerState<EventList> {
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
    ref
        .read(eventListScrollDirProvider.notifier)
        .set(_scrollController.position.userScrollDirection);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(activityListProvider);
    return AsyncStateView<List<BaseEventModel>>(
      value: events,
      data: _buildEventList,
      errorMessage: '加载项目失败',
      emptyMessage: '暂无项目',
      isEmpty: (events) => events.isEmpty,
      onRetry: () => ref.invalidate(activityListProvider),
    );
  }

  Widget _buildEventList(List<BaseEventModel> events) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: events.length,
      itemBuilder: (ctx, idx) {
        return EventDataHolder(event: events[idx], child: EventTile());
      },
    );
  }
}

class EventTileButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BaseEventModel event = EventDataHolder.of(context).event;
    EventStatus status = getEventStatus(event);
    switch (status) {
      case EventStatus.plain:
        return eventListButton(Icon(Icons.add_rounded), Text("新记录"), () {
          _submitRecording(context, ref, event, DateTime.now());
        });
      case EventStatus.notActive:
        return eventListButton(Icon(Icons.play_arrow_outlined), Text("开始"), () {
          _submitRecording(context, ref, event, DateTime.now());
        });
      case EventStatus.active:
        return eventListButton(
          Icon(Icons.stop_circle_outlined),
          Text("停止"),
          () {
            _submitRecording(context, ref, event, DateTime.now());
          },
        );
      default:
        return eventListButton(
          Icon(Icons.help_outline_rounded),
          Text("???"),
          () {},
        );
    }
  }

  Future<void> _submitRecording(
    BuildContext context,
    WidgetRef ref,
    BaseEventModel event,
    DateTime recordedAt,
  ) {
    final controller = ActivityRecordingController(
      actions: ActivityRecordingActions(ref.read(activityRepositoryProvider)),
      refresh: () => ref.invalidate(activityListProvider),
      notify: showToast,
    );

    return controller.record(
      event,
      recordedAt,
      requestValue: (unit) => inputValDialog(context, unit),
    );
  }
}

class EventDataHolder extends InheritedWidget {
  final BaseEventModel event;

  EventDataHolder({required this.event, required Widget child})
    : super(child: child);

  @override
  bool updateShouldNotify(EventDataHolder oldWidget) {
    return event.id != oldWidget.event.id;
  }

  static EventDataHolder of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventDataHolder>()!;
  }
}

class EventTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BaseEventModel event = EventDataHolder.of(context).event;
    final eventInfo = EventTileInfo(event);
    final isActive =
        event is TimingEventModel && event.status == EventStatus.active;

    return Card(
      elevation: 8,
      child: Stack(
        children: [
          if (isActive) Positioned.fill(child: ActiveTimingHighlight()),
          InkWell(
            onTap: () async {
              bool? deleted =
                  await Navigator.of(
                        context,
                      ).pushNamed("EventDetails", arguments: event)
                      as bool?;
              if (deleted != null && deleted) {
                ref.invalidate(activityListProvider);
              }
            },
            child: Container(
              margin: EdgeInsets.only(left: 10, top: 10),
              height: 68,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(event.name, style: TextStyle(fontSize: 17)),
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
              child: EventTileButton(),
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
  final BaseEventModel event;

  EventTileInfo(this.event);

  @override
  Widget build(BuildContext context) {
    if (event is TimingEventModel) {
      return _timingInfo(event as TimingEventModel);
    }

    return _plainInfo(event as PlainEventModel);
  }

  Widget _timingInfo(TimingEventModel event) {
    if (event.status == EventStatus.active) {
      return LapsedTimeStr(startTime: event.startTime!);
    }

    var summary = "尚未开始";
    if (event.sumDuration.inMicroseconds != 0) {
      summary = "共进行${formatDuration(event.sumDuration)}";
    }

    return _summaryInfo(summary, event.unit, event.sumVal);
  }

  Widget _plainInfo(PlainEventModel event) {
    final summary = event.time == 0 ? "尚未开始" : "已进行 ${event.time} 次";
    return _summaryInfo(summary, event.unit, event.sumVal);
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

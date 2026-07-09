import 'dart:async';

import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stateProviders.dart';
import '../common/commonWidget.dart';
import '../common/const.dart';
import '../domain/activity_models.dart';

part 'util.dart';

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
    ref.read(eventListScrollDirProvider.notifier).update(
          (state) => _scrollController.position.userScrollDirection,
        );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(activityListProvider);
    return events.when(
      data: _buildEventList,
      error: (error, stackTrace) => Center(child: Text("加载项目失败：$error")),
      loading: loadingScreen,
    );
  }

  Widget _buildEventList(List<BaseEventModel> events) {
    if (events.isEmpty) {
      return Center(child: Text("暂无项目"));
    }

    return ListView.builder(
        controller: _scrollController,
        itemCount: events.length,
        itemBuilder: (ctx, idx) {
          return EventDataHolder(event: events[idx], child: EventTile());
        });
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
          DateTime now = DateTime.now();
          addPlainRecord(context, ref, now);
        });
      case EventStatus.notActive:
        return eventListButton(Icon(Icons.play_arrow_outlined), Text("开始"), () {
          DateTime now = DateTime.now();
          startTimingRecord(context, ref, now);
        });
      case EventStatus.active:
        return eventListButton(Icon(Icons.stop_circle_outlined), Text("停止"),
            () {
          stopTimingRecord(context, ref, DateTime.now());
        });
      default:
        return eventListButton(
            Icon(Icons.help_outline_rounded), Text("???"), () {});
    }
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

class EventTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<EventTile> createState() => _EventTileState();
}

class _EventTileState extends ConsumerState<EventTile>
    with SingleTickerProviderStateMixin {
  late final Animation<double> animation;
  late final AnimationController _controller;
  late final int second; //渐变时长
  initState() {
    super.initState();
    second = 1;
    _controller = AnimationController(
        duration: Duration(seconds: second),
        reverseDuration: Duration(seconds: second),
        vsync: this)
      ..repeat(reverse: true);

    animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    BaseEventModel event = EventDataHolder.of(context).event;
    Widget eventInfo;
    if (event is TimingEventModel) {
      String sumValStr;
      var data = event;
      if (data.status == EventStatus.notActive) {
        _controller.reset();
        String sumTimeStr = "尚未开始";
        if (data.sumDuration.inMicroseconds != 0) {
          sumTimeStr = formatDuration(data.sumDuration);
          sumTimeStr = "共进行$sumTimeStr";
        }

        String? unit = data.unit;
        if (data.unit != null && data.sumVal != 0) {
          int val = data.sumVal!.toInt();
          sumValStr = "累计：$val $unit";
          eventInfo = Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(sumTimeStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14))),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(sumValStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          ]);
        } else {
          eventInfo = Align(
              alignment: Alignment.centerLeft,
              child: Text(
                sumTimeStr,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ));
        }
      } else {
        eventInfo = LapsedTimeStr(startTime: data.startTime!);
      }
    } else {
      _controller.reset();
      var data = (event as PlainEventModel);
      int time = data.time;

      String sumTimeStr;
      if (time == 0) {
        sumTimeStr = "尚未开始";
      } else {
        sumTimeStr = "已进行 $time 次";
      }
      String? unit = data.unit;
      if (data.unit != null && data.sumVal != 0) {
        int val = data.sumVal!.toInt();
        String sumValStr = "累计：$val $unit";
        eventInfo = Column(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text(sumTimeStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(sumValStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        ]);
      } else {
        eventInfo = Align(
            alignment: Alignment.centerLeft,
            child: Text(sumTimeStr,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)));
      }
    }
    return Card(
        elevation: 8,
        child: Stack(
          children: [
            Positioned.fill(
                child: FadeTransition(
                    opacity: animation,
                    child: Container(color: const Color(0xaabeddf5)))),
            InkWell(
              onTap: () async {
                bool? deleted = await Navigator.of(context)
                    .pushNamed("EventDetails", arguments: event) as bool?;
                if (deleted != null && deleted) {
                  refreshActivityList(ref);
                }
              },
              child: Container(
                  margin: EdgeInsets.only(left: 10, top: 10),
                  height: 68,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          event.name,
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                      Expanded(
                          child: Container(
                        margin: EdgeInsets.only(left: 5),
                        child: eventInfo,
                      ))
                    ],
                  )),
            ),
            Positioned.fill(
                child: Container(
                    alignment: Alignment.centerRight,
                    child: EventTileButton())),
          ],
        ));
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class LapsedTimeStr extends StatefulWidget {
  final DateTime startTime;

  LapsedTimeStr({Key? key, required this.startTime}) : super(key: key);

  @override
  _LapsedTimeStrState createState() => _LapsedTimeStrState();
}

class _LapsedTimeStrState extends State<LapsedTimeStr> {
  late String str;
  late final Timer timer;

  @override
  void initState() {
    _updateStr();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      _updateStr();
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          str,
          style: TextStyle(color: Colors.grey),
        ));
  }

  void _updateStr() {
    Duration timePassed = DateTime.now().difference(widget.startTime);
    setState(() {
      str = "已进行" + formatDuration(timePassed);
    });
  }
}

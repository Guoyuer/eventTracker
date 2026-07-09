part of 'eventsList.dart';

Future<void> startTimingRecord(BuildContext context, DateTime now) async {
  int eventId = EventDataHolder.of(context).event.id;
  await activityRepository().startTimedRecord(eventId, now);
  ReloadEventsN().dispatch(context);
}

Future<double?> inputValDialog(BuildContext ctx, String unit) async {
  final controller = TextEditingController();
  try {
    return await showDialog<double>(
        context: ctx,
        builder: (context) {
          return AlertDialog(
            title: Text("请输入数据"),
            content: Row(
              children: [
                Text("共完成了"),
                Flexible(
                    child: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: "?"),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                )),
                Text(unit),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: Text("取消")),
              TextButton(
                  onPressed: () {
                    try {
                      Navigator.of(context).pop(double.parse(controller.text));
                    } catch (err) {
                      showToast("请输入数值");
                    }
                  },
                  child: Text("确认")),
            ],
          );
        });
  } finally {
    controller.dispose();
  }
}

Future<void> addPlainRecord(BuildContext context, DateTime time) async {
  int eventId = EventDataHolder.of(context).event.id;

  String? unit = await activityRepository().getActivityUnit(eventId);

  double? val;
  if (unit != null) {
    val = await inputValDialog(context, unit);
    if (val == null) return;
  }
  await activityRepository().addPlainRecord(eventId, time, value: val);
  ReloadEventsN().dispatch(context);
}

Future<void> stopTimingRecord(BuildContext context, DateTime time) async {
  int eventId = EventDataHolder.of(context).event.id;

  final repository = activityRepository();
  int recordId = await repository.getLastRecordId(eventId);

  DateTime startTime = await repository.getActivityStartTime(eventId);
  var fiveSeconds = Duration(seconds: 5);
  Duration thisDuration = DateTime.now().difference(startTime);
  if (thisDuration.compareTo(fiveSeconds) < 0) {
    bool delete = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("时间不足5s，删除该记录还是继续？"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text("删除")),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text("继续"))
                ],
              );
            }) ??
        false;
    if (delete) {
      await repository.deleteActiveTimedRecord(eventId, recordId);
      ReloadEventsN().dispatch(context);
      return;
    } else {
      showToast("继续");
      return;
    }
  } else {
    String? unit = await repository.getActivityUnit(eventId);
    double? val = 0;
    if (unit != null) {
      val = await inputValDialog(context, unit);
      if (val == null) return;
    }

    await repository.stopTimedRecord(eventId, recordId, time, thisDuration,
        value: val);
    ReloadEventsN().dispatch(context);
  }
}

EventStatus getEventStatus(BaseEventModel event) {
  if (event is TimingEventModel) {
    return event.status;
  } else {
    if (event is PlainEventModel) return EventStatus.plain;
  }
  return EventStatus.plain;
}

String formatDuration(Duration duration) {
  String str = "";
  int hours = 0;
  if (duration.inHours > 0) {
    hours = duration.inHours;
    duration -= Duration(hours: hours);
    str += " $hours小时";
  }
  if (duration.inMinutes > 0) {
    int minutes = duration.inMinutes;
    duration -= Duration(minutes: minutes);
    str += " $minutes分钟";
  }
  if (duration.inSeconds > 0) {
    int seconds = duration.inSeconds;
    duration -= Duration(seconds: seconds);
    str += " $seconds秒";
  }
  return str;
}

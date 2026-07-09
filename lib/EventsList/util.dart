part of 'eventsList.dart';

const accidentalTimedRecordThreshold = Duration(seconds: 5);

void refreshActivityList(BuildContext context) {
  ProviderScope.containerOf(context).invalidate(activityListProvider);
}

Future<void> startTimingRecord(BuildContext context, DateTime now) async {
  int eventId = EventDataHolder.of(context).event.id;
  await activityRepository().startTimedRecord(eventId, now);
  refreshActivityList(context);
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
  refreshActivityList(context);
}

Future<void> stopTimingRecord(BuildContext context, DateTime time) async {
  final event = EventDataHolder.of(context).event as TimingEventModel;
  final eventId = event.id;

  final repository = activityRepository();
  final duration = time.difference(event.startTime!);
  if (duration < accidentalTimedRecordThreshold) {
    await repository.cancelActiveTimedRecord(eventId);
    refreshActivityList(context);
    showToast("已取消本次计时");
    return;
  }

  String? unit = await repository.getActivityUnit(eventId);
  double? val = 0;
  if (unit != null) {
    val = await inputValDialog(context, unit);
    if (val == null) return;
  }

  await repository.stopActiveTimedRecord(eventId, time, value: val);
  refreshActivityList(context);
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

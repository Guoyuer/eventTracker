part of 'eventsList.dart';

void refreshActivityList(WidgetRef ref) {
  ref.invalidate(activityListProvider);
}

Future<void> recordActivity(
  BuildContext context,
  WidgetRef ref,
  DateTime recordedAt,
) async {
  final event = EventDataHolder.of(context).event;
  final recorder =
      ActivityRecordingActions(ref.read(activityRepositoryProvider));
  final outcome = await recorder.record(
    event,
    recordedAt,
    requestValue: (unit) => inputValDialog(context, unit),
  );

  switch (outcome) {
    case ActivityRecordingOutcome.changed:
      refreshActivityList(ref);
      break;
    case ActivityRecordingOutcome.canceledAccidentalTimedRecord:
      refreshActivityList(ref);
      showToast("已取消本次计时");
      break;
    case ActivityRecordingOutcome.unchanged:
      break;
  }
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

part of 'eventsList.dart';

void startTimingRecord(BuildContext context) {
  int eventId = EventDataHolder.of(context).event.id;
  DBHandle()
      .db
      .startTimingRecordInDB((RecordsCompanion(
          startTime: Value(DateTime.now()), eventId: Value(eventId))))
      .then((_) => ReloadEventsNotification().dispatch(context));
}

Future<String> inputValDialog(
    BuildContext ctx, TextEditingController _c, String unit) {
  return showDialog<String>(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: Text("请输入"),
          content: Row(
            children: [
              Text("共完成了"),
              Flexible(
                  child: TextField(
                controller: _c,
                decoration: InputDecoration(hintText: "?"),
              )),
              Text(unit),
            ],
          ),
          actions: [
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: Text("取消")),
            FlatButton(
                onPressed: () {
                  print(_c.text);
                  Navigator.of(context).pop(_c.text);
                },
                child: Text("确认")),
          ],
        );
      });
}

Future addPlainRecord(BuildContext context) async {
  int eventId = EventDataHolder.of(context).event.id;
  //判断是否有unit
  TextEditingController _c = TextEditingController();

  String unit = await DBHandle().db.getEventUnit(eventId);

  double val = 0;
  if (unit != null) {
    //有单位
    String valStr = await inputValDialog(context, _c, unit);
    if (valStr == null) return; // 对话框点了取消，不记录
    if (valStr.isNotEmpty) {
      val = double.parse(valStr);
    }
  }
  DBHandle()
      .db
      .addPlainRecordInDB((RecordsCompanion(
          value: Value(val),
          endTime: Value(DateTime.now()),
          eventId: Value(eventId))))
      .then((_) => ReloadEventsNotification().dispatch(context));
}

//按下停止记录按钮的回调函数
Future stopTimingRecord(BuildContext context) async {
  int eventId = EventDataHolder.of(context).event.id;

  var db = DBHandle().db;
  TextEditingController _c = TextEditingController();
  int recordId = await db.getLastRecordId(eventId);

  DateTime startTime = await db.getStartTime(recordId);
  var fiveSeconds = Duration(seconds: 5);
  Duration thisDuration = DateTime.now().difference(startTime);
  if (thisDuration.compareTo(fiveSeconds) < 0) {
    //任务距开始不足5s
    bool delete = await showDialog(
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
        });
    if (delete) {
      db.deleteActiveTimingRecordInDB(recordId, eventId).then((_) {
        ReloadEventsNotification().dispatch(context);
      });
      return;
    } else {
      showToast("继续");
      return;
    }
  } else {
    //该任务距开始超过5s，进行正常停止操作
    String unit = await DBHandle().db.getEventUnit(eventId);
    double val = 0;
    if (unit != null) {
      String valStr = await inputValDialog(context, _c, unit);
      if (valStr == null) return;
      if (valStr.isNotEmpty) val = double.parse(valStr);
    }

    db
        .stopTimingRecordInDB(
            thisDuration,
            RecordsCompanion(
                id: Value(recordId),
                eventId: Value(eventId),
                endTime: Value(DateTime.now()),
                value: Value(val)))
        .then((_) => ReloadEventsNotification().dispatch(context));
  }
}

EventStatus getEventStatus(BaseEventDisplayModel event) {
  if (event is TimingEventDisplayModel) {
    return event.status;
  } else {
    if (event is PlainEventDisplayModel) return event.status;
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

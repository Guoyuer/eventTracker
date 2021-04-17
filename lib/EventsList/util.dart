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
            title: Text("时间不足5s，删除还是继续"),
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
    print("是否删除");
    print(delete);
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
    print(thisDuration.toString());
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

// String getSubtitleText(BaseEventDisplayModel event) {
//   String text;
//   if (event is TimingEventDisplayModel) {
//     //TimingEvent
//     var data = event;
//     if (!data.isActive) {
//       //inactive，显示累计时间和值(if有单位)
//       String sumTimeStr =
//           prettyDuration(data.sumTime, locale: ChineseDurationLocale());
//       text = "共进行 $sumTimeStr";
//
//       String unit = data.unit;
//       if (data.unit != null && data.sumVal != 0) {
//         int val = data.sumVal.toInt();
//         text += " | 累计：$val $unit";
//       }
//     } else {
//       //active，显示进行了的时间
//       Duration timePassed = DateTime.now().difference(data.startTime);
//       text =
//           "已进行 " + prettyDuration(timePassed, locale: ChineseDurationLocale());
//     }
//   } else {
//     //PlainEvent
//     var data = (event as PlainEventDisplayModel);
//     int time = data.time;
//     text = "已进行 $time 次";
//     String unit = data.unit;
//     if (data.unit != null && data.sumVal != 0) {
//       int val = data.sumVal.toInt();
//       text += " | 累计：$val $unit";
//     }
//   }
//
//   return text;
// }

EventStatus getEventStatus(BaseEventDisplayModel event) {
  if (event is TimingEventDisplayModel) {
    return event.status;
  } else {
    if (event is PlainEventDisplayModel) return event.status;
  }
  return EventStatus.plain;
}

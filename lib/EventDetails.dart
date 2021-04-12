import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:flutter_event_tracker/settingPage.dart';
import 'heatMapPage.dart';
import 'EventsList/eventsList.dart';
import 'eventEditor.dart';
import 'common/util.dart';
import 'common/const.dart';
import 'package:flutter/widgets.dart';
import 'DAO/base.dart';

class EventDetails extends StatefulWidget {
  EventDetails({Key key}) : super(key: key);

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  Future<List<Record>> _records;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int eventId = ModalRoute.of(context).settings.arguments;
    _records = DBHandle().db.getAllRecords(eventId);
    return FutureBuilder<List<Record>>(
        future: _records,
        builder: (ctx, snapshot) {
          List<Record> records = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Scaffold(
                  body: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (ctx, idx) {
                        return ListTile(
                            title: Text(records[idx].id.toString() +
                                "   " +
                                records[idx].startTime.toString()));
                      }));
              break;
            default:
              return loadingScreen();
          }
        });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'DAO/EventsProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/model/Unit.dart';
import 'package:sqflite/sqflite.dart';
import 'DAO/UnitsProvider.dart';
import 'common/customWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EventList extends StatefulWidget {
  EventList();

  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  EventsDbProvider db = EventsDbProvider();

  Future<List<Map>> _events;
  String a;

  @override
  void initState() {
    super.initState();
    _events = db.getEventsProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map>>(
        future: _events,
        builder: (ctx, snapshot) {
          List<Map> data = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (ctx, idx) {
                    return AnimationEventTile(data[idx]['name']);
                  });
              break;
            default:
              return loadingScreen();
          }
        });
  }
}




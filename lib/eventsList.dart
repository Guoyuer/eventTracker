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
    return Container(
        child: new ListView(
      children: [new EventTile()],
    ));
  }
}

class EventTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        new Flexible(
            child:
                new ListTile(title: Text("title"), subtitle: Text("subtitle"))),
        new AddRecordButton(),
        SizedBox(width: 10)
      ],
    );
  }
}

class AddRecordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return myRaisedButton(Text("+记录"), () {});
  }
}

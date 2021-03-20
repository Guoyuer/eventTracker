import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';

class EventsList extends StatelessWidget {
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

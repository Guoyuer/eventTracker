import 'package:flutter/material.dart';

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
    return RaisedButton(
      color: Colors.blue,
      highlightColor: Colors.blue[700],
      colorBrightness: Brightness.dark,
      splashColor: Colors.grey,
      child: Text("+纪录"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onPressed: () {},
    );
  }
}

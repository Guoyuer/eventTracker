import 'package:flutter/material.dart';
import 'DAO/model/Unit.dart';
import 'DAO/UnitsProvider.dart';

class EventEditor extends StatefulWidget {
  @override
  _EventEditorState createState() => new _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  TextEditingController _eventNameController = new TextEditingController();
  TextEditingController _eventDiscController = new TextEditingController();
  final _formKey = new GlobalKey<FormState>();
  UnitDbProvider provider = new UnitDbProvider();
  List<String> units;

  _EventEditorState() {
    getAllUsers();
  }

  void getAllUsers() async {
    units = await provider.getAllUsers();
    print(units);
  }


  // static insert() async {
  //   UnitDbProvider provider = new UnitDbProvider();
  //   UnitModel unit = UnitModel("TTTTest");
  //   // userModel.id = 1143824942687547394;
  //   provider.insert(unit);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("添加新项目"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.done_outline_rounded), onPressed: () {}),
          ],
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      onSaved: (String value) {
                        // model.eventName = value;
                      },
                      controller: _eventNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                          hintText: "项目名称",
                          prefixIcon: Icon(Icons.sticky_note_2_rounded)),
                    ),
                    TextFormField(
                      onSaved: (String value) {
                        // model.eventDesc = value;
                      },
                      controller: _eventDiscController,
                      decoration: InputDecoration(
                          hintText: "项目说明",
                          prefixIcon: Icon(Icons.subject_rounded)),
                    ),
                    RaisedButton(
                        child: Text("保存"),
                        onPressed: () {
                          _formKey.currentState.save();
                          Navigator.pop(context);
                        })
                  ],
                ))));
  }
}

class SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(Icons.done_outline_rounded), onPressed: () {});
  }
}

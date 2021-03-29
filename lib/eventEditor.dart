import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'DAO/model/Unit.dart';
import 'DAO/UnitsProvider.dart';
import 'DAO/EventsProvider.dart';

class EventEditor extends StatefulWidget {
  EventEditor();

  @override
  _EventEditorState createState() => new _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  UnitDbProvider dbUnit = UnitDbProvider();
  EventsDbProvider dbEvent = EventsDbProvider();

  TextEditingController _eventNameController = new TextEditingController();
  TextEditingController _eventDiscController = new TextEditingController();
  Future<List<String>> _units;
  Map<String, bool> _unitsChoices = Map();
  bool careTime = false;
  final _formKey = new GlobalKey<FormState>();
  Map<String, dynamic> data = Map();

  @override
  void initState() {
    super.initState();
    _units = dbUnit.getAllUnits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("添加新项目"),
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "项目名称不得为空";
                        }
                        return null;
                      },
                      onSaved: (String value) {
                        data["eventName"] = value;
                      },
                      // controller: _eventNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                          hintText: "项目名称",
                          prefixIcon: Icon(Icons.sticky_note_2_rounded)),
                    ),
                    TextFormField(
                      onSaved: (String value) {
                        data["eventDesc"] = value;
                      },
                      // controller: _eventDiscController,
                      decoration: InputDecoration(
                          hintText: "项目说明",
                          prefixIcon: Icon(Icons.subject_rounded)),
                    ),
                    SwitchListTile(
                        title: Text("关注时间"),
                        value: careTime,
                        onChanged: (bool val) {
                          setState(() {
                            careTime = val;
                          });
                        }),
                    FutureBuilder<List<String>>(
                        future: _units,
                        builder: (ctx, snapshot) {
                          List<String> units = snapshot.data;
                          switch (snapshot.connectionState) {
                            case ConnectionState.done:
                              if (_unitsChoices.isEmpty) {
                                for (String unit in units) {
                                  _unitsChoices[unit] = false;
                                }
                              }
                              return ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: units.length,
                                  itemBuilder: (ctx, idx) {
                                    return SwitchListTile(
                                        title: Text(units[idx]),
                                        value: _unitsChoices[units[idx]],
                                        onChanged: (bool val) {
                                          setState(() {
                                            _unitsChoices[units[idx]] = val;
                                          });
                                        });
                                  });
                              break;
                            default:
                              return loadingScreen();
                          }
                        }),
                    myRaisedButton(Text("保存"), () {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        data["careTime"] = careTime;
                        data['units'] = _unitsChoices;
                        Navigator.pop(context, data);
                      }
                    })
                  ],
                ))));
  }
}

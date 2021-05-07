import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/commonWidget.dart';
import 'common/util.dart';
import 'DAO/base.dart';
import 'package:moor_flutter/moor_flutter.dart' show Value;

class EventEditor extends StatefulWidget {
  EventEditor();

  @override
  _EventEditorState createState() => new _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  // UnitsDbProvider dbUnit = UnitsDbProvider();
  // EventsDbProvider dbEvent = EventsDbProvider();

  // TextEditingController _eventNameController = new TextEditingController();
  // TextEditingController _eventDiscController = new TextEditingController();
  late final Future<List<Unit>> _units;
  String? selectedUnit;
  bool careTime = true;
  final _formKey = new GlobalKey<FormState>();

  // Map<String, dynamic> data = Map();
  late String name;
  String? desc, unit;

  @override
  void initState() {
    super.initState();
    _units = DBHandle().db.getAllUnits();
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
                    Card(
                        elevation: 8,
                        child: Column(children: [
                          TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "项目名称不得为空";
                              }
                              return null;
                            },
                            onSaved: (String? value) {
                              name = value!;
                            },
                            // controller: _eventNameController,
                            autofocus: true,
                            decoration: InputDecoration(
                                hintText: "项目名称",
                                prefixIcon: Icon(Icons.sticky_note_2_rounded)),
                          ),
                          TextFormField(
                            onSaved: (String? value) {
                              desc = value;
                            },
                            // controller: _eventDiscController,
                            decoration: InputDecoration(
                                hintText: "项目说明",
                                prefixIcon: Icon(Icons.subject_rounded)),
                          ),
                          SwitchListTile(
                              title: Text("关注时长"),
                              value: careTime,
                              onChanged: (bool val) {
                                setState(() {
                                  careTime = val;
                                });
                              })
                        ])),
                    Card(
                        elevation: 8,
                        child: FutureBuilder<List<Unit>>(
                            future: _units,
                            builder: (ctx, snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.done:
                                  List<Unit> units = snapshot.data!;
                                  List<Widget> children = [];
                                  if (units.isEmpty) {
                                    children.add(ListTile(
                                        title: Text("暂无单位，可到单位管理页面添加")));
                                  } else {
                                    children
                                        .add(ListTile(title: Text("可选择单位：")));
                                  }
                                  var unitsList = ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: units.length,
                                      itemBuilder: (ctx, idx) {
                                        return RadioListTile(
                                            title: Text(units[idx].name),
                                            groupValue: selectedUnit,
                                            toggleable: true,
                                            value: units[idx].name,
                                            onChanged: (String? val) {
                                              setState(() {
                                                selectedUnit = val;
                                              });
                                            });
                                      });

                                  children.add(unitsList);
                                  return Column(
                                    children: children,
                                  );
                                default:
                                  return loadingScreen();
                              }
                            })),
                    myRaisedButton(Text("保存"), () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        EventsCompanion event = EventsCompanion(
                            name: Value(name),
                            unit: Value(selectedUnit),
                            description: Value(desc),
                            careTime: Value(careTime));
                        Navigator.pop(context, event);
                      }
                    })
                  ],
                ))));
  }
}

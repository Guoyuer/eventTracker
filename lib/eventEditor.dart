import 'package:flutter/material.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'persistence/activity_repository.dart';
import 'persistence/database/app_database.dart';
import 'stateProviders.dart';

class EventEditor extends ConsumerStatefulWidget {
  const EventEditor();

  @override
  ConsumerState<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends ConsumerState<EventEditor> {
  String? selectedUnit;
  bool careTime = true;
  final _formKey = GlobalKey<FormState>();

  late String name;
  String? desc;
  final ActivityRepository _activityRepository = activityRepository();

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitListProvider);
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
                            autofocus: true,
                            decoration: InputDecoration(
                                hintText: "项目名称",
                                prefixIcon: Icon(Icons.sticky_note_2_rounded)),
                          ),
                          TextFormField(
                            onSaved: (String? value) {
                              desc = value;
                            },
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
                        child: units.when(
                          data: _buildUnitSelector,
                          error: (error, stackTrace) => ListTile(
                            title: Text("加载单位失败"),
                          ),
                          loading: loadingScreen,
                        )),
                    myRaisedButton(Text("保存"), () {
                      _saveActivity();
                    })
                  ],
                ))));
  }

  Widget _buildUnitSelector(List<Unit> units) {
    List<Widget> children = [];
    if (units.isEmpty) {
      children.add(ListTile(title: Text("暂无单位，可到单位管理页面添加")));
    } else {
      children.add(ListTile(title: Text("可选择单位：")));
    }
    var unitsList = ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
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
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    try {
      await _activityRepository.createActivity(
        name: name,
        unit: selectedUnit,
        description: desc,
        careTime: careTime,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (_) {
      showToast("添加失败，可能是因为项目名重复！");
    }
  }
}

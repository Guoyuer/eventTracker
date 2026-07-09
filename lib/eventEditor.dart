import 'package:flutter/material.dart';
import 'package:event_tracker/common/async_state.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/activity_editor_controller.dart';
import 'domain/activity_models.dart';
import 'persistence/persistence_providers.dart';
import 'state/activity_editor_providers.dart';
import 'state/unit_providers.dart';

class EventEditor extends ConsumerWidget {
  EventEditor({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitListProvider);
    final selectedUnit = ref.watch(activityEditorSelectedUnitProvider);
    final careTime = ref.watch(activityEditorCareTimeProvider);
    String? name;
    String? description;

    Future<void> saveActivity() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      _formKey.currentState!.save();
      final created =
          await ActivityEditorController(
            repository: ref.read(activityRepositoryProvider),
            notify: showToast,
          ).createActivity(
            name: name!,
            unit: selectedUnit,
            description: description,
            careTime: careTime,
          );
      if (!created || !context.mounted) {
        return;
      }
      Navigator.pop(context, true);
    }

    return Scaffold(
      appBar: AppBar(title: Text("添加新项目")),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Card(
                elevation: 8,
                child: Column(
                  children: [
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
                        prefixIcon: Icon(Icons.sticky_note_2_rounded),
                      ),
                    ),
                    TextFormField(
                      onSaved: (String? value) {
                        description = value;
                      },
                      decoration: InputDecoration(
                        hintText: "项目说明",
                        prefixIcon: Icon(Icons.subject_rounded),
                      ),
                    ),
                    SwitchListTile(
                      title: Text("关注时长"),
                      value: careTime,
                      onChanged: (bool val) {
                        ref
                            .read(activityEditorCareTimeProvider.notifier)
                            .set(val);
                      },
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 8,
                child: AsyncStateView<List<ActivityUnit>>(
                  value: units,
                  data: (units) => _buildUnitSelector(ref, units, selectedUnit),
                  errorMessage: '加载单位失败',
                  layout: AsyncStateLayout.inline,
                  onRetry: () => ref.invalidate(unitListProvider),
                ),
              ),
              myRaisedButton(Text("保存"), () {
                saveActivity();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector(
    WidgetRef ref,
    List<ActivityUnit> units,
    String? selectedUnit,
  ) {
    List<Widget> children = [];
    if (units.isEmpty) {
      children.add(ListTile(title: Text("暂无单位，可到单位管理页面添加")));
    } else {
      children.add(ListTile(title: Text("可选择单位：")));
    }
    var unitsList = RadioGroup<String>(
      groupValue: selectedUnit,
      onChanged: (value) {
        ref.read(activityEditorSelectedUnitProvider.notifier).set(value);
      },
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: units.length,
        itemBuilder: (ctx, idx) {
          return RadioListTile<String>(
            title: Text(units[idx].name),
            toggleable: true,
            value: units[idx].name,
          );
        },
      ),
    );

    children.add(unitsList);
    return Column(children: children);
  }
}

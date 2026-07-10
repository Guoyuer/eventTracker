import 'package:flutter/material.dart';
import 'package:event_tracker/common/async_state.dart';
import 'package:event_tracker/common/common_widgets.dart';
import 'package:event_tracker/common/localized_activity_messages.dart';
import 'package:event_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/activity_editor_controller.dart';
import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_editor_providers.dart';
import '../state/unit_providers.dart';

class ActivityEditorPage extends ConsumerWidget {
  ActivityEditorPage({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitListProvider);
    final selectedUnit = ref.watch(activityEditorSelectedUnitProvider);
    final careTime = ref.watch(activityEditorCareTimeProvider);
    final localizations = AppLocalizations.of(context)!;
    String? name;
    String? description;

    Future<void> saveActivity() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      _formKey.currentState!.save();
      final created =
          await ActivityEditorController(
            repository: ref.read(activityWriterProvider),
            messages: localizedActivityMessages(localizations),
            notify: (message) => showMessage(context, message),
          ).createActivity(
            name: name!,
            unit: selectedUnit,
            description: description,
            careTime: careTime,
          );
      if (created && context.mounted) {
        Navigator.pop(context, true);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.activityEditorTitle)),
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
                          return localizations.activityNameRequired;
                        }
                        return null;
                      },
                      onSaved: (String? value) {
                        name = value!;
                      },
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: localizations.activityNameHint,
                        prefixIcon: Icon(Icons.sticky_note_2_rounded),
                      ),
                    ),
                    TextFormField(
                      onSaved: (String? value) {
                        description = value;
                      },
                      decoration: InputDecoration(
                        hintText: localizations.activityDescriptionHint,
                        prefixIcon: Icon(Icons.subject_rounded),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(localizations.trackDuration),
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
                  data: (units) => _buildUnitSelector(
                    localizations,
                    ref,
                    units,
                    selectedUnit,
                  ),
                  errorMessage: localizations.loadUnitsFailed,
                  layout: AsyncStateLayout.inline,
                  onRetry: () => ref.invalidate(unitListProvider),
                  retryLabel: localizations.retry,
                ),
              ),
              primaryActionButton(
                child: Text(localizations.save),
                onPressed: saveActivity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector(
    AppLocalizations localizations,
    WidgetRef ref,
    List<ActivityUnit> units,
    String? selectedUnit,
  ) {
    List<Widget> children = [];
    if (units.isEmpty) {
      children.add(ListTile(title: Text(localizations.noUnitsAvailable)));
    } else {
      children.add(ListTile(title: Text(localizations.availableUnits)));
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

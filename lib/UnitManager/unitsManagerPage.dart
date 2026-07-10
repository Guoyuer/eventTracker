import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/unit_management_controller.dart';
import '../common/async_state.dart';
import '../common/commonWidget.dart';
import '../common/localized_activity_messages.dart';
import '../domain/activity_models.dart';
import '../l10n/app_localizations.dart';
import '../persistence/persistence_providers.dart';
import '../state/unit_providers.dart';

class UnitsManager extends ConsumerWidget {
  const UnitsManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitListProvider);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.unitManagement)),
      body: AsyncStateView<List<ActivityUnit>>(
        value: units,
        data: (units) => _buildListView(context, ref, units),
        errorMessage: localizations.loadUnitsFailed,
        onRetry: () => ref.invalidate(unitListProvider),
        retryLabel: localizations.retry,
      ),
    );
  }

  Widget stackBehindDismiss() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.delete, color: Colors.white),
          Icon(Icons.delete, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<ActivityUnit> units,
  ) {
    final controller = _controller(context, ref);
    return Column(
      children: [
        ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: units.length,
          itemBuilder: (ctx, idx) {
            return Dismissible(
              background: stackBehindDismiss(),
              key: ObjectKey(units[idx]),
              child: Center(
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  title: Center(child: Text(units[idx].name)),
                ),
              ),
              confirmDismiss: (_) => controller.deleteUnit(
                units[idx].name,
                confirmDelete: () => _confirmDelete(context),
              ),
            );
          },
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 100),
          child: primaryActionButton(
            child: Text(AppLocalizations.of(context)!.addUnit),
            onPressed: () {
              final localizations = AppLocalizations.of(context)!;
              displayTextInputDialog(
                context,
                title: localizations.enterUnit,
                cancelLabel: localizations.cancel,
                submitLabel: localizations.add,
                onSubmit: controller.addUnit,
              );
            },
          ),
        ),
      ],
    );
  }

  UnitManagementController _controller(BuildContext context, WidgetRef ref) {
    return UnitManagementController(
      repository: ref.read(unitRepositoryProvider),
      messages: localizedActivityMessages(AppLocalizations.of(context)!),
      refresh: () => ref.invalidate(unitListProvider),
      notify: showToast,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.deleteUnitPrompt),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(AppLocalizations.of(context)!.delete),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

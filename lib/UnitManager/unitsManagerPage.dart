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
    return Scaffold(
      appBar: AppBar(title: Text("单位管理")),
      body: AsyncStateView<List<ActivityUnit>>(
        value: units,
        data: (units) => _buildListView(context, ref, units),
        errorMessage: '加载单位失败',
        onRetry: () => ref.invalidate(unitListProvider),
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
          child: myRaisedButton(Text("添加新单位"), () {
            displayTextInputDialog(context, "请输入单位", (unitName) {
              return controller.addUnit(unitName);
            });
          }),
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
              title: Text("是否删除该单位？"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("取消"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("删除"),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/commonWidget.dart';
import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import '../state/unit_providers.dart';

class UnitsManager extends ConsumerWidget {
  const UnitsManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text("单位管理"),
      ),
      body: units.when(
        data: (units) => _buildListView(context, ref, units),
        error: (error, stackTrace) => Center(child: Text("加载单位失败")),
        loading: loadingScreen,
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
          Icon(
            Icons.delete,
            color: Colors.white,
          ),
          Icon(
            Icons.delete,
            color: Colors.white,
          )
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<ActivityUnit> units,
  ) {
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
                      title: Center(child: Text(units[idx].name)))),
              confirmDismiss: (direction) =>
                  _confirmDismiss(context, direction),
              onDismissed: (direction) => _deleteUnit(ref, units[idx]),
            );
          },
        ),
        Container(
            padding: EdgeInsets.symmetric(horizontal: 100),
            child: myRaisedButton(Text("添加新单位"), () {
              displayTextInputDialog(context, "请输入单位", (unitName) {
                return _addUnit(ref, unitName);
              });
            }))
      ],
    );
  }

  Future<void> _deleteUnit(WidgetRef ref, ActivityUnit unit) async {
    try {
      await ref.read(unitRepositoryProvider).deleteUnit(unit.name);
      _refreshUnits(ref);
    } catch (_) {
      showToast("删除失败");
      _refreshUnits(ref);
    }
  }

  void _refreshUnits(WidgetRef ref) {
    ref.invalidate(unitListProvider);
  }

  Future<bool> _confirmDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("是否删除该单位？"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("取消")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("删除"))
            ],
          );
        });
  }

  Future<bool> _addUnit(WidgetRef ref, String unitName) async {
    try {
      await ref.read(unitRepositoryProvider).addUnit(unitName);
      _refreshUnits(ref);
      return true;
    } catch (_) {
      showToast("添加失败，可能是因为重复");
      return false;
    }
  }
}

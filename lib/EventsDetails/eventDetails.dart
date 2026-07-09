import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:event_tracker/common/const.dart';

import '../domain/activity_models.dart';
import '../stateProviders.dart';
import 'activity_detail_charts.dart';
import 'activity_description_editor.dart';

class EventDetailsWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BaseEventModel event =
        ModalRoute.of(context)!.settings.arguments as BaseEventModel;
    return EventDetails(event: event);
  }
}

class EventDetails extends ConsumerWidget {
  EventDetails({Key? key, required this.event}) : super(key: key);
  final BaseEventModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> listChildren = [_buildDescriptionCard()];

    if (event.lastRecordId != null) {
      listChildren.add(_buildCharts(ref));
    } else {
      listChildren.add(Text("暂无记录"));
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  final delete = await _confirmDelete(context);
                  if (delete != true) {
                    return;
                  }
                  await ref
                      .read(activityRepositoryProvider)
                      .deleteActivity(event.id);
                  ref.invalidate(activityListProvider);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                icon: Icon(Icons.delete))
          ],
          title: Text("${event.name} - 项目详细"),
        ),
        body: ListView(children: listChildren));
  }

  Widget _buildDescriptionCard() {
    return Card(
        elevation: 10,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Align(
                alignment: Alignment.center,
                child: Text(
                  "项目描述",
                  style: chartTitleStyle,
                )),
            Align(
                alignment: Alignment.center,
                child: ActivityDescriptionEditor(activityId: event.id))
          ],
        ));
  }

  Widget _buildCharts(WidgetRef ref) {
    final records = ref.watch(activityRecordsProvider(event.id));
    return records.when(
      data: (records) => ActivityDetailCharts(
        activity: event,
        records: records,
      ),
      error: (error, stackTrace) => Card(
        elevation: 10,
        child: Text("加载记录失败"),
      ),
      loading: loadingScreen,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("是否删除该项目及所有记录？"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("否")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("是"))
            ],
          );
        });
  }
}

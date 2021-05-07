import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

import '../DAO/base.dart';
import '../heatmap_calendar/heatMap.dart';

class StepDisplayModel {
  int step = 0;
  DateTime time = nilTime;

  StepDisplayModel({required this.step, required this.time});
}

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class PedometerPage extends StatelessWidget {
  PedometerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PedometerPageBuildingBlock();
  }
}

class PedometerPageBuildingBlock extends StatefulWidget {
  @override
  _PedometerPageBuildingBlockState createState() =>
      _PedometerPageBuildingBlockState();
}

class _PedometerPageBuildingBlockState
    extends State<PedometerPageBuildingBlock> {
  late final Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  var db = DBHandle().db;
  DateTime? displayDate;
  bool accumulate = false;
  String _status = '?';

  StepDisplayModel? countEvent; //初始的时候是null，注意判别
  int called = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    getLastStep();
  }

  void getLastStep() async {
    var tmp = await db.getLatestStep();
    if (tmp != null) {
      countEvent = StepDisplayModel(step: tmp.step, time: tmp.time);
    }
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onStepCount(StepCount event) async {
    //处理offset
    int offset = 0;
    StepOffsetData? lastOffset = await db.getStepOffset();
    if (lastOffset == null) {
      await db.writeStepOffset(event.steps, event.timeStamp);
      offset = event.steps;
    } else {
      if ((lastOffset.time.day != event.timeStamp.day) ||
          lastOffset.step > event.steps) {
        //与上次记录相比过了一天 或者 系统重启
        await db.updateStepOffset(event.steps, event.timeStamp);
        offset = event.steps;
      } else {
        offset = lastOffset.step;
      }
    }
    //计算步数

    setState(() {
      countEvent =
          StepDisplayModel(step: event.steps - offset, time: event.timeStamp);
    });
    db.writeStep(event.steps - offset, event.timeStamp);
  }

  void initPlatformState() async {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(onPedestrianStatusChanged);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '已走步数:',
            style: TextStyle(fontSize: 30),
          ),
          Text(
            countEvent == null ? '0' : countEvent!.step.toString(),
            style: TextStyle(fontSize: 60),
          ),
          Divider(
            height: 100,
            thickness: 0,
            color: Colors.white,
          ),
          Text(
            '步行状态:',
            style: TextStyle(fontSize: 30),
          ),
          Icon(
            _status == 'walking'
                ? Icons.directions_walk
                : _status == 'stopped'
                    ? Icons.accessibility_new
                    : Icons.error,
            size: 100,
          ),
          Center(
            child: Text(
              _status,
              style: _status == 'walking' || _status == 'stopped'
                  ? TextStyle(fontSize: 30)
                  : TextStyle(fontSize: 20, color: Colors.red),
            ),
          )
        ],
      ),
    );
  }
}

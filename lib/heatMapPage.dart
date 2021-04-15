import 'package:flutter/material.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'heatmap_calendar/heatMap.dart';
import 'heatmap_calendar/heatMapBuildingBlocks.dart';
import 'DAO/base.dart';
import 'common/const.dart';

class HeatMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MoorDbViewer(DBHandle().db);
  }
}

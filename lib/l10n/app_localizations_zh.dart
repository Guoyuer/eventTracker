// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '活动记录本';

  @override
  String appTitleWithSection(String section) {
    return '活动记录本 - $section';
  }

  @override
  String get tabActivities => '项目';

  @override
  String get tabStatistics => '统计';

  @override
  String get tabSettings => '选项';

  @override
  String get timingCancelled => '已取消本次计时';

  @override
  String get activityBusy => '该项目正在计时中';

  @override
  String duplicateActivityName(String name) {
    return '已存在名为「$name」的项目';
  }

  @override
  String duplicateUnitName(String name) {
    return '已存在名为「$name」的单位';
  }

  @override
  String unitInUse(String name) {
    return '「$name」正被某个项目使用，无法删除';
  }

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get add => '添加';

  @override
  String get confirm => '确认';

  @override
  String get delete => '删除';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get loadActivitiesFailed => '加载项目失败';

  @override
  String get loadUnitsFailed => '加载单位失败';

  @override
  String get loadRecordsFailed => '加载记录失败';

  @override
  String get loadDescriptionFailed => '加载描述失败';

  @override
  String get loadStatisticsFailed => '加载统计失败';

  @override
  String get noActivities => '暂无项目';

  @override
  String get noRecords => '暂无记录';

  @override
  String get noDescription => '无描述';

  @override
  String get activityEditorTitle => '添加新项目';

  @override
  String get activityNameRequired => '项目名称不得为空';

  @override
  String get activityNameHint => '项目名称';

  @override
  String get activityDescriptionHint => '项目说明';

  @override
  String get trackDuration => '关注时长';

  @override
  String get save => '保存';

  @override
  String get noUnitsAvailable => '暂无单位，可到单位管理页面添加';

  @override
  String get availableUnits => '可选择单位：';

  @override
  String get addUnit => '添加新单位';

  @override
  String get enterUnit => '请输入单位';

  @override
  String get deleteUnitPrompt => '是否删除该单位？';

  @override
  String get unitManagement => '单位管理';

  @override
  String get recordValueTitle => '请输入数据';

  @override
  String get recordValuePrefix => '共完成了';

  @override
  String get recordValueInvalid => '请输入大于 0 的有限数值';

  @override
  String get newRecord => '新记录';

  @override
  String get start => '开始';

  @override
  String get stop => '停止';

  @override
  String get notStarted => '尚未开始';

  @override
  String completedDuration(String duration) {
    return '共进行$duration';
  }

  @override
  String completedCount(int count) {
    return '已进行 $count 次';
  }

  @override
  String totalValue(String value, String unit) {
    return '累计：$value $unit';
  }

  @override
  String elapsedDuration(String duration) {
    return '已进行$duration';
  }

  @override
  String get elapsed => '已进行';

  @override
  String durationHours(int count) {
    return ' $count小时';
  }

  @override
  String durationMinutes(int count) {
    return ' $count分钟';
  }

  @override
  String durationSeconds(int count) {
    return ' $count秒';
  }

  @override
  String activityDetailTitle(String name) {
    return '$name - 项目详细';
  }

  @override
  String get activityDescription => '项目描述';

  @override
  String get deleteActivityPrompt => '是否删除该项目及所有记录？';

  @override
  String statisticsForMetric(String metric) {
    return '统计数据 - $metric';
  }

  @override
  String recordCountHeading(String month) {
    return '$month共进行';
  }

  @override
  String get recordCountSuffix => ' 次';

  @override
  String get metricDuration => '时长';

  @override
  String get metricCount => '次数';

  @override
  String get timeSlotActivity => '时段活跃度';

  @override
  String recordsOnDay(String date) {
    return '$date的记录';
  }

  @override
  String get noRecordsOnDay => '当日无记录';

  @override
  String statisticsRange(String start, String end) {
    return '$start 至 $end';
  }

  @override
  String get changeRange => '更改区间';

  @override
  String get countStatistics => '次数统计';

  @override
  String totalCount(int count) {
    return '共 $count 次';
  }

  @override
  String get dismissDialog => '关闭';
}

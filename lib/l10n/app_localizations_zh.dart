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
}

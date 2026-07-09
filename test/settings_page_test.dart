import 'package:event_tracker/settingPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings page exposes only product settings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {'unitsManager': (_) => const Scaffold(body: Text('units'))},
        home: SettingPage(),
      ),
    );

    expect(find.text('单位管理'), findsOneWidget);
    expect(find.text('查看数据库'), findsNothing);
    expect(find.text('删除所有数据'), findsNothing);
    expect(find.text('生成虚构数据'), findsNothing);
  });
}

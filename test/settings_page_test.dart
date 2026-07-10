import 'package:event_tracker/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

void main() {
  testWidgets('settings page exposes only product settings', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        routes: {'unitsManager': (_) => const Scaffold(body: Text('units'))},
        home: SettingPage(),
      ),
    );

    expect(find.text('Unit Management'), findsOneWidget);
    expect(find.text('查看数据库'), findsNothing);
    expect(find.text('删除所有数据'), findsNothing);
    expect(find.text('生成虚构数据'), findsNothing);
  });
}

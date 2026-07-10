import 'package:event_tracker/common/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reads chart styling from the ThemeExtension', (tester) async {
    const chartTheme = AppChartTheme(
      titleStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      heatmapColors: {0: Color(0xff123456)},
      timeSlotGradient: LinearGradient(colors: [Color(0xff123456)]),
    );
    late AppChartTheme resolvedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [chartTheme]),
        home: Builder(
          builder: (context) {
            resolvedTheme = AppChartTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolvedTheme.titleStyle.fontSize, 17);
    expect(resolvedTheme.heatmapColors[0], const Color(0xff123456));
    expect(resolvedTheme.timeSlotGradient.colors, [const Color(0xff123456)]);
  });
}

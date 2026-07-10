import 'package:flutter/material.dart';

@immutable
class AppChartTheme extends ThemeExtension<AppChartTheme> {
  const AppChartTheme({
    required this.titleStyle,
    required this.heatmapColors,
    required this.timeSlotGradient,
  });

  static const standard = AppChartTheme(
    titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    heatmapColors: {
      -1: Color.fromARGB(0, 255, 255, 255),
      0: Color.fromARGB(255, 235, 237, 240),
      1: Color.fromARGB(255, 155, 233, 168),
      2: Color.fromARGB(255, 64, 196, 99),
      3: Color.fromARGB(255, 48, 161, 78),
      4: Color.fromARGB(255, 33, 110, 57),
    },
    timeSlotGradient: LinearGradient(
      colors: [
        Color.fromARGB(255, 235, 237, 240),
        Color.fromARGB(255, 155, 233, 168),
        Color.fromARGB(255, 64, 196, 99),
        Color.fromARGB(255, 48, 161, 78),
        Color.fromARGB(255, 33, 110, 57),
      ],
    ),
  );

  final TextStyle titleStyle;
  final Map<int, Color> heatmapColors;
  final LinearGradient timeSlotGradient;

  static AppChartTheme of(BuildContext context) {
    return Theme.of(context).extension<AppChartTheme>() ?? standard;
  }

  @override
  AppChartTheme copyWith({
    TextStyle? titleStyle,
    Map<int, Color>? heatmapColors,
    LinearGradient? timeSlotGradient,
  }) {
    return AppChartTheme(
      titleStyle: titleStyle ?? this.titleStyle,
      heatmapColors: heatmapColors ?? this.heatmapColors,
      timeSlotGradient: timeSlotGradient ?? this.timeSlotGradient,
    );
  }

  @override
  AppChartTheme lerp(covariant ThemeExtension<AppChartTheme>? other, double t) {
    if (other is! AppChartTheme) {
      return this;
    }
    return AppChartTheme(
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t) ?? titleStyle,
      heatmapColors: t < 0.5 ? heatmapColors : other.heatmapColors,
      timeSlotGradient: t < 0.5 ? timeSlotGradient : other.timeSlotGradient,
    );
  }
}

import 'package:event_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Widget localizedTestApp({
  required Widget home,
  Map<String, WidgetBuilder> routes = const {},
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routes: routes,
    home: home,
  );
}

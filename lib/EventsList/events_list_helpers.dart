import 'package:flutter/material.dart';

import '../common/common_widgets.dart';
import '../domain/input_validation.dart';
import '../l10n/app_localizations.dart';

Future<double?> inputValDialog(BuildContext ctx, String unit) async {
  final localizations = AppLocalizations.of(ctx)!;
  final controller = TextEditingController();
  try {
    return await showDialog<double>(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.recordValueTitle),
          content: Row(
            children: [
              Text(localizations.recordValuePrefix),
              Flexible(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: "?"),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                ),
              ),
              Text(unit),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                try {
                  final value = validateRecordValue(
                    double.parse(controller.text),
                    hasUnit: true,
                  );
                  Navigator.of(context).pop(value);
                } catch (err) {
                  showToast(localizations.recordValueInvalid);
                }
              },
              child: Text(localizations.confirm),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

String formatDuration(AppLocalizations localizations, Duration duration) {
  String str = "";
  int hours = 0;
  if (duration.inHours > 0) {
    hours = duration.inHours;
    duration -= Duration(hours: hours);
    str += localizations.durationHours(hours);
  }
  if (duration.inMinutes > 0) {
    int minutes = duration.inMinutes;
    duration -= Duration(minutes: minutes);
    str += localizations.durationMinutes(minutes);
  }
  if (duration.inSeconds > 0) {
    int seconds = duration.inSeconds;
    duration -= Duration(seconds: seconds);
    str += localizations.durationSeconds(seconds);
  }
  return str;
}

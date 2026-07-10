import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            ElevatedButton.icon(
              label: Text(AppLocalizations.of(context)!.unitManagement),
              onPressed: () {
                Navigator.pushNamed(context, 'unitsManager');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              icon: Icon(Icons.edit_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

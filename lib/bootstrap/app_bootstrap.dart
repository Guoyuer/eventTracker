import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../firebase_options.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (usesSqfliteFfiOnPlatform(defaultTargetPlatform)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (supportsFirebaseOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
}

bool supportsFirebaseOnPlatform(TargetPlatform platform,
    {required bool isWeb}) {
  return isWeb ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;
}

bool usesSqfliteFfiOnPlatform(TargetPlatform platform) {
  return platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;
}

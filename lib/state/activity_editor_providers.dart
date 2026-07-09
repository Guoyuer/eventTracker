import 'package:flutter_riverpod/flutter_riverpod.dart';

final activityEditorCareTimeProvider =
    StateProvider.autoDispose<bool>((ref) => true);

final activityEditorSelectedUnitProvider =
    StateProvider.autoDispose<String?>((ref) => null);

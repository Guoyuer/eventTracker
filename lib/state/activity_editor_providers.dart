import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mutable_state.dart';

final activityEditorCareTimeProvider =
    NotifierProvider.autoDispose<MutableState<bool>, bool>(
      () => MutableState(true),
    );

final activityEditorSelectedUnitProvider =
    NotifierProvider.autoDispose<MutableState<String?>, String?>(
      () => MutableState(null),
    );

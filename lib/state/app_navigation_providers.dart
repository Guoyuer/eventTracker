import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mutable_state.dart';

final selectedIndexProvider = NotifierProvider<MutableState<int>, int>(
  () => MutableState(0),
);

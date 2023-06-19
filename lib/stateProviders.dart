import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final eventListScrollDirProvider = StateProvider<ScrollDirection>((ref) => ScrollDirection.forward);

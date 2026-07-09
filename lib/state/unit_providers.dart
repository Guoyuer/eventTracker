import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';

final unitListProvider = FutureProvider<List<ActivityUnit>>((ref) {
  return ref.watch(unitRepositoryProvider).getUnits();
});

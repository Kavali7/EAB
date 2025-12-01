import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/data_service.dart';
import '../core/services/in_memory_data_service.dart';

final dataServiceProvider = Provider<DataService>((ref) {
  // Easily swappable when Supabase sera branche.
  return InMemoryDataService();
});

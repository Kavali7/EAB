import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/data_service.dart';
import '../core/services/in_memory_data_service.dart';
import '../core/services/supabase_data_service.dart';

/// Mode de données actuel
/// - `true` : Utilise Supabase (backend réel)
/// - `false` : Utilise InMemoryDataService (données mock pour développement)
const bool useSupabase = true; // Connecté au backend Supabase

/// Provider du service de données
/// Change automatiquement entre InMemory et Supabase selon [useSupabase]
final dataServiceProvider = Provider<DataService>((ref) {
  if (useSupabase) {
    return SupabaseDataService();
  } else {
    return InMemoryDataService();
  }
});


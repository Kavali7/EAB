/// Providers Riverpod pour le service d'amortissement.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/providers/data_service_provider.dart';
import '../services/amortissement_service.dart';

/// Provider pour le service d'amortissement.
final amortissementServiceProvider = Provider<AmortissementService>((ref) {
  final ds = ref.read(dataServiceProvider) as SupabaseDataService;
  return AmortissementService(ds);
});

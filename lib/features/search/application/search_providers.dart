/// Providers Riverpod pour la recherche globale.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/data_service_provider.dart';
import 'package:eab/core/services/supabase_data_service.dart';
import '../data/search_repository.dart';

/// Repository injecté.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final ds = ref.watch(dataServiceProvider) as SupabaseDataService;
  return SearchRepository(ds);
});

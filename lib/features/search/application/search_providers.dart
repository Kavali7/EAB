/// Providers Riverpod pour la recherche globale.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/data_service_provider.dart';
import '../data/search_repository.dart';

/// Repository injecté.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final ds = ref.watch(dataServiceProvider);
  return SearchRepository(ds);
});

/// Providers Riverpod pour la feature Programmes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/data_service_provider.dart';
import '../../../models/program.dart';
import '../data/programs_repository.dart';

/// Repository injecté via le DataService courant.
final programsRepositoryProvider = Provider<ProgramsRepository>((ref) {
  final ds = ref.watch(dataServiceProvider);
  return ProgramsRepository(ds);
});

/// Liste des programmes avec recherche optionnelle.
final programsListProvider =
    FutureProvider.autoDispose.family<List<Program>, String?>((ref, query) async {
  final repo = ref.watch(programsRepositoryProvider);
  return repo.list(search: query);
});

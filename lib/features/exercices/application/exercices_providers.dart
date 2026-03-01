/// Providers Riverpod pour la feature Exercices Comptables.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/data_service_provider.dart';
import 'package:eab/models/exercice_comptable.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/core/services/supabase_data_service.dart';
import '../data/exercices_repository.dart';

/// Repository injecté via le DataService courant.
final exercicesRepositoryProvider = Provider<ExercicesRepository>((ref) {
  final ds = ref.watch(dataServiceProvider) as SupabaseDataService;
  return ExercicesRepository(ds);
});

/// Liste des exercices (chargée une fois, invalidable).
final exercicesListProvider =
    FutureProvider<List<ExerciceComptable>>((ref) async {
  final repo = ref.watch(exercicesRepositoryProvider);
  return repo.fetchAll();
});

/// Exercice ouvert actuellement (null si aucun).
final exerciceOuvertProvider =
    FutureProvider<ExerciceComptable?>((ref) async {
  final exercices = await ref.watch(exercicesListProvider.future);
  try {
    return exercices.firstWhere(
      (e) => e.statut == StatutExercice.ouvert,
    );
  } catch (_) {
    return null;
  }
});

/// Repository pour la feature Exercices Comptables.
library;

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/models/exercice_comptable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository des exercices — couche d'accès aux données + RPCs.
class ExercicesRepository {
  const ExercicesRepository(this._dataService);
  final SupabaseDataService _dataService;

  SupabaseClient get _sb => _dataService.client;

  /// Récupère tous les exercices de l'organisation courante.
  Future<List<ExerciceComptable>> fetchAll() async {
    final data = await _sb
        .from('exercices_comptables')
        .select()
        .order('annee', ascending: false);
    return data.map((e) => ExerciceComptable.fromJson(e)).toList();
  }

  /// Crée un exercice en brouillon.
  Future<ExerciceComptable> create(ExerciceComptable exercice) async {
    final data = await _sb
        .from('exercices_comptables')
        .insert(exercice.toJson()
          ..remove('id')
          ..remove('created_at')
          ..remove('updated_at'))
        .select()
        .single();
    return ExerciceComptable.fromJson(data);
  }

  /// Ouvre un exercice (brouillon → ouvert). RPC backend.
  Future<void> openExercice(String exerciceId) async {
    await _sb.rpc('open_exercice', params: {'p_exercice_id': exerciceId});
  }

  /// Clôture un exercice (ouvert → clôturé). RPC backend.
  /// Génère automatiquement écriture de résultat + à-nouveaux.
  Future<void> cloturerExercice(String exerciceId) async {
    await _sb.rpc('cloturer_exercice', params: {'p_exercice_id': exerciceId});
  }

  /// Récupère l'exercice ouvert pour une organisation, ou null.
  Future<ExerciceComptable?> getExerciceOuvert(String orgId) async {
    final data = await _sb.rpc(
      'get_exercice_ouvert',
      params: {'p_org_id': orgId},
    );
    if (data == null) return null;
    return ExerciceComptable.fromJson(data as Map<String, dynamic>);
  }

  /// Vérifie si on peut saisir une écriture à la date donnée.
  Future<bool> canPostInExercice(String orgId, DateTime date) async {
    final result = await _sb.rpc(
      'can_post_in_exercice',
      params: {
        'p_org_id': orgId,
        'p_date': date.toIso8601String().substring(0, 10),
      },
    );
    return result == true;
  }

  /// Supprime (soft delete) un exercice.
  Future<void> delete(String exerciceId) async {
    await _sb
        .from('exercices_comptables')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', exerciceId);
  }
}

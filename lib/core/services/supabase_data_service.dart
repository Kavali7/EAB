import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/accounting_entry.dart';
import '../../models/famille.dart';
import '../../models/member.dart';
import '../../models/region_eglise.dart';
import '../../models/district_eglise.dart';
import '../../models/assemblee_locale.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/program.dart';
import '../../models/compte_comptable.dart';
import '../../models/journal_comptable.dart';
import '../../models/centre_analytique.dart';
import '../../models/tiers.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/budget_comptable.dart';
import '../../models/immobilisation_comptable.dart';
import '../../models/releve_bancaire.dart';
import 'data_service.dart';

/// Service de données utilisant Supabase comme backend.
/// Implémente l'interface [DataService] pour permettre le remplacement
/// facile avec InMemoryDataService pendant le développement.
class SupabaseDataService implements DataService {
  SupabaseDataService();

  /// Client Supabase singleton
  SupabaseClient get _client => Supabase.instance.client;

  // ============================================================================
  // STRUCTURE ECCLÉSIASTIQUE
  // ============================================================================

  @override
  Future<List<RegionEglise>> getRegions() async {
    final response = await _client
        .from('regions_eglise')
        .select()
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => RegionEglise.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<DistrictEglise>> getDistricts() async {
    final response = await _client
        .from('districts_eglise')
        .select()
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => DistrictEglise.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<AssembleeLocale>> getAssembleesLocales() async {
    final response = await _client
        .from('assemblees_locales')
        .select()
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => AssembleeLocale.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<Famille>> getFamilies() async {
    final response = await _client
        .from('familles')
        .select()
        .is_('deleted_at', null)
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => Famille.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<ProfilUtilisateur>> getProfilsUtilisateurs() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);

    return (response as List)
        .map((json) => ProfilUtilisateur.fromJson(_snakeToCamel(json)))
        .toList();
  }

  // ============================================================================
  // MEMBRES
  // ============================================================================

  @override
  Future<List<Member>> getMembers() async {
    final response = await _client
        .from('membres')
        .select()
        .is_('deleted_at', null)
        .order('full_name', ascending: true);

    return (response as List)
        .map((json) => Member.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<void> addMember(Member member) async {
    await _client.from('membres').insert(_camelToSnake(member.toJson()));
  }

  @override
  Future<void> updateMember(Member member) async {
    await _client
        .from('membres')
        .update(_camelToSnake(member.toJson()))
        .eq('id', member.id);
  }

  @override
  Future<void> deleteMember(String id) async {
    // Soft delete
    await _client
        .from('membres')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // ============================================================================
  // PROGRAMMES
  // ============================================================================

  @override
  Future<List<Program>> getPrograms() async {
    final response = await _client
        .from('programmes')
        .select()
        .is_('deleted_at', null)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => Program.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<void> addProgram(Program program) async {
    await _client.from('programmes').insert(_camelToSnake(program.toJson()));
  }

  @override
  Future<void> updateProgram(Program program) async {
    await _client
        .from('programmes')
        .update(_camelToSnake(program.toJson()))
        .eq('id', program.id);
  }

  @override
  Future<void> deleteProgram(String id) async {
    // Soft delete
    await _client
        .from('programmes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // ============================================================================
  // COMPTABILITÉ - Entrées simples (pour compatibilité)
  // ============================================================================

  @override
  Future<List<AccountingEntry>> getAccountingEntries() async {
    // Note: Cette méthode est pour compatibilité avec l'ancien système simplifié
    // La vraie comptabilité utilise getEcrituresComptables()
    return [];
  }

  @override
  Future<void> addAccountingEntry(AccountingEntry entry) async {
    // Non implémenté - utiliser addEcritureComptable pour la vraie comptabilité
  }

  @override
  Future<void> updateAccountingEntry(AccountingEntry entry) async {
    // Non implémenté
  }

  @override
  Future<void> deleteAccountingEntry(String id) async {
    // Non implémenté
  }

  // ============================================================================
  // COMPTABILITÉ SYSCEBNL
  // ============================================================================

  @override
  Future<List<CompteComptable>> getComptesComptables() async {
    final response = await _client
        .from('comptes_comptables')
        .select()
        .eq('actif', true)
        .order('numero', ascending: true);

    return (response as List)
        .map((json) => CompteComptable.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<JournalComptable>> getJournauxComptables() async {
    final response = await _client
        .from('journaux_comptables')
        .select()
        .eq('actif', true)
        .order('code', ascending: true);

    return (response as List)
        .map((json) => JournalComptable.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<CentreAnalytique>> getCentresAnalytiques() async {
    final response = await _client
        .from('centres_analytiques')
        .select()
        .eq('actif', true)
        .order('code', ascending: true);

    return (response as List)
        .map((json) => CentreAnalytique.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<Tiers>> getTiers() async {
    final response = await _client
        .from('tiers')
        .select()
        .is_('deleted_at', null)
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => Tiers.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<EcritureComptable>> getEcrituresComptables() async {
    final response = await _client
        .from('ecritures_comptables')
        .select()
        .is_('deleted_at', null)
        .order('date', ascending: false);

    final ecritures = <EcritureComptable>[];

    for (final json in response as List) {
      // Récupérer les lignes pour chaque écriture
      final lignesResponse = await _client
          .from('lignes_ecritures')
          .select()
          .eq('id_ecriture', json['id']);

      final lignes = (lignesResponse as List)
          .map((l) => LigneEcritureComptable.fromJson(_snakeToCamel(l)))
          .toList();

      ecritures.add(EcritureComptable.fromJson({
        ..._snakeToCamel(json),
        'lignes': lignes.map((l) => l.toJson()).toList(),
      }));
    }

    return ecritures;
  }

  @override
  Future<List<BudgetComptable>> getBudgetsComptables() async {
    final response = await _client
        .from('budgets_comptables')
        .select()
        .is_('deleted_at', null)
        .order('exercice', ascending: false);

    return (response as List)
        .map((json) => BudgetComptable.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<LigneBudgetComptable>> getLignesBudgetsComptables() async {
    final response = await _client.from('lignes_budgets').select();

    return (response as List)
        .map((json) => LigneBudgetComptable.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<ImmobilisationComptable>> getImmobilisationsComptables() async {
    final response = await _client
        .from('immobilisations_comptables')
        .select()
        .is_('deleted_at', null)
        .order('libelle', ascending: true);

    return (response as List)
        .map((json) => ImmobilisationComptable.fromJson(_snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<LigneReleveBancaire>> getLignesRelevesBancaires() async {
    // Note: Cette table n'existe pas directement, les relevés sont dans releves_bancaires
    // On retourne une liste vide pour l'instant
    return [];
  }

  // ============================================================================
  // HELPERS - Conversion snake_case <-> camelCase
  // ============================================================================

  /// Convertit les clés d'un Map de snake_case vers camelCase
  Map<String, dynamic> _snakeToCamel(Map<String, dynamic> json) {
    return json.map((key, value) {
      final newKey = _snakeToCamelString(key);
      if (value is Map<String, dynamic>) {
        return MapEntry(newKey, _snakeToCamel(value));
      } else if (value is List) {
        return MapEntry(
          newKey,
          value.map((e) => e is Map<String, dynamic> ? _snakeToCamel(e) : e).toList(),
        );
      }
      return MapEntry(newKey, value);
    });
  }

  /// Convertit les clés d'un Map de camelCase vers snake_case
  Map<String, dynamic> _camelToSnake(Map<String, dynamic> json) {
    return json.map((key, value) {
      final newKey = _camelToSnakeString(key);
      if (value is Map<String, dynamic>) {
        return MapEntry(newKey, _camelToSnake(value));
      } else if (value is List) {
        return MapEntry(
          newKey,
          value.map((e) => e is Map<String, dynamic> ? _camelToSnake(e) : e).toList(),
        );
      }
      return MapEntry(newKey, value);
    });
  }

  /// Convertit une chaîne de snake_case vers camelCase
  String _snakeToCamelString(String input) {
    final parts = input.split('_');
    if (parts.length == 1) return input;

    return parts.first +
        parts.skip(1).map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }

  /// Convertit une chaîne de camelCase vers snake_case
  String _camelToSnakeString(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}

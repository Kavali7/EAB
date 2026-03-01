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
import '../utils/case_converters.dart';
import 'data_service.dart';

/// Service de données utilisant Supabase comme backend.
/// Implémente l'interface [DataService] pour permettre le remplacement
/// facile avec InMemoryDataService pendant le développement.
class SupabaseDataService implements DataService {
  SupabaseDataService();

  SupabaseClient get client => Supabase.instance.client;

  /// Client Supabase singleton (alias privé)
  SupabaseClient get _client => client;

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
        .map((json) => RegionEglise.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<DistrictEglise>> getDistricts() async {
    final response = await _client
        .from('districts_eglise')
        .select()
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => DistrictEglise.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<AssembleeLocale>> getAssembleesLocales() async {
    final response = await _client
        .from('assemblees_locales')
        .select()
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => AssembleeLocale.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<Famille>> getFamilies() async {
    final response = await _client
        .from('familles')
        .select()
        .isFilter('deleted_at', null)
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => Famille.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<ProfilUtilisateur>> getProfilsUtilisateurs() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);

    return (response as List).map((json) {
      final camel = snakeToCamel(json);
      // Map Supabase 'fullName' → model 'nom'
      camel['nom'] = camel['fullName'] ?? camel['nom'] ?? '';
      // Convert role enum snake_case → camelCase
      if (camel['role'] is String) {
        camel['role'] = snakeValueToCamel(camel['role'] as String);
      }
      return ProfilUtilisateur.fromJson(camel);
    }).toList();
  }

  // ============================================================================
  // MEMBRES
  // ============================================================================

  @override
  Future<List<Member>> getMembers() async {
    final response = await _client
        .from('membres')
        .select()
        .isFilter('deleted_at', null)
        .order('full_name', ascending: true);

    return (response as List).map((json) {
      final camel = snakeToCamel(json);
      // Supabase 'fullName' maps directly (model also uses fullName) ✓
      // Synthesize required English fields from French Supabase columns
      camel['birthDate'] = camel['dateNaissance'] ?? camel['birthDate'];
      camel['maritalStatus'] = mapStatutMatrimonialToEnglish(
        camel['statutMatrimonial'] as String?,
      );
      // Convert enum values from snake_case to camelCase
      if (camel['statut'] is String) {
        camel['statut'] = snakeValueToCamel(camel['statut'] as String);
      }
      if (camel['role'] is String) {
        camel['role'] = snakeValueToCamel(camel['role'] as String);
      }
      // Map baptism date
      camel['baptismDate'] = camel['dateBapteme'] ?? camel['baptismDate'];
      return Member.fromJson(camel);
    }).toList();
  }

  @override
  Future<void> addMember(Member member) async {
    await _client.from('membres').insert(camelToSnake(member.toJson()));
  }

  @override
  Future<void> updateMember(Member member) async {
    await _client
        .from('membres')
        .update(camelToSnake(member.toJson()))
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
        .isFilter('deleted_at', null)
        .order('date', ascending: false);

    return (response as List).map((json) {
      final camel = snakeToCamel(json);
      // Convert enum values from snake_case to camelCase
      if (camel['type'] is String) {
        camel['type'] = snakeValueToCamel(camel['type'] as String);
      }
      if (camel['typeVisite'] is String) {
        camel['typeVisite'] = snakeValueToCamel(camel['typeVisite'] as String);
      }
      return Program.fromJson(camel);
    }).toList();
  }

  @override
  Future<void> addProgram(Program program) async {
    await _client.from('programmes').insert(camelToSnake(program.toJson()));
  }

  @override
  Future<void> updateProgram(Program program) async {
    await _client
        .from('programmes')
        .update(camelToSnake(program.toJson()))
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
        .map((json) => CompteComptable.fromJson(snakeToCamel(json)))
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
        .map((json) => JournalComptable.fromJson(snakeToCamel(json)))
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
        .map((json) => CentreAnalytique.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<Tiers>> getTiers() async {
    final response = await _client
        .from('tiers')
        .select()
        .isFilter('deleted_at', null)
        .order('nom', ascending: true);

    return (response as List)
        .map((json) => Tiers.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<EcritureComptable>> getEcrituresComptables() async {
    final response = await _client
        .from('ecritures_comptables')
        .select()
        .isFilter('deleted_at', null)
        .order('date', ascending: false);

    final ecritures = <EcritureComptable>[];

    for (final json in response as List) {
      // Récupérer les lignes pour chaque écriture
      final lignesResponse = await _client
          .from('lignes_ecritures')
          .select()
          .eq('id_ecriture', json['id']);

      final lignes = (lignesResponse as List)
          .map((l) => LigneEcritureComptable.fromJson(snakeToCamel(l)))
          .toList();

      ecritures.add(EcritureComptable.fromJson({
        ...snakeToCamel(json),
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
        .isFilter('deleted_at', null)
        .order('exercice', ascending: false);

    return (response as List)
        .map((json) => BudgetComptable.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<LigneBudgetComptable>> getLignesBudgetsComptables() async {
    final response = await _client.from('lignes_budgets').select();

    return (response as List)
        .map((json) => LigneBudgetComptable.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<ImmobilisationComptable>> getImmobilisationsComptables() async {
    final response = await _client
        .from('immobilisations_comptables')
        .select()
        .isFilter('deleted_at', null)
        .order('libelle', ascending: true);

    return (response as List)
        .map((json) => ImmobilisationComptable.fromJson(snakeToCamel(json)))
        .toList();
  }

  @override
  Future<List<LigneReleveBancaire>> getLignesRelevesBancaires() async {
    // Note: Cette table n'existe pas directement, les relevés sont dans releves_bancaires
    // On retourne une liste vide pour l'instant
    return [];
  }

}

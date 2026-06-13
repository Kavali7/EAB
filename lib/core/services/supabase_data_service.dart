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
    final data = _memberToDbJson(member);
    data['organization_id'] = await _currentOrganizationId();
    await _client.from('membres').insert(data);
  }

  @override
  Future<void> updateMember(Member member) async {
    await _client
        .from('membres')
        .update(_memberToDbJson(member))
        .eq('id', member.id);
  }

  /// Convertit un Member en JSON compatible avec la table `membres`.
  Map<String, dynamic> _memberToDbJson(Member member) {
    final data = <String, dynamic>{
      'id': member.id,
      'full_name': member.fullName,
      'gender': member.gender.name,
      'date_naissance': (member.dateNaissance ?? member.birthDate)
          .toIso8601String(),
      'statut_matrimonial': member.statutMatrimonial?.name ?? 'celibataire',
      'phone': member.phone,
      'email': member.email,
      'address': member.address,
      'date_conversion': member.dateConversion?.toIso8601String(),
      'date_bapteme': member.dateBapteme?.toIso8601String(),
      'date_main_association': member.dateMainAssociation?.toIso8601String(),
      'statut': member.statut.name,
      'role': camelValueToSnake(member.role.name),
      'vulnerabilites': member.vulnerabilites
          .map((v) => camelValueToSnake(v.name))
          .toList(),
      'id_famille': member.idFamille,
      'id_assemblee_locale': member.idAssembleeLocale,
      'church_unit_id': member.churchUnitId,
    };
    data.removeWhere(
      (key, value) =>
          value == null &&
          key != 'id_famille' &&
          key != 'id_assemblee_locale' &&
          key != 'church_unit_id',
    );
    return data;
  }

  Future<String?> _currentOrganizationId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final profile = await _client
        .from('profiles')
        .select('organization_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['organization_id'] as String?;
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
    await _client.from('programmes').insert(_programToDbJson(program));
  }

  @override
  Future<void> updateProgram(Program program) async {
    await _client
        .from('programmes')
        .update(_programToDbJson(program))
        .eq('id', program.id);
  }

  /// Convertit un Program en JSON compatible avec la table `programmes`.
  Map<String, dynamic> _programToDbJson(Program program) {
    final data = <String, dynamic>{
      'id': program.id,
      'type': camelValueToSnake(program.type.name),
      'date': program.date.toIso8601String(),
      'location': program.location,
      'id_assemblee_locale': program.idAssembleeLocale,
      'description': program.description,
      'observations': program.observations,
      'participant_ids': program.participantIds,
      'type_visite': program.typeVisite != null
          ? camelValueToSnake(program.typeVisite!.name)
          : null,
      'nombre_hommes': program.nombreHommes,
      'nombre_femmes': program.nombreFemmes,
      'nombre_garcons': program.nombreGarcons,
      'nombre_filles': program.nombreFilles,
      'conversions_hommes': program.conversionsHommes,
      'conversions_femmes': program.conversionsFemmes,
      'conversions_garcons': program.conversionsGarcons,
      'conversions_filles': program.conversionsFilles,
      'nombre_classes_ecole_du_dimanche': program.nombreClassesEcoleDuDimanche,
      'nombre_moniteurs_hommes': program.nombreMoniteursHommes,
      'nombre_monitrices_femmes': program.nombreMonitricesFemmes,
      'derniere_lecon_ecole_du_dimanche': program.derniereLeconEcoleDuDimanche,
      'compte_rendu_visite': program.compteRenduVisite,
    };
    data.removeWhere((_, v) => v == null);
    return data;
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

      ecritures.add(
        EcritureComptable.fromJson({
          ...snakeToCamel(json),
          'lignes': lignes.map((l) => l.toJson()).toList(),
        }),
      );
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

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eab/core/services/supabase_data_service.dart';

import 'operational_finance_models.dart';

class OperationalFinanceRepository {
  OperationalFinanceRepository(this._dataService);

  final SupabaseDataService _dataService;

  SupabaseClient get _client => _dataService.client;

  Future<OperationalFinanceState> fetchState() async {
    try {
      final responses = await Future.wait([
        _client
            .from('v_campagnes_financieres_resume')
            .select()
            .order('updated_at', ascending: false),
        _client
            .from('promesses_financieres')
            .select()
            .order('date_promesse', ascending: false),
        _client
            .from('mouvements_financiers')
            .select()
            .order('date_mouvement', ascending: false),
      ]);

      return OperationalFinanceState(
        campaigns: (responses[0] as List)
            .map(
              (json) => FinancialCampaignSummary.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList(),
        pledges: (responses[1] as List)
            .map((json) => FinancialPledge.fromJson(json as Map<String, dynamic>))
            .toList(),
        movements: (responses[2] as List)
            .map(
              (json) => FinancialMovement.fromJson(json as Map<String, dynamic>),
            )
            .toList(),
      );
    } on PostgrestException catch (e) {
      if (_isMissingSchema(e)) {
        return const OperationalFinanceState(
          campaigns: [],
          pledges: [],
          movements: [],
        );
      }
      rethrow;
    }
  }

  Future<void> createCampaign({
    required String churchUnitId,
    required String titre,
    required String type,
    required DateTime dateDebut,
    String? programmeId,
    String? description,
    double? objectifMontant,
    DateTime? dateFin,
    String? periodicite,
  }) async {
    final profile = await _profileContext();
    await _client.from('campagnes_financieres').insert({
      'organization_id': profile.organizationId,
      'church_unit_id': churchUnitId,
      'programme_id': _blankToNull(programmeId),
      'titre': titre.trim(),
      'type': type,
      'description': _blankToNull(description),
      'objectif_montant': objectifMontant,
      'date_debut': _dateOnly(dateDebut),
      'date_fin': dateFin == null ? null : _dateOnly(dateFin),
      'periodicite': _blankToNull(periodicite),
      'statut': 'active',
      'allow_partial_payments': true,
      'created_by': profile.profileId,
    });
  }

  Future<void> createPledge({
    required String campagneId,
    required String churchUnitId,
    required double montantPromis,
    required DateTime datePromesse,
    String? membreId,
    String? tiersId,
    String? contributeurNom,
    DateTime? dateEcheance,
    String? notes,
  }) async {
    final profile = await _profileContext();
    await _client.from('promesses_financieres').insert({
      'organization_id': profile.organizationId,
      'campagne_id': campagneId,
      'church_unit_id': churchUnitId,
      'membre_id': _blankToNull(membreId),
      'tiers_id': _blankToNull(tiersId),
      'contributeur_nom': _blankToNull(contributeurNom),
      'montant_promis': montantPromis,
      'date_promesse': _dateOnly(datePromesse),
      'date_echeance': dateEcheance == null ? null : _dateOnly(dateEcheance),
      'notes': _blankToNull(notes),
      'created_by': profile.profileId,
    });
  }

  Future<void> createMovement({
    required String churchUnitId,
    required String financialAccountId,
    required String type,
    required double montant,
    required DateTime dateMouvement,
    required String libelle,
    String? campagneId,
    String? programmeId,
    String? promesseId,
    String? membreId,
    String? tiersId,
    String? contributeurNom,
    String? modePaiement,
    String? referenceExterne,
  }) async {
    final profile = await _profileContext();
    await _client.from('mouvements_financiers').insert({
      'organization_id': profile.organizationId,
      'church_unit_id': churchUnitId,
      'financial_account_id': financialAccountId,
      'campagne_id': _blankToNull(campagneId),
      'programme_id': _blankToNull(programmeId),
      'promesse_id': _blankToNull(promesseId),
      'membre_id': _blankToNull(membreId),
      'tiers_id': _blankToNull(tiersId),
      'contributeur_nom': _blankToNull(contributeurNom),
      'type': type,
      'montant': montant,
      'date_mouvement': _dateOnly(dateMouvement),
      'libelle': libelle.trim(),
      'mode_paiement': _blankToNull(modePaiement),
      'reference_externe': _blankToNull(referenceExterne),
      'statut': 'soumis',
      'created_by': profile.profileId,
      'submitted_by': profile.profileId,
    });
  }

  Future<void> closeCampaign(String campaignId) async {
    final profile = await _profileContext();
    await _client
        .from('campagnes_financieres')
        .update({
          'statut': 'cloturee',
          'closed_by': profile.profileId,
          'closed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', campaignId);
  }

  Future<void> validateMovementAsAccountingEntry({
    required String movementId,
    required String movementType,
    required String churchUnitId,
    required String journalId,
    required String treasuryAccountId,
    required String counterpartAccountId,
    required DateTime date,
    required String libelle,
    required double montant,
    String? referencePiece,
    String? modePaiement,
    String? centreAnalytiqueId,
    String? tiersId,
  }) async {
    final profile = await _profileContext();
    String? entryId;
    try {
      final entry = await _client
          .from('ecritures_comptables')
          .insert({
            'organization_id': profile.organizationId,
            'church_unit_id': churchUnitId,
            'id_journal': journalId,
            'id_centre_analytique_principal': _blankToNull(centreAnalytiqueId),
            'date': _dateOnly(date),
            'reference_piece': _blankToNull(referencePiece),
            'libelle': libelle.trim(),
            'statut': 'validee',
            'created_by': profile.profileId,
            'validated_by': profile.profileId,
            'validated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      entryId = entry['id'] as String;
      final isOut = movementType == 'decaissement';
      final lineLibelle = libelle.trim();
      final cleanMode = _blankToNull(modePaiement);
      final cleanCentre = _blankToNull(centreAnalytiqueId);
      final cleanTiers = _blankToNull(tiersId);

      await _client.from('lignes_ecritures').insert([
        {
          'id_ecriture': entryId,
          'id_compte_comptable': isOut
              ? counterpartAccountId
              : treasuryAccountId,
          'id_centre_analytique': cleanCentre,
          'id_tiers': cleanTiers,
          'libelle': lineLibelle,
          'debit': montant,
          'credit': 0,
          'mode_paiement': cleanMode,
        },
        {
          'id_ecriture': entryId,
          'id_compte_comptable': isOut
              ? treasuryAccountId
              : counterpartAccountId,
          'id_centre_analytique': cleanCentre,
          'id_tiers': cleanTiers,
          'libelle': lineLibelle,
          'debit': 0,
          'credit': montant,
          'mode_paiement': cleanMode,
        },
      ]);

      await _client
          .from('mouvements_financiers')
          .update({
            'statut': 'valide',
            'validated_by': profile.profileId,
            'validated_at': DateTime.now().toIso8601String(),
            'ecriture_id': entryId,
          })
          .eq('id', movementId);
    } catch (_) {
      if (entryId != null) {
        await _client
            .from('ecritures_comptables')
            .delete()
            .eq('id', entryId);
      }
      rethrow;
    }
  }

  Future<void> rejectMovement({
    required String movementId,
    required String reason,
  }) async {
    final profile = await _profileContext();
    await _client
        .from('mouvements_financiers')
        .update({
          'statut': 'rejete',
          'rejet_motif': reason.trim(),
          'validated_by': profile.profileId,
          'validated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', movementId);
  }

  Future<ProfileContext> _profileContext() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Utilisateur non connecte.');
    }
    final row = await _client
        .from('profiles')
        .select('id, organization_id')
        .eq('id', uid)
        .maybeSingle();
    final organizationId = row?['organization_id'] as String?;
    if (organizationId == null || organizationId.isEmpty) {
      throw StateError('Organisation utilisateur introuvable.');
    }
    return ProfileContext(profileId: uid, organizationId: organizationId);
  }

  bool _isMissingSchema(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == '42P01' ||
        message.contains('campagnes_financieres') ||
        message.contains('promesses_financieres') ||
        message.contains('mouvements_financiers') ||
        message.contains('v_campagnes_financieres_resume');
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String? _blankToNull(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }
}

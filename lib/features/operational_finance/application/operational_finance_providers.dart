import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/providers/data_service_provider.dart';

import '../data/operational_finance_models.dart';
import '../data/operational_finance_repository.dart';

final operationalFinanceRepositoryProvider =
    Provider<OperationalFinanceRepository?>((ref) {
      final dataService = ref.read(dataServiceProvider);
      if (dataService is! SupabaseDataService) return null;
      return OperationalFinanceRepository(dataService);
    });

final operationalFinanceProvider = AsyncNotifierProvider<
  OperationalFinanceNotifier,
  OperationalFinanceState
>(OperationalFinanceNotifier.new);

class OperationalFinanceNotifier
    extends AsyncNotifier<OperationalFinanceState> {
  @override
  Future<OperationalFinanceState> build() async {
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) {
      return const OperationalFinanceState(
        campaigns: [],
        pledges: [],
        movements: [],
      );
    }
    return repository.fetchState();
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
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) return;
    await repository.createCampaign(
      churchUnitId: churchUnitId,
      titre: titre,
      type: type,
      dateDebut: dateDebut,
      programmeId: programmeId,
      description: description,
      objectifMontant: objectifMontant,
      dateFin: dateFin,
      periodicite: periodicite,
    );
    ref.invalidateSelf();
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
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) return;
    await repository.createPledge(
      campagneId: campagneId,
      churchUnitId: churchUnitId,
      montantPromis: montantPromis,
      datePromesse: datePromesse,
      membreId: membreId,
      tiersId: tiersId,
      contributeurNom: contributeurNom,
      dateEcheance: dateEcheance,
      notes: notes,
    );
    ref.invalidateSelf();
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
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) return;
    await repository.createMovement(
      churchUnitId: churchUnitId,
      financialAccountId: financialAccountId,
      type: type,
      montant: montant,
      dateMouvement: dateMouvement,
      libelle: libelle,
      campagneId: campagneId,
      programmeId: programmeId,
      promesseId: promesseId,
      membreId: membreId,
      tiersId: tiersId,
      contributeurNom: contributeurNom,
      modePaiement: modePaiement,
      referenceExterne: referenceExterne,
    );
    ref.invalidateSelf();
  }

  Future<void> closeCampaign(String campaignId) async {
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) return;
    await repository.closeCampaign(campaignId);
    ref.invalidateSelf();
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
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) return;
    await repository.validateMovementAsAccountingEntry(
      movementId: movementId,
      movementType: movementType,
      churchUnitId: churchUnitId,
      journalId: journalId,
      treasuryAccountId: treasuryAccountId,
      counterpartAccountId: counterpartAccountId,
      date: date,
      libelle: libelle,
      montant: montant,
      referencePiece: referencePiece,
      modePaiement: modePaiement,
      centreAnalytiqueId: centreAnalytiqueId,
      tiersId: tiersId,
    );
    ref.invalidateSelf();
  }

  Future<void> rejectMovement({
    required String movementId,
    required String reason,
  }) async {
    final repository = ref.read(operationalFinanceRepositoryProvider);
    if (repository == null) return;
    await repository.rejectMovement(movementId: movementId, reason: reason);
    ref.invalidateSelf();
  }
}

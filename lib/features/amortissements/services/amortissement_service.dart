/// Service d'amortissement des immobilisations.
///
/// Génère le tableau d'amortissement linéaire année par année
/// et crée les écritures comptables de dotation.
library;

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/models/immobilisation_comptable.dart';

/// Ligne du tableau d'amortissement.
class LigneAmortissement {
  const LigneAmortissement({
    required this.annee,
    required this.baseAmortissable,
    required this.dotation,
    required this.amortissementCumule,
    required this.valeurNetteComptable,
    required this.estGenere,
  });

  final int annee;
  final double baseAmortissable;
  final double dotation;
  final double amortissementCumule;
  final double valeurNetteComptable;

  /// true si une écriture a déjà été générée pour cette année.
  final bool estGenere;
}

/// Service de calcul et génération des amortissements.
class AmortissementService {
  AmortissementService(this._dataService);

  final SupabaseDataService _dataService;

  /// Calcule le tableau d'amortissement complet (méthode linéaire).
  List<LigneAmortissement> calculerTableau(ImmobilisationComptable immo) {
    final baseAmortissable = (immo.valeurAcquisition - (immo.valeurResiduelle ?? 0))
        .clamp(0.0, double.maxFinite);
    final duree = immo.dureeUtiliteEnAnnees;
    if (duree <= 0 || baseAmortissable <= 0) return [];

    final dotationAnnuelle = baseAmortissable / duree;
    final anneeDebut = immo.dateAcquisition.year;
    final lignes = <LigneAmortissement>[];
    double cumul = 0;

    for (int i = 0; i < duree; i++) {
      final annee = anneeDebut + i;
      // Dernière année : ajuster pour ne pas dépasser la base
      final dotation = (i == duree - 1)
          ? baseAmortissable - cumul
          : dotationAnnuelle;
      cumul += dotation;
      final vnc = immo.valeurAcquisition - cumul;

      lignes.add(LigneAmortissement(
        annee: annee,
        baseAmortissable: baseAmortissable,
        dotation: dotation,
        amortissementCumule: cumul,
        valeurNetteComptable: vnc < 0 ? 0 : vnc,
        estGenere: false, // À vérifier via la DB
      ));
    }
    return lignes;
  }

  /// Génère l'écriture de dotation pour une année donnée.
  ///
  /// Débit : compte de dotation (68x)
  /// Crédit : compte d'amortissement (28x)
  Future<void> genererEcritureDotation({
    required ImmobilisationComptable immo,
    required int annee,
    required double montant,
    required String orgId,
    required String journalId,
  }) async {
    if (immo.idCompteDotation == null || immo.idCompteAmortissement == null) {
      throw Exception(
        'Comptes de dotation et d\'amortissement requis pour générer l\'écriture.',
      );
    }

    // Créer l'écriture avec 2 lignes
    final ecritureData = {
      'organization_id': orgId,
      'date_ecriture': '$annee-12-31',
      'libelle': 'Dotation amortissement ${immo.libelle} — $annee',
      'reference_piece': 'AMORT-${immo.id.substring(0, 8)}-$annee',
      'id_journal': journalId,
      'statut': 'brouillon',
    };

    // Insert écriture
    final result = await _dataService.client
        .from('ecritures_comptables')
        .insert(ecritureData)
        .select('id')
        .single();

    final ecritureId = result['id'] as String;

    // Insert 2 lignes
    await _dataService.client.from('lignes_ecritures').insert([
      {
        'id_ecriture': ecritureId,
        'id_compte': immo.idCompteDotation,
        'libelle': 'Dotation amortissement ${immo.libelle}',
        'debit': montant,
        'credit': 0,
      },
      {
        'id_ecriture': ecritureId,
        'id_compte': immo.idCompteAmortissement,
        'libelle': 'Amortissement ${immo.libelle}',
        'debit': 0,
        'credit': montant,
      },
    ]);
  }

  /// Génère les écritures de dotation pour toutes les immos actives.
  Future<int> genererDotationsAnnuelles({
    required String orgId,
    required int annee,
    required String journalId,
    required List<ImmobilisationComptable> immobilisations,
  }) async {
    int count = 0;
    for (final immo in immobilisations) {
      if (immo.estSortie) continue;
      if (immo.idCompteDotation == null || immo.idCompteAmortissement == null) {
        continue;
      }

      final tableau = calculerTableau(immo);
      final ligne = tableau.where((l) => l.annee == annee).firstOrNull;
      if (ligne == null || ligne.dotation <= 0) continue;

      await genererEcritureDotation(
        immo: immo,
        annee: annee,
        montant: ligne.dotation,
        orgId: orgId,
        journalId: journalId,
      );
      count++;
    }
    return count;
  }
}

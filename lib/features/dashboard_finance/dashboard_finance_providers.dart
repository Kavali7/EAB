/// Dashboard financier — données + providers.
///
/// Modèles pour les 3 RPCs : KPIs, évolution mensuelle, répartition.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/providers/data_service_provider.dart';

// ══════════════════════════════════════════════════════════════
// MODÈLES
// ══════════════════════════════════════════════════════════════

class FinanceKpis {
  const FinanceKpis({
    required this.tresorerieActuelle,
    required this.resultatMois,
    required this.totalProduits,
    required this.totalCharges,
    required this.resultatMoisPrecedent,
    required this.nbEcrituresMois,
  });

  final double tresorerieActuelle;
  final double resultatMois;
  final double totalProduits;
  final double totalCharges;
  final double resultatMoisPrecedent;
  final int nbEcrituresMois;

  /// Variation en % par rapport au mois précédent.
  double get variation {
    if (resultatMoisPrecedent == 0) return 0;
    return ((resultatMois - resultatMoisPrecedent) / resultatMoisPrecedent.abs()) * 100;
  }

  factory FinanceKpis.fromJson(Map<String, dynamic> json) => FinanceKpis(
        tresorerieActuelle: (json['tresorerie_actuelle'] as num?)?.toDouble() ?? 0,
        resultatMois: (json['resultat_exercice'] as num?)?.toDouble() ?? 0,
        totalProduits: (json['total_produits'] as num?)?.toDouble() ?? 0,
        totalCharges: (json['total_charges'] as num?)?.toDouble() ?? 0,
        resultatMoisPrecedent: (json['resultat_mois_precedent'] as num?)?.toDouble() ?? 0,
        nbEcrituresMois: (json['nb_ecritures_mois'] as num?)?.toInt() ?? 0,
      );

  factory FinanceKpis.empty() => const FinanceKpis(
        tresorerieActuelle: 0,
        resultatMois: 0,
        totalProduits: 0,
        totalCharges: 0,
        resultatMoisPrecedent: 0,
        nbEcrituresMois: 0,
      );
}

class EvolutionMensuelle {
  const EvolutionMensuelle({
    required this.mois,
    required this.labelMois,
    required this.produits,
    required this.charges,
    required this.soldeNet,
  });

  final DateTime mois;
  final String labelMois;
  final double produits;
  final double charges;
  final double soldeNet;

  factory EvolutionMensuelle.fromJson(Map<String, dynamic> json) => EvolutionMensuelle(
        mois: DateTime.parse(json['mois'] as String),
        labelMois: json['label_mois'] as String? ?? '',
        produits: (json['produits'] as num?)?.toDouble() ?? 0,
        charges: (json['charges'] as num?)?.toDouble() ?? 0,
        soldeNet: (json['solde_net'] as num?)?.toDouble() ?? 0,
      );
}

class RepartitionCategorie {
  const RepartitionCategorie({
    required this.section,
    required this.compteNumero,
    required this.compteIntitule,
    required this.montant,
    required this.pourcentage,
  });

  final String section;
  final String compteNumero;
  final String compteIntitule;
  final double montant;
  final double pourcentage;

  factory RepartitionCategorie.fromJson(Map<String, dynamic> json) => RepartitionCategorie(
        section: json['section'] as String? ?? '',
        compteNumero: json['compte_numero'] as String? ?? '',
        compteIntitule: json['compte_intitule'] as String? ?? '',
        montant: (json['montant'] as num?)?.toDouble() ?? 0,
        pourcentage: (json['pourcentage'] as num?)?.toDouble() ?? 0,
      );
}

// ══════════════════════════════════════════════════════════════
// REPOSITORY
// ══════════════════════════════════════════════════════════════

class DashboardFinanceRepository {
  DashboardFinanceRepository(this._ds);

  final SupabaseDataService _ds;

  Future<FinanceKpis> fetchKpis(String orgId) async {
    final result = await _ds.client.rpc(
      'dashboard_finance_kpis',
      params: {'p_org_id': orgId},
    );
    if (result is List && result.isNotEmpty) {
      return FinanceKpis.fromJson(result.first as Map<String, dynamic>);
    }
    return FinanceKpis.empty();
  }

  Future<List<EvolutionMensuelle>> fetchEvolution(String orgId, {int nbMois = 12}) async {
    final result = await _ds.client.rpc(
      'dashboard_finance_evolution',
      params: {'p_org_id': orgId, 'p_nb_mois': nbMois},
    );
    return (result as List).map((j) => EvolutionMensuelle.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<RepartitionCategorie>> fetchRepartition(String orgId) async {
    final result = await _ds.client.rpc(
      'dashboard_finance_repartition',
      params: {'p_org_id': orgId},
    );
    return (result as List).map((j) => RepartitionCategorie.fromJson(j as Map<String, dynamic>)).toList();
  }
}

// ══════════════════════════════════════════════════════════════
// PROVIDERS
// ══════════════════════════════════════════════════════════════

final dashboardFinanceRepoProvider = Provider<DashboardFinanceRepository>((ref) {
  final ds = ref.read(dataServiceProvider) as SupabaseDataService;
  return DashboardFinanceRepository(ds);
});

final financeKpisProvider = FutureProvider.family<FinanceKpis, String>((ref, orgId) {
  return ref.read(dashboardFinanceRepoProvider).fetchKpis(orgId);
});

final financeEvolutionProvider = FutureProvider.family<List<EvolutionMensuelle>, String>((ref, orgId) {
  return ref.read(dashboardFinanceRepoProvider).fetchEvolution(orgId);
});

final financeRepartitionProvider = FutureProvider.family<List<RepartitionCategorie>, String>((ref, orgId) {
  return ref.read(dashboardFinanceRepoProvider).fetchRepartition(orgId);
});

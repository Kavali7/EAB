/// Repository pour les états financiers SYCEBNL.
///
/// Appelle les RPCs : report_balance_generale, report_compte_resultat,
/// report_bilan, report_grand_livre.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eab/core/services/supabase_data_service.dart';

/// Ligne de la balance générale.
class LigneBalance {
  final String compteId;
  final String numero;
  final String intitule;
  final String nature;
  final int niveau;
  final double totalDebit;
  final double totalCredit;
  final double soldeDebiteur;
  final double soldeCrediteur;

  const LigneBalance({
    required this.compteId,
    required this.numero,
    required this.intitule,
    required this.nature,
    required this.niveau,
    required this.totalDebit,
    required this.totalCredit,
    required this.soldeDebiteur,
    required this.soldeCrediteur,
  });

  factory LigneBalance.fromJson(Map<String, dynamic> j) => LigneBalance(
        compteId: j['compte_id'] ?? '',
        numero: j['numero'] ?? '',
        intitule: j['intitule'] ?? '',
        nature: j['nature'] ?? '',
        niveau: j['niveau'] ?? 1,
        totalDebit: (j['total_debit'] as num?)?.toDouble() ?? 0,
        totalCredit: (j['total_credit'] as num?)?.toDouble() ?? 0,
        soldeDebiteur: (j['solde_debiteur'] as num?)?.toDouble() ?? 0,
        soldeCrediteur: (j['solde_crediteur'] as num?)?.toDouble() ?? 0,
      );
}

/// Ligne du compte de résultat.
class LigneResultat {
  final String section; // 'produits' ou 'charges'
  final String numero;
  final String intitule;
  final double montant;

  const LigneResultat({
    required this.section,
    required this.numero,
    required this.intitule,
    required this.montant,
  });

  factory LigneResultat.fromJson(Map<String, dynamic> j) => LigneResultat(
        section: j['section'] ?? '',
        numero: j['numero'] ?? '',
        intitule: j['intitule'] ?? '',
        montant: (j['montant'] as num?)?.toDouble() ?? 0,
      );
}

/// Ligne du bilan.
class LigneBilan {
  final String section; // 'actif' ou 'passif'
  final String sousSection; // 'immobilisations', 'circulant', 'fonds_propres', 'dettes'
  final String numero;
  final String intitule;
  final double solde;

  const LigneBilan({
    required this.section,
    required this.sousSection,
    required this.numero,
    required this.intitule,
    required this.solde,
  });

  factory LigneBilan.fromJson(Map<String, dynamic> j) => LigneBilan(
        section: j['section'] ?? '',
        sousSection: j['sous_section'] ?? '',
        numero: j['numero'] ?? '',
        intitule: j['intitule'] ?? '',
        solde: (j['solde'] as num?)?.toDouble() ?? 0,
      );
}

/// Ligne du grand livre.
class LigneGrandLivre {
  final String compteNumero;
  final String compteIntitule;
  final DateTime ecritureDate;
  final String ecritureLibelle;
  final String? referencePiece;
  final String journalCode;
  final String? ligneLibelle;
  final double debit;
  final double credit;
  final double soldeCumule;

  const LigneGrandLivre({
    required this.compteNumero,
    required this.compteIntitule,
    required this.ecritureDate,
    required this.ecritureLibelle,
    this.referencePiece,
    required this.journalCode,
    this.ligneLibelle,
    required this.debit,
    required this.credit,
    required this.soldeCumule,
  });

  factory LigneGrandLivre.fromJson(Map<String, dynamic> j) => LigneGrandLivre(
        compteNumero: j['compte_numero'] ?? '',
        compteIntitule: j['compte_intitule'] ?? '',
        ecritureDate: DateTime.parse(j['ecriture_date']),
        ecritureLibelle: j['ecriture_libelle'] ?? '',
        referencePiece: j['reference_piece'],
        journalCode: j['journal_code'] ?? '',
        ligneLibelle: j['ligne_libelle'],
        debit: (j['debit'] as num?)?.toDouble() ?? 0,
        credit: (j['credit'] as num?)?.toDouble() ?? 0,
        soldeCumule: (j['solde_cumule'] as num?)?.toDouble() ?? 0,
      );
}

/// Repository des états financiers.
class ReportsRepository {
  const ReportsRepository(this._dataService);
  final SupabaseDataService _dataService;

  SupabaseClient get _sb => _dataService.client;

  Future<List<LigneBalance>> fetchBalanceGenerale(
    String orgId, {
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final data = await _sb.rpc('report_balance_generale', params: {
      'p_org_id': orgId,
      if (dateDebut != null)
        'p_date_debut': dateDebut.toIso8601String().substring(0, 10),
      if (dateFin != null)
        'p_date_fin': dateFin.toIso8601String().substring(0, 10),
    });
    return (data as List).map((e) => LigneBalance.fromJson(e)).toList();
  }

  Future<List<LigneResultat>> fetchCompteResultat(
    String orgId, {
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final data = await _sb.rpc('report_compte_resultat', params: {
      'p_org_id': orgId,
      if (dateDebut != null)
        'p_date_debut': dateDebut.toIso8601String().substring(0, 10),
      if (dateFin != null)
        'p_date_fin': dateFin.toIso8601String().substring(0, 10),
    });
    return (data as List).map((e) => LigneResultat.fromJson(e)).toList();
  }

  Future<List<LigneBilan>> fetchBilan(
    String orgId, {
    DateTime? dateFin,
  }) async {
    final data = await _sb.rpc('report_bilan', params: {
      'p_org_id': orgId,
      if (dateFin != null)
        'p_date_fin': dateFin.toIso8601String().substring(0, 10),
    });
    return (data as List).map((e) => LigneBilan.fromJson(e)).toList();
  }

  Future<List<LigneGrandLivre>> fetchGrandLivre(
    String orgId, {
    String? compteId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final data = await _sb.rpc('report_grand_livre', params: {
      'p_org_id': orgId,
      if (compteId != null) 'p_compte_id': compteId,
      if (dateDebut != null)
        'p_date_debut': dateDebut.toIso8601String().substring(0, 10),
      if (dateFin != null)
        'p_date_fin': dateFin.toIso8601String().substring(0, 10),
    });
    return (data as List).map((e) => LigneGrandLivre.fromJson(e)).toList();
  }
}

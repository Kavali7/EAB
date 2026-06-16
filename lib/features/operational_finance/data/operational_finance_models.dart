class FinancialCampaignSummary {
  const FinancialCampaignSummary({
    required this.id,
    required this.organizationId,
    required this.churchUnitId,
    required this.titre,
    required this.type,
    required this.statut,
    required this.montantPromis,
    required this.montantEncaisse,
    required this.montantValide,
    required this.dateDebut,
    required this.createdAt,
    required this.updatedAt,
    this.programmeId,
    this.objectifMontant,
    this.resteSurPromesses,
    this.resteSurObjectif,
    this.dateFin,
  });

  final String id;
  final String organizationId;
  final String churchUnitId;
  final String? programmeId;
  final String titre;
  final String type;
  final String statut;
  final double? objectifMontant;
  final double montantPromis;
  final double montantEncaisse;
  final double montantValide;
  final double? resteSurPromesses;
  final double? resteSurObjectif;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get tauxObjectif {
    final objectif = objectifMontant ?? 0;
    if (objectif <= 0) return 0;
    return (montantEncaisse / objectif).clamp(0, 1).toDouble();
  }

  factory FinancialCampaignSummary.fromJson(Map<String, dynamic> json) {
    return FinancialCampaignSummary(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      churchUnitId: json['church_unit_id'] as String? ?? '',
      programmeId: json['programme_id'] as String?,
      titre: json['titre'] as String? ?? 'Campagne financiere',
      type: json['type'] as String? ?? 'cotisation',
      statut: json['statut'] as String? ?? 'brouillon',
      objectifMontant: _doubleOrNull(json['objectif_montant']),
      montantPromis: _doubleValue(json['montant_promis']),
      montantEncaisse: _doubleValue(json['montant_encaisse']),
      montantValide: _doubleValue(json['montant_valide']),
      resteSurPromesses: _doubleOrNull(json['reste_sur_promesses']),
      resteSurObjectif: _doubleOrNull(json['reste_sur_objectif']),
      dateDebut: _dateValue(json['date_debut']),
      dateFin: _dateOrNull(json['date_fin']),
      createdAt: _dateValue(json['created_at']),
      updatedAt: _dateValue(json['updated_at']),
    );
  }
}

class FinancialPledge {
  const FinancialPledge({
    required this.id,
    required this.organizationId,
    required this.campagneId,
    required this.churchUnitId,
    required this.montantPromis,
    required this.datePromesse,
    required this.statut,
    required this.createdAt,
    required this.updatedAt,
    this.membreId,
    this.tiersId,
    this.contributeurNom,
    this.dateEcheance,
    this.notes,
  });

  final String id;
  final String organizationId;
  final String campagneId;
  final String churchUnitId;
  final String? membreId;
  final String? tiersId;
  final String? contributeurNom;
  final double montantPromis;
  final DateTime datePromesse;
  final DateTime? dateEcheance;
  final String statut;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinancialPledge.fromJson(Map<String, dynamic> json) {
    return FinancialPledge(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      campagneId: json['campagne_id'] as String? ?? '',
      churchUnitId: json['church_unit_id'] as String? ?? '',
      membreId: json['membre_id'] as String?,
      tiersId: json['tiers_id'] as String?,
      contributeurNom: json['contributeur_nom'] as String?,
      montantPromis: _doubleValue(json['montant_promis']),
      datePromesse: _dateValue(json['date_promesse']),
      dateEcheance: _dateOrNull(json['date_echeance']),
      statut: json['statut'] as String? ?? 'ouverte',
      notes: json['notes'] as String?,
      createdAt: _dateValue(json['created_at']),
      updatedAt: _dateValue(json['updated_at']),
    );
  }
}

class FinancialMovement {
  const FinancialMovement({
    required this.id,
    required this.organizationId,
    required this.churchUnitId,
    required this.financialAccountId,
    required this.type,
    required this.montant,
    required this.dateMouvement,
    required this.libelle,
    required this.statut,
    required this.createdAt,
    required this.updatedAt,
    this.campagneId,
    this.programmeId,
    this.promesseId,
    this.membreId,
    this.tiersId,
    this.contributeurNom,
    this.modePaiement,
    this.referenceExterne,
    this.pieceJustificativeUrl,
    this.rejetMotif,
    this.ecritureId,
  });

  final String id;
  final String organizationId;
  final String churchUnitId;
  final String financialAccountId;
  final String? campagneId;
  final String? programmeId;
  final String? promesseId;
  final String? membreId;
  final String? tiersId;
  final String? contributeurNom;
  final String type;
  final double montant;
  final DateTime dateMouvement;
  final String libelle;
  final String? modePaiement;
  final String? referenceExterne;
  final String? pieceJustificativeUrl;
  final String statut;
  final String? rejetMotif;
  final String? ecritureId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinancialMovement.fromJson(Map<String, dynamic> json) {
    return FinancialMovement(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      churchUnitId: json['church_unit_id'] as String? ?? '',
      financialAccountId: json['financial_account_id'] as String? ?? '',
      campagneId: json['campagne_id'] as String?,
      programmeId: json['programme_id'] as String?,
      promesseId: json['promesse_id'] as String?,
      membreId: json['membre_id'] as String?,
      tiersId: json['tiers_id'] as String?,
      contributeurNom: json['contributeur_nom'] as String?,
      type: json['type'] as String? ?? 'encaissement',
      montant: _doubleValue(json['montant']),
      dateMouvement: _dateValue(json['date_mouvement']),
      libelle: json['libelle'] as String? ?? 'Mouvement financier',
      modePaiement: json['mode_paiement'] as String?,
      referenceExterne: json['reference_externe'] as String?,
      pieceJustificativeUrl: json['piece_justificative_url'] as String?,
      statut: json['statut'] as String? ?? 'brouillon',
      rejetMotif: json['rejet_motif'] as String?,
      ecritureId: json['ecriture_id'] as String?,
      createdAt: _dateValue(json['created_at']),
      updatedAt: _dateValue(json['updated_at']),
    );
  }
}

class OperationalFinanceState {
  const OperationalFinanceState({
    required this.campaigns,
    required this.pledges,
    required this.movements,
  });

  final List<FinancialCampaignSummary> campaigns;
  final List<FinancialPledge> pledges;
  final List<FinancialMovement> movements;
}

class ProfileContext {
  const ProfileContext({required this.profileId, required this.organizationId});

  final String profileId;
  final String organizationId;
}

double _doubleValue(Object? value) => _doubleOrNull(value) ?? 0;

double? _doubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime _dateValue(Object? value) {
  return _dateOrNull(value) ?? DateTime.now();
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

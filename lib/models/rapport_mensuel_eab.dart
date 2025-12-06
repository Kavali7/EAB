import 'package:freezed_annotation/freezed_annotation.dart';

part 'rapport_mensuel_eab.freezed.dart';
part 'rapport_mensuel_eab.g.dart';

@freezed
abstract class StatsMembresMensuelles with _$StatsMembresMensuelles {
  const factory StatsMembresMensuelles({
    // Effectif global
    required int totalMembresActifs,
    required int totalHommesActifs,
    required int totalFemmesActives,
    required int totalEnfants, // 0-14 ans

    // Officiers
    required int totalOfficiers,

    // Vulnerables
    required int totalOrphelins,
    required int totalVeufsVeuves,
    required int totalHandicapes,
    required int totalTroisiemeAge,

    // Mouvements du mois
    required int nouveauxConvertis,
    required int nouveauxBaptises,
    required int nouvellesMainsAssociation,
    required int mariagesCheres,
    required int departAssemblage, // departs / abandons / transferts
    required int deces,
  }) = _StatsMembresMensuelles;

  factory StatsMembresMensuelles.fromJson(Map<String, dynamic> json) =>
      _$StatsMembresMensuellesFromJson(json);
}

@freezed
abstract class StatsActivitesMensuelles with _$StatsActivitesMensuelles {
  const factory StatsActivitesMensuelles({
    // Evangelisations
    required int nbEvangelisationsMasse,
    required int nbEvangelisationsPorteAPorte,
    required int totalConversionsHommes,
    required int totalConversionsFemmes,
    required int totalConversionsGarcons,
    required int totalConversionsFilles,

    // Sainte cene, baptemes, mains d'association, reunions, mariages, visites
    required int nbBaptemes,
    required int nbMainsAssociation,
    required int nbSaintesCenes,
    required int nbReunionsPriere,
    required int nbMariages,
    required int nbDisciplines,
    required int nbVisitesFideles,
    required int nbVisitesAutorites,
    required int nbVisitesPartenaires,
    required int nbVisitesAutresAssemblees,

    // Ecole du dimanche
    required int nbSeancesEcoleDimanche,
    required int totalApprenantsHommes,
    required int totalApprenantsFemmes,
    required int totalApprenantsGarcons,
    required int totalApprenantsFilles,
    required int totalClassesEcoleDimanche,
    required int totalMoniteursHommes,
    required int totalMonitricesFemmes,
  }) = _StatsActivitesMensuelles;

  factory StatsActivitesMensuelles.fromJson(Map<String, dynamic> json) =>
      _$StatsActivitesMensuellesFromJson(json);
}

@freezed
abstract class StatsFinancieresMensuelles with _$StatsFinancieresMensuelles {
  const factory StatsFinancieresMensuelles({
    // Totaux globaux
    required double totalProduits,
    required double totalCharges,

    // Detail par grandes familles (simplifie)
    required double totalOffrandesCultes,
    required double totalDonsLiberaites,
    required double totalRecettesAutres,
    required double totalChargesFonctionnement,
    required double totalChargesSociales,
  }) = _StatsFinancieresMensuelles;

  factory StatsFinancieresMensuelles.fromJson(Map<String, dynamic> json) =>
      _$StatsFinancieresMensuellesFromJson(json);
}

@freezed
abstract class RapportMensuelEab with _$RapportMensuelEab {
  const factory RapportMensuelEab({
    required String id,
    required int annee,
    required int mois,
    required String idAssembleeLocale,

    // Statistiques calculees
    required StatsMembresMensuelles statsMembres,
    required StatsActivitesMensuelles statsActivites,
    required StatsFinancieresMensuelles statsFinances,

    // Champs texte (remplis plus tard via l'UI)
    String? resumeActivites,
    String? projetsRealisations,
    String? projetsMoisSuivant,
    String? observations,
  }) = _RapportMensuelEab;

  factory RapportMensuelEab.fromJson(Map<String, dynamic> json) =>
      _$RapportMensuelEabFromJson(json);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/compte_comptable.dart';
import '../models/compta_enums.dart';
import '../models/ecriture_comptable.dart';
import '../models/member.dart';
import '../models/program.dart';
import '../models/rapport_mensuel_eab.dart';
import 'accounting_providers.dart';
import 'members_provider.dart';
import 'programs_provider.dart';

class RapportMensuelParams {
  const RapportMensuelParams({
    required this.annee,
    required this.mois,
    required this.idAssembleeLocale,
  });

  final int annee;
  final int mois;
  final String idAssembleeLocale;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RapportMensuelParams &&
        other.annee == annee &&
        other.mois == mois &&
        other.idAssembleeLocale == idAssembleeLocale;
  }

  @override
  int get hashCode => Object.hash(annee, mois, idAssembleeLocale);
}

final rapportMensuelEabProvider =
    FutureProvider.family<RapportMensuelEab, RapportMensuelParams>(
  (ref, params) async {
    // 1) Charger les donnees necessaires
    final membres = await ref.watch(membersProvider.future);
    final programmes = await ref.watch(programsProvider.future);
    final ecritures = await ref.watch(ecrituresComptablesProvider.future);
    final comptes = await ref.watch(comptesComptablesProvider.future);

    final debutMois = DateTime(params.annee, params.mois, 1);
    final finMois = DateTime(params.annee, params.mois + 1, 0);

    // 2) Filtrer par assemblee et par mois
    final membresAssemblee = membres
        .where((m) => m.idAssembleeLocale == params.idAssembleeLocale)
        .toList();

    final programmesMois = programmes.where((p) {
      if (p.idAssembleeLocale != params.idAssembleeLocale) return false;
      final d = p.date;
      return !d.isBefore(debutMois) && !d.isAfter(finMois);
    }).toList();

    final ecrituresMois = ecritures.where((e) {
      if (e.idAssembleeLocale != params.idAssembleeLocale) return false;
      return !e.date.isBefore(debutMois) && !e.date.isAfter(finMois);
    }).toList();

    // 3) Calculs
    final statsMembres = _calculerStatsMembresMensuelles(
      membresAssemblee,
      debutMois,
      finMois,
    );
    final statsActivites = _calculerStatsActivitesMensuelles(programmesMois);
    final statsFinances =
        _calculerStatsFinancieresMensuelles(ecrituresMois, comptes);

    final idRapport =
        'rapport_${params.idAssembleeLocale}_${params.annee}_${params.mois}';

    return RapportMensuelEab(
      id: idRapport,
      annee: params.annee,
      mois: params.mois,
      idAssembleeLocale: params.idAssembleeLocale,
      statsMembres: statsMembres,
      statsActivites: statsActivites,
      statsFinances: statsFinances,
    );
  },
);

StatsMembresMensuelles _calculerStatsMembresMensuelles(
  List<Member> membres,
  DateTime debutMois,
  DateTime finMois,
) {
  int totalActifs = 0;
  int totalHommes = 0;
  int totalFemmes = 0;
  int totalEnfants = 0;
  int totalOfficiers = 0;

  int totalOrphelins = 0;
  int totalVeufsVeuves = 0;
  int totalHandicapes = 0;
  int totalTroisiemeAge = 0;

  int nouveauxConvertis = 0;
  int nouveauxBaptises = 0;
  int nouvellesMainsAssociation = 0;
  int mariagesCheres = 0;
  int departAssemblage = 0;
  int deces = 0;

  for (final m in membres) {
    if (m.statut == StatutFidele.actif) {
      totalActifs++;
      if (m.gender == Gender.male) {
        totalHommes++;
      } else if (m.gender == Gender.female) {
        totalFemmes++;
      }
      final naissance = m.dateNaissance ?? m.birthDate;
      final age = _ageEnAnnees(naissance, finMois);
      if (age <= 14) {
        totalEnfants++;
      }
    }

    if (m.estOfficier) {
      totalOfficiers++;
    }

    if (m.vulnerabilites.contains(VulnerabiliteFidele.orphelin)) {
      totalOrphelins++;
    }
    if (m.vulnerabilites.contains(VulnerabiliteFidele.veuf) ||
        m.vulnerabilites.contains(VulnerabiliteFidele.veuve)) {
      totalVeufsVeuves++;
    }
    if (m.vulnerabilites.contains(VulnerabiliteFidele.handicape)) {
      totalHandicapes++;
    }
    if (m.vulnerabilites.contains(VulnerabiliteFidele.troisiemeAge)) {
      totalTroisiemeAge++;
    }

    if (m.dateConversion != null &&
        _estDansMois(m.dateConversion!, debutMois, finMois)) {
      nouveauxConvertis++;
    }
    if (m.dateBapteme != null &&
        _estDansMois(m.dateBapteme!, debutMois, finMois)) {
      nouveauxBaptises++;
    } else if (m.baptismDate != null &&
        _estDansMois(m.baptismDate!, debutMois, finMois)) {
      nouveauxBaptises++;
    }
    if (m.dateMainAssociation != null &&
        _estDansMois(m.dateMainAssociation!, debutMois, finMois)) {
      nouvellesMainsAssociation++;
    }
    if (m.dateSortie != null &&
        _estDansMois(m.dateSortie!, debutMois, finMois)) {
      departAssemblage++;
    }
    if (m.dateDeces != null &&
        _estDansMois(m.dateDeces!, debutMois, finMois)) {
      deces++;
    }
  }

  return StatsMembresMensuelles(
    totalMembresActifs: totalActifs,
    totalHommesActifs: totalHommes,
    totalFemmesActives: totalFemmes,
    totalEnfants: totalEnfants,
    totalOfficiers: totalOfficiers,
    totalOrphelins: totalOrphelins,
    totalVeufsVeuves: totalVeufsVeuves,
    totalHandicapes: totalHandicapes,
    totalTroisiemeAge: totalTroisiemeAge,
    nouveauxConvertis: nouveauxConvertis,
    nouveauxBaptises: nouveauxBaptises,
    nouvellesMainsAssociation: nouvellesMainsAssociation,
    mariagesCheres: mariagesCheres,
    departAssemblage: departAssemblage,
    deces: deces,
  );
}

StatsActivitesMensuelles _calculerStatsActivitesMensuelles(
  List<Program> programmes,
) {
  int nbEvMasse = 0;
  int nbEvPorteAPorte = 0;
  int convH = 0, convF = 0, convG = 0, convFi = 0;

  int nbBaptemes = 0;
  int nbMainsAssoc = 0;
  int nbSaintesCenes = 0;
  int nbReunionsPriere = 0;
  int nbMariages = 0;
  int nbDisciplines = 0;
  int nbVisitesFideles = 0;
  int nbVisitesAutorites = 0;
  int nbVisitesPartenaires = 0;
  int nbVisitesAutresAssemblees = 0;

  int nbSeancesEdd = 0;
  int apprH = 0, apprF = 0, apprG = 0, apprFi = 0;
  int classes = 0;
  int moniteursH = 0, monitricesF = 0;

  for (final p in programmes) {
    switch (p.type) {
      case TypeProgramme.evangelisationMasse:
        nbEvMasse++;
        convH += p.conversionsHommes ?? 0;
        convF += p.conversionsFemmes ?? 0;
        convG += p.conversionsGarcons ?? 0;
        convFi += p.conversionsFilles ?? 0;
        break;
      case TypeProgramme.evangelisationPorteAPorte:
        nbEvPorteAPorte++;
        convH += p.conversionsHommes ?? 0;
        convF += p.conversionsFemmes ?? 0;
        convG += p.conversionsGarcons ?? 0;
        convFi += p.conversionsFilles ?? 0;
        break;
      case TypeProgramme.baptemes:
        nbBaptemes++;
        break;
      case TypeProgramme.mainsAssociation:
        nbMainsAssoc++;
        break;
      case TypeProgramme.sainteCene:
        nbSaintesCenes++;
        break;
      case TypeProgramme.reunionPriere:
        nbReunionsPriere++;
        break;
      case TypeProgramme.mariage:
        nbMariages++;
        break;
      case TypeProgramme.discipline:
        nbDisciplines++;
        break;
      case TypeProgramme.visite:
        switch (p.typeVisite) {
          case TypeVisite.fidele:
            nbVisitesFideles++;
            break;
          case TypeVisite.autorite:
            nbVisitesAutorites++;
            break;
          case TypeVisite.partenaire:
            nbVisitesPartenaires++;
            break;
          case TypeVisite.autreAssemblee:
            nbVisitesAutresAssemblees++;
            break;
          case TypeVisite.autre:
          case null:
            break;
        }
        break;
      case TypeProgramme.ecoleDuDimanche:
        nbSeancesEdd++;
        apprH += p.nombreHommes ?? 0;
        apprF += p.nombreFemmes ?? 0;
        apprG += p.nombreGarcons ?? 0;
        apprFi += p.nombreFilles ?? 0;
        classes += p.nombreClassesEcoleDuDimanche ?? 0;
        moniteursH += p.nombreMoniteursHommes ?? 0;
        monitricesF += p.nombreMonitricesFemmes ?? 0;
        break;
      case TypeProgramme.culte:
      case TypeProgramme.autre:
        break;
    }
  }

  return StatsActivitesMensuelles(
    nbEvangelisationsMasse: nbEvMasse,
    nbEvangelisationsPorteAPorte: nbEvPorteAPorte,
    totalConversionsHommes: convH,
    totalConversionsFemmes: convF,
    totalConversionsGarcons: convG,
    totalConversionsFilles: convFi,
    nbBaptemes: nbBaptemes,
    nbMainsAssociation: nbMainsAssoc,
    nbSaintesCenes: nbSaintesCenes,
    nbReunionsPriere: nbReunionsPriere,
    nbMariages: nbMariages,
    nbDisciplines: nbDisciplines,
    nbVisitesFideles: nbVisitesFideles,
    nbVisitesAutorites: nbVisitesAutorites,
    nbVisitesPartenaires: nbVisitesPartenaires,
    nbVisitesAutresAssemblees: nbVisitesAutresAssemblees,
    nbSeancesEcoleDimanche: nbSeancesEdd,
    totalApprenantsHommes: apprH,
    totalApprenantsFemmes: apprF,
    totalApprenantsGarcons: apprG,
    totalApprenantsFilles: apprFi,
    totalClassesEcoleDimanche: classes,
    totalMoniteursHommes: moniteursH,
    totalMonitricesFemmes: monitricesF,
  );
}

StatsFinancieresMensuelles _calculerStatsFinancieresMensuelles(
  List<EcritureComptable> ecritures,
  List<CompteComptable> comptes,
) {
  final comptesParId = {for (final c in comptes) c.id: c};

  double totalProduits = 0;
  double totalCharges = 0;

  double totalOffrandesCultes = 0;
  double totalDonsLiberaites = 0;
  double totalRecettesAutres = 0;
  double totalChargesFonctionnement = 0;
  double totalChargesSociales = 0;

  for (final e in ecritures) {
    for (final l in e.lignes) {
      final compte = comptesParId[l.idCompteComptable];
      if (compte == null) continue;
      final d = l.debit ?? 0;
      final c = l.credit ?? 0;

      if (compte.nature == NatureCompte.produit) {
        final montant = c - d;
        totalProduits += montant;

        if (compte.numero == '702') {
          totalOffrandesCultes += montant;
        } else if (compte.numero == '706') {
          totalDonsLiberaites += montant;
        } else {
          totalRecettesAutres += montant;
        }
      } else if (compte.nature == NatureCompte.charge) {
        final montant = d - c;
        totalCharges += montant;

        if (compte.numero.startsWith('61') || compte.numero.startsWith('62')) {
          totalChargesFonctionnement += montant;
        } else if (compte.numero == '645') {
          totalChargesSociales += montant;
        }
      }
    }
  }

  return StatsFinancieresMensuelles(
    totalProduits: totalProduits,
    totalCharges: totalCharges,
    totalOffrandesCultes: totalOffrandesCultes,
    totalDonsLiberaites: totalDonsLiberaites,
    totalRecettesAutres: totalRecettesAutres,
    totalChargesFonctionnement: totalChargesFonctionnement,
    totalChargesSociales: totalChargesSociales,
  );
}

int _ageEnAnnees(DateTime naissance, DateTime ref) {
  var age = ref.year - naissance.year;
  if (ref.month < naissance.month ||
      (ref.month == naissance.month && ref.day < naissance.day)) {
    age--;
  }
  return age;
}

bool _estDansMois(DateTime date, DateTime debut, DateTime fin) {
  return !date.isBefore(debut) && !date.isAfter(fin);
}

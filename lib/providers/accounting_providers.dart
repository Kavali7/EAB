import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/centre_analytique.dart';
import '../models/compte_comptable.dart';
import '../models/ecriture_comptable.dart';
import '../models/journal_comptable.dart';
import '../models/tiers.dart';
import '../models/compta_enums.dart';
import '../models/assemblee_locale.dart';
import '../models/district_eglise.dart';
import '../models/region_eglise.dart';
import '../models/profil_utilisateur.dart';
import '../models/budget_comptable.dart';
import 'data_service_provider.dart';
import 'user_profile_providers.dart';
import 'church_structure_providers.dart';

// Comptes comptables
final comptesComptablesProvider =
    AsyncNotifierProvider<ComptesComptablesNotifier, List<CompteComptable>>(
  ComptesComptablesNotifier.new,
);

final porteeComptableProvider =
    NotifierProvider<PorteeComptableNotifier, PorteeComptable>(
  PorteeComptableNotifier.new,
);

class PorteeComptableNotifier extends Notifier<PorteeComptable> {
  @override
  PorteeComptable build() => PorteeComptable.assemblee;

  void setPortee(PorteeComptable portee) {
    state = portee;
  }
}

class ComptesComptablesNotifier extends AsyncNotifier<List<CompteComptable>> {
  @override
  Future<List<CompteComptable>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getComptesComptables();
  }

  Future<void> ajouterCompte(CompteComptable compte) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, compte]);
  }

  Future<void> mettreAJourCompte(CompteComptable compte) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((c) => c.id == compte.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = compte;
    state = AsyncData(maj);
  }
}

// Journaux comptables
final journauxComptablesProvider =
    AsyncNotifierProvider<JournauxComptablesNotifier, List<JournalComptable>>(
  JournauxComptablesNotifier.new,
);

class JournauxComptablesNotifier extends AsyncNotifier<List<JournalComptable>> {
  @override
  Future<List<JournalComptable>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getJournauxComptables();
  }

  Future<void> ajouterJournal(JournalComptable journal) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, journal]);
  }

  Future<void> mettreAJourJournal(JournalComptable journal) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((j) => j.id == journal.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = journal;
    state = AsyncData(maj);
  }
}

// Centres analytiques
final centresAnalytiquesProvider = AsyncNotifierProvider<
    CentresAnalytiquesNotifier, List<CentreAnalytique>>(
  CentresAnalytiquesNotifier.new,
);

class CentresAnalytiquesNotifier
    extends AsyncNotifier<List<CentreAnalytique>> {
  @override
  Future<List<CentreAnalytique>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getCentresAnalytiques();
  }

  Future<void> ajouterCentre(CentreAnalytique centre) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, centre]);
  }

  Future<void> mettreAJourCentre(CentreAnalytique centre) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((c) => c.id == centre.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = centre;
    state = AsyncData(maj);
  }
}

// Tiers
final tiersProvider =
    AsyncNotifierProvider<TiersNotifier, List<Tiers>>(TiersNotifier.new);

class TiersNotifier extends AsyncNotifier<List<Tiers>> {
  @override
  Future<List<Tiers>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getTiers();
  }

  Future<void> ajouterTiers(Tiers t) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, t]);
  }

  Future<void> mettreAJourTiers(Tiers t) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((x) => x.id == t.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = t;
    state = AsyncData(maj);
  }
}

// Budgets
final budgetsComptablesProvider =
    AsyncNotifierProvider<BudgetsComptablesNotifier, List<BudgetComptable>>(
  BudgetsComptablesNotifier.new,
);

class BudgetsComptablesNotifier
    extends AsyncNotifier<List<BudgetComptable>> {
  @override
  Future<List<BudgetComptable>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getBudgetsComptables();
  }

  Future<void> ajouterBudget(BudgetComptable budget) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, budget]);
  }

  Future<void> mettreAJourBudget(BudgetComptable budget) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((b) => b.id == budget.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = budget;
    state = AsyncData(maj);
  }
}

final lignesBudgetsProvider = AsyncNotifierProvider<
    LignesBudgetsNotifier, List<LigneBudgetComptable>>(
  LignesBudgetsNotifier.new,
);

class LignesBudgetsNotifier
    extends AsyncNotifier<List<LigneBudgetComptable>> {
  @override
  Future<List<LigneBudgetComptable>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getLignesBudgetsComptables();
  }

  Future<void> ajouterLigne(LigneBudgetComptable ligne) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, ligne]);
  }

  Future<void> mettreAJourLigne(LigneBudgetComptable ligne) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((l) => l.id == ligne.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = ligne;
    state = AsyncData(maj);
  }
}

// Ecritures comptables
final ecrituresComptablesProvider = AsyncNotifierProvider<
    EcrituresComptablesNotifier, List<EcritureComptable>>(
  EcrituresComptablesNotifier.new,
);

class EcrituresComptablesNotifier
    extends AsyncNotifier<List<EcritureComptable>> {
  @override
  Future<List<EcritureComptable>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getEcrituresComptables();
  }

  Future<void> ajouterEcriture(EcritureComptable ecriture) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, ecriture]);
  }

  Future<void> mettreAJourEcriture(EcritureComptable ecriture) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((e) => e.id == ecriture.id);
    if (index == -1) return;
    final maj = [...actuelle];
    maj[index] = ecriture;
    state = AsyncData(maj);
  }

  Future<void> supprimerEcriture(String idEcriture) async {
    final actuelle = state.value ?? [];
    final maj = actuelle.where((e) => e.id != idEcriture).toList();
    state = AsyncData(maj);
  }
}

/// Ecritures filtrees par portee comptable et assemblees autorisees.
final ecrituresFiltreesProvider = Provider<List<EcritureComptable>>((ref) {
  final ecrituresAsync = ref.watch(ecrituresComptablesProvider);
  final portee = ref.watch(porteeComptableProvider);
  final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
  final profil = ref.watch(profilUtilisateurCourantProvider);

  final assembleesAsync = ref.watch(assembleesLocalesProvider);
  final districtsAsync = ref.watch(districtsProvider);
  final regionsAsync = ref.watch(regionsProvider);

  if (ecrituresAsync.asData == null ||
      assembleesAsync.asData == null ||
      districtsAsync.asData == null ||
      regionsAsync.asData == null) {
    return <EcritureComptable>[];
  }

  final ecritures = ecrituresAsync.asData!.value;
  final assemblees = assembleesAsync.asData!.value;
  final districts = districtsAsync.asData!.value;
  final regions = regionsAsync.asData!.value;

  final assembleesParId = {for (var a in assemblees) a.id: a};
  final districtsParId = {for (var d in districts) d.id: d};
  final regionsParId = {for (var r in regions) r.id: r};

  final idsAssembleesAutorisees = _calculerAssembleesAutorisees(
    profil: profil,
    assemblees: assemblees,
    districtsParId: districtsParId,
    regionsParId: regionsParId,
  );

  if (idsAssembleesAutorisees.isEmpty) return <EcritureComptable>[];

  final idsAssembleesCiblees = _calculerAssembleesCibleesParPortee(
    portee: portee,
    assembleeActiveId: assembleeActiveId,
    assembleesParId: assembleesParId,
    districtsParId: districtsParId,
    regionsParId: regionsParId,
    idsAssembleesAutorisees: idsAssembleesAutorisees,
  );

  if (idsAssembleesCiblees.isEmpty) return <EcritureComptable>[];

  return ecritures.where((e) {
    final idAss = e.idAssembleeLocale;
    if (idAss == null) return false;
    return idsAssembleesCiblees.contains(idAss);
  }).toList();
});

Set<String> _calculerAssembleesAutorisees({
  required ProfilUtilisateur? profil,
  required List<AssembleeLocale> assemblees,
  required Map<String, DistrictEglise> districtsParId,
  required Map<String, RegionEglise> regionsParId,
}) {
  final result = <String>{};
  if (profil == null) return result;

  switch (profil.role) {
    case RoleUtilisateur.adminNational:
      result.addAll(assemblees.map((a) => a.id));
      return result;
    case RoleUtilisateur.responsableRegion:
      final idRegion = profil.idRegion;
      if (idRegion == null) return result;
      for (final a in assemblees) {
        final district = districtsParId[a.idDistrict];
        if (district != null && district.idRegion == idRegion) {
          result.add(a.id);
        }
      }
      return result;
    case RoleUtilisateur.surintendantDistrict:
      final idDistrict = profil.idDistrict;
      if (idDistrict == null) return result;
      for (final a in assemblees) {
        if (a.idDistrict == idDistrict) result.add(a.id);
      }
      return result;
    case RoleUtilisateur.tresorierAssemblee:
      final idAss = profil.idAssembleeLocale;
      if (idAss != null) result.add(idAss);
      return result;
  }
}

Set<String> _calculerAssembleesCibleesParPortee({
  required PorteeComptable portee,
  required String? assembleeActiveId,
  required Map<String, AssembleeLocale> assembleesParId,
  required Map<String, DistrictEglise> districtsParId,
  required Map<String, RegionEglise> regionsParId,
  required Set<String> idsAssembleesAutorisees,
}) {
  final result = <String>{};
  if (idsAssembleesAutorisees.isEmpty) return result;

  final assembleeActive =
      assembleeActiveId != null ? assembleesParId[assembleeActiveId] : null;

  switch (portee) {
    case PorteeComptable.assemblee:
      if (assembleeActive != null &&
          idsAssembleesAutorisees.contains(assembleeActive.id)) {
        result.add(assembleeActive.id);
      }
      break;
    case PorteeComptable.district:
      if (assembleeActive == null) break;
      final district = districtsParId[assembleeActive.idDistrict];
      if (district == null) break;
      for (final a in assembleesParId.values) {
        if (a.idDistrict == district.id &&
            idsAssembleesAutorisees.contains(a.id)) {
          result.add(a.id);
        }
      }
      break;
    case PorteeComptable.region:
      if (assembleeActive == null) break;
      final district = districtsParId[assembleeActive.idDistrict];
      if (district == null) break;
      final region = regionsParId[district.idRegion];
      if (region == null) break;
      for (final a in assembleesParId.values) {
        final d = districtsParId[a.idDistrict];
        if (d != null &&
            d.idRegion == region.id &&
            idsAssembleesAutorisees.contains(a.id)) {
          result.add(a.id);
        }
      }
      break;
    case PorteeComptable.national:
      result.addAll(idsAssembleesAutorisees);
      break;
  }

  return result;
}

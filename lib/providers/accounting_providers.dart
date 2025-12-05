import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/centre_analytique.dart';
import '../models/compte_comptable.dart';
import '../models/ecriture_comptable.dart';
import '../models/journal_comptable.dart';
import '../models/tiers.dart';
import 'data_service_provider.dart';
import 'user_profile_providers.dart';

// Comptes comptables
final comptesComptablesProvider =
    AsyncNotifierProvider<ComptesComptablesNotifier, List<CompteComptable>>(
  ComptesComptablesNotifier.new,
);

class ComptesComptablesNotifier extends AsyncNotifier<List<CompteComptable>> {
  @override
  Future<List<CompteComptable>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getComptesComptables();
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

/// Ecritures filtrees par assemblee active.
final ecrituresFiltreesProvider = Provider<List<EcritureComptable>>((ref) {
  final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
  final ecrituresAsync = ref.watch(ecrituresComptablesProvider);

  return ecrituresAsync.maybeWhen(
    data: (ecritures) {
      if (assembleeActiveId == null) return ecritures;
      return ecritures
          .where(
            (e) =>
                e.idAssembleeLocale == null ||
                e.idAssembleeLocale == assembleeActiveId,
          )
          .toList();
    },
    orElse: () => <EcritureComptable>[],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/error_reporting.dart';
import '../models/profil_utilisateur.dart';
import 'data_service_provider.dart';

final profilsUtilisateursProvider = AsyncNotifierProvider<
    ProfilsUtilisateursNotifier, List<ProfilUtilisateur>>(
  ProfilsUtilisateursNotifier.new,
);

class ProfilsUtilisateursNotifier
    extends AsyncNotifier<List<ProfilUtilisateur>> {
  @override
  Future<List<ProfilUtilisateur>> build() async {
    try {
      final dataService = ref.read(dataServiceProvider);
      final profils = await dataService.getProfilsUtilisateurs();

      // Auto-initialiser le profil courant si pas encore défini
      final courant = ref.read(profilUtilisateurCourantProvider);
      if (courant == null && profils.isNotEmpty) {
        final defaultProfil = profils.firstWhere(
          (p) => p.id == 'profil_tresorier_cotonou_centre',
          orElse: () => profils.first,
        );
        ref
            .read(profilUtilisateurCourantProvider.notifier)
            .setProfil(defaultProfil);
      }
      return profils;
    } catch (e, st) {
      ErrorReporting.captureException(e, stackTrace: st, context: {'provider': 'profilsUtilisateursProvider'});
      rethrow;
    }
  }
}

class ProfilUtilisateurCourantNotifier extends Notifier<ProfilUtilisateur?> {
  @override
  ProfilUtilisateur? build() => null;

  void setProfil(ProfilUtilisateur profil) {
    state = profil;
  }
}

final profilUtilisateurCourantProvider =
    NotifierProvider<ProfilUtilisateurCourantNotifier, ProfilUtilisateur?>(
  ProfilUtilisateurCourantNotifier.new,
);

class AssembleeActiveNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setAssemblee(String? id) {
    state = id;
  }
}

final assembleeActiveIdProvider =
    NotifierProvider<AssembleeActiveNotifier, String?>(
  AssembleeActiveNotifier.new,
);

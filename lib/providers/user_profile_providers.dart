import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final dataService = ref.read(dataServiceProvider);
    return dataService.getProfilsUtilisateurs();
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

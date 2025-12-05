import 'package:freezed_annotation/freezed_annotation.dart';

part 'profil_utilisateur.freezed.dart';
part 'profil_utilisateur.g.dart';

enum RoleUtilisateur {
  adminNational,
  responsableRegion,
  surintendantDistrict,
  tresorierAssemblee,
}

@freezed
abstract class ProfilUtilisateur with _$ProfilUtilisateur {
  const factory ProfilUtilisateur({
    required String id,
    required String nom,
    required RoleUtilisateur role,
    String? idRegion,
    String? idDistrict,
    String? idAssembleeLocale,
  }) = _ProfilUtilisateur;

  factory ProfilUtilisateur.fromJson(Map<String, dynamic> json) =>
      _$ProfilUtilisateurFromJson(json);
}

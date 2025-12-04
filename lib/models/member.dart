import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/constants.dart';

part 'member.freezed.dart';
part 'member.g.dart';

enum RoleFidele {
  membre,
  pasteur,
  ancien,
  diacre,
  diaconesse,
  evangeliste,
  autreOfficier,
}

enum StatutMatrimonial {
  celibataire,
  marie,
  veuf,
  veuve,
  divorce,
  separe,
}

enum StatutFidele {
  actif,
  inactif,
  parti,
  decede,
  transfere,
}

enum VulnerabiliteFidele {
  orphelin,
  veuf,
  veuve,
  handicape,
  troisiemeAge,
  autre,
}

@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required String id,
    required String fullName,
    required Gender gender,
    required DateTime birthDate,
    required MaritalStatus maritalStatus,
    DateTime? baptismDate,
    String? phone,
    String? email,
    String? address,
    DateTime? dateNaissance,
    StatutMatrimonial? statutMatrimonial,
    DateTime? dateConversion,
    DateTime? dateBapteme,
    DateTime? dateMainAssociation,
    @Default(StatutFidele.actif) StatutFidele statut,
    DateTime? dateEntree,
    DateTime? dateSortie,
    String? motifSortie,
    DateTime? dateDeces,
    @Default(RoleFidele.membre) RoleFidele role,
    @Default(<VulnerabiliteFidele>{}) Set<VulnerabiliteFidele> vulnerabilites,
    String? idFamille,
  }) = _Member;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get estOfficier => role != RoleFidele.membre;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'compta_enums.dart';

part 'compte_comptable.freezed.dart';
part 'compte_comptable.g.dart';

@freezed
abstract class CompteComptable with _$CompteComptable {
  const factory CompteComptable({
    required String id, // identifiant interne (UUID ou similaire)
    required String numero, // numero du compte (ex: "5121", "701")
    required String intitule, // libelle du compte
    required NatureCompte nature, // actif, passif, charge, produit, etc.
    int? niveau, // niveau dans l'arborescence (1 = classe, 2 = compte, 3 = sous-compte)
    String? idCompteParent, // lien vers un compte parent pour construire l'arborescence
    @Default(true) bool actif, // compte actif ou non
  }) = _CompteComptable;

  factory CompteComptable.fromJson(Map<String, dynamic> json) =>
      _$CompteComptableFromJson(json);
}

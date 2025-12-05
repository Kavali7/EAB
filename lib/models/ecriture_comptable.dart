import 'package:freezed_annotation/freezed_annotation.dart';

import 'compta_enums.dart';

part 'ecriture_comptable.freezed.dart';
part 'ecriture_comptable.g.dart';

@freezed
abstract class LigneEcritureComptable with _$LigneEcritureComptable {
  const factory LigneEcritureComptable({
    required String id,
    required String idCompteComptable, // reference a CompteComptable.id
    double? debit,
    double? credit,
    String? idCentreAnalytique, // reference a CentreAnalytique.id
    String? idTiers, // reference a Tiers.id
    ModePaiement? modePaiement, // si pertinent pour la ligne
    String? libelle, // libelle ligne
  }) = _LigneEcritureComptable;

  factory LigneEcritureComptable.fromJson(Map<String, dynamic> json) =>
      _$LigneEcritureComptableFromJson(json);
}

@freezed
abstract class EcritureComptable with _$EcritureComptable {
  const factory EcritureComptable({
    required String id,
    required DateTime date,
    required String idJournal, // reference a JournalComptable.id
    String? referencePiece, // reference interne / piece justificative
    required String libelle, // libelle general de l'ecriture
    required List<LigneEcritureComptable> lignes,
    // Rattachement a une assemblee / centre principal
    String? idAssembleeLocale,
    String? idCentreAnalytiquePrincipal,
    // Pour plus tard : etat de validation, auteur, etc.
  }) = _EcritureComptable;

  factory EcritureComptable.fromJson(Map<String, dynamic> json) =>
      _$EcritureComptableFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'releve_bancaire.freezed.dart';
part 'releve_bancaire.g.dart';

@freezed
abstract class LigneReleveBancaire with _$LigneReleveBancaire {
  const factory LigneReleveBancaire({
    required String id,
    required DateTime dateOperation,
    required String libelle,
    required double montant,
    required double soldeApresOperation,
    required String idCompteBanque,
    String? referenceOperation,
    @Default(false) bool estPointe,
    String? idEcritureComptableLiee,
  }) = _LigneReleveBancaire;

  factory LigneReleveBancaire.fromJson(Map<String, dynamic> json) =>
      _$LigneReleveBancaireFromJson(json);
}

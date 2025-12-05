// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'releve_bancaire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LigneReleveBancaire _$LigneReleveBancaireFromJson(Map<String, dynamic> json) =>
    _LigneReleveBancaire(
      id: json['id'] as String,
      dateOperation: DateTime.parse(json['dateOperation'] as String),
      libelle: json['libelle'] as String,
      montant: (json['montant'] as num).toDouble(),
      soldeApresOperation: (json['soldeApresOperation'] as num).toDouble(),
      idCompteBanque: json['idCompteBanque'] as String,
      referenceOperation: json['referenceOperation'] as String?,
      estPointe: json['estPointe'] as bool? ?? false,
      idEcritureComptableLiee: json['idEcritureComptableLiee'] as String?,
    );

Map<String, dynamic> _$LigneReleveBancaireToJson(
  _LigneReleveBancaire instance,
) => <String, dynamic>{
  'id': instance.id,
  'dateOperation': instance.dateOperation.toIso8601String(),
  'libelle': instance.libelle,
  'montant': instance.montant,
  'soldeApresOperation': instance.soldeApresOperation,
  'idCompteBanque': instance.idCompteBanque,
  'referenceOperation': instance.referenceOperation,
  'estPointe': instance.estPointe,
  'idEcritureComptableLiee': instance.idEcritureComptableLiee,
};

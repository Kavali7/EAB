// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compte_comptable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompteComptable _$CompteComptableFromJson(Map<String, dynamic> json) =>
    _CompteComptable(
      id: json['id'] as String,
      numero: json['numero'] as String,
      intitule: json['intitule'] as String,
      nature: $enumDecode(_$NatureCompteEnumMap, json['nature']),
      niveau: (json['niveau'] as num?)?.toInt(),
      idCompteParent: json['idCompteParent'] as String?,
      actif: json['actif'] as bool? ?? true,
    );

Map<String, dynamic> _$CompteComptableToJson(_CompteComptable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'numero': instance.numero,
      'intitule': instance.intitule,
      'nature': _$NatureCompteEnumMap[instance.nature]!,
      'niveau': instance.niveau,
      'idCompteParent': instance.idCompteParent,
      'actif': instance.actif,
    };

const _$NatureCompteEnumMap = {
  NatureCompte.actif: 'actif',
  NatureCompte.passif: 'passif',
  NatureCompte.charge: 'charge',
  NatureCompte.produit: 'produit',
  NatureCompte.horsActiviteOrdinaire: 'horsActiviteOrdinaire',
  NatureCompte.engagement: 'engagement',
  NatureCompte.autre: 'autre',
};

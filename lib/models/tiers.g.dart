// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tiers _$TiersFromJson(Map<String, dynamic> json) => _Tiers(
  id: json['id'] as String,
  nom: json['nom'] as String,
  type: $enumDecode(_$TypeTiersEnumMap, json['type']),
  telephone: json['telephone'] as String?,
  email: json['email'] as String?,
  adresse: json['adresse'] as String?,
  idAssembleeLocale: json['idAssembleeLocale'] as String?,
  idFideleLie: json['idFideleLie'] as String?,
);

Map<String, dynamic> _$TiersToJson(_Tiers instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'type': _$TypeTiersEnumMap[instance.type]!,
  'telephone': instance.telephone,
  'email': instance.email,
  'adresse': instance.adresse,
  'idAssembleeLocale': instance.idAssembleeLocale,
  'idFideleLie': instance.idFideleLie,
};

const _$TypeTiersEnumMap = {
  TypeTiers.membre: 'membre',
  TypeTiers.fournisseur: 'fournisseur',
  TypeTiers.bailleur: 'bailleur',
  TypeTiers.employe: 'employe',
  TypeTiers.partenaire: 'partenaire',
  TypeTiers.autre: 'autre',
};

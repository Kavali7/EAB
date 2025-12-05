// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'centre_analytique.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CentreAnalytique _$CentreAnalytiqueFromJson(Map<String, dynamic> json) =>
    _CentreAnalytique(
      id: json['id'] as String,
      code: json['code'] as String,
      nom: json['nom'] as String,
      type: $enumDecode(_$TypeCentreAnalytiqueEnumMap, json['type']),
      description: json['description'] as String?,
      idAssembleeLocale: json['idAssembleeLocale'] as String?,
    );

Map<String, dynamic> _$CentreAnalytiqueToJson(_CentreAnalytique instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'nom': instance.nom,
      'type': _$TypeCentreAnalytiqueEnumMap[instance.type]!,
      'description': instance.description,
      'idAssembleeLocale': instance.idAssembleeLocale,
    };

const _$TypeCentreAnalytiqueEnumMap = {
  TypeCentreAnalytique.assembleeLocale: 'assembleeLocale',
  TypeCentreAnalytique.projet: 'projet',
  TypeCentreAnalytique.activite: 'activite',
  TypeCentreAnalytique.departement: 'departement',
  TypeCentreAnalytique.autre: 'autre',
};

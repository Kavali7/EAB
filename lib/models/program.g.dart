// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Program _$ProgramFromJson(Map<String, dynamic> json) => _Program(
  id: json['id'] as String,
  type: $enumDecode(_$TypeProgrammeEnumMap, json['type']),
  date: DateTime.parse(json['date'] as String),
  location: json['location'] as String,
  idAssembleeLocale: json['idAssembleeLocale'] as String?,
  description: json['description'] as String?,
  observations: json['observations'] as String?,
  participantIds:
      (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  typeVisite: $enumDecodeNullable(_$TypeVisiteEnumMap, json['typeVisite']),
  nombreHommes: (json['nombreHommes'] as num?)?.toInt(),
  nombreFemmes: (json['nombreFemmes'] as num?)?.toInt(),
  nombreGarcons: (json['nombreGarcons'] as num?)?.toInt(),
  nombreFilles: (json['nombreFilles'] as num?)?.toInt(),
  conversionsHommes: (json['conversionsHommes'] as num?)?.toInt(),
  conversionsFemmes: (json['conversionsFemmes'] as num?)?.toInt(),
  conversionsGarcons: (json['conversionsGarcons'] as num?)?.toInt(),
  conversionsFilles: (json['conversionsFilles'] as num?)?.toInt(),
  nombreClassesEcoleDuDimanche: (json['nombreClassesEcoleDuDimanche'] as num?)
      ?.toInt(),
  nombreMoniteursHommes: (json['nombreMoniteursHommes'] as num?)?.toInt(),
  nombreMonitricesFemmes: (json['nombreMonitricesFemmes'] as num?)?.toInt(),
  derniereLeconEcoleDuDimanche: json['derniereLeconEcoleDuDimanche'] as String?,
  compteRenduVisite: json['compteRenduVisite'] as String?,
);

Map<String, dynamic> _$ProgramToJson(_Program instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$TypeProgrammeEnumMap[instance.type]!,
  'date': instance.date.toIso8601String(),
  'location': instance.location,
  'idAssembleeLocale': instance.idAssembleeLocale,
  'description': instance.description,
  'observations': instance.observations,
  'participantIds': instance.participantIds,
  'typeVisite': _$TypeVisiteEnumMap[instance.typeVisite],
  'nombreHommes': instance.nombreHommes,
  'nombreFemmes': instance.nombreFemmes,
  'nombreGarcons': instance.nombreGarcons,
  'nombreFilles': instance.nombreFilles,
  'conversionsHommes': instance.conversionsHommes,
  'conversionsFemmes': instance.conversionsFemmes,
  'conversionsGarcons': instance.conversionsGarcons,
  'conversionsFilles': instance.conversionsFilles,
  'nombreClassesEcoleDuDimanche': instance.nombreClassesEcoleDuDimanche,
  'nombreMoniteursHommes': instance.nombreMoniteursHommes,
  'nombreMonitricesFemmes': instance.nombreMonitricesFemmes,
  'derniereLeconEcoleDuDimanche': instance.derniereLeconEcoleDuDimanche,
  'compteRenduVisite': instance.compteRenduVisite,
};

const _$TypeProgrammeEnumMap = {
  TypeProgramme.culte: 'culte',
  TypeProgramme.evangelisationMasse: 'evangelisationMasse',
  TypeProgramme.evangelisationPorteAPorte: 'evangelisationPorteAPorte',
  TypeProgramme.baptemes: 'baptemes',
  TypeProgramme.mainsAssociation: 'mainsAssociation',
  TypeProgramme.sainteCene: 'sainteCene',
  TypeProgramme.reunionPriere: 'reunionPriere',
  TypeProgramme.mariage: 'mariage',
  TypeProgramme.discipline: 'discipline',
  TypeProgramme.visite: 'visite',
  TypeProgramme.ecoleDuDimanche: 'ecoleDuDimanche',
  TypeProgramme.autre: 'autre',
};

const _$TypeVisiteEnumMap = {
  TypeVisite.fidele: 'fidele',
  TypeVisite.autorite: 'autorite',
  TypeVisite.partenaire: 'partenaire',
  TypeVisite.autreAssemblee: 'autreAssemblee',
  TypeVisite.autre: 'autre',
};

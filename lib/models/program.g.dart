// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Program _$ProgramFromJson(Map<String, dynamic> json) => _Program(
  id: json['id'] as String,
  type: $enumDecode(_$ProgramTypeEnumMap, json['type']),
  date: DateTime.parse(json['date'] as String),
  location: json['location'] as String,
  description: json['description'] as String?,
  participantIds:
      (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProgramToJson(_Program instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$ProgramTypeEnumMap[instance.type]!,
  'date': instance.date.toIso8601String(),
  'location': instance.location,
  'description': instance.description,
  'participantIds': instance.participantIds,
};

const _$ProgramTypeEnumMap = {
  ProgramType.wedding: 'wedding',
  ProgramType.baptism: 'baptism',
  ProgramType.communion: 'communion',
  ProgramType.evangelization: 'evangelization',
  ProgramType.prayer: 'prayer',
  ProgramType.seminar: 'seminar',
  ProgramType.vigil: 'vigil',
  ProgramType.conference: 'conference',
  ProgramType.youthRetreat: 'youthRetreat',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_comptable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JournalComptable _$JournalComptableFromJson(Map<String, dynamic> json) =>
    _JournalComptable(
      id: json['id'] as String,
      code: json['code'] as String,
      intitule: json['intitule'] as String,
      type: $enumDecode(_$TypeJournalComptableEnumMap, json['type']),
      actif: json['actif'] as bool? ?? true,
    );

Map<String, dynamic> _$JournalComptableToJson(_JournalComptable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'intitule': instance.intitule,
      'type': _$TypeJournalComptableEnumMap[instance.type]!,
      'actif': instance.actif,
    };

const _$TypeJournalComptableEnumMap = {
  TypeJournalComptable.caisse: 'caisse',
  TypeJournalComptable.banque: 'banque',
  TypeJournalComptable.operationsDiverses: 'operationsDiverses',
};

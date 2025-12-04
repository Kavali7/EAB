// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'famille.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Famille _$FamilleFromJson(Map<String, dynamic> json) => _Famille(
  id: json['id'] as String,
  nom: json['nom'] as String,
  idEpoux: json['idEpoux'] as String?,
  idEpouse: json['idEpouse'] as String?,
  idsEnfants:
      (json['idsEnfants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$FamilleToJson(_Famille instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'idEpoux': instance.idEpoux,
  'idEpouse': instance.idEpouse,
  'idsEnfants': instance.idsEnfants,
};

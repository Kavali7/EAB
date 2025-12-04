// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'district_eglise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DistrictEglise _$DistrictEgliseFromJson(Map<String, dynamic> json) =>
    _DistrictEglise(
      id: json['id'] as String,
      nom: json['nom'] as String,
      code: json['code'] as String?,
      idRegion: json['idRegion'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$DistrictEgliseToJson(_DistrictEglise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'code': instance.code,
      'idRegion': instance.idRegion,
      'description': instance.description,
    };

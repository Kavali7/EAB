// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_eglise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegionEglise _$RegionEgliseFromJson(Map<String, dynamic> json) =>
    _RegionEglise(
      id: json['id'] as String,
      nom: json['nom'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$RegionEgliseToJson(_RegionEglise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'code': instance.code,
      'description': instance.description,
    };

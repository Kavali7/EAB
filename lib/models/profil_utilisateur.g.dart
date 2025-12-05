// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profil_utilisateur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfilUtilisateur _$ProfilUtilisateurFromJson(Map<String, dynamic> json) =>
    _ProfilUtilisateur(
      id: json['id'] as String,
      nom: json['nom'] as String,
      role: $enumDecode(_$RoleUtilisateurEnumMap, json['role']),
      idRegion: json['idRegion'] as String?,
      idDistrict: json['idDistrict'] as String?,
      idAssembleeLocale: json['idAssembleeLocale'] as String?,
    );

Map<String, dynamic> _$ProfilUtilisateurToJson(_ProfilUtilisateur instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'role': _$RoleUtilisateurEnumMap[instance.role]!,
      'idRegion': instance.idRegion,
      'idDistrict': instance.idDistrict,
      'idAssembleeLocale': instance.idAssembleeLocale,
    };

const _$RoleUtilisateurEnumMap = {
  RoleUtilisateur.adminNational: 'adminNational',
  RoleUtilisateur.responsableRegion: 'responsableRegion',
  RoleUtilisateur.surintendantDistrict: 'surintendantDistrict',
  RoleUtilisateur.tresorierAssemblee: 'tresorierAssemblee',
};

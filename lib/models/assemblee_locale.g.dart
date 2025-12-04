// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assemblee_locale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssembleeLocale _$AssembleeLocaleFromJson(Map<String, dynamic> json) =>
    _AssembleeLocale(
      id: json['id'] as String,
      nom: json['nom'] as String,
      code: json['code'] as String?,
      idDistrict: json['idDistrict'] as String,
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      adressePostale: json['adressePostale'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      idFidelePasteurResponsable: json['idFidelePasteurResponsable'] as String?,
    );

Map<String, dynamic> _$AssembleeLocaleToJson(_AssembleeLocale instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'code': instance.code,
      'idDistrict': instance.idDistrict,
      'ville': instance.ville,
      'quartier': instance.quartier,
      'adressePostale': instance.adressePostale,
      'telephone': instance.telephone,
      'email': instance.email,
      'idFidelePasteurResponsable': instance.idFidelePasteurResponsable,
    };

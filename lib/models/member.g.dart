// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  gender: $enumDecode(_$GenderEnumMap, json['gender']),
  birthDate: DateTime.parse(json['birthDate'] as String),
  maritalStatus: $enumDecode(_$MaritalStatusEnumMap, json['maritalStatus']),
  baptismDate: json['baptismDate'] == null
      ? null
      : DateTime.parse(json['baptismDate'] as String),
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  address: json['address'] as String?,
  dateNaissance: json['dateNaissance'] == null
      ? null
      : DateTime.parse(json['dateNaissance'] as String),
  statutMatrimonial: $enumDecodeNullable(
    _$StatutMatrimonialEnumMap,
    json['statutMatrimonial'],
  ),
  dateConversion: json['dateConversion'] == null
      ? null
      : DateTime.parse(json['dateConversion'] as String),
  dateBapteme: json['dateBapteme'] == null
      ? null
      : DateTime.parse(json['dateBapteme'] as String),
  dateMainAssociation: json['dateMainAssociation'] == null
      ? null
      : DateTime.parse(json['dateMainAssociation'] as String),
  statut:
      $enumDecodeNullable(_$StatutFideleEnumMap, json['statut']) ??
      StatutFidele.actif,
  dateEntree: json['dateEntree'] == null
      ? null
      : DateTime.parse(json['dateEntree'] as String),
  dateSortie: json['dateSortie'] == null
      ? null
      : DateTime.parse(json['dateSortie'] as String),
  motifSortie: json['motifSortie'] as String?,
  dateDeces: json['dateDeces'] == null
      ? null
      : DateTime.parse(json['dateDeces'] as String),
  role:
      $enumDecodeNullable(_$RoleFideleEnumMap, json['role']) ??
      RoleFidele.membre,
  vulnerabilites:
      (json['vulnerabilites'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$VulnerabiliteFideleEnumMap, e))
          .toSet() ??
      const <VulnerabiliteFidele>{},
  idFamille: json['idFamille'] as String?,
  idAssembleeLocale: json['idAssembleeLocale'] as String?,
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'gender': _$GenderEnumMap[instance.gender]!,
  'birthDate': instance.birthDate.toIso8601String(),
  'maritalStatus': _$MaritalStatusEnumMap[instance.maritalStatus]!,
  'baptismDate': instance.baptismDate?.toIso8601String(),
  'phone': instance.phone,
  'email': instance.email,
  'address': instance.address,
  'dateNaissance': instance.dateNaissance?.toIso8601String(),
  'statutMatrimonial': _$StatutMatrimonialEnumMap[instance.statutMatrimonial],
  'dateConversion': instance.dateConversion?.toIso8601String(),
  'dateBapteme': instance.dateBapteme?.toIso8601String(),
  'dateMainAssociation': instance.dateMainAssociation?.toIso8601String(),
  'statut': _$StatutFideleEnumMap[instance.statut]!,
  'dateEntree': instance.dateEntree?.toIso8601String(),
  'dateSortie': instance.dateSortie?.toIso8601String(),
  'motifSortie': instance.motifSortie,
  'dateDeces': instance.dateDeces?.toIso8601String(),
  'role': _$RoleFideleEnumMap[instance.role]!,
  'vulnerabilites': instance.vulnerabilites
      .map((e) => _$VulnerabiliteFideleEnumMap[e]!)
      .toList(),
  'idFamille': instance.idFamille,
  'idAssembleeLocale': instance.idAssembleeLocale,
};

const _$GenderEnumMap = {Gender.male: 'male', Gender.female: 'female'};

const _$MaritalStatusEnumMap = {
  MaritalStatus.single: 'single',
  MaritalStatus.married: 'married',
  MaritalStatus.divorced: 'divorced',
  MaritalStatus.widowed: 'widowed',
};

const _$StatutMatrimonialEnumMap = {
  StatutMatrimonial.celibataire: 'celibataire',
  StatutMatrimonial.marie: 'marie',
  StatutMatrimonial.veuf: 'veuf',
  StatutMatrimonial.veuve: 'veuve',
  StatutMatrimonial.divorce: 'divorce',
  StatutMatrimonial.separe: 'separe',
};

const _$StatutFideleEnumMap = {
  StatutFidele.actif: 'actif',
  StatutFidele.inactif: 'inactif',
  StatutFidele.parti: 'parti',
  StatutFidele.decede: 'decede',
  StatutFidele.transfere: 'transfere',
};

const _$RoleFideleEnumMap = {
  RoleFidele.membre: 'membre',
  RoleFidele.pasteur: 'pasteur',
  RoleFidele.ancien: 'ancien',
  RoleFidele.diacre: 'diacre',
  RoleFidele.diaconesse: 'diaconesse',
  RoleFidele.evangeliste: 'evangeliste',
  RoleFidele.autreOfficier: 'autreOfficier',
};

const _$VulnerabiliteFideleEnumMap = {
  VulnerabiliteFidele.orphelin: 'orphelin',
  VulnerabiliteFidele.veuf: 'veuf',
  VulnerabiliteFidele.veuve: 'veuve',
  VulnerabiliteFidele.handicape: 'handicape',
  VulnerabiliteFidele.troisiemeAge: 'troisiemeAge',
  VulnerabiliteFidele.autre: 'autre',
};

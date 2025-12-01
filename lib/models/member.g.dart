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
};

const _$GenderEnumMap = {Gender.male: 'male', Gender.female: 'female'};

const _$MaritalStatusEnumMap = {
  MaritalStatus.single: 'single',
  MaritalStatus.married: 'married',
  MaritalStatus.divorced: 'divorced',
  MaritalStatus.widowed: 'widowed',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountingEntry _$AccountingEntryFromJson(Map<String, dynamic> json) =>
    _AccountingEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$AccountingTypeEnumMap, json['type']),
      category: json['category'] as String,
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );

Map<String, dynamic> _$AccountingEntryToJson(_AccountingEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'type': _$AccountingTypeEnumMap[instance.type]!,
      'category': instance.category,
      'description': instance.description,
      'paymentMethod': instance.paymentMethod,
    };

const _$AccountingTypeEnumMap = {
  AccountingType.income: 'income',
  AccountingType.expense: 'expense',
};

import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/constants.dart';

part 'accounting_entry.freezed.dart';
part 'accounting_entry.g.dart';

@freezed
abstract class AccountingEntry with _$AccountingEntry {
  const factory AccountingEntry({
    required String id,
    required DateTime date,
    required double amount,
    required AccountingType type,
    required String category,
    String? description,
    String? paymentMethod,
  }) = _AccountingEntry;

  factory AccountingEntry.fromJson(Map<String, dynamic> json) =>
      _$AccountingEntryFromJson(json);
}

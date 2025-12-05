import 'package:freezed_annotation/freezed_annotation.dart';

import 'compta_enums.dart';

part 'journal_comptable.freezed.dart';
part 'journal_comptable.g.dart';

@freezed
abstract class JournalComptable with _$JournalComptable {
  const factory JournalComptable({
    required String id,
    required String code, // ex: "CAI", "BAN", "OD"
    required String intitule, // libelle : "Journal de caisse", "Journal de banque", etc.
    required TypeJournalComptable type,
    @Default(true) bool actif,
  }) = _JournalComptable;

  factory JournalComptable.fromJson(Map<String, dynamic> json) =>
      _$JournalComptableFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_comptable.freezed.dart';
part 'budget_comptable.g.dart';

@freezed
abstract class BudgetComptable with _$BudgetComptable {
  const factory BudgetComptable({
    required String id,
    required int exercice,
    String? idAssembleeLocale,
    String? idCentreAnalytique,
    String? idTiersBailleur,
    String? libelle,
    @Default(false) bool estVerrouille,
  }) = _BudgetComptable;

  factory BudgetComptable.fromJson(Map<String, dynamic> json) =>
      _$BudgetComptableFromJson(json);
}

@freezed
abstract class LigneBudgetComptable with _$LigneBudgetComptable {
  const factory LigneBudgetComptable({
    required String id,
    required String idBudget,
    required String idCompteComptable,
    required double montantPrevu,
    double? montantRevu,
  }) = _LigneBudgetComptable;

  factory LigneBudgetComptable.fromJson(Map<String, dynamic> json) =>
      _$LigneBudgetComptableFromJson(json);
}

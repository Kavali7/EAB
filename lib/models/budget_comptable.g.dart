// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_comptable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetComptable _$BudgetComptableFromJson(Map<String, dynamic> json) =>
    _BudgetComptable(
      id: json['id'] as String,
      exercice: (json['exercice'] as num).toInt(),
      idAssembleeLocale: json['idAssembleeLocale'] as String?,
      idCentreAnalytique: json['idCentreAnalytique'] as String?,
      idTiersBailleur: json['idTiersBailleur'] as String?,
      libelle: json['libelle'] as String?,
      estVerrouille: json['estVerrouille'] as bool? ?? false,
    );

Map<String, dynamic> _$BudgetComptableToJson(_BudgetComptable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exercice': instance.exercice,
      'idAssembleeLocale': instance.idAssembleeLocale,
      'idCentreAnalytique': instance.idCentreAnalytique,
      'idTiersBailleur': instance.idTiersBailleur,
      'libelle': instance.libelle,
      'estVerrouille': instance.estVerrouille,
    };

_LigneBudgetComptable _$LigneBudgetComptableFromJson(
  Map<String, dynamic> json,
) => _LigneBudgetComptable(
  id: json['id'] as String,
  idBudget: json['idBudget'] as String,
  idCompteComptable: json['idCompteComptable'] as String,
  montantPrevu: (json['montantPrevu'] as num).toDouble(),
  montantRevu: (json['montantRevu'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LigneBudgetComptableToJson(
  _LigneBudgetComptable instance,
) => <String, dynamic>{
  'id': instance.id,
  'idBudget': instance.idBudget,
  'idCompteComptable': instance.idCompteComptable,
  'montantPrevu': instance.montantPrevu,
  'montantRevu': instance.montantRevu,
};

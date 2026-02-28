// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercice_comptable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciceComptable _$ExerciceComptableFromJson(Map<String, dynamic> json) =>
    _ExerciceComptable(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      annee: (json['annee'] as num).toInt(),
      dateDebut: DateTime.parse(json['dateDebut'] as String),
      dateFin: DateTime.parse(json['dateFin'] as String),
      libelle: json['libelle'] as String?,
      statut:
          $enumDecodeNullable(_$StatutExerciceEnumMap, json['statut']) ??
          StatutExercice.brouillon,
      estOuvert: json['estOuvert'] as bool? ?? false,
      estCloture: json['estCloture'] as bool? ?? false,
      cloturePar: json['cloturePar'] as String?,
      clotureAt: json['clotureAt'] == null
          ? null
          : DateTime.parse(json['clotureAt'] as String),
      openingEntryId: json['openingEntryId'] as String?,
      closingEntryId: json['closingEntryId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ExerciceComptableToJson(_ExerciceComptable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organizationId': instance.organizationId,
      'annee': instance.annee,
      'dateDebut': instance.dateDebut.toIso8601String(),
      'dateFin': instance.dateFin.toIso8601String(),
      'libelle': instance.libelle,
      'statut': _$StatutExerciceEnumMap[instance.statut]!,
      'estOuvert': instance.estOuvert,
      'estCloture': instance.estCloture,
      'cloturePar': instance.cloturePar,
      'clotureAt': instance.clotureAt?.toIso8601String(),
      'openingEntryId': instance.openingEntryId,
      'closingEntryId': instance.closingEntryId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$StatutExerciceEnumMap = {
  StatutExercice.brouillon: 'brouillon',
  StatutExercice.ouvert: 'ouvert',
  StatutExercice.cloture: 'cloture',
};

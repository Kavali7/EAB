import 'package:freezed_annotation/freezed_annotation.dart';

import 'compta_enums.dart';

part 'exercice_comptable.freezed.dart';
part 'exercice_comptable.g.dart';

@freezed
abstract class ExerciceComptable with _$ExerciceComptable {
  const factory ExerciceComptable({
    required String id,
    required String organizationId,
    required int annee,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? libelle,
    @Default(StatutExercice.brouillon) StatutExercice statut,
    // Legacy booleans — conservés pour compatibilité
    @Default(false) bool estOuvert,
    @Default(false) bool estCloture,
    // Clôture
    String? cloturePar,
    DateTime? clotureAt,
    // Écritures système
    String? openingEntryId,
    String? closingEntryId,
    // Métadonnées
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExerciceComptable;

  factory ExerciceComptable.fromJson(Map<String, dynamic> json) =>
      _$ExerciceComptableFromJson(json);
}

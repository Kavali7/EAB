import 'package:freezed_annotation/freezed_annotation.dart';

part 'immobilisation_comptable.freezed.dart';
part 'immobilisation_comptable.g.dart';

enum TypeImmobilisation {
  terrain,
  batiment,
  mobilier,
  materielInformatique,
  materielSono,
  vehicule,
  autre,
}

@freezed
abstract class ImmobilisationComptable with _$ImmobilisationComptable {
  const factory ImmobilisationComptable({
    required String id,
    required String libelle,
    required TypeImmobilisation type,
    required DateTime dateAcquisition,
    required double valeurAcquisition,
    double? valeurResiduelle,
    required int dureeUtiliteEnAnnees,
    required String idCompteImmobilisation,
    String? idCompteAmortissement,
    String? idCompteDotation,
    String? idAssembleeLocale,
    String? idCentreAnalytique,
    @Default(false) bool estSortie,
    DateTime? dateSortie,
    double? valeurCession,
  }) = _ImmobilisationComptable;

  factory ImmobilisationComptable.fromJson(Map<String, dynamic> json) =>
      _$ImmobilisationComptableFromJson(json);
}

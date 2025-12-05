// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'immobilisation_comptable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImmobilisationComptable _$ImmobilisationComptableFromJson(
  Map<String, dynamic> json,
) => _ImmobilisationComptable(
  id: json['id'] as String,
  libelle: json['libelle'] as String,
  type: $enumDecode(_$TypeImmobilisationEnumMap, json['type']),
  dateAcquisition: DateTime.parse(json['dateAcquisition'] as String),
  valeurAcquisition: (json['valeurAcquisition'] as num).toDouble(),
  valeurResiduelle: (json['valeurResiduelle'] as num?)?.toDouble(),
  dureeUtiliteEnAnnees: (json['dureeUtiliteEnAnnees'] as num).toInt(),
  idCompteImmobilisation: json['idCompteImmobilisation'] as String,
  idCompteAmortissement: json['idCompteAmortissement'] as String?,
  idCompteDotation: json['idCompteDotation'] as String?,
  idAssembleeLocale: json['idAssembleeLocale'] as String?,
  idCentreAnalytique: json['idCentreAnalytique'] as String?,
  estSortie: json['estSortie'] as bool? ?? false,
  dateSortie: json['dateSortie'] == null
      ? null
      : DateTime.parse(json['dateSortie'] as String),
  valeurCession: (json['valeurCession'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ImmobilisationComptableToJson(
  _ImmobilisationComptable instance,
) => <String, dynamic>{
  'id': instance.id,
  'libelle': instance.libelle,
  'type': _$TypeImmobilisationEnumMap[instance.type]!,
  'dateAcquisition': instance.dateAcquisition.toIso8601String(),
  'valeurAcquisition': instance.valeurAcquisition,
  'valeurResiduelle': instance.valeurResiduelle,
  'dureeUtiliteEnAnnees': instance.dureeUtiliteEnAnnees,
  'idCompteImmobilisation': instance.idCompteImmobilisation,
  'idCompteAmortissement': instance.idCompteAmortissement,
  'idCompteDotation': instance.idCompteDotation,
  'idAssembleeLocale': instance.idAssembleeLocale,
  'idCentreAnalytique': instance.idCentreAnalytique,
  'estSortie': instance.estSortie,
  'dateSortie': instance.dateSortie?.toIso8601String(),
  'valeurCession': instance.valeurCession,
};

const _$TypeImmobilisationEnumMap = {
  TypeImmobilisation.terrain: 'terrain',
  TypeImmobilisation.batiment: 'batiment',
  TypeImmobilisation.mobilier: 'mobilier',
  TypeImmobilisation.materielInformatique: 'materielInformatique',
  TypeImmobilisation.materielSono: 'materielSono',
  TypeImmobilisation.vehicule: 'vehicule',
  TypeImmobilisation.autre: 'autre',
};

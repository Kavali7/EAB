// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ecriture_comptable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LigneEcritureComptable _$LigneEcritureComptableFromJson(
  Map<String, dynamic> json,
) => _LigneEcritureComptable(
  id: json['id'] as String,
  idCompteComptable: json['idCompteComptable'] as String,
  debit: (json['debit'] as num?)?.toDouble(),
  credit: (json['credit'] as num?)?.toDouble(),
  idCentreAnalytique: json['idCentreAnalytique'] as String?,
  idTiers: json['idTiers'] as String?,
  modePaiement: $enumDecodeNullable(
    _$ModePaiementEnumMap,
    json['modePaiement'],
  ),
  libelle: json['libelle'] as String?,
);

Map<String, dynamic> _$LigneEcritureComptableToJson(
  _LigneEcritureComptable instance,
) => <String, dynamic>{
  'id': instance.id,
  'idCompteComptable': instance.idCompteComptable,
  'debit': instance.debit,
  'credit': instance.credit,
  'idCentreAnalytique': instance.idCentreAnalytique,
  'idTiers': instance.idTiers,
  'modePaiement': _$ModePaiementEnumMap[instance.modePaiement],
  'libelle': instance.libelle,
};

const _$ModePaiementEnumMap = {
  ModePaiement.especes: 'especes',
  ModePaiement.cheque: 'cheque',
  ModePaiement.virementBancaire: 'virementBancaire',
  ModePaiement.mobileMoney: 'mobileMoney',
  ModePaiement.microfinance: 'microfinance',
  ModePaiement.autre: 'autre',
};

_EcritureComptable _$EcritureComptableFromJson(
  Map<String, dynamic> json,
) => _EcritureComptable(
  id: json['id'] as String,
  date: DateTime.parse(json['date'] as String),
  idJournal: json['idJournal'] as String,
  referencePiece: json['referencePiece'] as String?,
  libelle: json['libelle'] as String,
  lignes: (json['lignes'] as List<dynamic>)
      .map((e) => LigneEcritureComptable.fromJson(e as Map<String, dynamic>))
      .toList(),
  idAssembleeLocale: json['idAssembleeLocale'] as String?,
  idCentreAnalytiquePrincipal: json['idCentreAnalytiquePrincipal'] as String?,
);

Map<String, dynamic> _$EcritureComptableToJson(_EcritureComptable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'idJournal': instance.idJournal,
      'referencePiece': instance.referencePiece,
      'libelle': instance.libelle,
      'lignes': instance.lignes,
      'idAssembleeLocale': instance.idAssembleeLocale,
      'idCentreAnalytiquePrincipal': instance.idCentreAnalytiquePrincipal,
    };

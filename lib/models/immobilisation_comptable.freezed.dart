// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'immobilisation_comptable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImmobilisationComptable {

 String get id; String get libelle; TypeImmobilisation get type; DateTime get dateAcquisition; double get valeurAcquisition; double? get valeurResiduelle; int get dureeUtiliteEnAnnees; String get idCompteImmobilisation; String? get idCompteAmortissement; String? get idCompteDotation; String? get idAssembleeLocale; String? get idCentreAnalytique; bool get estSortie; DateTime? get dateSortie; double? get valeurCession;
/// Create a copy of ImmobilisationComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImmobilisationComptableCopyWith<ImmobilisationComptable> get copyWith => _$ImmobilisationComptableCopyWithImpl<ImmobilisationComptable>(this as ImmobilisationComptable, _$identity);

  /// Serializes this ImmobilisationComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImmobilisationComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.type, type) || other.type == type)&&(identical(other.dateAcquisition, dateAcquisition) || other.dateAcquisition == dateAcquisition)&&(identical(other.valeurAcquisition, valeurAcquisition) || other.valeurAcquisition == valeurAcquisition)&&(identical(other.valeurResiduelle, valeurResiduelle) || other.valeurResiduelle == valeurResiduelle)&&(identical(other.dureeUtiliteEnAnnees, dureeUtiliteEnAnnees) || other.dureeUtiliteEnAnnees == dureeUtiliteEnAnnees)&&(identical(other.idCompteImmobilisation, idCompteImmobilisation) || other.idCompteImmobilisation == idCompteImmobilisation)&&(identical(other.idCompteAmortissement, idCompteAmortissement) || other.idCompteAmortissement == idCompteAmortissement)&&(identical(other.idCompteDotation, idCompteDotation) || other.idCompteDotation == idCompteDotation)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idCentreAnalytique, idCentreAnalytique) || other.idCentreAnalytique == idCentreAnalytique)&&(identical(other.estSortie, estSortie) || other.estSortie == estSortie)&&(identical(other.dateSortie, dateSortie) || other.dateSortie == dateSortie)&&(identical(other.valeurCession, valeurCession) || other.valeurCession == valeurCession));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle,type,dateAcquisition,valeurAcquisition,valeurResiduelle,dureeUtiliteEnAnnees,idCompteImmobilisation,idCompteAmortissement,idCompteDotation,idAssembleeLocale,idCentreAnalytique,estSortie,dateSortie,valeurCession);

@override
String toString() {
  return 'ImmobilisationComptable(id: $id, libelle: $libelle, type: $type, dateAcquisition: $dateAcquisition, valeurAcquisition: $valeurAcquisition, valeurResiduelle: $valeurResiduelle, dureeUtiliteEnAnnees: $dureeUtiliteEnAnnees, idCompteImmobilisation: $idCompteImmobilisation, idCompteAmortissement: $idCompteAmortissement, idCompteDotation: $idCompteDotation, idAssembleeLocale: $idAssembleeLocale, idCentreAnalytique: $idCentreAnalytique, estSortie: $estSortie, dateSortie: $dateSortie, valeurCession: $valeurCession)';
}


}

/// @nodoc
abstract mixin class $ImmobilisationComptableCopyWith<$Res>  {
  factory $ImmobilisationComptableCopyWith(ImmobilisationComptable value, $Res Function(ImmobilisationComptable) _then) = _$ImmobilisationComptableCopyWithImpl;
@useResult
$Res call({
 String id, String libelle, TypeImmobilisation type, DateTime dateAcquisition, double valeurAcquisition, double? valeurResiduelle, int dureeUtiliteEnAnnees, String idCompteImmobilisation, String? idCompteAmortissement, String? idCompteDotation, String? idAssembleeLocale, String? idCentreAnalytique, bool estSortie, DateTime? dateSortie, double? valeurCession
});




}
/// @nodoc
class _$ImmobilisationComptableCopyWithImpl<$Res>
    implements $ImmobilisationComptableCopyWith<$Res> {
  _$ImmobilisationComptableCopyWithImpl(this._self, this._then);

  final ImmobilisationComptable _self;
  final $Res Function(ImmobilisationComptable) _then;

/// Create a copy of ImmobilisationComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? libelle = null,Object? type = null,Object? dateAcquisition = null,Object? valeurAcquisition = null,Object? valeurResiduelle = freezed,Object? dureeUtiliteEnAnnees = null,Object? idCompteImmobilisation = null,Object? idCompteAmortissement = freezed,Object? idCompteDotation = freezed,Object? idAssembleeLocale = freezed,Object? idCentreAnalytique = freezed,Object? estSortie = null,Object? dateSortie = freezed,Object? valeurCession = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeImmobilisation,dateAcquisition: null == dateAcquisition ? _self.dateAcquisition : dateAcquisition // ignore: cast_nullable_to_non_nullable
as DateTime,valeurAcquisition: null == valeurAcquisition ? _self.valeurAcquisition : valeurAcquisition // ignore: cast_nullable_to_non_nullable
as double,valeurResiduelle: freezed == valeurResiduelle ? _self.valeurResiduelle : valeurResiduelle // ignore: cast_nullable_to_non_nullable
as double?,dureeUtiliteEnAnnees: null == dureeUtiliteEnAnnees ? _self.dureeUtiliteEnAnnees : dureeUtiliteEnAnnees // ignore: cast_nullable_to_non_nullable
as int,idCompteImmobilisation: null == idCompteImmobilisation ? _self.idCompteImmobilisation : idCompteImmobilisation // ignore: cast_nullable_to_non_nullable
as String,idCompteAmortissement: freezed == idCompteAmortissement ? _self.idCompteAmortissement : idCompteAmortissement // ignore: cast_nullable_to_non_nullable
as String?,idCompteDotation: freezed == idCompteDotation ? _self.idCompteDotation : idCompteDotation // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idCentreAnalytique: freezed == idCentreAnalytique ? _self.idCentreAnalytique : idCentreAnalytique // ignore: cast_nullable_to_non_nullable
as String?,estSortie: null == estSortie ? _self.estSortie : estSortie // ignore: cast_nullable_to_non_nullable
as bool,dateSortie: freezed == dateSortie ? _self.dateSortie : dateSortie // ignore: cast_nullable_to_non_nullable
as DateTime?,valeurCession: freezed == valeurCession ? _self.valeurCession : valeurCession // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImmobilisationComptable].
extension ImmobilisationComptablePatterns on ImmobilisationComptable {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImmobilisationComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImmobilisationComptable() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImmobilisationComptable value)  $default,){
final _that = this;
switch (_that) {
case _ImmobilisationComptable():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImmobilisationComptable value)?  $default,){
final _that = this;
switch (_that) {
case _ImmobilisationComptable() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String libelle,  TypeImmobilisation type,  DateTime dateAcquisition,  double valeurAcquisition,  double? valeurResiduelle,  int dureeUtiliteEnAnnees,  String idCompteImmobilisation,  String? idCompteAmortissement,  String? idCompteDotation,  String? idAssembleeLocale,  String? idCentreAnalytique,  bool estSortie,  DateTime? dateSortie,  double? valeurCession)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImmobilisationComptable() when $default != null:
return $default(_that.id,_that.libelle,_that.type,_that.dateAcquisition,_that.valeurAcquisition,_that.valeurResiduelle,_that.dureeUtiliteEnAnnees,_that.idCompteImmobilisation,_that.idCompteAmortissement,_that.idCompteDotation,_that.idAssembleeLocale,_that.idCentreAnalytique,_that.estSortie,_that.dateSortie,_that.valeurCession);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String libelle,  TypeImmobilisation type,  DateTime dateAcquisition,  double valeurAcquisition,  double? valeurResiduelle,  int dureeUtiliteEnAnnees,  String idCompteImmobilisation,  String? idCompteAmortissement,  String? idCompteDotation,  String? idAssembleeLocale,  String? idCentreAnalytique,  bool estSortie,  DateTime? dateSortie,  double? valeurCession)  $default,) {final _that = this;
switch (_that) {
case _ImmobilisationComptable():
return $default(_that.id,_that.libelle,_that.type,_that.dateAcquisition,_that.valeurAcquisition,_that.valeurResiduelle,_that.dureeUtiliteEnAnnees,_that.idCompteImmobilisation,_that.idCompteAmortissement,_that.idCompteDotation,_that.idAssembleeLocale,_that.idCentreAnalytique,_that.estSortie,_that.dateSortie,_that.valeurCession);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String libelle,  TypeImmobilisation type,  DateTime dateAcquisition,  double valeurAcquisition,  double? valeurResiduelle,  int dureeUtiliteEnAnnees,  String idCompteImmobilisation,  String? idCompteAmortissement,  String? idCompteDotation,  String? idAssembleeLocale,  String? idCentreAnalytique,  bool estSortie,  DateTime? dateSortie,  double? valeurCession)?  $default,) {final _that = this;
switch (_that) {
case _ImmobilisationComptable() when $default != null:
return $default(_that.id,_that.libelle,_that.type,_that.dateAcquisition,_that.valeurAcquisition,_that.valeurResiduelle,_that.dureeUtiliteEnAnnees,_that.idCompteImmobilisation,_that.idCompteAmortissement,_that.idCompteDotation,_that.idAssembleeLocale,_that.idCentreAnalytique,_that.estSortie,_that.dateSortie,_that.valeurCession);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImmobilisationComptable implements ImmobilisationComptable {
  const _ImmobilisationComptable({required this.id, required this.libelle, required this.type, required this.dateAcquisition, required this.valeurAcquisition, this.valeurResiduelle, required this.dureeUtiliteEnAnnees, required this.idCompteImmobilisation, this.idCompteAmortissement, this.idCompteDotation, this.idAssembleeLocale, this.idCentreAnalytique, this.estSortie = false, this.dateSortie, this.valeurCession});
  factory _ImmobilisationComptable.fromJson(Map<String, dynamic> json) => _$ImmobilisationComptableFromJson(json);

@override final  String id;
@override final  String libelle;
@override final  TypeImmobilisation type;
@override final  DateTime dateAcquisition;
@override final  double valeurAcquisition;
@override final  double? valeurResiduelle;
@override final  int dureeUtiliteEnAnnees;
@override final  String idCompteImmobilisation;
@override final  String? idCompteAmortissement;
@override final  String? idCompteDotation;
@override final  String? idAssembleeLocale;
@override final  String? idCentreAnalytique;
@override@JsonKey() final  bool estSortie;
@override final  DateTime? dateSortie;
@override final  double? valeurCession;

/// Create a copy of ImmobilisationComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImmobilisationComptableCopyWith<_ImmobilisationComptable> get copyWith => __$ImmobilisationComptableCopyWithImpl<_ImmobilisationComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImmobilisationComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImmobilisationComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.type, type) || other.type == type)&&(identical(other.dateAcquisition, dateAcquisition) || other.dateAcquisition == dateAcquisition)&&(identical(other.valeurAcquisition, valeurAcquisition) || other.valeurAcquisition == valeurAcquisition)&&(identical(other.valeurResiduelle, valeurResiduelle) || other.valeurResiduelle == valeurResiduelle)&&(identical(other.dureeUtiliteEnAnnees, dureeUtiliteEnAnnees) || other.dureeUtiliteEnAnnees == dureeUtiliteEnAnnees)&&(identical(other.idCompteImmobilisation, idCompteImmobilisation) || other.idCompteImmobilisation == idCompteImmobilisation)&&(identical(other.idCompteAmortissement, idCompteAmortissement) || other.idCompteAmortissement == idCompteAmortissement)&&(identical(other.idCompteDotation, idCompteDotation) || other.idCompteDotation == idCompteDotation)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idCentreAnalytique, idCentreAnalytique) || other.idCentreAnalytique == idCentreAnalytique)&&(identical(other.estSortie, estSortie) || other.estSortie == estSortie)&&(identical(other.dateSortie, dateSortie) || other.dateSortie == dateSortie)&&(identical(other.valeurCession, valeurCession) || other.valeurCession == valeurCession));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,libelle,type,dateAcquisition,valeurAcquisition,valeurResiduelle,dureeUtiliteEnAnnees,idCompteImmobilisation,idCompteAmortissement,idCompteDotation,idAssembleeLocale,idCentreAnalytique,estSortie,dateSortie,valeurCession);

@override
String toString() {
  return 'ImmobilisationComptable(id: $id, libelle: $libelle, type: $type, dateAcquisition: $dateAcquisition, valeurAcquisition: $valeurAcquisition, valeurResiduelle: $valeurResiduelle, dureeUtiliteEnAnnees: $dureeUtiliteEnAnnees, idCompteImmobilisation: $idCompteImmobilisation, idCompteAmortissement: $idCompteAmortissement, idCompteDotation: $idCompteDotation, idAssembleeLocale: $idAssembleeLocale, idCentreAnalytique: $idCentreAnalytique, estSortie: $estSortie, dateSortie: $dateSortie, valeurCession: $valeurCession)';
}


}

/// @nodoc
abstract mixin class _$ImmobilisationComptableCopyWith<$Res> implements $ImmobilisationComptableCopyWith<$Res> {
  factory _$ImmobilisationComptableCopyWith(_ImmobilisationComptable value, $Res Function(_ImmobilisationComptable) _then) = __$ImmobilisationComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, String libelle, TypeImmobilisation type, DateTime dateAcquisition, double valeurAcquisition, double? valeurResiduelle, int dureeUtiliteEnAnnees, String idCompteImmobilisation, String? idCompteAmortissement, String? idCompteDotation, String? idAssembleeLocale, String? idCentreAnalytique, bool estSortie, DateTime? dateSortie, double? valeurCession
});




}
/// @nodoc
class __$ImmobilisationComptableCopyWithImpl<$Res>
    implements _$ImmobilisationComptableCopyWith<$Res> {
  __$ImmobilisationComptableCopyWithImpl(this._self, this._then);

  final _ImmobilisationComptable _self;
  final $Res Function(_ImmobilisationComptable) _then;

/// Create a copy of ImmobilisationComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? libelle = null,Object? type = null,Object? dateAcquisition = null,Object? valeurAcquisition = null,Object? valeurResiduelle = freezed,Object? dureeUtiliteEnAnnees = null,Object? idCompteImmobilisation = null,Object? idCompteAmortissement = freezed,Object? idCompteDotation = freezed,Object? idAssembleeLocale = freezed,Object? idCentreAnalytique = freezed,Object? estSortie = null,Object? dateSortie = freezed,Object? valeurCession = freezed,}) {
  return _then(_ImmobilisationComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeImmobilisation,dateAcquisition: null == dateAcquisition ? _self.dateAcquisition : dateAcquisition // ignore: cast_nullable_to_non_nullable
as DateTime,valeurAcquisition: null == valeurAcquisition ? _self.valeurAcquisition : valeurAcquisition // ignore: cast_nullable_to_non_nullable
as double,valeurResiduelle: freezed == valeurResiduelle ? _self.valeurResiduelle : valeurResiduelle // ignore: cast_nullable_to_non_nullable
as double?,dureeUtiliteEnAnnees: null == dureeUtiliteEnAnnees ? _self.dureeUtiliteEnAnnees : dureeUtiliteEnAnnees // ignore: cast_nullable_to_non_nullable
as int,idCompteImmobilisation: null == idCompteImmobilisation ? _self.idCompteImmobilisation : idCompteImmobilisation // ignore: cast_nullable_to_non_nullable
as String,idCompteAmortissement: freezed == idCompteAmortissement ? _self.idCompteAmortissement : idCompteAmortissement // ignore: cast_nullable_to_non_nullable
as String?,idCompteDotation: freezed == idCompteDotation ? _self.idCompteDotation : idCompteDotation // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idCentreAnalytique: freezed == idCentreAnalytique ? _self.idCentreAnalytique : idCentreAnalytique // ignore: cast_nullable_to_non_nullable
as String?,estSortie: null == estSortie ? _self.estSortie : estSortie // ignore: cast_nullable_to_non_nullable
as bool,dateSortie: freezed == dateSortie ? _self.dateSortie : dateSortie // ignore: cast_nullable_to_non_nullable
as DateTime?,valeurCession: freezed == valeurCession ? _self.valeurCession : valeurCession // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on

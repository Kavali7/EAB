// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rapport_mensuel_eab.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatsMembresMensuelles {

// Effectif global
 int get totalMembresActifs; int get totalHommesActifs; int get totalFemmesActives; int get totalEnfants;// 0-14 ans
// Officiers
 int get totalOfficiers;// Vulnerables
 int get totalOrphelins; int get totalVeufsVeuves; int get totalHandicapes; int get totalTroisiemeAge;// Mouvements du mois
 int get nouveauxConvertis; int get nouveauxBaptises; int get nouvellesMainsAssociation; int get mariagesCheres; int get departAssemblage;// departs / abandons / transferts
 int get deces;
/// Create a copy of StatsMembresMensuelles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsMembresMensuellesCopyWith<StatsMembresMensuelles> get copyWith => _$StatsMembresMensuellesCopyWithImpl<StatsMembresMensuelles>(this as StatsMembresMensuelles, _$identity);

  /// Serializes this StatsMembresMensuelles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsMembresMensuelles&&(identical(other.totalMembresActifs, totalMembresActifs) || other.totalMembresActifs == totalMembresActifs)&&(identical(other.totalHommesActifs, totalHommesActifs) || other.totalHommesActifs == totalHommesActifs)&&(identical(other.totalFemmesActives, totalFemmesActives) || other.totalFemmesActives == totalFemmesActives)&&(identical(other.totalEnfants, totalEnfants) || other.totalEnfants == totalEnfants)&&(identical(other.totalOfficiers, totalOfficiers) || other.totalOfficiers == totalOfficiers)&&(identical(other.totalOrphelins, totalOrphelins) || other.totalOrphelins == totalOrphelins)&&(identical(other.totalVeufsVeuves, totalVeufsVeuves) || other.totalVeufsVeuves == totalVeufsVeuves)&&(identical(other.totalHandicapes, totalHandicapes) || other.totalHandicapes == totalHandicapes)&&(identical(other.totalTroisiemeAge, totalTroisiemeAge) || other.totalTroisiemeAge == totalTroisiemeAge)&&(identical(other.nouveauxConvertis, nouveauxConvertis) || other.nouveauxConvertis == nouveauxConvertis)&&(identical(other.nouveauxBaptises, nouveauxBaptises) || other.nouveauxBaptises == nouveauxBaptises)&&(identical(other.nouvellesMainsAssociation, nouvellesMainsAssociation) || other.nouvellesMainsAssociation == nouvellesMainsAssociation)&&(identical(other.mariagesCheres, mariagesCheres) || other.mariagesCheres == mariagesCheres)&&(identical(other.departAssemblage, departAssemblage) || other.departAssemblage == departAssemblage)&&(identical(other.deces, deces) || other.deces == deces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalMembresActifs,totalHommesActifs,totalFemmesActives,totalEnfants,totalOfficiers,totalOrphelins,totalVeufsVeuves,totalHandicapes,totalTroisiemeAge,nouveauxConvertis,nouveauxBaptises,nouvellesMainsAssociation,mariagesCheres,departAssemblage,deces);

@override
String toString() {
  return 'StatsMembresMensuelles(totalMembresActifs: $totalMembresActifs, totalHommesActifs: $totalHommesActifs, totalFemmesActives: $totalFemmesActives, totalEnfants: $totalEnfants, totalOfficiers: $totalOfficiers, totalOrphelins: $totalOrphelins, totalVeufsVeuves: $totalVeufsVeuves, totalHandicapes: $totalHandicapes, totalTroisiemeAge: $totalTroisiemeAge, nouveauxConvertis: $nouveauxConvertis, nouveauxBaptises: $nouveauxBaptises, nouvellesMainsAssociation: $nouvellesMainsAssociation, mariagesCheres: $mariagesCheres, departAssemblage: $departAssemblage, deces: $deces)';
}


}

/// @nodoc
abstract mixin class $StatsMembresMensuellesCopyWith<$Res>  {
  factory $StatsMembresMensuellesCopyWith(StatsMembresMensuelles value, $Res Function(StatsMembresMensuelles) _then) = _$StatsMembresMensuellesCopyWithImpl;
@useResult
$Res call({
 int totalMembresActifs, int totalHommesActifs, int totalFemmesActives, int totalEnfants, int totalOfficiers, int totalOrphelins, int totalVeufsVeuves, int totalHandicapes, int totalTroisiemeAge, int nouveauxConvertis, int nouveauxBaptises, int nouvellesMainsAssociation, int mariagesCheres, int departAssemblage, int deces
});




}
/// @nodoc
class _$StatsMembresMensuellesCopyWithImpl<$Res>
    implements $StatsMembresMensuellesCopyWith<$Res> {
  _$StatsMembresMensuellesCopyWithImpl(this._self, this._then);

  final StatsMembresMensuelles _self;
  final $Res Function(StatsMembresMensuelles) _then;

/// Create a copy of StatsMembresMensuelles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalMembresActifs = null,Object? totalHommesActifs = null,Object? totalFemmesActives = null,Object? totalEnfants = null,Object? totalOfficiers = null,Object? totalOrphelins = null,Object? totalVeufsVeuves = null,Object? totalHandicapes = null,Object? totalTroisiemeAge = null,Object? nouveauxConvertis = null,Object? nouveauxBaptises = null,Object? nouvellesMainsAssociation = null,Object? mariagesCheres = null,Object? departAssemblage = null,Object? deces = null,}) {
  return _then(_self.copyWith(
totalMembresActifs: null == totalMembresActifs ? _self.totalMembresActifs : totalMembresActifs // ignore: cast_nullable_to_non_nullable
as int,totalHommesActifs: null == totalHommesActifs ? _self.totalHommesActifs : totalHommesActifs // ignore: cast_nullable_to_non_nullable
as int,totalFemmesActives: null == totalFemmesActives ? _self.totalFemmesActives : totalFemmesActives // ignore: cast_nullable_to_non_nullable
as int,totalEnfants: null == totalEnfants ? _self.totalEnfants : totalEnfants // ignore: cast_nullable_to_non_nullable
as int,totalOfficiers: null == totalOfficiers ? _self.totalOfficiers : totalOfficiers // ignore: cast_nullable_to_non_nullable
as int,totalOrphelins: null == totalOrphelins ? _self.totalOrphelins : totalOrphelins // ignore: cast_nullable_to_non_nullable
as int,totalVeufsVeuves: null == totalVeufsVeuves ? _self.totalVeufsVeuves : totalVeufsVeuves // ignore: cast_nullable_to_non_nullable
as int,totalHandicapes: null == totalHandicapes ? _self.totalHandicapes : totalHandicapes // ignore: cast_nullable_to_non_nullable
as int,totalTroisiemeAge: null == totalTroisiemeAge ? _self.totalTroisiemeAge : totalTroisiemeAge // ignore: cast_nullable_to_non_nullable
as int,nouveauxConvertis: null == nouveauxConvertis ? _self.nouveauxConvertis : nouveauxConvertis // ignore: cast_nullable_to_non_nullable
as int,nouveauxBaptises: null == nouveauxBaptises ? _self.nouveauxBaptises : nouveauxBaptises // ignore: cast_nullable_to_non_nullable
as int,nouvellesMainsAssociation: null == nouvellesMainsAssociation ? _self.nouvellesMainsAssociation : nouvellesMainsAssociation // ignore: cast_nullable_to_non_nullable
as int,mariagesCheres: null == mariagesCheres ? _self.mariagesCheres : mariagesCheres // ignore: cast_nullable_to_non_nullable
as int,departAssemblage: null == departAssemblage ? _self.departAssemblage : departAssemblage // ignore: cast_nullable_to_non_nullable
as int,deces: null == deces ? _self.deces : deces // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsMembresMensuelles].
extension StatsMembresMensuellesPatterns on StatsMembresMensuelles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsMembresMensuelles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsMembresMensuelles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsMembresMensuelles value)  $default,){
final _that = this;
switch (_that) {
case _StatsMembresMensuelles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsMembresMensuelles value)?  $default,){
final _that = this;
switch (_that) {
case _StatsMembresMensuelles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalMembresActifs,  int totalHommesActifs,  int totalFemmesActives,  int totalEnfants,  int totalOfficiers,  int totalOrphelins,  int totalVeufsVeuves,  int totalHandicapes,  int totalTroisiemeAge,  int nouveauxConvertis,  int nouveauxBaptises,  int nouvellesMainsAssociation,  int mariagesCheres,  int departAssemblage,  int deces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsMembresMensuelles() when $default != null:
return $default(_that.totalMembresActifs,_that.totalHommesActifs,_that.totalFemmesActives,_that.totalEnfants,_that.totalOfficiers,_that.totalOrphelins,_that.totalVeufsVeuves,_that.totalHandicapes,_that.totalTroisiemeAge,_that.nouveauxConvertis,_that.nouveauxBaptises,_that.nouvellesMainsAssociation,_that.mariagesCheres,_that.departAssemblage,_that.deces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalMembresActifs,  int totalHommesActifs,  int totalFemmesActives,  int totalEnfants,  int totalOfficiers,  int totalOrphelins,  int totalVeufsVeuves,  int totalHandicapes,  int totalTroisiemeAge,  int nouveauxConvertis,  int nouveauxBaptises,  int nouvellesMainsAssociation,  int mariagesCheres,  int departAssemblage,  int deces)  $default,) {final _that = this;
switch (_that) {
case _StatsMembresMensuelles():
return $default(_that.totalMembresActifs,_that.totalHommesActifs,_that.totalFemmesActives,_that.totalEnfants,_that.totalOfficiers,_that.totalOrphelins,_that.totalVeufsVeuves,_that.totalHandicapes,_that.totalTroisiemeAge,_that.nouveauxConvertis,_that.nouveauxBaptises,_that.nouvellesMainsAssociation,_that.mariagesCheres,_that.departAssemblage,_that.deces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalMembresActifs,  int totalHommesActifs,  int totalFemmesActives,  int totalEnfants,  int totalOfficiers,  int totalOrphelins,  int totalVeufsVeuves,  int totalHandicapes,  int totalTroisiemeAge,  int nouveauxConvertis,  int nouveauxBaptises,  int nouvellesMainsAssociation,  int mariagesCheres,  int departAssemblage,  int deces)?  $default,) {final _that = this;
switch (_that) {
case _StatsMembresMensuelles() when $default != null:
return $default(_that.totalMembresActifs,_that.totalHommesActifs,_that.totalFemmesActives,_that.totalEnfants,_that.totalOfficiers,_that.totalOrphelins,_that.totalVeufsVeuves,_that.totalHandicapes,_that.totalTroisiemeAge,_that.nouveauxConvertis,_that.nouveauxBaptises,_that.nouvellesMainsAssociation,_that.mariagesCheres,_that.departAssemblage,_that.deces);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsMembresMensuelles implements StatsMembresMensuelles {
  const _StatsMembresMensuelles({required this.totalMembresActifs, required this.totalHommesActifs, required this.totalFemmesActives, required this.totalEnfants, required this.totalOfficiers, required this.totalOrphelins, required this.totalVeufsVeuves, required this.totalHandicapes, required this.totalTroisiemeAge, required this.nouveauxConvertis, required this.nouveauxBaptises, required this.nouvellesMainsAssociation, required this.mariagesCheres, required this.departAssemblage, required this.deces});
  factory _StatsMembresMensuelles.fromJson(Map<String, dynamic> json) => _$StatsMembresMensuellesFromJson(json);

// Effectif global
@override final  int totalMembresActifs;
@override final  int totalHommesActifs;
@override final  int totalFemmesActives;
@override final  int totalEnfants;
// 0-14 ans
// Officiers
@override final  int totalOfficiers;
// Vulnerables
@override final  int totalOrphelins;
@override final  int totalVeufsVeuves;
@override final  int totalHandicapes;
@override final  int totalTroisiemeAge;
// Mouvements du mois
@override final  int nouveauxConvertis;
@override final  int nouveauxBaptises;
@override final  int nouvellesMainsAssociation;
@override final  int mariagesCheres;
@override final  int departAssemblage;
// departs / abandons / transferts
@override final  int deces;

/// Create a copy of StatsMembresMensuelles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsMembresMensuellesCopyWith<_StatsMembresMensuelles> get copyWith => __$StatsMembresMensuellesCopyWithImpl<_StatsMembresMensuelles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsMembresMensuellesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsMembresMensuelles&&(identical(other.totalMembresActifs, totalMembresActifs) || other.totalMembresActifs == totalMembresActifs)&&(identical(other.totalHommesActifs, totalHommesActifs) || other.totalHommesActifs == totalHommesActifs)&&(identical(other.totalFemmesActives, totalFemmesActives) || other.totalFemmesActives == totalFemmesActives)&&(identical(other.totalEnfants, totalEnfants) || other.totalEnfants == totalEnfants)&&(identical(other.totalOfficiers, totalOfficiers) || other.totalOfficiers == totalOfficiers)&&(identical(other.totalOrphelins, totalOrphelins) || other.totalOrphelins == totalOrphelins)&&(identical(other.totalVeufsVeuves, totalVeufsVeuves) || other.totalVeufsVeuves == totalVeufsVeuves)&&(identical(other.totalHandicapes, totalHandicapes) || other.totalHandicapes == totalHandicapes)&&(identical(other.totalTroisiemeAge, totalTroisiemeAge) || other.totalTroisiemeAge == totalTroisiemeAge)&&(identical(other.nouveauxConvertis, nouveauxConvertis) || other.nouveauxConvertis == nouveauxConvertis)&&(identical(other.nouveauxBaptises, nouveauxBaptises) || other.nouveauxBaptises == nouveauxBaptises)&&(identical(other.nouvellesMainsAssociation, nouvellesMainsAssociation) || other.nouvellesMainsAssociation == nouvellesMainsAssociation)&&(identical(other.mariagesCheres, mariagesCheres) || other.mariagesCheres == mariagesCheres)&&(identical(other.departAssemblage, departAssemblage) || other.departAssemblage == departAssemblage)&&(identical(other.deces, deces) || other.deces == deces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalMembresActifs,totalHommesActifs,totalFemmesActives,totalEnfants,totalOfficiers,totalOrphelins,totalVeufsVeuves,totalHandicapes,totalTroisiemeAge,nouveauxConvertis,nouveauxBaptises,nouvellesMainsAssociation,mariagesCheres,departAssemblage,deces);

@override
String toString() {
  return 'StatsMembresMensuelles(totalMembresActifs: $totalMembresActifs, totalHommesActifs: $totalHommesActifs, totalFemmesActives: $totalFemmesActives, totalEnfants: $totalEnfants, totalOfficiers: $totalOfficiers, totalOrphelins: $totalOrphelins, totalVeufsVeuves: $totalVeufsVeuves, totalHandicapes: $totalHandicapes, totalTroisiemeAge: $totalTroisiemeAge, nouveauxConvertis: $nouveauxConvertis, nouveauxBaptises: $nouveauxBaptises, nouvellesMainsAssociation: $nouvellesMainsAssociation, mariagesCheres: $mariagesCheres, departAssemblage: $departAssemblage, deces: $deces)';
}


}

/// @nodoc
abstract mixin class _$StatsMembresMensuellesCopyWith<$Res> implements $StatsMembresMensuellesCopyWith<$Res> {
  factory _$StatsMembresMensuellesCopyWith(_StatsMembresMensuelles value, $Res Function(_StatsMembresMensuelles) _then) = __$StatsMembresMensuellesCopyWithImpl;
@override @useResult
$Res call({
 int totalMembresActifs, int totalHommesActifs, int totalFemmesActives, int totalEnfants, int totalOfficiers, int totalOrphelins, int totalVeufsVeuves, int totalHandicapes, int totalTroisiemeAge, int nouveauxConvertis, int nouveauxBaptises, int nouvellesMainsAssociation, int mariagesCheres, int departAssemblage, int deces
});




}
/// @nodoc
class __$StatsMembresMensuellesCopyWithImpl<$Res>
    implements _$StatsMembresMensuellesCopyWith<$Res> {
  __$StatsMembresMensuellesCopyWithImpl(this._self, this._then);

  final _StatsMembresMensuelles _self;
  final $Res Function(_StatsMembresMensuelles) _then;

/// Create a copy of StatsMembresMensuelles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalMembresActifs = null,Object? totalHommesActifs = null,Object? totalFemmesActives = null,Object? totalEnfants = null,Object? totalOfficiers = null,Object? totalOrphelins = null,Object? totalVeufsVeuves = null,Object? totalHandicapes = null,Object? totalTroisiemeAge = null,Object? nouveauxConvertis = null,Object? nouveauxBaptises = null,Object? nouvellesMainsAssociation = null,Object? mariagesCheres = null,Object? departAssemblage = null,Object? deces = null,}) {
  return _then(_StatsMembresMensuelles(
totalMembresActifs: null == totalMembresActifs ? _self.totalMembresActifs : totalMembresActifs // ignore: cast_nullable_to_non_nullable
as int,totalHommesActifs: null == totalHommesActifs ? _self.totalHommesActifs : totalHommesActifs // ignore: cast_nullable_to_non_nullable
as int,totalFemmesActives: null == totalFemmesActives ? _self.totalFemmesActives : totalFemmesActives // ignore: cast_nullable_to_non_nullable
as int,totalEnfants: null == totalEnfants ? _self.totalEnfants : totalEnfants // ignore: cast_nullable_to_non_nullable
as int,totalOfficiers: null == totalOfficiers ? _self.totalOfficiers : totalOfficiers // ignore: cast_nullable_to_non_nullable
as int,totalOrphelins: null == totalOrphelins ? _self.totalOrphelins : totalOrphelins // ignore: cast_nullable_to_non_nullable
as int,totalVeufsVeuves: null == totalVeufsVeuves ? _self.totalVeufsVeuves : totalVeufsVeuves // ignore: cast_nullable_to_non_nullable
as int,totalHandicapes: null == totalHandicapes ? _self.totalHandicapes : totalHandicapes // ignore: cast_nullable_to_non_nullable
as int,totalTroisiemeAge: null == totalTroisiemeAge ? _self.totalTroisiemeAge : totalTroisiemeAge // ignore: cast_nullable_to_non_nullable
as int,nouveauxConvertis: null == nouveauxConvertis ? _self.nouveauxConvertis : nouveauxConvertis // ignore: cast_nullable_to_non_nullable
as int,nouveauxBaptises: null == nouveauxBaptises ? _self.nouveauxBaptises : nouveauxBaptises // ignore: cast_nullable_to_non_nullable
as int,nouvellesMainsAssociation: null == nouvellesMainsAssociation ? _self.nouvellesMainsAssociation : nouvellesMainsAssociation // ignore: cast_nullable_to_non_nullable
as int,mariagesCheres: null == mariagesCheres ? _self.mariagesCheres : mariagesCheres // ignore: cast_nullable_to_non_nullable
as int,departAssemblage: null == departAssemblage ? _self.departAssemblage : departAssemblage // ignore: cast_nullable_to_non_nullable
as int,deces: null == deces ? _self.deces : deces // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StatsActivitesMensuelles {

// Evangelisations
 int get nbEvangelisationsMasse; int get nbEvangelisationsPorteAPorte; int get totalConversionsHommes; int get totalConversionsFemmes; int get totalConversionsGarcons; int get totalConversionsFilles;// Sainte cene, baptemes, mains d'association, reunions, mariages, visites
 int get nbBaptemes; int get nbMainsAssociation; int get nbSaintesCenes; int get nbReunionsPriere; int get nbMariages; int get nbDisciplines; int get nbVisitesFideles; int get nbVisitesAutorites; int get nbVisitesPartenaires; int get nbVisitesAutresAssemblees;// Ecole du dimanche
 int get nbSeancesEcoleDimanche; int get totalApprenantsHommes; int get totalApprenantsFemmes; int get totalApprenantsGarcons; int get totalApprenantsFilles; int get totalClassesEcoleDimanche; int get totalMoniteursHommes; int get totalMonitricesFemmes;
/// Create a copy of StatsActivitesMensuelles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsActivitesMensuellesCopyWith<StatsActivitesMensuelles> get copyWith => _$StatsActivitesMensuellesCopyWithImpl<StatsActivitesMensuelles>(this as StatsActivitesMensuelles, _$identity);

  /// Serializes this StatsActivitesMensuelles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsActivitesMensuelles&&(identical(other.nbEvangelisationsMasse, nbEvangelisationsMasse) || other.nbEvangelisationsMasse == nbEvangelisationsMasse)&&(identical(other.nbEvangelisationsPorteAPorte, nbEvangelisationsPorteAPorte) || other.nbEvangelisationsPorteAPorte == nbEvangelisationsPorteAPorte)&&(identical(other.totalConversionsHommes, totalConversionsHommes) || other.totalConversionsHommes == totalConversionsHommes)&&(identical(other.totalConversionsFemmes, totalConversionsFemmes) || other.totalConversionsFemmes == totalConversionsFemmes)&&(identical(other.totalConversionsGarcons, totalConversionsGarcons) || other.totalConversionsGarcons == totalConversionsGarcons)&&(identical(other.totalConversionsFilles, totalConversionsFilles) || other.totalConversionsFilles == totalConversionsFilles)&&(identical(other.nbBaptemes, nbBaptemes) || other.nbBaptemes == nbBaptemes)&&(identical(other.nbMainsAssociation, nbMainsAssociation) || other.nbMainsAssociation == nbMainsAssociation)&&(identical(other.nbSaintesCenes, nbSaintesCenes) || other.nbSaintesCenes == nbSaintesCenes)&&(identical(other.nbReunionsPriere, nbReunionsPriere) || other.nbReunionsPriere == nbReunionsPriere)&&(identical(other.nbMariages, nbMariages) || other.nbMariages == nbMariages)&&(identical(other.nbDisciplines, nbDisciplines) || other.nbDisciplines == nbDisciplines)&&(identical(other.nbVisitesFideles, nbVisitesFideles) || other.nbVisitesFideles == nbVisitesFideles)&&(identical(other.nbVisitesAutorites, nbVisitesAutorites) || other.nbVisitesAutorites == nbVisitesAutorites)&&(identical(other.nbVisitesPartenaires, nbVisitesPartenaires) || other.nbVisitesPartenaires == nbVisitesPartenaires)&&(identical(other.nbVisitesAutresAssemblees, nbVisitesAutresAssemblees) || other.nbVisitesAutresAssemblees == nbVisitesAutresAssemblees)&&(identical(other.nbSeancesEcoleDimanche, nbSeancesEcoleDimanche) || other.nbSeancesEcoleDimanche == nbSeancesEcoleDimanche)&&(identical(other.totalApprenantsHommes, totalApprenantsHommes) || other.totalApprenantsHommes == totalApprenantsHommes)&&(identical(other.totalApprenantsFemmes, totalApprenantsFemmes) || other.totalApprenantsFemmes == totalApprenantsFemmes)&&(identical(other.totalApprenantsGarcons, totalApprenantsGarcons) || other.totalApprenantsGarcons == totalApprenantsGarcons)&&(identical(other.totalApprenantsFilles, totalApprenantsFilles) || other.totalApprenantsFilles == totalApprenantsFilles)&&(identical(other.totalClassesEcoleDimanche, totalClassesEcoleDimanche) || other.totalClassesEcoleDimanche == totalClassesEcoleDimanche)&&(identical(other.totalMoniteursHommes, totalMoniteursHommes) || other.totalMoniteursHommes == totalMoniteursHommes)&&(identical(other.totalMonitricesFemmes, totalMonitricesFemmes) || other.totalMonitricesFemmes == totalMonitricesFemmes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,nbEvangelisationsMasse,nbEvangelisationsPorteAPorte,totalConversionsHommes,totalConversionsFemmes,totalConversionsGarcons,totalConversionsFilles,nbBaptemes,nbMainsAssociation,nbSaintesCenes,nbReunionsPriere,nbMariages,nbDisciplines,nbVisitesFideles,nbVisitesAutorites,nbVisitesPartenaires,nbVisitesAutresAssemblees,nbSeancesEcoleDimanche,totalApprenantsHommes,totalApprenantsFemmes,totalApprenantsGarcons,totalApprenantsFilles,totalClassesEcoleDimanche,totalMoniteursHommes,totalMonitricesFemmes]);

@override
String toString() {
  return 'StatsActivitesMensuelles(nbEvangelisationsMasse: $nbEvangelisationsMasse, nbEvangelisationsPorteAPorte: $nbEvangelisationsPorteAPorte, totalConversionsHommes: $totalConversionsHommes, totalConversionsFemmes: $totalConversionsFemmes, totalConversionsGarcons: $totalConversionsGarcons, totalConversionsFilles: $totalConversionsFilles, nbBaptemes: $nbBaptemes, nbMainsAssociation: $nbMainsAssociation, nbSaintesCenes: $nbSaintesCenes, nbReunionsPriere: $nbReunionsPriere, nbMariages: $nbMariages, nbDisciplines: $nbDisciplines, nbVisitesFideles: $nbVisitesFideles, nbVisitesAutorites: $nbVisitesAutorites, nbVisitesPartenaires: $nbVisitesPartenaires, nbVisitesAutresAssemblees: $nbVisitesAutresAssemblees, nbSeancesEcoleDimanche: $nbSeancesEcoleDimanche, totalApprenantsHommes: $totalApprenantsHommes, totalApprenantsFemmes: $totalApprenantsFemmes, totalApprenantsGarcons: $totalApprenantsGarcons, totalApprenantsFilles: $totalApprenantsFilles, totalClassesEcoleDimanche: $totalClassesEcoleDimanche, totalMoniteursHommes: $totalMoniteursHommes, totalMonitricesFemmes: $totalMonitricesFemmes)';
}


}

/// @nodoc
abstract mixin class $StatsActivitesMensuellesCopyWith<$Res>  {
  factory $StatsActivitesMensuellesCopyWith(StatsActivitesMensuelles value, $Res Function(StatsActivitesMensuelles) _then) = _$StatsActivitesMensuellesCopyWithImpl;
@useResult
$Res call({
 int nbEvangelisationsMasse, int nbEvangelisationsPorteAPorte, int totalConversionsHommes, int totalConversionsFemmes, int totalConversionsGarcons, int totalConversionsFilles, int nbBaptemes, int nbMainsAssociation, int nbSaintesCenes, int nbReunionsPriere, int nbMariages, int nbDisciplines, int nbVisitesFideles, int nbVisitesAutorites, int nbVisitesPartenaires, int nbVisitesAutresAssemblees, int nbSeancesEcoleDimanche, int totalApprenantsHommes, int totalApprenantsFemmes, int totalApprenantsGarcons, int totalApprenantsFilles, int totalClassesEcoleDimanche, int totalMoniteursHommes, int totalMonitricesFemmes
});




}
/// @nodoc
class _$StatsActivitesMensuellesCopyWithImpl<$Res>
    implements $StatsActivitesMensuellesCopyWith<$Res> {
  _$StatsActivitesMensuellesCopyWithImpl(this._self, this._then);

  final StatsActivitesMensuelles _self;
  final $Res Function(StatsActivitesMensuelles) _then;

/// Create a copy of StatsActivitesMensuelles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nbEvangelisationsMasse = null,Object? nbEvangelisationsPorteAPorte = null,Object? totalConversionsHommes = null,Object? totalConversionsFemmes = null,Object? totalConversionsGarcons = null,Object? totalConversionsFilles = null,Object? nbBaptemes = null,Object? nbMainsAssociation = null,Object? nbSaintesCenes = null,Object? nbReunionsPriere = null,Object? nbMariages = null,Object? nbDisciplines = null,Object? nbVisitesFideles = null,Object? nbVisitesAutorites = null,Object? nbVisitesPartenaires = null,Object? nbVisitesAutresAssemblees = null,Object? nbSeancesEcoleDimanche = null,Object? totalApprenantsHommes = null,Object? totalApprenantsFemmes = null,Object? totalApprenantsGarcons = null,Object? totalApprenantsFilles = null,Object? totalClassesEcoleDimanche = null,Object? totalMoniteursHommes = null,Object? totalMonitricesFemmes = null,}) {
  return _then(_self.copyWith(
nbEvangelisationsMasse: null == nbEvangelisationsMasse ? _self.nbEvangelisationsMasse : nbEvangelisationsMasse // ignore: cast_nullable_to_non_nullable
as int,nbEvangelisationsPorteAPorte: null == nbEvangelisationsPorteAPorte ? _self.nbEvangelisationsPorteAPorte : nbEvangelisationsPorteAPorte // ignore: cast_nullable_to_non_nullable
as int,totalConversionsHommes: null == totalConversionsHommes ? _self.totalConversionsHommes : totalConversionsHommes // ignore: cast_nullable_to_non_nullable
as int,totalConversionsFemmes: null == totalConversionsFemmes ? _self.totalConversionsFemmes : totalConversionsFemmes // ignore: cast_nullable_to_non_nullable
as int,totalConversionsGarcons: null == totalConversionsGarcons ? _self.totalConversionsGarcons : totalConversionsGarcons // ignore: cast_nullable_to_non_nullable
as int,totalConversionsFilles: null == totalConversionsFilles ? _self.totalConversionsFilles : totalConversionsFilles // ignore: cast_nullable_to_non_nullable
as int,nbBaptemes: null == nbBaptemes ? _self.nbBaptemes : nbBaptemes // ignore: cast_nullable_to_non_nullable
as int,nbMainsAssociation: null == nbMainsAssociation ? _self.nbMainsAssociation : nbMainsAssociation // ignore: cast_nullable_to_non_nullable
as int,nbSaintesCenes: null == nbSaintesCenes ? _self.nbSaintesCenes : nbSaintesCenes // ignore: cast_nullable_to_non_nullable
as int,nbReunionsPriere: null == nbReunionsPriere ? _self.nbReunionsPriere : nbReunionsPriere // ignore: cast_nullable_to_non_nullable
as int,nbMariages: null == nbMariages ? _self.nbMariages : nbMariages // ignore: cast_nullable_to_non_nullable
as int,nbDisciplines: null == nbDisciplines ? _self.nbDisciplines : nbDisciplines // ignore: cast_nullable_to_non_nullable
as int,nbVisitesFideles: null == nbVisitesFideles ? _self.nbVisitesFideles : nbVisitesFideles // ignore: cast_nullable_to_non_nullable
as int,nbVisitesAutorites: null == nbVisitesAutorites ? _self.nbVisitesAutorites : nbVisitesAutorites // ignore: cast_nullable_to_non_nullable
as int,nbVisitesPartenaires: null == nbVisitesPartenaires ? _self.nbVisitesPartenaires : nbVisitesPartenaires // ignore: cast_nullable_to_non_nullable
as int,nbVisitesAutresAssemblees: null == nbVisitesAutresAssemblees ? _self.nbVisitesAutresAssemblees : nbVisitesAutresAssemblees // ignore: cast_nullable_to_non_nullable
as int,nbSeancesEcoleDimanche: null == nbSeancesEcoleDimanche ? _self.nbSeancesEcoleDimanche : nbSeancesEcoleDimanche // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsHommes: null == totalApprenantsHommes ? _self.totalApprenantsHommes : totalApprenantsHommes // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsFemmes: null == totalApprenantsFemmes ? _self.totalApprenantsFemmes : totalApprenantsFemmes // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsGarcons: null == totalApprenantsGarcons ? _self.totalApprenantsGarcons : totalApprenantsGarcons // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsFilles: null == totalApprenantsFilles ? _self.totalApprenantsFilles : totalApprenantsFilles // ignore: cast_nullable_to_non_nullable
as int,totalClassesEcoleDimanche: null == totalClassesEcoleDimanche ? _self.totalClassesEcoleDimanche : totalClassesEcoleDimanche // ignore: cast_nullable_to_non_nullable
as int,totalMoniteursHommes: null == totalMoniteursHommes ? _self.totalMoniteursHommes : totalMoniteursHommes // ignore: cast_nullable_to_non_nullable
as int,totalMonitricesFemmes: null == totalMonitricesFemmes ? _self.totalMonitricesFemmes : totalMonitricesFemmes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsActivitesMensuelles].
extension StatsActivitesMensuellesPatterns on StatsActivitesMensuelles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsActivitesMensuelles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsActivitesMensuelles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsActivitesMensuelles value)  $default,){
final _that = this;
switch (_that) {
case _StatsActivitesMensuelles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsActivitesMensuelles value)?  $default,){
final _that = this;
switch (_that) {
case _StatsActivitesMensuelles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int nbEvangelisationsMasse,  int nbEvangelisationsPorteAPorte,  int totalConversionsHommes,  int totalConversionsFemmes,  int totalConversionsGarcons,  int totalConversionsFilles,  int nbBaptemes,  int nbMainsAssociation,  int nbSaintesCenes,  int nbReunionsPriere,  int nbMariages,  int nbDisciplines,  int nbVisitesFideles,  int nbVisitesAutorites,  int nbVisitesPartenaires,  int nbVisitesAutresAssemblees,  int nbSeancesEcoleDimanche,  int totalApprenantsHommes,  int totalApprenantsFemmes,  int totalApprenantsGarcons,  int totalApprenantsFilles,  int totalClassesEcoleDimanche,  int totalMoniteursHommes,  int totalMonitricesFemmes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsActivitesMensuelles() when $default != null:
return $default(_that.nbEvangelisationsMasse,_that.nbEvangelisationsPorteAPorte,_that.totalConversionsHommes,_that.totalConversionsFemmes,_that.totalConversionsGarcons,_that.totalConversionsFilles,_that.nbBaptemes,_that.nbMainsAssociation,_that.nbSaintesCenes,_that.nbReunionsPriere,_that.nbMariages,_that.nbDisciplines,_that.nbVisitesFideles,_that.nbVisitesAutorites,_that.nbVisitesPartenaires,_that.nbVisitesAutresAssemblees,_that.nbSeancesEcoleDimanche,_that.totalApprenantsHommes,_that.totalApprenantsFemmes,_that.totalApprenantsGarcons,_that.totalApprenantsFilles,_that.totalClassesEcoleDimanche,_that.totalMoniteursHommes,_that.totalMonitricesFemmes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int nbEvangelisationsMasse,  int nbEvangelisationsPorteAPorte,  int totalConversionsHommes,  int totalConversionsFemmes,  int totalConversionsGarcons,  int totalConversionsFilles,  int nbBaptemes,  int nbMainsAssociation,  int nbSaintesCenes,  int nbReunionsPriere,  int nbMariages,  int nbDisciplines,  int nbVisitesFideles,  int nbVisitesAutorites,  int nbVisitesPartenaires,  int nbVisitesAutresAssemblees,  int nbSeancesEcoleDimanche,  int totalApprenantsHommes,  int totalApprenantsFemmes,  int totalApprenantsGarcons,  int totalApprenantsFilles,  int totalClassesEcoleDimanche,  int totalMoniteursHommes,  int totalMonitricesFemmes)  $default,) {final _that = this;
switch (_that) {
case _StatsActivitesMensuelles():
return $default(_that.nbEvangelisationsMasse,_that.nbEvangelisationsPorteAPorte,_that.totalConversionsHommes,_that.totalConversionsFemmes,_that.totalConversionsGarcons,_that.totalConversionsFilles,_that.nbBaptemes,_that.nbMainsAssociation,_that.nbSaintesCenes,_that.nbReunionsPriere,_that.nbMariages,_that.nbDisciplines,_that.nbVisitesFideles,_that.nbVisitesAutorites,_that.nbVisitesPartenaires,_that.nbVisitesAutresAssemblees,_that.nbSeancesEcoleDimanche,_that.totalApprenantsHommes,_that.totalApprenantsFemmes,_that.totalApprenantsGarcons,_that.totalApprenantsFilles,_that.totalClassesEcoleDimanche,_that.totalMoniteursHommes,_that.totalMonitricesFemmes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int nbEvangelisationsMasse,  int nbEvangelisationsPorteAPorte,  int totalConversionsHommes,  int totalConversionsFemmes,  int totalConversionsGarcons,  int totalConversionsFilles,  int nbBaptemes,  int nbMainsAssociation,  int nbSaintesCenes,  int nbReunionsPriere,  int nbMariages,  int nbDisciplines,  int nbVisitesFideles,  int nbVisitesAutorites,  int nbVisitesPartenaires,  int nbVisitesAutresAssemblees,  int nbSeancesEcoleDimanche,  int totalApprenantsHommes,  int totalApprenantsFemmes,  int totalApprenantsGarcons,  int totalApprenantsFilles,  int totalClassesEcoleDimanche,  int totalMoniteursHommes,  int totalMonitricesFemmes)?  $default,) {final _that = this;
switch (_that) {
case _StatsActivitesMensuelles() when $default != null:
return $default(_that.nbEvangelisationsMasse,_that.nbEvangelisationsPorteAPorte,_that.totalConversionsHommes,_that.totalConversionsFemmes,_that.totalConversionsGarcons,_that.totalConversionsFilles,_that.nbBaptemes,_that.nbMainsAssociation,_that.nbSaintesCenes,_that.nbReunionsPriere,_that.nbMariages,_that.nbDisciplines,_that.nbVisitesFideles,_that.nbVisitesAutorites,_that.nbVisitesPartenaires,_that.nbVisitesAutresAssemblees,_that.nbSeancesEcoleDimanche,_that.totalApprenantsHommes,_that.totalApprenantsFemmes,_that.totalApprenantsGarcons,_that.totalApprenantsFilles,_that.totalClassesEcoleDimanche,_that.totalMoniteursHommes,_that.totalMonitricesFemmes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsActivitesMensuelles implements StatsActivitesMensuelles {
  const _StatsActivitesMensuelles({required this.nbEvangelisationsMasse, required this.nbEvangelisationsPorteAPorte, required this.totalConversionsHommes, required this.totalConversionsFemmes, required this.totalConversionsGarcons, required this.totalConversionsFilles, required this.nbBaptemes, required this.nbMainsAssociation, required this.nbSaintesCenes, required this.nbReunionsPriere, required this.nbMariages, required this.nbDisciplines, required this.nbVisitesFideles, required this.nbVisitesAutorites, required this.nbVisitesPartenaires, required this.nbVisitesAutresAssemblees, required this.nbSeancesEcoleDimanche, required this.totalApprenantsHommes, required this.totalApprenantsFemmes, required this.totalApprenantsGarcons, required this.totalApprenantsFilles, required this.totalClassesEcoleDimanche, required this.totalMoniteursHommes, required this.totalMonitricesFemmes});
  factory _StatsActivitesMensuelles.fromJson(Map<String, dynamic> json) => _$StatsActivitesMensuellesFromJson(json);

// Evangelisations
@override final  int nbEvangelisationsMasse;
@override final  int nbEvangelisationsPorteAPorte;
@override final  int totalConversionsHommes;
@override final  int totalConversionsFemmes;
@override final  int totalConversionsGarcons;
@override final  int totalConversionsFilles;
// Sainte cene, baptemes, mains d'association, reunions, mariages, visites
@override final  int nbBaptemes;
@override final  int nbMainsAssociation;
@override final  int nbSaintesCenes;
@override final  int nbReunionsPriere;
@override final  int nbMariages;
@override final  int nbDisciplines;
@override final  int nbVisitesFideles;
@override final  int nbVisitesAutorites;
@override final  int nbVisitesPartenaires;
@override final  int nbVisitesAutresAssemblees;
// Ecole du dimanche
@override final  int nbSeancesEcoleDimanche;
@override final  int totalApprenantsHommes;
@override final  int totalApprenantsFemmes;
@override final  int totalApprenantsGarcons;
@override final  int totalApprenantsFilles;
@override final  int totalClassesEcoleDimanche;
@override final  int totalMoniteursHommes;
@override final  int totalMonitricesFemmes;

/// Create a copy of StatsActivitesMensuelles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsActivitesMensuellesCopyWith<_StatsActivitesMensuelles> get copyWith => __$StatsActivitesMensuellesCopyWithImpl<_StatsActivitesMensuelles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsActivitesMensuellesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsActivitesMensuelles&&(identical(other.nbEvangelisationsMasse, nbEvangelisationsMasse) || other.nbEvangelisationsMasse == nbEvangelisationsMasse)&&(identical(other.nbEvangelisationsPorteAPorte, nbEvangelisationsPorteAPorte) || other.nbEvangelisationsPorteAPorte == nbEvangelisationsPorteAPorte)&&(identical(other.totalConversionsHommes, totalConversionsHommes) || other.totalConversionsHommes == totalConversionsHommes)&&(identical(other.totalConversionsFemmes, totalConversionsFemmes) || other.totalConversionsFemmes == totalConversionsFemmes)&&(identical(other.totalConversionsGarcons, totalConversionsGarcons) || other.totalConversionsGarcons == totalConversionsGarcons)&&(identical(other.totalConversionsFilles, totalConversionsFilles) || other.totalConversionsFilles == totalConversionsFilles)&&(identical(other.nbBaptemes, nbBaptemes) || other.nbBaptemes == nbBaptemes)&&(identical(other.nbMainsAssociation, nbMainsAssociation) || other.nbMainsAssociation == nbMainsAssociation)&&(identical(other.nbSaintesCenes, nbSaintesCenes) || other.nbSaintesCenes == nbSaintesCenes)&&(identical(other.nbReunionsPriere, nbReunionsPriere) || other.nbReunionsPriere == nbReunionsPriere)&&(identical(other.nbMariages, nbMariages) || other.nbMariages == nbMariages)&&(identical(other.nbDisciplines, nbDisciplines) || other.nbDisciplines == nbDisciplines)&&(identical(other.nbVisitesFideles, nbVisitesFideles) || other.nbVisitesFideles == nbVisitesFideles)&&(identical(other.nbVisitesAutorites, nbVisitesAutorites) || other.nbVisitesAutorites == nbVisitesAutorites)&&(identical(other.nbVisitesPartenaires, nbVisitesPartenaires) || other.nbVisitesPartenaires == nbVisitesPartenaires)&&(identical(other.nbVisitesAutresAssemblees, nbVisitesAutresAssemblees) || other.nbVisitesAutresAssemblees == nbVisitesAutresAssemblees)&&(identical(other.nbSeancesEcoleDimanche, nbSeancesEcoleDimanche) || other.nbSeancesEcoleDimanche == nbSeancesEcoleDimanche)&&(identical(other.totalApprenantsHommes, totalApprenantsHommes) || other.totalApprenantsHommes == totalApprenantsHommes)&&(identical(other.totalApprenantsFemmes, totalApprenantsFemmes) || other.totalApprenantsFemmes == totalApprenantsFemmes)&&(identical(other.totalApprenantsGarcons, totalApprenantsGarcons) || other.totalApprenantsGarcons == totalApprenantsGarcons)&&(identical(other.totalApprenantsFilles, totalApprenantsFilles) || other.totalApprenantsFilles == totalApprenantsFilles)&&(identical(other.totalClassesEcoleDimanche, totalClassesEcoleDimanche) || other.totalClassesEcoleDimanche == totalClassesEcoleDimanche)&&(identical(other.totalMoniteursHommes, totalMoniteursHommes) || other.totalMoniteursHommes == totalMoniteursHommes)&&(identical(other.totalMonitricesFemmes, totalMonitricesFemmes) || other.totalMonitricesFemmes == totalMonitricesFemmes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,nbEvangelisationsMasse,nbEvangelisationsPorteAPorte,totalConversionsHommes,totalConversionsFemmes,totalConversionsGarcons,totalConversionsFilles,nbBaptemes,nbMainsAssociation,nbSaintesCenes,nbReunionsPriere,nbMariages,nbDisciplines,nbVisitesFideles,nbVisitesAutorites,nbVisitesPartenaires,nbVisitesAutresAssemblees,nbSeancesEcoleDimanche,totalApprenantsHommes,totalApprenantsFemmes,totalApprenantsGarcons,totalApprenantsFilles,totalClassesEcoleDimanche,totalMoniteursHommes,totalMonitricesFemmes]);

@override
String toString() {
  return 'StatsActivitesMensuelles(nbEvangelisationsMasse: $nbEvangelisationsMasse, nbEvangelisationsPorteAPorte: $nbEvangelisationsPorteAPorte, totalConversionsHommes: $totalConversionsHommes, totalConversionsFemmes: $totalConversionsFemmes, totalConversionsGarcons: $totalConversionsGarcons, totalConversionsFilles: $totalConversionsFilles, nbBaptemes: $nbBaptemes, nbMainsAssociation: $nbMainsAssociation, nbSaintesCenes: $nbSaintesCenes, nbReunionsPriere: $nbReunionsPriere, nbMariages: $nbMariages, nbDisciplines: $nbDisciplines, nbVisitesFideles: $nbVisitesFideles, nbVisitesAutorites: $nbVisitesAutorites, nbVisitesPartenaires: $nbVisitesPartenaires, nbVisitesAutresAssemblees: $nbVisitesAutresAssemblees, nbSeancesEcoleDimanche: $nbSeancesEcoleDimanche, totalApprenantsHommes: $totalApprenantsHommes, totalApprenantsFemmes: $totalApprenantsFemmes, totalApprenantsGarcons: $totalApprenantsGarcons, totalApprenantsFilles: $totalApprenantsFilles, totalClassesEcoleDimanche: $totalClassesEcoleDimanche, totalMoniteursHommes: $totalMoniteursHommes, totalMonitricesFemmes: $totalMonitricesFemmes)';
}


}

/// @nodoc
abstract mixin class _$StatsActivitesMensuellesCopyWith<$Res> implements $StatsActivitesMensuellesCopyWith<$Res> {
  factory _$StatsActivitesMensuellesCopyWith(_StatsActivitesMensuelles value, $Res Function(_StatsActivitesMensuelles) _then) = __$StatsActivitesMensuellesCopyWithImpl;
@override @useResult
$Res call({
 int nbEvangelisationsMasse, int nbEvangelisationsPorteAPorte, int totalConversionsHommes, int totalConversionsFemmes, int totalConversionsGarcons, int totalConversionsFilles, int nbBaptemes, int nbMainsAssociation, int nbSaintesCenes, int nbReunionsPriere, int nbMariages, int nbDisciplines, int nbVisitesFideles, int nbVisitesAutorites, int nbVisitesPartenaires, int nbVisitesAutresAssemblees, int nbSeancesEcoleDimanche, int totalApprenantsHommes, int totalApprenantsFemmes, int totalApprenantsGarcons, int totalApprenantsFilles, int totalClassesEcoleDimanche, int totalMoniteursHommes, int totalMonitricesFemmes
});




}
/// @nodoc
class __$StatsActivitesMensuellesCopyWithImpl<$Res>
    implements _$StatsActivitesMensuellesCopyWith<$Res> {
  __$StatsActivitesMensuellesCopyWithImpl(this._self, this._then);

  final _StatsActivitesMensuelles _self;
  final $Res Function(_StatsActivitesMensuelles) _then;

/// Create a copy of StatsActivitesMensuelles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nbEvangelisationsMasse = null,Object? nbEvangelisationsPorteAPorte = null,Object? totalConversionsHommes = null,Object? totalConversionsFemmes = null,Object? totalConversionsGarcons = null,Object? totalConversionsFilles = null,Object? nbBaptemes = null,Object? nbMainsAssociation = null,Object? nbSaintesCenes = null,Object? nbReunionsPriere = null,Object? nbMariages = null,Object? nbDisciplines = null,Object? nbVisitesFideles = null,Object? nbVisitesAutorites = null,Object? nbVisitesPartenaires = null,Object? nbVisitesAutresAssemblees = null,Object? nbSeancesEcoleDimanche = null,Object? totalApprenantsHommes = null,Object? totalApprenantsFemmes = null,Object? totalApprenantsGarcons = null,Object? totalApprenantsFilles = null,Object? totalClassesEcoleDimanche = null,Object? totalMoniteursHommes = null,Object? totalMonitricesFemmes = null,}) {
  return _then(_StatsActivitesMensuelles(
nbEvangelisationsMasse: null == nbEvangelisationsMasse ? _self.nbEvangelisationsMasse : nbEvangelisationsMasse // ignore: cast_nullable_to_non_nullable
as int,nbEvangelisationsPorteAPorte: null == nbEvangelisationsPorteAPorte ? _self.nbEvangelisationsPorteAPorte : nbEvangelisationsPorteAPorte // ignore: cast_nullable_to_non_nullable
as int,totalConversionsHommes: null == totalConversionsHommes ? _self.totalConversionsHommes : totalConversionsHommes // ignore: cast_nullable_to_non_nullable
as int,totalConversionsFemmes: null == totalConversionsFemmes ? _self.totalConversionsFemmes : totalConversionsFemmes // ignore: cast_nullable_to_non_nullable
as int,totalConversionsGarcons: null == totalConversionsGarcons ? _self.totalConversionsGarcons : totalConversionsGarcons // ignore: cast_nullable_to_non_nullable
as int,totalConversionsFilles: null == totalConversionsFilles ? _self.totalConversionsFilles : totalConversionsFilles // ignore: cast_nullable_to_non_nullable
as int,nbBaptemes: null == nbBaptemes ? _self.nbBaptemes : nbBaptemes // ignore: cast_nullable_to_non_nullable
as int,nbMainsAssociation: null == nbMainsAssociation ? _self.nbMainsAssociation : nbMainsAssociation // ignore: cast_nullable_to_non_nullable
as int,nbSaintesCenes: null == nbSaintesCenes ? _self.nbSaintesCenes : nbSaintesCenes // ignore: cast_nullable_to_non_nullable
as int,nbReunionsPriere: null == nbReunionsPriere ? _self.nbReunionsPriere : nbReunionsPriere // ignore: cast_nullable_to_non_nullable
as int,nbMariages: null == nbMariages ? _self.nbMariages : nbMariages // ignore: cast_nullable_to_non_nullable
as int,nbDisciplines: null == nbDisciplines ? _self.nbDisciplines : nbDisciplines // ignore: cast_nullable_to_non_nullable
as int,nbVisitesFideles: null == nbVisitesFideles ? _self.nbVisitesFideles : nbVisitesFideles // ignore: cast_nullable_to_non_nullable
as int,nbVisitesAutorites: null == nbVisitesAutorites ? _self.nbVisitesAutorites : nbVisitesAutorites // ignore: cast_nullable_to_non_nullable
as int,nbVisitesPartenaires: null == nbVisitesPartenaires ? _self.nbVisitesPartenaires : nbVisitesPartenaires // ignore: cast_nullable_to_non_nullable
as int,nbVisitesAutresAssemblees: null == nbVisitesAutresAssemblees ? _self.nbVisitesAutresAssemblees : nbVisitesAutresAssemblees // ignore: cast_nullable_to_non_nullable
as int,nbSeancesEcoleDimanche: null == nbSeancesEcoleDimanche ? _self.nbSeancesEcoleDimanche : nbSeancesEcoleDimanche // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsHommes: null == totalApprenantsHommes ? _self.totalApprenantsHommes : totalApprenantsHommes // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsFemmes: null == totalApprenantsFemmes ? _self.totalApprenantsFemmes : totalApprenantsFemmes // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsGarcons: null == totalApprenantsGarcons ? _self.totalApprenantsGarcons : totalApprenantsGarcons // ignore: cast_nullable_to_non_nullable
as int,totalApprenantsFilles: null == totalApprenantsFilles ? _self.totalApprenantsFilles : totalApprenantsFilles // ignore: cast_nullable_to_non_nullable
as int,totalClassesEcoleDimanche: null == totalClassesEcoleDimanche ? _self.totalClassesEcoleDimanche : totalClassesEcoleDimanche // ignore: cast_nullable_to_non_nullable
as int,totalMoniteursHommes: null == totalMoniteursHommes ? _self.totalMoniteursHommes : totalMoniteursHommes // ignore: cast_nullable_to_non_nullable
as int,totalMonitricesFemmes: null == totalMonitricesFemmes ? _self.totalMonitricesFemmes : totalMonitricesFemmes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StatsFinancieresMensuelles {

// Totaux globaux
 double get totalProduits; double get totalCharges;// Detail par grandes familles (simplifie)
 double get totalOffrandesCultes; double get totalDonsLiberaites; double get totalRecettesAutres; double get totalChargesFonctionnement; double get totalChargesSociales;
/// Create a copy of StatsFinancieresMensuelles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsFinancieresMensuellesCopyWith<StatsFinancieresMensuelles> get copyWith => _$StatsFinancieresMensuellesCopyWithImpl<StatsFinancieresMensuelles>(this as StatsFinancieresMensuelles, _$identity);

  /// Serializes this StatsFinancieresMensuelles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsFinancieresMensuelles&&(identical(other.totalProduits, totalProduits) || other.totalProduits == totalProduits)&&(identical(other.totalCharges, totalCharges) || other.totalCharges == totalCharges)&&(identical(other.totalOffrandesCultes, totalOffrandesCultes) || other.totalOffrandesCultes == totalOffrandesCultes)&&(identical(other.totalDonsLiberaites, totalDonsLiberaites) || other.totalDonsLiberaites == totalDonsLiberaites)&&(identical(other.totalRecettesAutres, totalRecettesAutres) || other.totalRecettesAutres == totalRecettesAutres)&&(identical(other.totalChargesFonctionnement, totalChargesFonctionnement) || other.totalChargesFonctionnement == totalChargesFonctionnement)&&(identical(other.totalChargesSociales, totalChargesSociales) || other.totalChargesSociales == totalChargesSociales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalProduits,totalCharges,totalOffrandesCultes,totalDonsLiberaites,totalRecettesAutres,totalChargesFonctionnement,totalChargesSociales);

@override
String toString() {
  return 'StatsFinancieresMensuelles(totalProduits: $totalProduits, totalCharges: $totalCharges, totalOffrandesCultes: $totalOffrandesCultes, totalDonsLiberaites: $totalDonsLiberaites, totalRecettesAutres: $totalRecettesAutres, totalChargesFonctionnement: $totalChargesFonctionnement, totalChargesSociales: $totalChargesSociales)';
}


}

/// @nodoc
abstract mixin class $StatsFinancieresMensuellesCopyWith<$Res>  {
  factory $StatsFinancieresMensuellesCopyWith(StatsFinancieresMensuelles value, $Res Function(StatsFinancieresMensuelles) _then) = _$StatsFinancieresMensuellesCopyWithImpl;
@useResult
$Res call({
 double totalProduits, double totalCharges, double totalOffrandesCultes, double totalDonsLiberaites, double totalRecettesAutres, double totalChargesFonctionnement, double totalChargesSociales
});




}
/// @nodoc
class _$StatsFinancieresMensuellesCopyWithImpl<$Res>
    implements $StatsFinancieresMensuellesCopyWith<$Res> {
  _$StatsFinancieresMensuellesCopyWithImpl(this._self, this._then);

  final StatsFinancieresMensuelles _self;
  final $Res Function(StatsFinancieresMensuelles) _then;

/// Create a copy of StatsFinancieresMensuelles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalProduits = null,Object? totalCharges = null,Object? totalOffrandesCultes = null,Object? totalDonsLiberaites = null,Object? totalRecettesAutres = null,Object? totalChargesFonctionnement = null,Object? totalChargesSociales = null,}) {
  return _then(_self.copyWith(
totalProduits: null == totalProduits ? _self.totalProduits : totalProduits // ignore: cast_nullable_to_non_nullable
as double,totalCharges: null == totalCharges ? _self.totalCharges : totalCharges // ignore: cast_nullable_to_non_nullable
as double,totalOffrandesCultes: null == totalOffrandesCultes ? _self.totalOffrandesCultes : totalOffrandesCultes // ignore: cast_nullable_to_non_nullable
as double,totalDonsLiberaites: null == totalDonsLiberaites ? _self.totalDonsLiberaites : totalDonsLiberaites // ignore: cast_nullable_to_non_nullable
as double,totalRecettesAutres: null == totalRecettesAutres ? _self.totalRecettesAutres : totalRecettesAutres // ignore: cast_nullable_to_non_nullable
as double,totalChargesFonctionnement: null == totalChargesFonctionnement ? _self.totalChargesFonctionnement : totalChargesFonctionnement // ignore: cast_nullable_to_non_nullable
as double,totalChargesSociales: null == totalChargesSociales ? _self.totalChargesSociales : totalChargesSociales // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsFinancieresMensuelles].
extension StatsFinancieresMensuellesPatterns on StatsFinancieresMensuelles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsFinancieresMensuelles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsFinancieresMensuelles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsFinancieresMensuelles value)  $default,){
final _that = this;
switch (_that) {
case _StatsFinancieresMensuelles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsFinancieresMensuelles value)?  $default,){
final _that = this;
switch (_that) {
case _StatsFinancieresMensuelles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalProduits,  double totalCharges,  double totalOffrandesCultes,  double totalDonsLiberaites,  double totalRecettesAutres,  double totalChargesFonctionnement,  double totalChargesSociales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsFinancieresMensuelles() when $default != null:
return $default(_that.totalProduits,_that.totalCharges,_that.totalOffrandesCultes,_that.totalDonsLiberaites,_that.totalRecettesAutres,_that.totalChargesFonctionnement,_that.totalChargesSociales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalProduits,  double totalCharges,  double totalOffrandesCultes,  double totalDonsLiberaites,  double totalRecettesAutres,  double totalChargesFonctionnement,  double totalChargesSociales)  $default,) {final _that = this;
switch (_that) {
case _StatsFinancieresMensuelles():
return $default(_that.totalProduits,_that.totalCharges,_that.totalOffrandesCultes,_that.totalDonsLiberaites,_that.totalRecettesAutres,_that.totalChargesFonctionnement,_that.totalChargesSociales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalProduits,  double totalCharges,  double totalOffrandesCultes,  double totalDonsLiberaites,  double totalRecettesAutres,  double totalChargesFonctionnement,  double totalChargesSociales)?  $default,) {final _that = this;
switch (_that) {
case _StatsFinancieresMensuelles() when $default != null:
return $default(_that.totalProduits,_that.totalCharges,_that.totalOffrandesCultes,_that.totalDonsLiberaites,_that.totalRecettesAutres,_that.totalChargesFonctionnement,_that.totalChargesSociales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsFinancieresMensuelles implements StatsFinancieresMensuelles {
  const _StatsFinancieresMensuelles({required this.totalProduits, required this.totalCharges, required this.totalOffrandesCultes, required this.totalDonsLiberaites, required this.totalRecettesAutres, required this.totalChargesFonctionnement, required this.totalChargesSociales});
  factory _StatsFinancieresMensuelles.fromJson(Map<String, dynamic> json) => _$StatsFinancieresMensuellesFromJson(json);

// Totaux globaux
@override final  double totalProduits;
@override final  double totalCharges;
// Detail par grandes familles (simplifie)
@override final  double totalOffrandesCultes;
@override final  double totalDonsLiberaites;
@override final  double totalRecettesAutres;
@override final  double totalChargesFonctionnement;
@override final  double totalChargesSociales;

/// Create a copy of StatsFinancieresMensuelles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsFinancieresMensuellesCopyWith<_StatsFinancieresMensuelles> get copyWith => __$StatsFinancieresMensuellesCopyWithImpl<_StatsFinancieresMensuelles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsFinancieresMensuellesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsFinancieresMensuelles&&(identical(other.totalProduits, totalProduits) || other.totalProduits == totalProduits)&&(identical(other.totalCharges, totalCharges) || other.totalCharges == totalCharges)&&(identical(other.totalOffrandesCultes, totalOffrandesCultes) || other.totalOffrandesCultes == totalOffrandesCultes)&&(identical(other.totalDonsLiberaites, totalDonsLiberaites) || other.totalDonsLiberaites == totalDonsLiberaites)&&(identical(other.totalRecettesAutres, totalRecettesAutres) || other.totalRecettesAutres == totalRecettesAutres)&&(identical(other.totalChargesFonctionnement, totalChargesFonctionnement) || other.totalChargesFonctionnement == totalChargesFonctionnement)&&(identical(other.totalChargesSociales, totalChargesSociales) || other.totalChargesSociales == totalChargesSociales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalProduits,totalCharges,totalOffrandesCultes,totalDonsLiberaites,totalRecettesAutres,totalChargesFonctionnement,totalChargesSociales);

@override
String toString() {
  return 'StatsFinancieresMensuelles(totalProduits: $totalProduits, totalCharges: $totalCharges, totalOffrandesCultes: $totalOffrandesCultes, totalDonsLiberaites: $totalDonsLiberaites, totalRecettesAutres: $totalRecettesAutres, totalChargesFonctionnement: $totalChargesFonctionnement, totalChargesSociales: $totalChargesSociales)';
}


}

/// @nodoc
abstract mixin class _$StatsFinancieresMensuellesCopyWith<$Res> implements $StatsFinancieresMensuellesCopyWith<$Res> {
  factory _$StatsFinancieresMensuellesCopyWith(_StatsFinancieresMensuelles value, $Res Function(_StatsFinancieresMensuelles) _then) = __$StatsFinancieresMensuellesCopyWithImpl;
@override @useResult
$Res call({
 double totalProduits, double totalCharges, double totalOffrandesCultes, double totalDonsLiberaites, double totalRecettesAutres, double totalChargesFonctionnement, double totalChargesSociales
});




}
/// @nodoc
class __$StatsFinancieresMensuellesCopyWithImpl<$Res>
    implements _$StatsFinancieresMensuellesCopyWith<$Res> {
  __$StatsFinancieresMensuellesCopyWithImpl(this._self, this._then);

  final _StatsFinancieresMensuelles _self;
  final $Res Function(_StatsFinancieresMensuelles) _then;

/// Create a copy of StatsFinancieresMensuelles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalProduits = null,Object? totalCharges = null,Object? totalOffrandesCultes = null,Object? totalDonsLiberaites = null,Object? totalRecettesAutres = null,Object? totalChargesFonctionnement = null,Object? totalChargesSociales = null,}) {
  return _then(_StatsFinancieresMensuelles(
totalProduits: null == totalProduits ? _self.totalProduits : totalProduits // ignore: cast_nullable_to_non_nullable
as double,totalCharges: null == totalCharges ? _self.totalCharges : totalCharges // ignore: cast_nullable_to_non_nullable
as double,totalOffrandesCultes: null == totalOffrandesCultes ? _self.totalOffrandesCultes : totalOffrandesCultes // ignore: cast_nullable_to_non_nullable
as double,totalDonsLiberaites: null == totalDonsLiberaites ? _self.totalDonsLiberaites : totalDonsLiberaites // ignore: cast_nullable_to_non_nullable
as double,totalRecettesAutres: null == totalRecettesAutres ? _self.totalRecettesAutres : totalRecettesAutres // ignore: cast_nullable_to_non_nullable
as double,totalChargesFonctionnement: null == totalChargesFonctionnement ? _self.totalChargesFonctionnement : totalChargesFonctionnement // ignore: cast_nullable_to_non_nullable
as double,totalChargesSociales: null == totalChargesSociales ? _self.totalChargesSociales : totalChargesSociales // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$RapportMensuelEab {

 String get id; int get annee; int get mois; String get idAssembleeLocale;// Statistiques calculees
 StatsMembresMensuelles get statsMembres; StatsActivitesMensuelles get statsActivites; StatsFinancieresMensuelles get statsFinances;// Champs texte (remplis plus tard via l'UI)
 String? get resumeActivites; String? get projetsRealisations; String? get projetsMoisSuivant; String? get observations;
/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RapportMensuelEabCopyWith<RapportMensuelEab> get copyWith => _$RapportMensuelEabCopyWithImpl<RapportMensuelEab>(this as RapportMensuelEab, _$identity);

  /// Serializes this RapportMensuelEab to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RapportMensuelEab&&(identical(other.id, id) || other.id == id)&&(identical(other.annee, annee) || other.annee == annee)&&(identical(other.mois, mois) || other.mois == mois)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.statsMembres, statsMembres) || other.statsMembres == statsMembres)&&(identical(other.statsActivites, statsActivites) || other.statsActivites == statsActivites)&&(identical(other.statsFinances, statsFinances) || other.statsFinances == statsFinances)&&(identical(other.resumeActivites, resumeActivites) || other.resumeActivites == resumeActivites)&&(identical(other.projetsRealisations, projetsRealisations) || other.projetsRealisations == projetsRealisations)&&(identical(other.projetsMoisSuivant, projetsMoisSuivant) || other.projetsMoisSuivant == projetsMoisSuivant)&&(identical(other.observations, observations) || other.observations == observations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,annee,mois,idAssembleeLocale,statsMembres,statsActivites,statsFinances,resumeActivites,projetsRealisations,projetsMoisSuivant,observations);

@override
String toString() {
  return 'RapportMensuelEab(id: $id, annee: $annee, mois: $mois, idAssembleeLocale: $idAssembleeLocale, statsMembres: $statsMembres, statsActivites: $statsActivites, statsFinances: $statsFinances, resumeActivites: $resumeActivites, projetsRealisations: $projetsRealisations, projetsMoisSuivant: $projetsMoisSuivant, observations: $observations)';
}


}

/// @nodoc
abstract mixin class $RapportMensuelEabCopyWith<$Res>  {
  factory $RapportMensuelEabCopyWith(RapportMensuelEab value, $Res Function(RapportMensuelEab) _then) = _$RapportMensuelEabCopyWithImpl;
@useResult
$Res call({
 String id, int annee, int mois, String idAssembleeLocale, StatsMembresMensuelles statsMembres, StatsActivitesMensuelles statsActivites, StatsFinancieresMensuelles statsFinances, String? resumeActivites, String? projetsRealisations, String? projetsMoisSuivant, String? observations
});


$StatsMembresMensuellesCopyWith<$Res> get statsMembres;$StatsActivitesMensuellesCopyWith<$Res> get statsActivites;$StatsFinancieresMensuellesCopyWith<$Res> get statsFinances;

}
/// @nodoc
class _$RapportMensuelEabCopyWithImpl<$Res>
    implements $RapportMensuelEabCopyWith<$Res> {
  _$RapportMensuelEabCopyWithImpl(this._self, this._then);

  final RapportMensuelEab _self;
  final $Res Function(RapportMensuelEab) _then;

/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? annee = null,Object? mois = null,Object? idAssembleeLocale = null,Object? statsMembres = null,Object? statsActivites = null,Object? statsFinances = null,Object? resumeActivites = freezed,Object? projetsRealisations = freezed,Object? projetsMoisSuivant = freezed,Object? observations = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,idAssembleeLocale: null == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String,statsMembres: null == statsMembres ? _self.statsMembres : statsMembres // ignore: cast_nullable_to_non_nullable
as StatsMembresMensuelles,statsActivites: null == statsActivites ? _self.statsActivites : statsActivites // ignore: cast_nullable_to_non_nullable
as StatsActivitesMensuelles,statsFinances: null == statsFinances ? _self.statsFinances : statsFinances // ignore: cast_nullable_to_non_nullable
as StatsFinancieresMensuelles,resumeActivites: freezed == resumeActivites ? _self.resumeActivites : resumeActivites // ignore: cast_nullable_to_non_nullable
as String?,projetsRealisations: freezed == projetsRealisations ? _self.projetsRealisations : projetsRealisations // ignore: cast_nullable_to_non_nullable
as String?,projetsMoisSuivant: freezed == projetsMoisSuivant ? _self.projetsMoisSuivant : projetsMoisSuivant // ignore: cast_nullable_to_non_nullable
as String?,observations: freezed == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsMembresMensuellesCopyWith<$Res> get statsMembres {
  
  return $StatsMembresMensuellesCopyWith<$Res>(_self.statsMembres, (value) {
    return _then(_self.copyWith(statsMembres: value));
  });
}/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsActivitesMensuellesCopyWith<$Res> get statsActivites {
  
  return $StatsActivitesMensuellesCopyWith<$Res>(_self.statsActivites, (value) {
    return _then(_self.copyWith(statsActivites: value));
  });
}/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsFinancieresMensuellesCopyWith<$Res> get statsFinances {
  
  return $StatsFinancieresMensuellesCopyWith<$Res>(_self.statsFinances, (value) {
    return _then(_self.copyWith(statsFinances: value));
  });
}
}


/// Adds pattern-matching-related methods to [RapportMensuelEab].
extension RapportMensuelEabPatterns on RapportMensuelEab {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RapportMensuelEab value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RapportMensuelEab() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RapportMensuelEab value)  $default,){
final _that = this;
switch (_that) {
case _RapportMensuelEab():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RapportMensuelEab value)?  $default,){
final _that = this;
switch (_that) {
case _RapportMensuelEab() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int annee,  int mois,  String idAssembleeLocale,  StatsMembresMensuelles statsMembres,  StatsActivitesMensuelles statsActivites,  StatsFinancieresMensuelles statsFinances,  String? resumeActivites,  String? projetsRealisations,  String? projetsMoisSuivant,  String? observations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RapportMensuelEab() when $default != null:
return $default(_that.id,_that.annee,_that.mois,_that.idAssembleeLocale,_that.statsMembres,_that.statsActivites,_that.statsFinances,_that.resumeActivites,_that.projetsRealisations,_that.projetsMoisSuivant,_that.observations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int annee,  int mois,  String idAssembleeLocale,  StatsMembresMensuelles statsMembres,  StatsActivitesMensuelles statsActivites,  StatsFinancieresMensuelles statsFinances,  String? resumeActivites,  String? projetsRealisations,  String? projetsMoisSuivant,  String? observations)  $default,) {final _that = this;
switch (_that) {
case _RapportMensuelEab():
return $default(_that.id,_that.annee,_that.mois,_that.idAssembleeLocale,_that.statsMembres,_that.statsActivites,_that.statsFinances,_that.resumeActivites,_that.projetsRealisations,_that.projetsMoisSuivant,_that.observations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int annee,  int mois,  String idAssembleeLocale,  StatsMembresMensuelles statsMembres,  StatsActivitesMensuelles statsActivites,  StatsFinancieresMensuelles statsFinances,  String? resumeActivites,  String? projetsRealisations,  String? projetsMoisSuivant,  String? observations)?  $default,) {final _that = this;
switch (_that) {
case _RapportMensuelEab() when $default != null:
return $default(_that.id,_that.annee,_that.mois,_that.idAssembleeLocale,_that.statsMembres,_that.statsActivites,_that.statsFinances,_that.resumeActivites,_that.projetsRealisations,_that.projetsMoisSuivant,_that.observations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RapportMensuelEab implements RapportMensuelEab {
  const _RapportMensuelEab({required this.id, required this.annee, required this.mois, required this.idAssembleeLocale, required this.statsMembres, required this.statsActivites, required this.statsFinances, this.resumeActivites, this.projetsRealisations, this.projetsMoisSuivant, this.observations});
  factory _RapportMensuelEab.fromJson(Map<String, dynamic> json) => _$RapportMensuelEabFromJson(json);

@override final  String id;
@override final  int annee;
@override final  int mois;
@override final  String idAssembleeLocale;
// Statistiques calculees
@override final  StatsMembresMensuelles statsMembres;
@override final  StatsActivitesMensuelles statsActivites;
@override final  StatsFinancieresMensuelles statsFinances;
// Champs texte (remplis plus tard via l'UI)
@override final  String? resumeActivites;
@override final  String? projetsRealisations;
@override final  String? projetsMoisSuivant;
@override final  String? observations;

/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RapportMensuelEabCopyWith<_RapportMensuelEab> get copyWith => __$RapportMensuelEabCopyWithImpl<_RapportMensuelEab>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RapportMensuelEabToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RapportMensuelEab&&(identical(other.id, id) || other.id == id)&&(identical(other.annee, annee) || other.annee == annee)&&(identical(other.mois, mois) || other.mois == mois)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.statsMembres, statsMembres) || other.statsMembres == statsMembres)&&(identical(other.statsActivites, statsActivites) || other.statsActivites == statsActivites)&&(identical(other.statsFinances, statsFinances) || other.statsFinances == statsFinances)&&(identical(other.resumeActivites, resumeActivites) || other.resumeActivites == resumeActivites)&&(identical(other.projetsRealisations, projetsRealisations) || other.projetsRealisations == projetsRealisations)&&(identical(other.projetsMoisSuivant, projetsMoisSuivant) || other.projetsMoisSuivant == projetsMoisSuivant)&&(identical(other.observations, observations) || other.observations == observations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,annee,mois,idAssembleeLocale,statsMembres,statsActivites,statsFinances,resumeActivites,projetsRealisations,projetsMoisSuivant,observations);

@override
String toString() {
  return 'RapportMensuelEab(id: $id, annee: $annee, mois: $mois, idAssembleeLocale: $idAssembleeLocale, statsMembres: $statsMembres, statsActivites: $statsActivites, statsFinances: $statsFinances, resumeActivites: $resumeActivites, projetsRealisations: $projetsRealisations, projetsMoisSuivant: $projetsMoisSuivant, observations: $observations)';
}


}

/// @nodoc
abstract mixin class _$RapportMensuelEabCopyWith<$Res> implements $RapportMensuelEabCopyWith<$Res> {
  factory _$RapportMensuelEabCopyWith(_RapportMensuelEab value, $Res Function(_RapportMensuelEab) _then) = __$RapportMensuelEabCopyWithImpl;
@override @useResult
$Res call({
 String id, int annee, int mois, String idAssembleeLocale, StatsMembresMensuelles statsMembres, StatsActivitesMensuelles statsActivites, StatsFinancieresMensuelles statsFinances, String? resumeActivites, String? projetsRealisations, String? projetsMoisSuivant, String? observations
});


@override $StatsMembresMensuellesCopyWith<$Res> get statsMembres;@override $StatsActivitesMensuellesCopyWith<$Res> get statsActivites;@override $StatsFinancieresMensuellesCopyWith<$Res> get statsFinances;

}
/// @nodoc
class __$RapportMensuelEabCopyWithImpl<$Res>
    implements _$RapportMensuelEabCopyWith<$Res> {
  __$RapportMensuelEabCopyWithImpl(this._self, this._then);

  final _RapportMensuelEab _self;
  final $Res Function(_RapportMensuelEab) _then;

/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? annee = null,Object? mois = null,Object? idAssembleeLocale = null,Object? statsMembres = null,Object? statsActivites = null,Object? statsFinances = null,Object? resumeActivites = freezed,Object? projetsRealisations = freezed,Object? projetsMoisSuivant = freezed,Object? observations = freezed,}) {
  return _then(_RapportMensuelEab(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,idAssembleeLocale: null == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String,statsMembres: null == statsMembres ? _self.statsMembres : statsMembres // ignore: cast_nullable_to_non_nullable
as StatsMembresMensuelles,statsActivites: null == statsActivites ? _self.statsActivites : statsActivites // ignore: cast_nullable_to_non_nullable
as StatsActivitesMensuelles,statsFinances: null == statsFinances ? _self.statsFinances : statsFinances // ignore: cast_nullable_to_non_nullable
as StatsFinancieresMensuelles,resumeActivites: freezed == resumeActivites ? _self.resumeActivites : resumeActivites // ignore: cast_nullable_to_non_nullable
as String?,projetsRealisations: freezed == projetsRealisations ? _self.projetsRealisations : projetsRealisations // ignore: cast_nullable_to_non_nullable
as String?,projetsMoisSuivant: freezed == projetsMoisSuivant ? _self.projetsMoisSuivant : projetsMoisSuivant // ignore: cast_nullable_to_non_nullable
as String?,observations: freezed == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsMembresMensuellesCopyWith<$Res> get statsMembres {
  
  return $StatsMembresMensuellesCopyWith<$Res>(_self.statsMembres, (value) {
    return _then(_self.copyWith(statsMembres: value));
  });
}/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsActivitesMensuellesCopyWith<$Res> get statsActivites {
  
  return $StatsActivitesMensuellesCopyWith<$Res>(_self.statsActivites, (value) {
    return _then(_self.copyWith(statsActivites: value));
  });
}/// Create a copy of RapportMensuelEab
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsFinancieresMensuellesCopyWith<$Res> get statsFinances {
  
  return $StatsFinancieresMensuellesCopyWith<$Res>(_self.statsFinances, (value) {
    return _then(_self.copyWith(statsFinances: value));
  });
}
}

// dart format on

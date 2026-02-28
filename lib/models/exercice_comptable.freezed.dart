// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercice_comptable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciceComptable {

 String get id; String get organizationId; int get annee; DateTime get dateDebut; DateTime get dateFin; String? get libelle; StatutExercice get statut;// Legacy booleans — conservés pour compatibilité
 bool get estOuvert; bool get estCloture;// Clôture
 String? get cloturePar; DateTime? get clotureAt;// Écritures système
 String? get openingEntryId; String? get closingEntryId;// Métadonnées
 DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of ExerciceComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciceComptableCopyWith<ExerciceComptable> get copyWith => _$ExerciceComptableCopyWithImpl<ExerciceComptable>(this as ExerciceComptable, _$identity);

  /// Serializes this ExerciceComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciceComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.annee, annee) || other.annee == annee)&&(identical(other.dateDebut, dateDebut) || other.dateDebut == dateDebut)&&(identical(other.dateFin, dateFin) || other.dateFin == dateFin)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.estOuvert, estOuvert) || other.estOuvert == estOuvert)&&(identical(other.estCloture, estCloture) || other.estCloture == estCloture)&&(identical(other.cloturePar, cloturePar) || other.cloturePar == cloturePar)&&(identical(other.clotureAt, clotureAt) || other.clotureAt == clotureAt)&&(identical(other.openingEntryId, openingEntryId) || other.openingEntryId == openingEntryId)&&(identical(other.closingEntryId, closingEntryId) || other.closingEntryId == closingEntryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,organizationId,annee,dateDebut,dateFin,libelle,statut,estOuvert,estCloture,cloturePar,clotureAt,openingEntryId,closingEntryId,createdAt,updatedAt);

@override
String toString() {
  return 'ExerciceComptable(id: $id, organizationId: $organizationId, annee: $annee, dateDebut: $dateDebut, dateFin: $dateFin, libelle: $libelle, statut: $statut, estOuvert: $estOuvert, estCloture: $estCloture, cloturePar: $cloturePar, clotureAt: $clotureAt, openingEntryId: $openingEntryId, closingEntryId: $closingEntryId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ExerciceComptableCopyWith<$Res>  {
  factory $ExerciceComptableCopyWith(ExerciceComptable value, $Res Function(ExerciceComptable) _then) = _$ExerciceComptableCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, int annee, DateTime dateDebut, DateTime dateFin, String? libelle, StatutExercice statut, bool estOuvert, bool estCloture, String? cloturePar, DateTime? clotureAt, String? openingEntryId, String? closingEntryId, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ExerciceComptableCopyWithImpl<$Res>
    implements $ExerciceComptableCopyWith<$Res> {
  _$ExerciceComptableCopyWithImpl(this._self, this._then);

  final ExerciceComptable _self;
  final $Res Function(ExerciceComptable) _then;

/// Create a copy of ExerciceComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? annee = null,Object? dateDebut = null,Object? dateFin = null,Object? libelle = freezed,Object? statut = null,Object? estOuvert = null,Object? estCloture = null,Object? cloturePar = freezed,Object? clotureAt = freezed,Object? openingEntryId = freezed,Object? closingEntryId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,dateDebut: null == dateDebut ? _self.dateDebut : dateDebut // ignore: cast_nullable_to_non_nullable
as DateTime,dateFin: null == dateFin ? _self.dateFin : dateFin // ignore: cast_nullable_to_non_nullable
as DateTime,libelle: freezed == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String?,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutExercice,estOuvert: null == estOuvert ? _self.estOuvert : estOuvert // ignore: cast_nullable_to_non_nullable
as bool,estCloture: null == estCloture ? _self.estCloture : estCloture // ignore: cast_nullable_to_non_nullable
as bool,cloturePar: freezed == cloturePar ? _self.cloturePar : cloturePar // ignore: cast_nullable_to_non_nullable
as String?,clotureAt: freezed == clotureAt ? _self.clotureAt : clotureAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openingEntryId: freezed == openingEntryId ? _self.openingEntryId : openingEntryId // ignore: cast_nullable_to_non_nullable
as String?,closingEntryId: freezed == closingEntryId ? _self.closingEntryId : closingEntryId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciceComptable].
extension ExerciceComptablePatterns on ExerciceComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciceComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciceComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciceComptable value)  $default,){
final _that = this;
switch (_that) {
case _ExerciceComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciceComptable value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciceComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  int annee,  DateTime dateDebut,  DateTime dateFin,  String? libelle,  StatutExercice statut,  bool estOuvert,  bool estCloture,  String? cloturePar,  DateTime? clotureAt,  String? openingEntryId,  String? closingEntryId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciceComptable() when $default != null:
return $default(_that.id,_that.organizationId,_that.annee,_that.dateDebut,_that.dateFin,_that.libelle,_that.statut,_that.estOuvert,_that.estCloture,_that.cloturePar,_that.clotureAt,_that.openingEntryId,_that.closingEntryId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  int annee,  DateTime dateDebut,  DateTime dateFin,  String? libelle,  StatutExercice statut,  bool estOuvert,  bool estCloture,  String? cloturePar,  DateTime? clotureAt,  String? openingEntryId,  String? closingEntryId,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ExerciceComptable():
return $default(_that.id,_that.organizationId,_that.annee,_that.dateDebut,_that.dateFin,_that.libelle,_that.statut,_that.estOuvert,_that.estCloture,_that.cloturePar,_that.clotureAt,_that.openingEntryId,_that.closingEntryId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  int annee,  DateTime dateDebut,  DateTime dateFin,  String? libelle,  StatutExercice statut,  bool estOuvert,  bool estCloture,  String? cloturePar,  DateTime? clotureAt,  String? openingEntryId,  String? closingEntryId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ExerciceComptable() when $default != null:
return $default(_that.id,_that.organizationId,_that.annee,_that.dateDebut,_that.dateFin,_that.libelle,_that.statut,_that.estOuvert,_that.estCloture,_that.cloturePar,_that.clotureAt,_that.openingEntryId,_that.closingEntryId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciceComptable implements ExerciceComptable {
  const _ExerciceComptable({required this.id, required this.organizationId, required this.annee, required this.dateDebut, required this.dateFin, this.libelle, this.statut = StatutExercice.brouillon, this.estOuvert = false, this.estCloture = false, this.cloturePar, this.clotureAt, this.openingEntryId, this.closingEntryId, this.createdAt, this.updatedAt});
  factory _ExerciceComptable.fromJson(Map<String, dynamic> json) => _$ExerciceComptableFromJson(json);

@override final  String id;
@override final  String organizationId;
@override final  int annee;
@override final  DateTime dateDebut;
@override final  DateTime dateFin;
@override final  String? libelle;
@override@JsonKey() final  StatutExercice statut;
// Legacy booleans — conservés pour compatibilité
@override@JsonKey() final  bool estOuvert;
@override@JsonKey() final  bool estCloture;
// Clôture
@override final  String? cloturePar;
@override final  DateTime? clotureAt;
// Écritures système
@override final  String? openingEntryId;
@override final  String? closingEntryId;
// Métadonnées
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of ExerciceComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciceComptableCopyWith<_ExerciceComptable> get copyWith => __$ExerciceComptableCopyWithImpl<_ExerciceComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciceComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciceComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.annee, annee) || other.annee == annee)&&(identical(other.dateDebut, dateDebut) || other.dateDebut == dateDebut)&&(identical(other.dateFin, dateFin) || other.dateFin == dateFin)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.estOuvert, estOuvert) || other.estOuvert == estOuvert)&&(identical(other.estCloture, estCloture) || other.estCloture == estCloture)&&(identical(other.cloturePar, cloturePar) || other.cloturePar == cloturePar)&&(identical(other.clotureAt, clotureAt) || other.clotureAt == clotureAt)&&(identical(other.openingEntryId, openingEntryId) || other.openingEntryId == openingEntryId)&&(identical(other.closingEntryId, closingEntryId) || other.closingEntryId == closingEntryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,organizationId,annee,dateDebut,dateFin,libelle,statut,estOuvert,estCloture,cloturePar,clotureAt,openingEntryId,closingEntryId,createdAt,updatedAt);

@override
String toString() {
  return 'ExerciceComptable(id: $id, organizationId: $organizationId, annee: $annee, dateDebut: $dateDebut, dateFin: $dateFin, libelle: $libelle, statut: $statut, estOuvert: $estOuvert, estCloture: $estCloture, cloturePar: $cloturePar, clotureAt: $clotureAt, openingEntryId: $openingEntryId, closingEntryId: $closingEntryId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ExerciceComptableCopyWith<$Res> implements $ExerciceComptableCopyWith<$Res> {
  factory _$ExerciceComptableCopyWith(_ExerciceComptable value, $Res Function(_ExerciceComptable) _then) = __$ExerciceComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, int annee, DateTime dateDebut, DateTime dateFin, String? libelle, StatutExercice statut, bool estOuvert, bool estCloture, String? cloturePar, DateTime? clotureAt, String? openingEntryId, String? closingEntryId, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ExerciceComptableCopyWithImpl<$Res>
    implements _$ExerciceComptableCopyWith<$Res> {
  __$ExerciceComptableCopyWithImpl(this._self, this._then);

  final _ExerciceComptable _self;
  final $Res Function(_ExerciceComptable) _then;

/// Create a copy of ExerciceComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? annee = null,Object? dateDebut = null,Object? dateFin = null,Object? libelle = freezed,Object? statut = null,Object? estOuvert = null,Object? estCloture = null,Object? cloturePar = freezed,Object? clotureAt = freezed,Object? openingEntryId = freezed,Object? closingEntryId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ExerciceComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,dateDebut: null == dateDebut ? _self.dateDebut : dateDebut // ignore: cast_nullable_to_non_nullable
as DateTime,dateFin: null == dateFin ? _self.dateFin : dateFin // ignore: cast_nullable_to_non_nullable
as DateTime,libelle: freezed == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String?,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutExercice,estOuvert: null == estOuvert ? _self.estOuvert : estOuvert // ignore: cast_nullable_to_non_nullable
as bool,estCloture: null == estCloture ? _self.estCloture : estCloture // ignore: cast_nullable_to_non_nullable
as bool,cloturePar: freezed == cloturePar ? _self.cloturePar : cloturePar // ignore: cast_nullable_to_non_nullable
as String?,clotureAt: freezed == clotureAt ? _self.clotureAt : clotureAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openingEntryId: freezed == openingEntryId ? _self.openingEntryId : openingEntryId // ignore: cast_nullable_to_non_nullable
as String?,closingEntryId: freezed == closingEntryId ? _self.closingEntryId : closingEntryId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

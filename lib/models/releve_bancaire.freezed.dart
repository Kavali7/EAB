// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'releve_bancaire.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LigneReleveBancaire {

 String get id; DateTime get dateOperation; String get libelle; double get montant; double get soldeApresOperation; String get idCompteBanque; String? get referenceOperation; bool get estPointe; String? get idEcritureComptableLiee;
/// Create a copy of LigneReleveBancaire
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LigneReleveBancaireCopyWith<LigneReleveBancaire> get copyWith => _$LigneReleveBancaireCopyWithImpl<LigneReleveBancaire>(this as LigneReleveBancaire, _$identity);

  /// Serializes this LigneReleveBancaire to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LigneReleveBancaire&&(identical(other.id, id) || other.id == id)&&(identical(other.dateOperation, dateOperation) || other.dateOperation == dateOperation)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.montant, montant) || other.montant == montant)&&(identical(other.soldeApresOperation, soldeApresOperation) || other.soldeApresOperation == soldeApresOperation)&&(identical(other.idCompteBanque, idCompteBanque) || other.idCompteBanque == idCompteBanque)&&(identical(other.referenceOperation, referenceOperation) || other.referenceOperation == referenceOperation)&&(identical(other.estPointe, estPointe) || other.estPointe == estPointe)&&(identical(other.idEcritureComptableLiee, idEcritureComptableLiee) || other.idEcritureComptableLiee == idEcritureComptableLiee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,dateOperation,libelle,montant,soldeApresOperation,idCompteBanque,referenceOperation,estPointe,idEcritureComptableLiee);

@override
String toString() {
  return 'LigneReleveBancaire(id: $id, dateOperation: $dateOperation, libelle: $libelle, montant: $montant, soldeApresOperation: $soldeApresOperation, idCompteBanque: $idCompteBanque, referenceOperation: $referenceOperation, estPointe: $estPointe, idEcritureComptableLiee: $idEcritureComptableLiee)';
}


}

/// @nodoc
abstract mixin class $LigneReleveBancaireCopyWith<$Res>  {
  factory $LigneReleveBancaireCopyWith(LigneReleveBancaire value, $Res Function(LigneReleveBancaire) _then) = _$LigneReleveBancaireCopyWithImpl;
@useResult
$Res call({
 String id, DateTime dateOperation, String libelle, double montant, double soldeApresOperation, String idCompteBanque, String? referenceOperation, bool estPointe, String? idEcritureComptableLiee
});




}
/// @nodoc
class _$LigneReleveBancaireCopyWithImpl<$Res>
    implements $LigneReleveBancaireCopyWith<$Res> {
  _$LigneReleveBancaireCopyWithImpl(this._self, this._then);

  final LigneReleveBancaire _self;
  final $Res Function(LigneReleveBancaire) _then;

/// Create a copy of LigneReleveBancaire
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dateOperation = null,Object? libelle = null,Object? montant = null,Object? soldeApresOperation = null,Object? idCompteBanque = null,Object? referenceOperation = freezed,Object? estPointe = null,Object? idEcritureComptableLiee = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dateOperation: null == dateOperation ? _self.dateOperation : dateOperation // ignore: cast_nullable_to_non_nullable
as DateTime,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,soldeApresOperation: null == soldeApresOperation ? _self.soldeApresOperation : soldeApresOperation // ignore: cast_nullable_to_non_nullable
as double,idCompteBanque: null == idCompteBanque ? _self.idCompteBanque : idCompteBanque // ignore: cast_nullable_to_non_nullable
as String,referenceOperation: freezed == referenceOperation ? _self.referenceOperation : referenceOperation // ignore: cast_nullable_to_non_nullable
as String?,estPointe: null == estPointe ? _self.estPointe : estPointe // ignore: cast_nullable_to_non_nullable
as bool,idEcritureComptableLiee: freezed == idEcritureComptableLiee ? _self.idEcritureComptableLiee : idEcritureComptableLiee // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LigneReleveBancaire].
extension LigneReleveBancairePatterns on LigneReleveBancaire {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LigneReleveBancaire value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LigneReleveBancaire() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LigneReleveBancaire value)  $default,){
final _that = this;
switch (_that) {
case _LigneReleveBancaire():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LigneReleveBancaire value)?  $default,){
final _that = this;
switch (_that) {
case _LigneReleveBancaire() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime dateOperation,  String libelle,  double montant,  double soldeApresOperation,  String idCompteBanque,  String? referenceOperation,  bool estPointe,  String? idEcritureComptableLiee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LigneReleveBancaire() when $default != null:
return $default(_that.id,_that.dateOperation,_that.libelle,_that.montant,_that.soldeApresOperation,_that.idCompteBanque,_that.referenceOperation,_that.estPointe,_that.idEcritureComptableLiee);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime dateOperation,  String libelle,  double montant,  double soldeApresOperation,  String idCompteBanque,  String? referenceOperation,  bool estPointe,  String? idEcritureComptableLiee)  $default,) {final _that = this;
switch (_that) {
case _LigneReleveBancaire():
return $default(_that.id,_that.dateOperation,_that.libelle,_that.montant,_that.soldeApresOperation,_that.idCompteBanque,_that.referenceOperation,_that.estPointe,_that.idEcritureComptableLiee);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime dateOperation,  String libelle,  double montant,  double soldeApresOperation,  String idCompteBanque,  String? referenceOperation,  bool estPointe,  String? idEcritureComptableLiee)?  $default,) {final _that = this;
switch (_that) {
case _LigneReleveBancaire() when $default != null:
return $default(_that.id,_that.dateOperation,_that.libelle,_that.montant,_that.soldeApresOperation,_that.idCompteBanque,_that.referenceOperation,_that.estPointe,_that.idEcritureComptableLiee);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LigneReleveBancaire implements LigneReleveBancaire {
  const _LigneReleveBancaire({required this.id, required this.dateOperation, required this.libelle, required this.montant, required this.soldeApresOperation, required this.idCompteBanque, this.referenceOperation, this.estPointe = false, this.idEcritureComptableLiee});
  factory _LigneReleveBancaire.fromJson(Map<String, dynamic> json) => _$LigneReleveBancaireFromJson(json);

@override final  String id;
@override final  DateTime dateOperation;
@override final  String libelle;
@override final  double montant;
@override final  double soldeApresOperation;
@override final  String idCompteBanque;
@override final  String? referenceOperation;
@override@JsonKey() final  bool estPointe;
@override final  String? idEcritureComptableLiee;

/// Create a copy of LigneReleveBancaire
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LigneReleveBancaireCopyWith<_LigneReleveBancaire> get copyWith => __$LigneReleveBancaireCopyWithImpl<_LigneReleveBancaire>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LigneReleveBancaireToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LigneReleveBancaire&&(identical(other.id, id) || other.id == id)&&(identical(other.dateOperation, dateOperation) || other.dateOperation == dateOperation)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.montant, montant) || other.montant == montant)&&(identical(other.soldeApresOperation, soldeApresOperation) || other.soldeApresOperation == soldeApresOperation)&&(identical(other.idCompteBanque, idCompteBanque) || other.idCompteBanque == idCompteBanque)&&(identical(other.referenceOperation, referenceOperation) || other.referenceOperation == referenceOperation)&&(identical(other.estPointe, estPointe) || other.estPointe == estPointe)&&(identical(other.idEcritureComptableLiee, idEcritureComptableLiee) || other.idEcritureComptableLiee == idEcritureComptableLiee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,dateOperation,libelle,montant,soldeApresOperation,idCompteBanque,referenceOperation,estPointe,idEcritureComptableLiee);

@override
String toString() {
  return 'LigneReleveBancaire(id: $id, dateOperation: $dateOperation, libelle: $libelle, montant: $montant, soldeApresOperation: $soldeApresOperation, idCompteBanque: $idCompteBanque, referenceOperation: $referenceOperation, estPointe: $estPointe, idEcritureComptableLiee: $idEcritureComptableLiee)';
}


}

/// @nodoc
abstract mixin class _$LigneReleveBancaireCopyWith<$Res> implements $LigneReleveBancaireCopyWith<$Res> {
  factory _$LigneReleveBancaireCopyWith(_LigneReleveBancaire value, $Res Function(_LigneReleveBancaire) _then) = __$LigneReleveBancaireCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime dateOperation, String libelle, double montant, double soldeApresOperation, String idCompteBanque, String? referenceOperation, bool estPointe, String? idEcritureComptableLiee
});




}
/// @nodoc
class __$LigneReleveBancaireCopyWithImpl<$Res>
    implements _$LigneReleveBancaireCopyWith<$Res> {
  __$LigneReleveBancaireCopyWithImpl(this._self, this._then);

  final _LigneReleveBancaire _self;
  final $Res Function(_LigneReleveBancaire) _then;

/// Create a copy of LigneReleveBancaire
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dateOperation = null,Object? libelle = null,Object? montant = null,Object? soldeApresOperation = null,Object? idCompteBanque = null,Object? referenceOperation = freezed,Object? estPointe = null,Object? idEcritureComptableLiee = freezed,}) {
  return _then(_LigneReleveBancaire(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dateOperation: null == dateOperation ? _self.dateOperation : dateOperation // ignore: cast_nullable_to_non_nullable
as DateTime,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,soldeApresOperation: null == soldeApresOperation ? _self.soldeApresOperation : soldeApresOperation // ignore: cast_nullable_to_non_nullable
as double,idCompteBanque: null == idCompteBanque ? _self.idCompteBanque : idCompteBanque // ignore: cast_nullable_to_non_nullable
as String,referenceOperation: freezed == referenceOperation ? _self.referenceOperation : referenceOperation // ignore: cast_nullable_to_non_nullable
as String?,estPointe: null == estPointe ? _self.estPointe : estPointe // ignore: cast_nullable_to_non_nullable
as bool,idEcritureComptableLiee: freezed == idEcritureComptableLiee ? _self.idEcritureComptableLiee : idEcritureComptableLiee // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

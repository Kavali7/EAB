// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_comptable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetComptable {

 String get id; int get exercice; String? get idAssembleeLocale; String? get idCentreAnalytique; String? get idTiersBailleur; String? get libelle; bool get estVerrouille;
/// Create a copy of BudgetComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetComptableCopyWith<BudgetComptable> get copyWith => _$BudgetComptableCopyWithImpl<BudgetComptable>(this as BudgetComptable, _$identity);

  /// Serializes this BudgetComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.exercice, exercice) || other.exercice == exercice)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idCentreAnalytique, idCentreAnalytique) || other.idCentreAnalytique == idCentreAnalytique)&&(identical(other.idTiersBailleur, idTiersBailleur) || other.idTiersBailleur == idTiersBailleur)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.estVerrouille, estVerrouille) || other.estVerrouille == estVerrouille));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exercice,idAssembleeLocale,idCentreAnalytique,idTiersBailleur,libelle,estVerrouille);

@override
String toString() {
  return 'BudgetComptable(id: $id, exercice: $exercice, idAssembleeLocale: $idAssembleeLocale, idCentreAnalytique: $idCentreAnalytique, idTiersBailleur: $idTiersBailleur, libelle: $libelle, estVerrouille: $estVerrouille)';
}


}

/// @nodoc
abstract mixin class $BudgetComptableCopyWith<$Res>  {
  factory $BudgetComptableCopyWith(BudgetComptable value, $Res Function(BudgetComptable) _then) = _$BudgetComptableCopyWithImpl;
@useResult
$Res call({
 String id, int exercice, String? idAssembleeLocale, String? idCentreAnalytique, String? idTiersBailleur, String? libelle, bool estVerrouille
});




}
/// @nodoc
class _$BudgetComptableCopyWithImpl<$Res>
    implements $BudgetComptableCopyWith<$Res> {
  _$BudgetComptableCopyWithImpl(this._self, this._then);

  final BudgetComptable _self;
  final $Res Function(BudgetComptable) _then;

/// Create a copy of BudgetComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exercice = null,Object? idAssembleeLocale = freezed,Object? idCentreAnalytique = freezed,Object? idTiersBailleur = freezed,Object? libelle = freezed,Object? estVerrouille = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exercice: null == exercice ? _self.exercice : exercice // ignore: cast_nullable_to_non_nullable
as int,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idCentreAnalytique: freezed == idCentreAnalytique ? _self.idCentreAnalytique : idCentreAnalytique // ignore: cast_nullable_to_non_nullable
as String?,idTiersBailleur: freezed == idTiersBailleur ? _self.idTiersBailleur : idTiersBailleur // ignore: cast_nullable_to_non_nullable
as String?,libelle: freezed == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String?,estVerrouille: null == estVerrouille ? _self.estVerrouille : estVerrouille // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetComptable].
extension BudgetComptablePatterns on BudgetComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetComptable value)  $default,){
final _that = this;
switch (_that) {
case _BudgetComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetComptable value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int exercice,  String? idAssembleeLocale,  String? idCentreAnalytique,  String? idTiersBailleur,  String? libelle,  bool estVerrouille)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetComptable() when $default != null:
return $default(_that.id,_that.exercice,_that.idAssembleeLocale,_that.idCentreAnalytique,_that.idTiersBailleur,_that.libelle,_that.estVerrouille);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int exercice,  String? idAssembleeLocale,  String? idCentreAnalytique,  String? idTiersBailleur,  String? libelle,  bool estVerrouille)  $default,) {final _that = this;
switch (_that) {
case _BudgetComptable():
return $default(_that.id,_that.exercice,_that.idAssembleeLocale,_that.idCentreAnalytique,_that.idTiersBailleur,_that.libelle,_that.estVerrouille);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int exercice,  String? idAssembleeLocale,  String? idCentreAnalytique,  String? idTiersBailleur,  String? libelle,  bool estVerrouille)?  $default,) {final _that = this;
switch (_that) {
case _BudgetComptable() when $default != null:
return $default(_that.id,_that.exercice,_that.idAssembleeLocale,_that.idCentreAnalytique,_that.idTiersBailleur,_that.libelle,_that.estVerrouille);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetComptable implements BudgetComptable {
  const _BudgetComptable({required this.id, required this.exercice, this.idAssembleeLocale, this.idCentreAnalytique, this.idTiersBailleur, this.libelle, this.estVerrouille = false});
  factory _BudgetComptable.fromJson(Map<String, dynamic> json) => _$BudgetComptableFromJson(json);

@override final  String id;
@override final  int exercice;
@override final  String? idAssembleeLocale;
@override final  String? idCentreAnalytique;
@override final  String? idTiersBailleur;
@override final  String? libelle;
@override@JsonKey() final  bool estVerrouille;

/// Create a copy of BudgetComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetComptableCopyWith<_BudgetComptable> get copyWith => __$BudgetComptableCopyWithImpl<_BudgetComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.exercice, exercice) || other.exercice == exercice)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idCentreAnalytique, idCentreAnalytique) || other.idCentreAnalytique == idCentreAnalytique)&&(identical(other.idTiersBailleur, idTiersBailleur) || other.idTiersBailleur == idTiersBailleur)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.estVerrouille, estVerrouille) || other.estVerrouille == estVerrouille));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exercice,idAssembleeLocale,idCentreAnalytique,idTiersBailleur,libelle,estVerrouille);

@override
String toString() {
  return 'BudgetComptable(id: $id, exercice: $exercice, idAssembleeLocale: $idAssembleeLocale, idCentreAnalytique: $idCentreAnalytique, idTiersBailleur: $idTiersBailleur, libelle: $libelle, estVerrouille: $estVerrouille)';
}


}

/// @nodoc
abstract mixin class _$BudgetComptableCopyWith<$Res> implements $BudgetComptableCopyWith<$Res> {
  factory _$BudgetComptableCopyWith(_BudgetComptable value, $Res Function(_BudgetComptable) _then) = __$BudgetComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, int exercice, String? idAssembleeLocale, String? idCentreAnalytique, String? idTiersBailleur, String? libelle, bool estVerrouille
});




}
/// @nodoc
class __$BudgetComptableCopyWithImpl<$Res>
    implements _$BudgetComptableCopyWith<$Res> {
  __$BudgetComptableCopyWithImpl(this._self, this._then);

  final _BudgetComptable _self;
  final $Res Function(_BudgetComptable) _then;

/// Create a copy of BudgetComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exercice = null,Object? idAssembleeLocale = freezed,Object? idCentreAnalytique = freezed,Object? idTiersBailleur = freezed,Object? libelle = freezed,Object? estVerrouille = null,}) {
  return _then(_BudgetComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exercice: null == exercice ? _self.exercice : exercice // ignore: cast_nullable_to_non_nullable
as int,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idCentreAnalytique: freezed == idCentreAnalytique ? _self.idCentreAnalytique : idCentreAnalytique // ignore: cast_nullable_to_non_nullable
as String?,idTiersBailleur: freezed == idTiersBailleur ? _self.idTiersBailleur : idTiersBailleur // ignore: cast_nullable_to_non_nullable
as String?,libelle: freezed == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String?,estVerrouille: null == estVerrouille ? _self.estVerrouille : estVerrouille // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$LigneBudgetComptable {

 String get id; String get idBudget; String get idCompteComptable; double get montantPrevu; double? get montantRevu;
/// Create a copy of LigneBudgetComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LigneBudgetComptableCopyWith<LigneBudgetComptable> get copyWith => _$LigneBudgetComptableCopyWithImpl<LigneBudgetComptable>(this as LigneBudgetComptable, _$identity);

  /// Serializes this LigneBudgetComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LigneBudgetComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.idBudget, idBudget) || other.idBudget == idBudget)&&(identical(other.idCompteComptable, idCompteComptable) || other.idCompteComptable == idCompteComptable)&&(identical(other.montantPrevu, montantPrevu) || other.montantPrevu == montantPrevu)&&(identical(other.montantRevu, montantRevu) || other.montantRevu == montantRevu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,idBudget,idCompteComptable,montantPrevu,montantRevu);

@override
String toString() {
  return 'LigneBudgetComptable(id: $id, idBudget: $idBudget, idCompteComptable: $idCompteComptable, montantPrevu: $montantPrevu, montantRevu: $montantRevu)';
}


}

/// @nodoc
abstract mixin class $LigneBudgetComptableCopyWith<$Res>  {
  factory $LigneBudgetComptableCopyWith(LigneBudgetComptable value, $Res Function(LigneBudgetComptable) _then) = _$LigneBudgetComptableCopyWithImpl;
@useResult
$Res call({
 String id, String idBudget, String idCompteComptable, double montantPrevu, double? montantRevu
});




}
/// @nodoc
class _$LigneBudgetComptableCopyWithImpl<$Res>
    implements $LigneBudgetComptableCopyWith<$Res> {
  _$LigneBudgetComptableCopyWithImpl(this._self, this._then);

  final LigneBudgetComptable _self;
  final $Res Function(LigneBudgetComptable) _then;

/// Create a copy of LigneBudgetComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? idBudget = null,Object? idCompteComptable = null,Object? montantPrevu = null,Object? montantRevu = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,idBudget: null == idBudget ? _self.idBudget : idBudget // ignore: cast_nullable_to_non_nullable
as String,idCompteComptable: null == idCompteComptable ? _self.idCompteComptable : idCompteComptable // ignore: cast_nullable_to_non_nullable
as String,montantPrevu: null == montantPrevu ? _self.montantPrevu : montantPrevu // ignore: cast_nullable_to_non_nullable
as double,montantRevu: freezed == montantRevu ? _self.montantRevu : montantRevu // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [LigneBudgetComptable].
extension LigneBudgetComptablePatterns on LigneBudgetComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LigneBudgetComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LigneBudgetComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LigneBudgetComptable value)  $default,){
final _that = this;
switch (_that) {
case _LigneBudgetComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LigneBudgetComptable value)?  $default,){
final _that = this;
switch (_that) {
case _LigneBudgetComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String idBudget,  String idCompteComptable,  double montantPrevu,  double? montantRevu)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LigneBudgetComptable() when $default != null:
return $default(_that.id,_that.idBudget,_that.idCompteComptable,_that.montantPrevu,_that.montantRevu);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String idBudget,  String idCompteComptable,  double montantPrevu,  double? montantRevu)  $default,) {final _that = this;
switch (_that) {
case _LigneBudgetComptable():
return $default(_that.id,_that.idBudget,_that.idCompteComptable,_that.montantPrevu,_that.montantRevu);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String idBudget,  String idCompteComptable,  double montantPrevu,  double? montantRevu)?  $default,) {final _that = this;
switch (_that) {
case _LigneBudgetComptable() when $default != null:
return $default(_that.id,_that.idBudget,_that.idCompteComptable,_that.montantPrevu,_that.montantRevu);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LigneBudgetComptable implements LigneBudgetComptable {
  const _LigneBudgetComptable({required this.id, required this.idBudget, required this.idCompteComptable, required this.montantPrevu, this.montantRevu});
  factory _LigneBudgetComptable.fromJson(Map<String, dynamic> json) => _$LigneBudgetComptableFromJson(json);

@override final  String id;
@override final  String idBudget;
@override final  String idCompteComptable;
@override final  double montantPrevu;
@override final  double? montantRevu;

/// Create a copy of LigneBudgetComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LigneBudgetComptableCopyWith<_LigneBudgetComptable> get copyWith => __$LigneBudgetComptableCopyWithImpl<_LigneBudgetComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LigneBudgetComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LigneBudgetComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.idBudget, idBudget) || other.idBudget == idBudget)&&(identical(other.idCompteComptable, idCompteComptable) || other.idCompteComptable == idCompteComptable)&&(identical(other.montantPrevu, montantPrevu) || other.montantPrevu == montantPrevu)&&(identical(other.montantRevu, montantRevu) || other.montantRevu == montantRevu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,idBudget,idCompteComptable,montantPrevu,montantRevu);

@override
String toString() {
  return 'LigneBudgetComptable(id: $id, idBudget: $idBudget, idCompteComptable: $idCompteComptable, montantPrevu: $montantPrevu, montantRevu: $montantRevu)';
}


}

/// @nodoc
abstract mixin class _$LigneBudgetComptableCopyWith<$Res> implements $LigneBudgetComptableCopyWith<$Res> {
  factory _$LigneBudgetComptableCopyWith(_LigneBudgetComptable value, $Res Function(_LigneBudgetComptable) _then) = __$LigneBudgetComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, String idBudget, String idCompteComptable, double montantPrevu, double? montantRevu
});




}
/// @nodoc
class __$LigneBudgetComptableCopyWithImpl<$Res>
    implements _$LigneBudgetComptableCopyWith<$Res> {
  __$LigneBudgetComptableCopyWithImpl(this._self, this._then);

  final _LigneBudgetComptable _self;
  final $Res Function(_LigneBudgetComptable) _then;

/// Create a copy of LigneBudgetComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? idBudget = null,Object? idCompteComptable = null,Object? montantPrevu = null,Object? montantRevu = freezed,}) {
  return _then(_LigneBudgetComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,idBudget: null == idBudget ? _self.idBudget : idBudget // ignore: cast_nullable_to_non_nullable
as String,idCompteComptable: null == idCompteComptable ? _self.idCompteComptable : idCompteComptable // ignore: cast_nullable_to_non_nullable
as String,montantPrevu: null == montantPrevu ? _self.montantPrevu : montantPrevu // ignore: cast_nullable_to_non_nullable
as double,montantRevu: freezed == montantRevu ? _self.montantRevu : montantRevu // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on

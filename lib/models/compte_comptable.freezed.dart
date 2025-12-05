// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compte_comptable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompteComptable {

 String get id;// identifiant interne (UUID ou similaire)
 String get numero;// numero du compte (ex: "5121", "701")
 String get intitule;// libelle du compte
 NatureCompte get nature;// actif, passif, charge, produit, etc.
 int? get niveau;// niveau dans l'arborescence (1 = classe, 2 = compte, 3 = sous-compte)
 String? get idCompteParent;// lien vers un compte parent pour construire l'arborescence
 bool get actif;
/// Create a copy of CompteComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompteComptableCopyWith<CompteComptable> get copyWith => _$CompteComptableCopyWithImpl<CompteComptable>(this as CompteComptable, _$identity);

  /// Serializes this CompteComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompteComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.numero, numero) || other.numero == numero)&&(identical(other.intitule, intitule) || other.intitule == intitule)&&(identical(other.nature, nature) || other.nature == nature)&&(identical(other.niveau, niveau) || other.niveau == niveau)&&(identical(other.idCompteParent, idCompteParent) || other.idCompteParent == idCompteParent)&&(identical(other.actif, actif) || other.actif == actif));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,numero,intitule,nature,niveau,idCompteParent,actif);

@override
String toString() {
  return 'CompteComptable(id: $id, numero: $numero, intitule: $intitule, nature: $nature, niveau: $niveau, idCompteParent: $idCompteParent, actif: $actif)';
}


}

/// @nodoc
abstract mixin class $CompteComptableCopyWith<$Res>  {
  factory $CompteComptableCopyWith(CompteComptable value, $Res Function(CompteComptable) _then) = _$CompteComptableCopyWithImpl;
@useResult
$Res call({
 String id, String numero, String intitule, NatureCompte nature, int? niveau, String? idCompteParent, bool actif
});




}
/// @nodoc
class _$CompteComptableCopyWithImpl<$Res>
    implements $CompteComptableCopyWith<$Res> {
  _$CompteComptableCopyWithImpl(this._self, this._then);

  final CompteComptable _self;
  final $Res Function(CompteComptable) _then;

/// Create a copy of CompteComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? numero = null,Object? intitule = null,Object? nature = null,Object? niveau = freezed,Object? idCompteParent = freezed,Object? actif = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,numero: null == numero ? _self.numero : numero // ignore: cast_nullable_to_non_nullable
as String,intitule: null == intitule ? _self.intitule : intitule // ignore: cast_nullable_to_non_nullable
as String,nature: null == nature ? _self.nature : nature // ignore: cast_nullable_to_non_nullable
as NatureCompte,niveau: freezed == niveau ? _self.niveau : niveau // ignore: cast_nullable_to_non_nullable
as int?,idCompteParent: freezed == idCompteParent ? _self.idCompteParent : idCompteParent // ignore: cast_nullable_to_non_nullable
as String?,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CompteComptable].
extension CompteComptablePatterns on CompteComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompteComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompteComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompteComptable value)  $default,){
final _that = this;
switch (_that) {
case _CompteComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompteComptable value)?  $default,){
final _that = this;
switch (_that) {
case _CompteComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String numero,  String intitule,  NatureCompte nature,  int? niveau,  String? idCompteParent,  bool actif)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompteComptable() when $default != null:
return $default(_that.id,_that.numero,_that.intitule,_that.nature,_that.niveau,_that.idCompteParent,_that.actif);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String numero,  String intitule,  NatureCompte nature,  int? niveau,  String? idCompteParent,  bool actif)  $default,) {final _that = this;
switch (_that) {
case _CompteComptable():
return $default(_that.id,_that.numero,_that.intitule,_that.nature,_that.niveau,_that.idCompteParent,_that.actif);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String numero,  String intitule,  NatureCompte nature,  int? niveau,  String? idCompteParent,  bool actif)?  $default,) {final _that = this;
switch (_that) {
case _CompteComptable() when $default != null:
return $default(_that.id,_that.numero,_that.intitule,_that.nature,_that.niveau,_that.idCompteParent,_that.actif);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompteComptable implements CompteComptable {
  const _CompteComptable({required this.id, required this.numero, required this.intitule, required this.nature, this.niveau, this.idCompteParent, this.actif = true});
  factory _CompteComptable.fromJson(Map<String, dynamic> json) => _$CompteComptableFromJson(json);

@override final  String id;
// identifiant interne (UUID ou similaire)
@override final  String numero;
// numero du compte (ex: "5121", "701")
@override final  String intitule;
// libelle du compte
@override final  NatureCompte nature;
// actif, passif, charge, produit, etc.
@override final  int? niveau;
// niveau dans l'arborescence (1 = classe, 2 = compte, 3 = sous-compte)
@override final  String? idCompteParent;
// lien vers un compte parent pour construire l'arborescence
@override@JsonKey() final  bool actif;

/// Create a copy of CompteComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompteComptableCopyWith<_CompteComptable> get copyWith => __$CompteComptableCopyWithImpl<_CompteComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompteComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompteComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.numero, numero) || other.numero == numero)&&(identical(other.intitule, intitule) || other.intitule == intitule)&&(identical(other.nature, nature) || other.nature == nature)&&(identical(other.niveau, niveau) || other.niveau == niveau)&&(identical(other.idCompteParent, idCompteParent) || other.idCompteParent == idCompteParent)&&(identical(other.actif, actif) || other.actif == actif));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,numero,intitule,nature,niveau,idCompteParent,actif);

@override
String toString() {
  return 'CompteComptable(id: $id, numero: $numero, intitule: $intitule, nature: $nature, niveau: $niveau, idCompteParent: $idCompteParent, actif: $actif)';
}


}

/// @nodoc
abstract mixin class _$CompteComptableCopyWith<$Res> implements $CompteComptableCopyWith<$Res> {
  factory _$CompteComptableCopyWith(_CompteComptable value, $Res Function(_CompteComptable) _then) = __$CompteComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, String numero, String intitule, NatureCompte nature, int? niveau, String? idCompteParent, bool actif
});




}
/// @nodoc
class __$CompteComptableCopyWithImpl<$Res>
    implements _$CompteComptableCopyWith<$Res> {
  __$CompteComptableCopyWithImpl(this._self, this._then);

  final _CompteComptable _self;
  final $Res Function(_CompteComptable) _then;

/// Create a copy of CompteComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? numero = null,Object? intitule = null,Object? nature = null,Object? niveau = freezed,Object? idCompteParent = freezed,Object? actif = null,}) {
  return _then(_CompteComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,numero: null == numero ? _self.numero : numero // ignore: cast_nullable_to_non_nullable
as String,intitule: null == intitule ? _self.intitule : intitule // ignore: cast_nullable_to_non_nullable
as String,nature: null == nature ? _self.nature : nature // ignore: cast_nullable_to_non_nullable
as NatureCompte,niveau: freezed == niveau ? _self.niveau : niveau // ignore: cast_nullable_to_non_nullable
as int?,idCompteParent: freezed == idCompteParent ? _self.idCompteParent : idCompteParent // ignore: cast_nullable_to_non_nullable
as String?,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

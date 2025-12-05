// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profil_utilisateur.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfilUtilisateur {

 String get id; String get nom; RoleUtilisateur get role; String? get idRegion; String? get idDistrict; String? get idAssembleeLocale;
/// Create a copy of ProfilUtilisateur
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfilUtilisateurCopyWith<ProfilUtilisateur> get copyWith => _$ProfilUtilisateurCopyWithImpl<ProfilUtilisateur>(this as ProfilUtilisateur, _$identity);

  /// Serializes this ProfilUtilisateur to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfilUtilisateur&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.role, role) || other.role == role)&&(identical(other.idRegion, idRegion) || other.idRegion == idRegion)&&(identical(other.idDistrict, idDistrict) || other.idDistrict == idDistrict)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,role,idRegion,idDistrict,idAssembleeLocale);

@override
String toString() {
  return 'ProfilUtilisateur(id: $id, nom: $nom, role: $role, idRegion: $idRegion, idDistrict: $idDistrict, idAssembleeLocale: $idAssembleeLocale)';
}


}

/// @nodoc
abstract mixin class $ProfilUtilisateurCopyWith<$Res>  {
  factory $ProfilUtilisateurCopyWith(ProfilUtilisateur value, $Res Function(ProfilUtilisateur) _then) = _$ProfilUtilisateurCopyWithImpl;
@useResult
$Res call({
 String id, String nom, RoleUtilisateur role, String? idRegion, String? idDistrict, String? idAssembleeLocale
});




}
/// @nodoc
class _$ProfilUtilisateurCopyWithImpl<$Res>
    implements $ProfilUtilisateurCopyWith<$Res> {
  _$ProfilUtilisateurCopyWithImpl(this._self, this._then);

  final ProfilUtilisateur _self;
  final $Res Function(ProfilUtilisateur) _then;

/// Create a copy of ProfilUtilisateur
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? role = null,Object? idRegion = freezed,Object? idDistrict = freezed,Object? idAssembleeLocale = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RoleUtilisateur,idRegion: freezed == idRegion ? _self.idRegion : idRegion // ignore: cast_nullable_to_non_nullable
as String?,idDistrict: freezed == idDistrict ? _self.idDistrict : idDistrict // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfilUtilisateur].
extension ProfilUtilisateurPatterns on ProfilUtilisateur {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfilUtilisateur value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfilUtilisateur() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfilUtilisateur value)  $default,){
final _that = this;
switch (_that) {
case _ProfilUtilisateur():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfilUtilisateur value)?  $default,){
final _that = this;
switch (_that) {
case _ProfilUtilisateur() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  RoleUtilisateur role,  String? idRegion,  String? idDistrict,  String? idAssembleeLocale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfilUtilisateur() when $default != null:
return $default(_that.id,_that.nom,_that.role,_that.idRegion,_that.idDistrict,_that.idAssembleeLocale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  RoleUtilisateur role,  String? idRegion,  String? idDistrict,  String? idAssembleeLocale)  $default,) {final _that = this;
switch (_that) {
case _ProfilUtilisateur():
return $default(_that.id,_that.nom,_that.role,_that.idRegion,_that.idDistrict,_that.idAssembleeLocale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  RoleUtilisateur role,  String? idRegion,  String? idDistrict,  String? idAssembleeLocale)?  $default,) {final _that = this;
switch (_that) {
case _ProfilUtilisateur() when $default != null:
return $default(_that.id,_that.nom,_that.role,_that.idRegion,_that.idDistrict,_that.idAssembleeLocale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfilUtilisateur implements ProfilUtilisateur {
  const _ProfilUtilisateur({required this.id, required this.nom, required this.role, this.idRegion, this.idDistrict, this.idAssembleeLocale});
  factory _ProfilUtilisateur.fromJson(Map<String, dynamic> json) => _$ProfilUtilisateurFromJson(json);

@override final  String id;
@override final  String nom;
@override final  RoleUtilisateur role;
@override final  String? idRegion;
@override final  String? idDistrict;
@override final  String? idAssembleeLocale;

/// Create a copy of ProfilUtilisateur
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfilUtilisateurCopyWith<_ProfilUtilisateur> get copyWith => __$ProfilUtilisateurCopyWithImpl<_ProfilUtilisateur>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfilUtilisateurToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfilUtilisateur&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.role, role) || other.role == role)&&(identical(other.idRegion, idRegion) || other.idRegion == idRegion)&&(identical(other.idDistrict, idDistrict) || other.idDistrict == idDistrict)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,role,idRegion,idDistrict,idAssembleeLocale);

@override
String toString() {
  return 'ProfilUtilisateur(id: $id, nom: $nom, role: $role, idRegion: $idRegion, idDistrict: $idDistrict, idAssembleeLocale: $idAssembleeLocale)';
}


}

/// @nodoc
abstract mixin class _$ProfilUtilisateurCopyWith<$Res> implements $ProfilUtilisateurCopyWith<$Res> {
  factory _$ProfilUtilisateurCopyWith(_ProfilUtilisateur value, $Res Function(_ProfilUtilisateur) _then) = __$ProfilUtilisateurCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, RoleUtilisateur role, String? idRegion, String? idDistrict, String? idAssembleeLocale
});




}
/// @nodoc
class __$ProfilUtilisateurCopyWithImpl<$Res>
    implements _$ProfilUtilisateurCopyWith<$Res> {
  __$ProfilUtilisateurCopyWithImpl(this._self, this._then);

  final _ProfilUtilisateur _self;
  final $Res Function(_ProfilUtilisateur) _then;

/// Create a copy of ProfilUtilisateur
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? role = null,Object? idRegion = freezed,Object? idDistrict = freezed,Object? idAssembleeLocale = freezed,}) {
  return _then(_ProfilUtilisateur(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RoleUtilisateur,idRegion: freezed == idRegion ? _self.idRegion : idRegion // ignore: cast_nullable_to_non_nullable
as String?,idDistrict: freezed == idDistrict ? _self.idDistrict : idDistrict // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

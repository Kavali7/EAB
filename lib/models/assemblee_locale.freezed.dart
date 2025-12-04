// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assemblee_locale.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssembleeLocale {

 String get id; String get nom; String? get code; String get idDistrict; String? get ville; String? get quartier; String? get adressePostale; String? get telephone; String? get email; String? get idFidelePasteurResponsable;
/// Create a copy of AssembleeLocale
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssembleeLocaleCopyWith<AssembleeLocale> get copyWith => _$AssembleeLocaleCopyWithImpl<AssembleeLocale>(this as AssembleeLocale, _$identity);

  /// Serializes this AssembleeLocale to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssembleeLocale&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.code, code) || other.code == code)&&(identical(other.idDistrict, idDistrict) || other.idDistrict == idDistrict)&&(identical(other.ville, ville) || other.ville == ville)&&(identical(other.quartier, quartier) || other.quartier == quartier)&&(identical(other.adressePostale, adressePostale) || other.adressePostale == adressePostale)&&(identical(other.telephone, telephone) || other.telephone == telephone)&&(identical(other.email, email) || other.email == email)&&(identical(other.idFidelePasteurResponsable, idFidelePasteurResponsable) || other.idFidelePasteurResponsable == idFidelePasteurResponsable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,code,idDistrict,ville,quartier,adressePostale,telephone,email,idFidelePasteurResponsable);

@override
String toString() {
  return 'AssembleeLocale(id: $id, nom: $nom, code: $code, idDistrict: $idDistrict, ville: $ville, quartier: $quartier, adressePostale: $adressePostale, telephone: $telephone, email: $email, idFidelePasteurResponsable: $idFidelePasteurResponsable)';
}


}

/// @nodoc
abstract mixin class $AssembleeLocaleCopyWith<$Res>  {
  factory $AssembleeLocaleCopyWith(AssembleeLocale value, $Res Function(AssembleeLocale) _then) = _$AssembleeLocaleCopyWithImpl;
@useResult
$Res call({
 String id, String nom, String? code, String idDistrict, String? ville, String? quartier, String? adressePostale, String? telephone, String? email, String? idFidelePasteurResponsable
});




}
/// @nodoc
class _$AssembleeLocaleCopyWithImpl<$Res>
    implements $AssembleeLocaleCopyWith<$Res> {
  _$AssembleeLocaleCopyWithImpl(this._self, this._then);

  final AssembleeLocale _self;
  final $Res Function(AssembleeLocale) _then;

/// Create a copy of AssembleeLocale
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? code = freezed,Object? idDistrict = null,Object? ville = freezed,Object? quartier = freezed,Object? adressePostale = freezed,Object? telephone = freezed,Object? email = freezed,Object? idFidelePasteurResponsable = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,idDistrict: null == idDistrict ? _self.idDistrict : idDistrict // ignore: cast_nullable_to_non_nullable
as String,ville: freezed == ville ? _self.ville : ville // ignore: cast_nullable_to_non_nullable
as String?,quartier: freezed == quartier ? _self.quartier : quartier // ignore: cast_nullable_to_non_nullable
as String?,adressePostale: freezed == adressePostale ? _self.adressePostale : adressePostale // ignore: cast_nullable_to_non_nullable
as String?,telephone: freezed == telephone ? _self.telephone : telephone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idFidelePasteurResponsable: freezed == idFidelePasteurResponsable ? _self.idFidelePasteurResponsable : idFidelePasteurResponsable // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssembleeLocale].
extension AssembleeLocalePatterns on AssembleeLocale {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssembleeLocale value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssembleeLocale() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssembleeLocale value)  $default,){
final _that = this;
switch (_that) {
case _AssembleeLocale():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssembleeLocale value)?  $default,){
final _that = this;
switch (_that) {
case _AssembleeLocale() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  String? code,  String idDistrict,  String? ville,  String? quartier,  String? adressePostale,  String? telephone,  String? email,  String? idFidelePasteurResponsable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssembleeLocale() when $default != null:
return $default(_that.id,_that.nom,_that.code,_that.idDistrict,_that.ville,_that.quartier,_that.adressePostale,_that.telephone,_that.email,_that.idFidelePasteurResponsable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  String? code,  String idDistrict,  String? ville,  String? quartier,  String? adressePostale,  String? telephone,  String? email,  String? idFidelePasteurResponsable)  $default,) {final _that = this;
switch (_that) {
case _AssembleeLocale():
return $default(_that.id,_that.nom,_that.code,_that.idDistrict,_that.ville,_that.quartier,_that.adressePostale,_that.telephone,_that.email,_that.idFidelePasteurResponsable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  String? code,  String idDistrict,  String? ville,  String? quartier,  String? adressePostale,  String? telephone,  String? email,  String? idFidelePasteurResponsable)?  $default,) {final _that = this;
switch (_that) {
case _AssembleeLocale() when $default != null:
return $default(_that.id,_that.nom,_that.code,_that.idDistrict,_that.ville,_that.quartier,_that.adressePostale,_that.telephone,_that.email,_that.idFidelePasteurResponsable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssembleeLocale extends AssembleeLocale {
  const _AssembleeLocale({required this.id, required this.nom, this.code, required this.idDistrict, this.ville, this.quartier, this.adressePostale, this.telephone, this.email, this.idFidelePasteurResponsable}): super._();
  factory _AssembleeLocale.fromJson(Map<String, dynamic> json) => _$AssembleeLocaleFromJson(json);

@override final  String id;
@override final  String nom;
@override final  String? code;
@override final  String idDistrict;
@override final  String? ville;
@override final  String? quartier;
@override final  String? adressePostale;
@override final  String? telephone;
@override final  String? email;
@override final  String? idFidelePasteurResponsable;

/// Create a copy of AssembleeLocale
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssembleeLocaleCopyWith<_AssembleeLocale> get copyWith => __$AssembleeLocaleCopyWithImpl<_AssembleeLocale>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssembleeLocaleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssembleeLocale&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.code, code) || other.code == code)&&(identical(other.idDistrict, idDistrict) || other.idDistrict == idDistrict)&&(identical(other.ville, ville) || other.ville == ville)&&(identical(other.quartier, quartier) || other.quartier == quartier)&&(identical(other.adressePostale, adressePostale) || other.adressePostale == adressePostale)&&(identical(other.telephone, telephone) || other.telephone == telephone)&&(identical(other.email, email) || other.email == email)&&(identical(other.idFidelePasteurResponsable, idFidelePasteurResponsable) || other.idFidelePasteurResponsable == idFidelePasteurResponsable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,code,idDistrict,ville,quartier,adressePostale,telephone,email,idFidelePasteurResponsable);

@override
String toString() {
  return 'AssembleeLocale(id: $id, nom: $nom, code: $code, idDistrict: $idDistrict, ville: $ville, quartier: $quartier, adressePostale: $adressePostale, telephone: $telephone, email: $email, idFidelePasteurResponsable: $idFidelePasteurResponsable)';
}


}

/// @nodoc
abstract mixin class _$AssembleeLocaleCopyWith<$Res> implements $AssembleeLocaleCopyWith<$Res> {
  factory _$AssembleeLocaleCopyWith(_AssembleeLocale value, $Res Function(_AssembleeLocale) _then) = __$AssembleeLocaleCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, String? code, String idDistrict, String? ville, String? quartier, String? adressePostale, String? telephone, String? email, String? idFidelePasteurResponsable
});




}
/// @nodoc
class __$AssembleeLocaleCopyWithImpl<$Res>
    implements _$AssembleeLocaleCopyWith<$Res> {
  __$AssembleeLocaleCopyWithImpl(this._self, this._then);

  final _AssembleeLocale _self;
  final $Res Function(_AssembleeLocale) _then;

/// Create a copy of AssembleeLocale
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? code = freezed,Object? idDistrict = null,Object? ville = freezed,Object? quartier = freezed,Object? adressePostale = freezed,Object? telephone = freezed,Object? email = freezed,Object? idFidelePasteurResponsable = freezed,}) {
  return _then(_AssembleeLocale(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,idDistrict: null == idDistrict ? _self.idDistrict : idDistrict // ignore: cast_nullable_to_non_nullable
as String,ville: freezed == ville ? _self.ville : ville // ignore: cast_nullable_to_non_nullable
as String?,quartier: freezed == quartier ? _self.quartier : quartier // ignore: cast_nullable_to_non_nullable
as String?,adressePostale: freezed == adressePostale ? _self.adressePostale : adressePostale // ignore: cast_nullable_to_non_nullable
as String?,telephone: freezed == telephone ? _self.telephone : telephone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,idFidelePasteurResponsable: freezed == idFidelePasteurResponsable ? _self.idFidelePasteurResponsable : idFidelePasteurResponsable // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

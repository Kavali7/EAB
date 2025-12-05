// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tiers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Tiers {

 String get id; String get nom; TypeTiers get type; String? get telephone; String? get email; String? get adresse;// Rattachement eventuel a une assemblee
 String? get idAssembleeLocale;// Pour lier un tiers a un fidele existant (ex: membre)
 String? get idFideleLie;
/// Create a copy of Tiers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TiersCopyWith<Tiers> get copyWith => _$TiersCopyWithImpl<Tiers>(this as Tiers, _$identity);

  /// Serializes this Tiers to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tiers&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.telephone, telephone) || other.telephone == telephone)&&(identical(other.email, email) || other.email == email)&&(identical(other.adresse, adresse) || other.adresse == adresse)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idFideleLie, idFideleLie) || other.idFideleLie == idFideleLie));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,type,telephone,email,adresse,idAssembleeLocale,idFideleLie);

@override
String toString() {
  return 'Tiers(id: $id, nom: $nom, type: $type, telephone: $telephone, email: $email, adresse: $adresse, idAssembleeLocale: $idAssembleeLocale, idFideleLie: $idFideleLie)';
}


}

/// @nodoc
abstract mixin class $TiersCopyWith<$Res>  {
  factory $TiersCopyWith(Tiers value, $Res Function(Tiers) _then) = _$TiersCopyWithImpl;
@useResult
$Res call({
 String id, String nom, TypeTiers type, String? telephone, String? email, String? adresse, String? idAssembleeLocale, String? idFideleLie
});




}
/// @nodoc
class _$TiersCopyWithImpl<$Res>
    implements $TiersCopyWith<$Res> {
  _$TiersCopyWithImpl(this._self, this._then);

  final Tiers _self;
  final $Res Function(Tiers) _then;

/// Create a copy of Tiers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? type = null,Object? telephone = freezed,Object? email = freezed,Object? adresse = freezed,Object? idAssembleeLocale = freezed,Object? idFideleLie = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeTiers,telephone: freezed == telephone ? _self.telephone : telephone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,adresse: freezed == adresse ? _self.adresse : adresse // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idFideleLie: freezed == idFideleLie ? _self.idFideleLie : idFideleLie // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Tiers].
extension TiersPatterns on Tiers {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tiers value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tiers() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tiers value)  $default,){
final _that = this;
switch (_that) {
case _Tiers():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tiers value)?  $default,){
final _that = this;
switch (_that) {
case _Tiers() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  TypeTiers type,  String? telephone,  String? email,  String? adresse,  String? idAssembleeLocale,  String? idFideleLie)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tiers() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.telephone,_that.email,_that.adresse,_that.idAssembleeLocale,_that.idFideleLie);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  TypeTiers type,  String? telephone,  String? email,  String? adresse,  String? idAssembleeLocale,  String? idFideleLie)  $default,) {final _that = this;
switch (_that) {
case _Tiers():
return $default(_that.id,_that.nom,_that.type,_that.telephone,_that.email,_that.adresse,_that.idAssembleeLocale,_that.idFideleLie);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  TypeTiers type,  String? telephone,  String? email,  String? adresse,  String? idAssembleeLocale,  String? idFideleLie)?  $default,) {final _that = this;
switch (_that) {
case _Tiers() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.telephone,_that.email,_that.adresse,_that.idAssembleeLocale,_that.idFideleLie);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tiers implements Tiers {
  const _Tiers({required this.id, required this.nom, required this.type, this.telephone, this.email, this.adresse, this.idAssembleeLocale, this.idFideleLie});
  factory _Tiers.fromJson(Map<String, dynamic> json) => _$TiersFromJson(json);

@override final  String id;
@override final  String nom;
@override final  TypeTiers type;
@override final  String? telephone;
@override final  String? email;
@override final  String? adresse;
// Rattachement eventuel a une assemblee
@override final  String? idAssembleeLocale;
// Pour lier un tiers a un fidele existant (ex: membre)
@override final  String? idFideleLie;

/// Create a copy of Tiers
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TiersCopyWith<_Tiers> get copyWith => __$TiersCopyWithImpl<_Tiers>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TiersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tiers&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.telephone, telephone) || other.telephone == telephone)&&(identical(other.email, email) || other.email == email)&&(identical(other.adresse, adresse) || other.adresse == adresse)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idFideleLie, idFideleLie) || other.idFideleLie == idFideleLie));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,type,telephone,email,adresse,idAssembleeLocale,idFideleLie);

@override
String toString() {
  return 'Tiers(id: $id, nom: $nom, type: $type, telephone: $telephone, email: $email, adresse: $adresse, idAssembleeLocale: $idAssembleeLocale, idFideleLie: $idFideleLie)';
}


}

/// @nodoc
abstract mixin class _$TiersCopyWith<$Res> implements $TiersCopyWith<$Res> {
  factory _$TiersCopyWith(_Tiers value, $Res Function(_Tiers) _then) = __$TiersCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, TypeTiers type, String? telephone, String? email, String? adresse, String? idAssembleeLocale, String? idFideleLie
});




}
/// @nodoc
class __$TiersCopyWithImpl<$Res>
    implements _$TiersCopyWith<$Res> {
  __$TiersCopyWithImpl(this._self, this._then);

  final _Tiers _self;
  final $Res Function(_Tiers) _then;

/// Create a copy of Tiers
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? type = null,Object? telephone = freezed,Object? email = freezed,Object? adresse = freezed,Object? idAssembleeLocale = freezed,Object? idFideleLie = freezed,}) {
  return _then(_Tiers(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeTiers,telephone: freezed == telephone ? _self.telephone : telephone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,adresse: freezed == adresse ? _self.adresse : adresse // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idFideleLie: freezed == idFideleLie ? _self.idFideleLie : idFideleLie // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

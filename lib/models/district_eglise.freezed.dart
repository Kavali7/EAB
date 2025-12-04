// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'district_eglise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DistrictEglise {

 String get id; String get nom; String? get code; String get idRegion; String? get description;
/// Create a copy of DistrictEglise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DistrictEgliseCopyWith<DistrictEglise> get copyWith => _$DistrictEgliseCopyWithImpl<DistrictEglise>(this as DistrictEglise, _$identity);

  /// Serializes this DistrictEglise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DistrictEglise&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.code, code) || other.code == code)&&(identical(other.idRegion, idRegion) || other.idRegion == idRegion)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,code,idRegion,description);

@override
String toString() {
  return 'DistrictEglise(id: $id, nom: $nom, code: $code, idRegion: $idRegion, description: $description)';
}


}

/// @nodoc
abstract mixin class $DistrictEgliseCopyWith<$Res>  {
  factory $DistrictEgliseCopyWith(DistrictEglise value, $Res Function(DistrictEglise) _then) = _$DistrictEgliseCopyWithImpl;
@useResult
$Res call({
 String id, String nom, String? code, String idRegion, String? description
});




}
/// @nodoc
class _$DistrictEgliseCopyWithImpl<$Res>
    implements $DistrictEgliseCopyWith<$Res> {
  _$DistrictEgliseCopyWithImpl(this._self, this._then);

  final DistrictEglise _self;
  final $Res Function(DistrictEglise) _then;

/// Create a copy of DistrictEglise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? code = freezed,Object? idRegion = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,idRegion: null == idRegion ? _self.idRegion : idRegion // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DistrictEglise].
extension DistrictEglisePatterns on DistrictEglise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DistrictEglise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DistrictEglise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DistrictEglise value)  $default,){
final _that = this;
switch (_that) {
case _DistrictEglise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DistrictEglise value)?  $default,){
final _that = this;
switch (_that) {
case _DistrictEglise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  String? code,  String idRegion,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DistrictEglise() when $default != null:
return $default(_that.id,_that.nom,_that.code,_that.idRegion,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  String? code,  String idRegion,  String? description)  $default,) {final _that = this;
switch (_that) {
case _DistrictEglise():
return $default(_that.id,_that.nom,_that.code,_that.idRegion,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  String? code,  String idRegion,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _DistrictEglise() when $default != null:
return $default(_that.id,_that.nom,_that.code,_that.idRegion,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DistrictEglise extends DistrictEglise {
  const _DistrictEglise({required this.id, required this.nom, this.code, required this.idRegion, this.description}): super._();
  factory _DistrictEglise.fromJson(Map<String, dynamic> json) => _$DistrictEgliseFromJson(json);

@override final  String id;
@override final  String nom;
@override final  String? code;
@override final  String idRegion;
@override final  String? description;

/// Create a copy of DistrictEglise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DistrictEgliseCopyWith<_DistrictEglise> get copyWith => __$DistrictEgliseCopyWithImpl<_DistrictEglise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DistrictEgliseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DistrictEglise&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.code, code) || other.code == code)&&(identical(other.idRegion, idRegion) || other.idRegion == idRegion)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,code,idRegion,description);

@override
String toString() {
  return 'DistrictEglise(id: $id, nom: $nom, code: $code, idRegion: $idRegion, description: $description)';
}


}

/// @nodoc
abstract mixin class _$DistrictEgliseCopyWith<$Res> implements $DistrictEgliseCopyWith<$Res> {
  factory _$DistrictEgliseCopyWith(_DistrictEglise value, $Res Function(_DistrictEglise) _then) = __$DistrictEgliseCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, String? code, String idRegion, String? description
});




}
/// @nodoc
class __$DistrictEgliseCopyWithImpl<$Res>
    implements _$DistrictEgliseCopyWith<$Res> {
  __$DistrictEgliseCopyWithImpl(this._self, this._then);

  final _DistrictEglise _self;
  final $Res Function(_DistrictEglise) _then;

/// Create a copy of DistrictEglise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? code = freezed,Object? idRegion = null,Object? description = freezed,}) {
  return _then(_DistrictEglise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,idRegion: null == idRegion ? _self.idRegion : idRegion // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

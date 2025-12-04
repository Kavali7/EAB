// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'region_eglise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegionEglise {

 String get id; String get nom; String? get code; String? get description;
/// Create a copy of RegionEglise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionEgliseCopyWith<RegionEglise> get copyWith => _$RegionEgliseCopyWithImpl<RegionEglise>(this as RegionEglise, _$identity);

  /// Serializes this RegionEglise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionEglise&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.code, code) || other.code == code)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,code,description);

@override
String toString() {
  return 'RegionEglise(id: $id, nom: $nom, code: $code, description: $description)';
}


}

/// @nodoc
abstract mixin class $RegionEgliseCopyWith<$Res>  {
  factory $RegionEgliseCopyWith(RegionEglise value, $Res Function(RegionEglise) _then) = _$RegionEgliseCopyWithImpl;
@useResult
$Res call({
 String id, String nom, String? code, String? description
});




}
/// @nodoc
class _$RegionEgliseCopyWithImpl<$Res>
    implements $RegionEgliseCopyWith<$Res> {
  _$RegionEgliseCopyWithImpl(this._self, this._then);

  final RegionEglise _self;
  final $Res Function(RegionEglise) _then;

/// Create a copy of RegionEglise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? code = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RegionEglise].
extension RegionEglisePatterns on RegionEglise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegionEglise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegionEglise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegionEglise value)  $default,){
final _that = this;
switch (_that) {
case _RegionEglise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegionEglise value)?  $default,){
final _that = this;
switch (_that) {
case _RegionEglise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  String? code,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegionEglise() when $default != null:
return $default(_that.id,_that.nom,_that.code,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  String? code,  String? description)  $default,) {final _that = this;
switch (_that) {
case _RegionEglise():
return $default(_that.id,_that.nom,_that.code,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  String? code,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _RegionEglise() when $default != null:
return $default(_that.id,_that.nom,_that.code,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegionEglise extends RegionEglise {
  const _RegionEglise({required this.id, required this.nom, this.code, this.description}): super._();
  factory _RegionEglise.fromJson(Map<String, dynamic> json) => _$RegionEgliseFromJson(json);

@override final  String id;
@override final  String nom;
@override final  String? code;
@override final  String? description;

/// Create a copy of RegionEglise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegionEgliseCopyWith<_RegionEglise> get copyWith => __$RegionEgliseCopyWithImpl<_RegionEglise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegionEgliseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegionEglise&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.code, code) || other.code == code)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,code,description);

@override
String toString() {
  return 'RegionEglise(id: $id, nom: $nom, code: $code, description: $description)';
}


}

/// @nodoc
abstract mixin class _$RegionEgliseCopyWith<$Res> implements $RegionEgliseCopyWith<$Res> {
  factory _$RegionEgliseCopyWith(_RegionEglise value, $Res Function(_RegionEglise) _then) = __$RegionEgliseCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, String? code, String? description
});




}
/// @nodoc
class __$RegionEgliseCopyWithImpl<$Res>
    implements _$RegionEgliseCopyWith<$Res> {
  __$RegionEgliseCopyWithImpl(this._self, this._then);

  final _RegionEglise _self;
  final $Res Function(_RegionEglise) _then;

/// Create a copy of RegionEglise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? code = freezed,Object? description = freezed,}) {
  return _then(_RegionEglise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

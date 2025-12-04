// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'famille.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Famille {

 String get id; String get nom; String? get idEpoux; String? get idEpouse; List<String> get idsEnfants;
/// Create a copy of Famille
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilleCopyWith<Famille> get copyWith => _$FamilleCopyWithImpl<Famille>(this as Famille, _$identity);

  /// Serializes this Famille to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Famille&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.idEpoux, idEpoux) || other.idEpoux == idEpoux)&&(identical(other.idEpouse, idEpouse) || other.idEpouse == idEpouse)&&const DeepCollectionEquality().equals(other.idsEnfants, idsEnfants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,idEpoux,idEpouse,const DeepCollectionEquality().hash(idsEnfants));

@override
String toString() {
  return 'Famille(id: $id, nom: $nom, idEpoux: $idEpoux, idEpouse: $idEpouse, idsEnfants: $idsEnfants)';
}


}

/// @nodoc
abstract mixin class $FamilleCopyWith<$Res>  {
  factory $FamilleCopyWith(Famille value, $Res Function(Famille) _then) = _$FamilleCopyWithImpl;
@useResult
$Res call({
 String id, String nom, String? idEpoux, String? idEpouse, List<String> idsEnfants
});




}
/// @nodoc
class _$FamilleCopyWithImpl<$Res>
    implements $FamilleCopyWith<$Res> {
  _$FamilleCopyWithImpl(this._self, this._then);

  final Famille _self;
  final $Res Function(Famille) _then;

/// Create a copy of Famille
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? idEpoux = freezed,Object? idEpouse = freezed,Object? idsEnfants = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,idEpoux: freezed == idEpoux ? _self.idEpoux : idEpoux // ignore: cast_nullable_to_non_nullable
as String?,idEpouse: freezed == idEpouse ? _self.idEpouse : idEpouse // ignore: cast_nullable_to_non_nullable
as String?,idsEnfants: null == idsEnfants ? _self.idsEnfants : idsEnfants // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Famille].
extension FamillePatterns on Famille {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Famille value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Famille() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Famille value)  $default,){
final _that = this;
switch (_that) {
case _Famille():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Famille value)?  $default,){
final _that = this;
switch (_that) {
case _Famille() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  String? idEpoux,  String? idEpouse,  List<String> idsEnfants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Famille() when $default != null:
return $default(_that.id,_that.nom,_that.idEpoux,_that.idEpouse,_that.idsEnfants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  String? idEpoux,  String? idEpouse,  List<String> idsEnfants)  $default,) {final _that = this;
switch (_that) {
case _Famille():
return $default(_that.id,_that.nom,_that.idEpoux,_that.idEpouse,_that.idsEnfants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  String? idEpoux,  String? idEpouse,  List<String> idsEnfants)?  $default,) {final _that = this;
switch (_that) {
case _Famille() when $default != null:
return $default(_that.id,_that.nom,_that.idEpoux,_that.idEpouse,_that.idsEnfants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Famille implements Famille {
  const _Famille({required this.id, required this.nom, this.idEpoux, this.idEpouse, final  List<String> idsEnfants = const <String>[]}): _idsEnfants = idsEnfants;
  factory _Famille.fromJson(Map<String, dynamic> json) => _$FamilleFromJson(json);

@override final  String id;
@override final  String nom;
@override final  String? idEpoux;
@override final  String? idEpouse;
 final  List<String> _idsEnfants;
@override@JsonKey() List<String> get idsEnfants {
  if (_idsEnfants is EqualUnmodifiableListView) return _idsEnfants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_idsEnfants);
}


/// Create a copy of Famille
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilleCopyWith<_Famille> get copyWith => __$FamilleCopyWithImpl<_Famille>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Famille&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.idEpoux, idEpoux) || other.idEpoux == idEpoux)&&(identical(other.idEpouse, idEpouse) || other.idEpouse == idEpouse)&&const DeepCollectionEquality().equals(other._idsEnfants, _idsEnfants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,idEpoux,idEpouse,const DeepCollectionEquality().hash(_idsEnfants));

@override
String toString() {
  return 'Famille(id: $id, nom: $nom, idEpoux: $idEpoux, idEpouse: $idEpouse, idsEnfants: $idsEnfants)';
}


}

/// @nodoc
abstract mixin class _$FamilleCopyWith<$Res> implements $FamilleCopyWith<$Res> {
  factory _$FamilleCopyWith(_Famille value, $Res Function(_Famille) _then) = __$FamilleCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, String? idEpoux, String? idEpouse, List<String> idsEnfants
});




}
/// @nodoc
class __$FamilleCopyWithImpl<$Res>
    implements _$FamilleCopyWith<$Res> {
  __$FamilleCopyWithImpl(this._self, this._then);

  final _Famille _self;
  final $Res Function(_Famille) _then;

/// Create a copy of Famille
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? idEpoux = freezed,Object? idEpouse = freezed,Object? idsEnfants = null,}) {
  return _then(_Famille(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,idEpoux: freezed == idEpoux ? _self.idEpoux : idEpoux // ignore: cast_nullable_to_non_nullable
as String?,idEpouse: freezed == idEpouse ? _self.idEpouse : idEpouse // ignore: cast_nullable_to_non_nullable
as String?,idsEnfants: null == idsEnfants ? _self._idsEnfants : idsEnfants // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

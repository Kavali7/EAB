// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'centre_analytique.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CentreAnalytique {

 String get id; String get code;// ex: "ASS-COT-CENTRE", "PROJ-EV-2025"
 String get nom;// ex: "Assemblee de Cotonou Centre", "Projet evangelisation 2025"
 TypeCentreAnalytique get type; String? get description;// Pour plus tard : rattacher a une assemblee, un district, etc. si besoin
 String? get idAssembleeLocale;
/// Create a copy of CentreAnalytique
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CentreAnalytiqueCopyWith<CentreAnalytique> get copyWith => _$CentreAnalytiqueCopyWithImpl<CentreAnalytique>(this as CentreAnalytique, _$identity);

  /// Serializes this CentreAnalytique to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CentreAnalytique&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,nom,type,description,idAssembleeLocale);

@override
String toString() {
  return 'CentreAnalytique(id: $id, code: $code, nom: $nom, type: $type, description: $description, idAssembleeLocale: $idAssembleeLocale)';
}


}

/// @nodoc
abstract mixin class $CentreAnalytiqueCopyWith<$Res>  {
  factory $CentreAnalytiqueCopyWith(CentreAnalytique value, $Res Function(CentreAnalytique) _then) = _$CentreAnalytiqueCopyWithImpl;
@useResult
$Res call({
 String id, String code, String nom, TypeCentreAnalytique type, String? description, String? idAssembleeLocale
});




}
/// @nodoc
class _$CentreAnalytiqueCopyWithImpl<$Res>
    implements $CentreAnalytiqueCopyWith<$Res> {
  _$CentreAnalytiqueCopyWithImpl(this._self, this._then);

  final CentreAnalytique _self;
  final $Res Function(CentreAnalytique) _then;

/// Create a copy of CentreAnalytique
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? nom = null,Object? type = null,Object? description = freezed,Object? idAssembleeLocale = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeCentreAnalytique,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CentreAnalytique].
extension CentreAnalytiquePatterns on CentreAnalytique {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CentreAnalytique value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CentreAnalytique() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CentreAnalytique value)  $default,){
final _that = this;
switch (_that) {
case _CentreAnalytique():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CentreAnalytique value)?  $default,){
final _that = this;
switch (_that) {
case _CentreAnalytique() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String nom,  TypeCentreAnalytique type,  String? description,  String? idAssembleeLocale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CentreAnalytique() when $default != null:
return $default(_that.id,_that.code,_that.nom,_that.type,_that.description,_that.idAssembleeLocale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String nom,  TypeCentreAnalytique type,  String? description,  String? idAssembleeLocale)  $default,) {final _that = this;
switch (_that) {
case _CentreAnalytique():
return $default(_that.id,_that.code,_that.nom,_that.type,_that.description,_that.idAssembleeLocale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String nom,  TypeCentreAnalytique type,  String? description,  String? idAssembleeLocale)?  $default,) {final _that = this;
switch (_that) {
case _CentreAnalytique() when $default != null:
return $default(_that.id,_that.code,_that.nom,_that.type,_that.description,_that.idAssembleeLocale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CentreAnalytique implements CentreAnalytique {
  const _CentreAnalytique({required this.id, required this.code, required this.nom, required this.type, this.description, this.idAssembleeLocale});
  factory _CentreAnalytique.fromJson(Map<String, dynamic> json) => _$CentreAnalytiqueFromJson(json);

@override final  String id;
@override final  String code;
// ex: "ASS-COT-CENTRE", "PROJ-EV-2025"
@override final  String nom;
// ex: "Assemblee de Cotonou Centre", "Projet evangelisation 2025"
@override final  TypeCentreAnalytique type;
@override final  String? description;
// Pour plus tard : rattacher a une assemblee, un district, etc. si besoin
@override final  String? idAssembleeLocale;

/// Create a copy of CentreAnalytique
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CentreAnalytiqueCopyWith<_CentreAnalytique> get copyWith => __$CentreAnalytiqueCopyWithImpl<_CentreAnalytique>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CentreAnalytiqueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CentreAnalytique&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,nom,type,description,idAssembleeLocale);

@override
String toString() {
  return 'CentreAnalytique(id: $id, code: $code, nom: $nom, type: $type, description: $description, idAssembleeLocale: $idAssembleeLocale)';
}


}

/// @nodoc
abstract mixin class _$CentreAnalytiqueCopyWith<$Res> implements $CentreAnalytiqueCopyWith<$Res> {
  factory _$CentreAnalytiqueCopyWith(_CentreAnalytique value, $Res Function(_CentreAnalytique) _then) = __$CentreAnalytiqueCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String nom, TypeCentreAnalytique type, String? description, String? idAssembleeLocale
});




}
/// @nodoc
class __$CentreAnalytiqueCopyWithImpl<$Res>
    implements _$CentreAnalytiqueCopyWith<$Res> {
  __$CentreAnalytiqueCopyWithImpl(this._self, this._then);

  final _CentreAnalytique _self;
  final $Res Function(_CentreAnalytique) _then;

/// Create a copy of CentreAnalytique
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? nom = null,Object? type = null,Object? description = freezed,Object? idAssembleeLocale = freezed,}) {
  return _then(_CentreAnalytique(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeCentreAnalytique,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

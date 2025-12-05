// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_comptable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JournalComptable {

 String get id; String get code;// ex: "CAI", "BAN", "OD"
 String get intitule;// libelle : "Journal de caisse", "Journal de banque", etc.
 TypeJournalComptable get type; bool get actif;
/// Create a copy of JournalComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalComptableCopyWith<JournalComptable> get copyWith => _$JournalComptableCopyWithImpl<JournalComptable>(this as JournalComptable, _$identity);

  /// Serializes this JournalComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.intitule, intitule) || other.intitule == intitule)&&(identical(other.type, type) || other.type == type)&&(identical(other.actif, actif) || other.actif == actif));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,intitule,type,actif);

@override
String toString() {
  return 'JournalComptable(id: $id, code: $code, intitule: $intitule, type: $type, actif: $actif)';
}


}

/// @nodoc
abstract mixin class $JournalComptableCopyWith<$Res>  {
  factory $JournalComptableCopyWith(JournalComptable value, $Res Function(JournalComptable) _then) = _$JournalComptableCopyWithImpl;
@useResult
$Res call({
 String id, String code, String intitule, TypeJournalComptable type, bool actif
});




}
/// @nodoc
class _$JournalComptableCopyWithImpl<$Res>
    implements $JournalComptableCopyWith<$Res> {
  _$JournalComptableCopyWithImpl(this._self, this._then);

  final JournalComptable _self;
  final $Res Function(JournalComptable) _then;

/// Create a copy of JournalComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? intitule = null,Object? type = null,Object? actif = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,intitule: null == intitule ? _self.intitule : intitule // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeJournalComptable,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalComptable].
extension JournalComptablePatterns on JournalComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalComptable value)  $default,){
final _that = this;
switch (_that) {
case _JournalComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalComptable value)?  $default,){
final _that = this;
switch (_that) {
case _JournalComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String intitule,  TypeJournalComptable type,  bool actif)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalComptable() when $default != null:
return $default(_that.id,_that.code,_that.intitule,_that.type,_that.actif);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String intitule,  TypeJournalComptable type,  bool actif)  $default,) {final _that = this;
switch (_that) {
case _JournalComptable():
return $default(_that.id,_that.code,_that.intitule,_that.type,_that.actif);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String intitule,  TypeJournalComptable type,  bool actif)?  $default,) {final _that = this;
switch (_that) {
case _JournalComptable() when $default != null:
return $default(_that.id,_that.code,_that.intitule,_that.type,_that.actif);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JournalComptable implements JournalComptable {
  const _JournalComptable({required this.id, required this.code, required this.intitule, required this.type, this.actif = true});
  factory _JournalComptable.fromJson(Map<String, dynamic> json) => _$JournalComptableFromJson(json);

@override final  String id;
@override final  String code;
// ex: "CAI", "BAN", "OD"
@override final  String intitule;
// libelle : "Journal de caisse", "Journal de banque", etc.
@override final  TypeJournalComptable type;
@override@JsonKey() final  bool actif;

/// Create a copy of JournalComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalComptableCopyWith<_JournalComptable> get copyWith => __$JournalComptableCopyWithImpl<_JournalComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JournalComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.intitule, intitule) || other.intitule == intitule)&&(identical(other.type, type) || other.type == type)&&(identical(other.actif, actif) || other.actif == actif));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,intitule,type,actif);

@override
String toString() {
  return 'JournalComptable(id: $id, code: $code, intitule: $intitule, type: $type, actif: $actif)';
}


}

/// @nodoc
abstract mixin class _$JournalComptableCopyWith<$Res> implements $JournalComptableCopyWith<$Res> {
  factory _$JournalComptableCopyWith(_JournalComptable value, $Res Function(_JournalComptable) _then) = __$JournalComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String intitule, TypeJournalComptable type, bool actif
});




}
/// @nodoc
class __$JournalComptableCopyWithImpl<$Res>
    implements _$JournalComptableCopyWith<$Res> {
  __$JournalComptableCopyWithImpl(this._self, this._then);

  final _JournalComptable _self;
  final $Res Function(_JournalComptable) _then;

/// Create a copy of JournalComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? intitule = null,Object? type = null,Object? actif = null,}) {
  return _then(_JournalComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,intitule: null == intitule ? _self.intitule : intitule // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeJournalComptable,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

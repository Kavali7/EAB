// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Program {

 String get id; ProgramType get type; DateTime get date; String get location; String? get description; List<String> get participantIds;
/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramCopyWith<Program> get copyWith => _$ProgramCopyWithImpl<Program>(this as Program, _$identity);

  /// Serializes this Program to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Program&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.date, date) || other.date == date)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.participantIds, participantIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,date,location,description,const DeepCollectionEquality().hash(participantIds));

@override
String toString() {
  return 'Program(id: $id, type: $type, date: $date, location: $location, description: $description, participantIds: $participantIds)';
}


}

/// @nodoc
abstract mixin class $ProgramCopyWith<$Res>  {
  factory $ProgramCopyWith(Program value, $Res Function(Program) _then) = _$ProgramCopyWithImpl;
@useResult
$Res call({
 String id, ProgramType type, DateTime date, String location, String? description, List<String> participantIds
});




}
/// @nodoc
class _$ProgramCopyWithImpl<$Res>
    implements $ProgramCopyWith<$Res> {
  _$ProgramCopyWithImpl(this._self, this._then);

  final Program _self;
  final $Res Function(Program) _then;

/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? date = null,Object? location = null,Object? description = freezed,Object? participantIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProgramType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,participantIds: null == participantIds ? _self.participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Program].
extension ProgramPatterns on Program {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Program value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Program() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Program value)  $default,){
final _that = this;
switch (_that) {
case _Program():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Program value)?  $default,){
final _that = this;
switch (_that) {
case _Program() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ProgramType type,  DateTime date,  String location,  String? description,  List<String> participantIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Program() when $default != null:
return $default(_that.id,_that.type,_that.date,_that.location,_that.description,_that.participantIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ProgramType type,  DateTime date,  String location,  String? description,  List<String> participantIds)  $default,) {final _that = this;
switch (_that) {
case _Program():
return $default(_that.id,_that.type,_that.date,_that.location,_that.description,_that.participantIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ProgramType type,  DateTime date,  String location,  String? description,  List<String> participantIds)?  $default,) {final _that = this;
switch (_that) {
case _Program() when $default != null:
return $default(_that.id,_that.type,_that.date,_that.location,_that.description,_that.participantIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Program implements Program {
  const _Program({required this.id, required this.type, required this.date, required this.location, this.description, final  List<String> participantIds = const []}): _participantIds = participantIds;
  factory _Program.fromJson(Map<String, dynamic> json) => _$ProgramFromJson(json);

@override final  String id;
@override final  ProgramType type;
@override final  DateTime date;
@override final  String location;
@override final  String? description;
 final  List<String> _participantIds;
@override@JsonKey() List<String> get participantIds {
  if (_participantIds is EqualUnmodifiableListView) return _participantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantIds);
}


/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramCopyWith<_Program> get copyWith => __$ProgramCopyWithImpl<_Program>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgramToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Program&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.date, date) || other.date == date)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._participantIds, _participantIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,date,location,description,const DeepCollectionEquality().hash(_participantIds));

@override
String toString() {
  return 'Program(id: $id, type: $type, date: $date, location: $location, description: $description, participantIds: $participantIds)';
}


}

/// @nodoc
abstract mixin class _$ProgramCopyWith<$Res> implements $ProgramCopyWith<$Res> {
  factory _$ProgramCopyWith(_Program value, $Res Function(_Program) _then) = __$ProgramCopyWithImpl;
@override @useResult
$Res call({
 String id, ProgramType type, DateTime date, String location, String? description, List<String> participantIds
});




}
/// @nodoc
class __$ProgramCopyWithImpl<$Res>
    implements _$ProgramCopyWith<$Res> {
  __$ProgramCopyWithImpl(this._self, this._then);

  final _Program _self;
  final $Res Function(_Program) _then;

/// Create a copy of Program
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? date = null,Object? location = null,Object? description = freezed,Object? participantIds = null,}) {
  return _then(_Program(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProgramType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,participantIds: null == participantIds ? _self._participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

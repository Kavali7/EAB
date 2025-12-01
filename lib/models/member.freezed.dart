// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Member {

 String get id; String get fullName; Gender get gender; DateTime get birthDate; MaritalStatus get maritalStatus; DateTime? get baptismDate; String? get phone; String? get email; String? get address;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.maritalStatus, maritalStatus) || other.maritalStatus == maritalStatus)&&(identical(other.baptismDate, baptismDate) || other.baptismDate == baptismDate)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,gender,birthDate,maritalStatus,baptismDate,phone,email,address);

@override
String toString() {
  return 'Member(id: $id, fullName: $fullName, gender: $gender, birthDate: $birthDate, maritalStatus: $maritalStatus, baptismDate: $baptismDate, phone: $phone, email: $email, address: $address)';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, Gender gender, DateTime birthDate, MaritalStatus maritalStatus, DateTime? baptismDate, String? phone, String? email, String? address
});




}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? gender = null,Object? birthDate = null,Object? maritalStatus = null,Object? baptismDate = freezed,Object? phone = freezed,Object? email = freezed,Object? address = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,maritalStatus: null == maritalStatus ? _self.maritalStatus : maritalStatus // ignore: cast_nullable_to_non_nullable
as MaritalStatus,baptismDate: freezed == baptismDate ? _self.baptismDate : baptismDate // ignore: cast_nullable_to_non_nullable
as DateTime?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  Gender gender,  DateTime birthDate,  MaritalStatus maritalStatus,  DateTime? baptismDate,  String? phone,  String? email,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.fullName,_that.gender,_that.birthDate,_that.maritalStatus,_that.baptismDate,_that.phone,_that.email,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  Gender gender,  DateTime birthDate,  MaritalStatus maritalStatus,  DateTime? baptismDate,  String? phone,  String? email,  String? address)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.id,_that.fullName,_that.gender,_that.birthDate,_that.maritalStatus,_that.baptismDate,_that.phone,_that.email,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  Gender gender,  DateTime birthDate,  MaritalStatus maritalStatus,  DateTime? baptismDate,  String? phone,  String? email,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.fullName,_that.gender,_that.birthDate,_that.maritalStatus,_that.baptismDate,_that.phone,_that.email,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member implements Member {
  const _Member({required this.id, required this.fullName, required this.gender, required this.birthDate, required this.maritalStatus, this.baptismDate, this.phone, this.email, this.address});
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override final  String id;
@override final  String fullName;
@override final  Gender gender;
@override final  DateTime birthDate;
@override final  MaritalStatus maritalStatus;
@override final  DateTime? baptismDate;
@override final  String? phone;
@override final  String? email;
@override final  String? address;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.maritalStatus, maritalStatus) || other.maritalStatus == maritalStatus)&&(identical(other.baptismDate, baptismDate) || other.baptismDate == baptismDate)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,gender,birthDate,maritalStatus,baptismDate,phone,email,address);

@override
String toString() {
  return 'Member(id: $id, fullName: $fullName, gender: $gender, birthDate: $birthDate, maritalStatus: $maritalStatus, baptismDate: $baptismDate, phone: $phone, email: $email, address: $address)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, Gender gender, DateTime birthDate, MaritalStatus maritalStatus, DateTime? baptismDate, String? phone, String? email, String? address
});




}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? gender = null,Object? birthDate = null,Object? maritalStatus = null,Object? baptismDate = freezed,Object? phone = freezed,Object? email = freezed,Object? address = freezed,}) {
  return _then(_Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,maritalStatus: null == maritalStatus ? _self.maritalStatus : maritalStatus // ignore: cast_nullable_to_non_nullable
as MaritalStatus,baptismDate: freezed == baptismDate ? _self.baptismDate : baptismDate // ignore: cast_nullable_to_non_nullable
as DateTime?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

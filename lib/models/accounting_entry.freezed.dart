// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounting_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountingEntry {

 String get id; DateTime get date; double get amount; AccountingType get type; String get category; String? get description; String? get paymentMethod;
/// Create a copy of AccountingEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountingEntryCopyWith<AccountingEntry> get copyWith => _$AccountingEntryCopyWithImpl<AccountingEntry>(this as AccountingEntry, _$identity);

  /// Serializes this AccountingEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountingEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,amount,type,category,description,paymentMethod);

@override
String toString() {
  return 'AccountingEntry(id: $id, date: $date, amount: $amount, type: $type, category: $category, description: $description, paymentMethod: $paymentMethod)';
}


}

/// @nodoc
abstract mixin class $AccountingEntryCopyWith<$Res>  {
  factory $AccountingEntryCopyWith(AccountingEntry value, $Res Function(AccountingEntry) _then) = _$AccountingEntryCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, double amount, AccountingType type, String category, String? description, String? paymentMethod
});




}
/// @nodoc
class _$AccountingEntryCopyWithImpl<$Res>
    implements $AccountingEntryCopyWith<$Res> {
  _$AccountingEntryCopyWithImpl(this._self, this._then);

  final AccountingEntry _self;
  final $Res Function(AccountingEntry) _then;

/// Create a copy of AccountingEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? amount = null,Object? type = null,Object? category = null,Object? description = freezed,Object? paymentMethod = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountingType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountingEntry].
extension AccountingEntryPatterns on AccountingEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountingEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountingEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountingEntry value)  $default,){
final _that = this;
switch (_that) {
case _AccountingEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountingEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AccountingEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  double amount,  AccountingType type,  String category,  String? description,  String? paymentMethod)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountingEntry() when $default != null:
return $default(_that.id,_that.date,_that.amount,_that.type,_that.category,_that.description,_that.paymentMethod);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  double amount,  AccountingType type,  String category,  String? description,  String? paymentMethod)  $default,) {final _that = this;
switch (_that) {
case _AccountingEntry():
return $default(_that.id,_that.date,_that.amount,_that.type,_that.category,_that.description,_that.paymentMethod);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  double amount,  AccountingType type,  String category,  String? description,  String? paymentMethod)?  $default,) {final _that = this;
switch (_that) {
case _AccountingEntry() when $default != null:
return $default(_that.id,_that.date,_that.amount,_that.type,_that.category,_that.description,_that.paymentMethod);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountingEntry implements AccountingEntry {
  const _AccountingEntry({required this.id, required this.date, required this.amount, required this.type, required this.category, this.description, this.paymentMethod});
  factory _AccountingEntry.fromJson(Map<String, dynamic> json) => _$AccountingEntryFromJson(json);

@override final  String id;
@override final  DateTime date;
@override final  double amount;
@override final  AccountingType type;
@override final  String category;
@override final  String? description;
@override final  String? paymentMethod;

/// Create a copy of AccountingEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountingEntryCopyWith<_AccountingEntry> get copyWith => __$AccountingEntryCopyWithImpl<_AccountingEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountingEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountingEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,amount,type,category,description,paymentMethod);

@override
String toString() {
  return 'AccountingEntry(id: $id, date: $date, amount: $amount, type: $type, category: $category, description: $description, paymentMethod: $paymentMethod)';
}


}

/// @nodoc
abstract mixin class _$AccountingEntryCopyWith<$Res> implements $AccountingEntryCopyWith<$Res> {
  factory _$AccountingEntryCopyWith(_AccountingEntry value, $Res Function(_AccountingEntry) _then) = __$AccountingEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, double amount, AccountingType type, String category, String? description, String? paymentMethod
});




}
/// @nodoc
class __$AccountingEntryCopyWithImpl<$Res>
    implements _$AccountingEntryCopyWith<$Res> {
  __$AccountingEntryCopyWithImpl(this._self, this._then);

  final _AccountingEntry _self;
  final $Res Function(_AccountingEntry) _then;

/// Create a copy of AccountingEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? amount = null,Object? type = null,Object? category = null,Object? description = freezed,Object? paymentMethod = freezed,}) {
  return _then(_AccountingEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountingType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

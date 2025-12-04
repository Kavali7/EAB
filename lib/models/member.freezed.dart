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

 String get id; String get fullName; Gender get gender; DateTime get birthDate; MaritalStatus get maritalStatus; DateTime? get baptismDate; String? get phone; String? get email; String? get address; DateTime? get dateNaissance; StatutMatrimonial? get statutMatrimonial; DateTime? get dateConversion; DateTime? get dateBapteme; DateTime? get dateMainAssociation; StatutFidele get statut; DateTime? get dateEntree; DateTime? get dateSortie; String? get motifSortie; DateTime? get dateDeces; RoleFidele get role; Set<VulnerabiliteFidele> get vulnerabilites; String? get idFamille; String? get idAssembleeLocale;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.maritalStatus, maritalStatus) || other.maritalStatus == maritalStatus)&&(identical(other.baptismDate, baptismDate) || other.baptismDate == baptismDate)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.dateNaissance, dateNaissance) || other.dateNaissance == dateNaissance)&&(identical(other.statutMatrimonial, statutMatrimonial) || other.statutMatrimonial == statutMatrimonial)&&(identical(other.dateConversion, dateConversion) || other.dateConversion == dateConversion)&&(identical(other.dateBapteme, dateBapteme) || other.dateBapteme == dateBapteme)&&(identical(other.dateMainAssociation, dateMainAssociation) || other.dateMainAssociation == dateMainAssociation)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.dateEntree, dateEntree) || other.dateEntree == dateEntree)&&(identical(other.dateSortie, dateSortie) || other.dateSortie == dateSortie)&&(identical(other.motifSortie, motifSortie) || other.motifSortie == motifSortie)&&(identical(other.dateDeces, dateDeces) || other.dateDeces == dateDeces)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.vulnerabilites, vulnerabilites)&&(identical(other.idFamille, idFamille) || other.idFamille == idFamille)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,gender,birthDate,maritalStatus,baptismDate,phone,email,address,dateNaissance,statutMatrimonial,dateConversion,dateBapteme,dateMainAssociation,statut,dateEntree,dateSortie,motifSortie,dateDeces,role,const DeepCollectionEquality().hash(vulnerabilites),idFamille,idAssembleeLocale]);

@override
String toString() {
  return 'Member(id: $id, fullName: $fullName, gender: $gender, birthDate: $birthDate, maritalStatus: $maritalStatus, baptismDate: $baptismDate, phone: $phone, email: $email, address: $address, dateNaissance: $dateNaissance, statutMatrimonial: $statutMatrimonial, dateConversion: $dateConversion, dateBapteme: $dateBapteme, dateMainAssociation: $dateMainAssociation, statut: $statut, dateEntree: $dateEntree, dateSortie: $dateSortie, motifSortie: $motifSortie, dateDeces: $dateDeces, role: $role, vulnerabilites: $vulnerabilites, idFamille: $idFamille, idAssembleeLocale: $idAssembleeLocale)';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, Gender gender, DateTime birthDate, MaritalStatus maritalStatus, DateTime? baptismDate, String? phone, String? email, String? address, DateTime? dateNaissance, StatutMatrimonial? statutMatrimonial, DateTime? dateConversion, DateTime? dateBapteme, DateTime? dateMainAssociation, StatutFidele statut, DateTime? dateEntree, DateTime? dateSortie, String? motifSortie, DateTime? dateDeces, RoleFidele role, Set<VulnerabiliteFidele> vulnerabilites, String? idFamille, String? idAssembleeLocale
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? gender = null,Object? birthDate = null,Object? maritalStatus = null,Object? baptismDate = freezed,Object? phone = freezed,Object? email = freezed,Object? address = freezed,Object? dateNaissance = freezed,Object? statutMatrimonial = freezed,Object? dateConversion = freezed,Object? dateBapteme = freezed,Object? dateMainAssociation = freezed,Object? statut = null,Object? dateEntree = freezed,Object? dateSortie = freezed,Object? motifSortie = freezed,Object? dateDeces = freezed,Object? role = null,Object? vulnerabilites = null,Object? idFamille = freezed,Object? idAssembleeLocale = freezed,}) {
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
as String?,dateNaissance: freezed == dateNaissance ? _self.dateNaissance : dateNaissance // ignore: cast_nullable_to_non_nullable
as DateTime?,statutMatrimonial: freezed == statutMatrimonial ? _self.statutMatrimonial : statutMatrimonial // ignore: cast_nullable_to_non_nullable
as StatutMatrimonial?,dateConversion: freezed == dateConversion ? _self.dateConversion : dateConversion // ignore: cast_nullable_to_non_nullable
as DateTime?,dateBapteme: freezed == dateBapteme ? _self.dateBapteme : dateBapteme // ignore: cast_nullable_to_non_nullable
as DateTime?,dateMainAssociation: freezed == dateMainAssociation ? _self.dateMainAssociation : dateMainAssociation // ignore: cast_nullable_to_non_nullable
as DateTime?,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutFidele,dateEntree: freezed == dateEntree ? _self.dateEntree : dateEntree // ignore: cast_nullable_to_non_nullable
as DateTime?,dateSortie: freezed == dateSortie ? _self.dateSortie : dateSortie // ignore: cast_nullable_to_non_nullable
as DateTime?,motifSortie: freezed == motifSortie ? _self.motifSortie : motifSortie // ignore: cast_nullable_to_non_nullable
as String?,dateDeces: freezed == dateDeces ? _self.dateDeces : dateDeces // ignore: cast_nullable_to_non_nullable
as DateTime?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RoleFidele,vulnerabilites: null == vulnerabilites ? _self.vulnerabilites : vulnerabilites // ignore: cast_nullable_to_non_nullable
as Set<VulnerabiliteFidele>,idFamille: freezed == idFamille ? _self.idFamille : idFamille // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  Gender gender,  DateTime birthDate,  MaritalStatus maritalStatus,  DateTime? baptismDate,  String? phone,  String? email,  String? address,  DateTime? dateNaissance,  StatutMatrimonial? statutMatrimonial,  DateTime? dateConversion,  DateTime? dateBapteme,  DateTime? dateMainAssociation,  StatutFidele statut,  DateTime? dateEntree,  DateTime? dateSortie,  String? motifSortie,  DateTime? dateDeces,  RoleFidele role,  Set<VulnerabiliteFidele> vulnerabilites,  String? idFamille,  String? idAssembleeLocale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.fullName,_that.gender,_that.birthDate,_that.maritalStatus,_that.baptismDate,_that.phone,_that.email,_that.address,_that.dateNaissance,_that.statutMatrimonial,_that.dateConversion,_that.dateBapteme,_that.dateMainAssociation,_that.statut,_that.dateEntree,_that.dateSortie,_that.motifSortie,_that.dateDeces,_that.role,_that.vulnerabilites,_that.idFamille,_that.idAssembleeLocale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  Gender gender,  DateTime birthDate,  MaritalStatus maritalStatus,  DateTime? baptismDate,  String? phone,  String? email,  String? address,  DateTime? dateNaissance,  StatutMatrimonial? statutMatrimonial,  DateTime? dateConversion,  DateTime? dateBapteme,  DateTime? dateMainAssociation,  StatutFidele statut,  DateTime? dateEntree,  DateTime? dateSortie,  String? motifSortie,  DateTime? dateDeces,  RoleFidele role,  Set<VulnerabiliteFidele> vulnerabilites,  String? idFamille,  String? idAssembleeLocale)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.id,_that.fullName,_that.gender,_that.birthDate,_that.maritalStatus,_that.baptismDate,_that.phone,_that.email,_that.address,_that.dateNaissance,_that.statutMatrimonial,_that.dateConversion,_that.dateBapteme,_that.dateMainAssociation,_that.statut,_that.dateEntree,_that.dateSortie,_that.motifSortie,_that.dateDeces,_that.role,_that.vulnerabilites,_that.idFamille,_that.idAssembleeLocale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  Gender gender,  DateTime birthDate,  MaritalStatus maritalStatus,  DateTime? baptismDate,  String? phone,  String? email,  String? address,  DateTime? dateNaissance,  StatutMatrimonial? statutMatrimonial,  DateTime? dateConversion,  DateTime? dateBapteme,  DateTime? dateMainAssociation,  StatutFidele statut,  DateTime? dateEntree,  DateTime? dateSortie,  String? motifSortie,  DateTime? dateDeces,  RoleFidele role,  Set<VulnerabiliteFidele> vulnerabilites,  String? idFamille,  String? idAssembleeLocale)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.fullName,_that.gender,_that.birthDate,_that.maritalStatus,_that.baptismDate,_that.phone,_that.email,_that.address,_that.dateNaissance,_that.statutMatrimonial,_that.dateConversion,_that.dateBapteme,_that.dateMainAssociation,_that.statut,_that.dateEntree,_that.dateSortie,_that.motifSortie,_that.dateDeces,_that.role,_that.vulnerabilites,_that.idFamille,_that.idAssembleeLocale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member extends Member {
  const _Member({required this.id, required this.fullName, required this.gender, required this.birthDate, required this.maritalStatus, this.baptismDate, this.phone, this.email, this.address, this.dateNaissance, this.statutMatrimonial, this.dateConversion, this.dateBapteme, this.dateMainAssociation, this.statut = StatutFidele.actif, this.dateEntree, this.dateSortie, this.motifSortie, this.dateDeces, this.role = RoleFidele.membre, final  Set<VulnerabiliteFidele> vulnerabilites = const <VulnerabiliteFidele>{}, this.idFamille, this.idAssembleeLocale}): _vulnerabilites = vulnerabilites,super._();
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
@override final  DateTime? dateNaissance;
@override final  StatutMatrimonial? statutMatrimonial;
@override final  DateTime? dateConversion;
@override final  DateTime? dateBapteme;
@override final  DateTime? dateMainAssociation;
@override@JsonKey() final  StatutFidele statut;
@override final  DateTime? dateEntree;
@override final  DateTime? dateSortie;
@override final  String? motifSortie;
@override final  DateTime? dateDeces;
@override@JsonKey() final  RoleFidele role;
 final  Set<VulnerabiliteFidele> _vulnerabilites;
@override@JsonKey() Set<VulnerabiliteFidele> get vulnerabilites {
  if (_vulnerabilites is EqualUnmodifiableSetView) return _vulnerabilites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_vulnerabilites);
}

@override final  String? idFamille;
@override final  String? idAssembleeLocale;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.maritalStatus, maritalStatus) || other.maritalStatus == maritalStatus)&&(identical(other.baptismDate, baptismDate) || other.baptismDate == baptismDate)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.dateNaissance, dateNaissance) || other.dateNaissance == dateNaissance)&&(identical(other.statutMatrimonial, statutMatrimonial) || other.statutMatrimonial == statutMatrimonial)&&(identical(other.dateConversion, dateConversion) || other.dateConversion == dateConversion)&&(identical(other.dateBapteme, dateBapteme) || other.dateBapteme == dateBapteme)&&(identical(other.dateMainAssociation, dateMainAssociation) || other.dateMainAssociation == dateMainAssociation)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.dateEntree, dateEntree) || other.dateEntree == dateEntree)&&(identical(other.dateSortie, dateSortie) || other.dateSortie == dateSortie)&&(identical(other.motifSortie, motifSortie) || other.motifSortie == motifSortie)&&(identical(other.dateDeces, dateDeces) || other.dateDeces == dateDeces)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._vulnerabilites, _vulnerabilites)&&(identical(other.idFamille, idFamille) || other.idFamille == idFamille)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,gender,birthDate,maritalStatus,baptismDate,phone,email,address,dateNaissance,statutMatrimonial,dateConversion,dateBapteme,dateMainAssociation,statut,dateEntree,dateSortie,motifSortie,dateDeces,role,const DeepCollectionEquality().hash(_vulnerabilites),idFamille,idAssembleeLocale]);

@override
String toString() {
  return 'Member(id: $id, fullName: $fullName, gender: $gender, birthDate: $birthDate, maritalStatus: $maritalStatus, baptismDate: $baptismDate, phone: $phone, email: $email, address: $address, dateNaissance: $dateNaissance, statutMatrimonial: $statutMatrimonial, dateConversion: $dateConversion, dateBapteme: $dateBapteme, dateMainAssociation: $dateMainAssociation, statut: $statut, dateEntree: $dateEntree, dateSortie: $dateSortie, motifSortie: $motifSortie, dateDeces: $dateDeces, role: $role, vulnerabilites: $vulnerabilites, idFamille: $idFamille, idAssembleeLocale: $idAssembleeLocale)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, Gender gender, DateTime birthDate, MaritalStatus maritalStatus, DateTime? baptismDate, String? phone, String? email, String? address, DateTime? dateNaissance, StatutMatrimonial? statutMatrimonial, DateTime? dateConversion, DateTime? dateBapteme, DateTime? dateMainAssociation, StatutFidele statut, DateTime? dateEntree, DateTime? dateSortie, String? motifSortie, DateTime? dateDeces, RoleFidele role, Set<VulnerabiliteFidele> vulnerabilites, String? idFamille, String? idAssembleeLocale
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? gender = null,Object? birthDate = null,Object? maritalStatus = null,Object? baptismDate = freezed,Object? phone = freezed,Object? email = freezed,Object? address = freezed,Object? dateNaissance = freezed,Object? statutMatrimonial = freezed,Object? dateConversion = freezed,Object? dateBapteme = freezed,Object? dateMainAssociation = freezed,Object? statut = null,Object? dateEntree = freezed,Object? dateSortie = freezed,Object? motifSortie = freezed,Object? dateDeces = freezed,Object? role = null,Object? vulnerabilites = null,Object? idFamille = freezed,Object? idAssembleeLocale = freezed,}) {
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
as String?,dateNaissance: freezed == dateNaissance ? _self.dateNaissance : dateNaissance // ignore: cast_nullable_to_non_nullable
as DateTime?,statutMatrimonial: freezed == statutMatrimonial ? _self.statutMatrimonial : statutMatrimonial // ignore: cast_nullable_to_non_nullable
as StatutMatrimonial?,dateConversion: freezed == dateConversion ? _self.dateConversion : dateConversion // ignore: cast_nullable_to_non_nullable
as DateTime?,dateBapteme: freezed == dateBapteme ? _self.dateBapteme : dateBapteme // ignore: cast_nullable_to_non_nullable
as DateTime?,dateMainAssociation: freezed == dateMainAssociation ? _self.dateMainAssociation : dateMainAssociation // ignore: cast_nullable_to_non_nullable
as DateTime?,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutFidele,dateEntree: freezed == dateEntree ? _self.dateEntree : dateEntree // ignore: cast_nullable_to_non_nullable
as DateTime?,dateSortie: freezed == dateSortie ? _self.dateSortie : dateSortie // ignore: cast_nullable_to_non_nullable
as DateTime?,motifSortie: freezed == motifSortie ? _self.motifSortie : motifSortie // ignore: cast_nullable_to_non_nullable
as String?,dateDeces: freezed == dateDeces ? _self.dateDeces : dateDeces // ignore: cast_nullable_to_non_nullable
as DateTime?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RoleFidele,vulnerabilites: null == vulnerabilites ? _self._vulnerabilites : vulnerabilites // ignore: cast_nullable_to_non_nullable
as Set<VulnerabiliteFidele>,idFamille: freezed == idFamille ? _self.idFamille : idFamille // ignore: cast_nullable_to_non_nullable
as String?,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

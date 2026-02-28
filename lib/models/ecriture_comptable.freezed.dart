// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ecriture_comptable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LigneEcritureComptable {

 String get id; String get idCompteComptable;// reference a CompteComptable.id
 double? get debit; double? get credit; String? get idCentreAnalytique;// reference a CentreAnalytique.id
 String? get idTiers;// reference a Tiers.id
 ModePaiement? get modePaiement;// si pertinent pour la ligne
 String? get libelle;
/// Create a copy of LigneEcritureComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LigneEcritureComptableCopyWith<LigneEcritureComptable> get copyWith => _$LigneEcritureComptableCopyWithImpl<LigneEcritureComptable>(this as LigneEcritureComptable, _$identity);

  /// Serializes this LigneEcritureComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LigneEcritureComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.idCompteComptable, idCompteComptable) || other.idCompteComptable == idCompteComptable)&&(identical(other.debit, debit) || other.debit == debit)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.idCentreAnalytique, idCentreAnalytique) || other.idCentreAnalytique == idCentreAnalytique)&&(identical(other.idTiers, idTiers) || other.idTiers == idTiers)&&(identical(other.modePaiement, modePaiement) || other.modePaiement == modePaiement)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,idCompteComptable,debit,credit,idCentreAnalytique,idTiers,modePaiement,libelle);

@override
String toString() {
  return 'LigneEcritureComptable(id: $id, idCompteComptable: $idCompteComptable, debit: $debit, credit: $credit, idCentreAnalytique: $idCentreAnalytique, idTiers: $idTiers, modePaiement: $modePaiement, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class $LigneEcritureComptableCopyWith<$Res>  {
  factory $LigneEcritureComptableCopyWith(LigneEcritureComptable value, $Res Function(LigneEcritureComptable) _then) = _$LigneEcritureComptableCopyWithImpl;
@useResult
$Res call({
 String id, String idCompteComptable, double? debit, double? credit, String? idCentreAnalytique, String? idTiers, ModePaiement? modePaiement, String? libelle
});




}
/// @nodoc
class _$LigneEcritureComptableCopyWithImpl<$Res>
    implements $LigneEcritureComptableCopyWith<$Res> {
  _$LigneEcritureComptableCopyWithImpl(this._self, this._then);

  final LigneEcritureComptable _self;
  final $Res Function(LigneEcritureComptable) _then;

/// Create a copy of LigneEcritureComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? idCompteComptable = null,Object? debit = freezed,Object? credit = freezed,Object? idCentreAnalytique = freezed,Object? idTiers = freezed,Object? modePaiement = freezed,Object? libelle = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,idCompteComptable: null == idCompteComptable ? _self.idCompteComptable : idCompteComptable // ignore: cast_nullable_to_non_nullable
as String,debit: freezed == debit ? _self.debit : debit // ignore: cast_nullable_to_non_nullable
as double?,credit: freezed == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as double?,idCentreAnalytique: freezed == idCentreAnalytique ? _self.idCentreAnalytique : idCentreAnalytique // ignore: cast_nullable_to_non_nullable
as String?,idTiers: freezed == idTiers ? _self.idTiers : idTiers // ignore: cast_nullable_to_non_nullable
as String?,modePaiement: freezed == modePaiement ? _self.modePaiement : modePaiement // ignore: cast_nullable_to_non_nullable
as ModePaiement?,libelle: freezed == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LigneEcritureComptable].
extension LigneEcritureComptablePatterns on LigneEcritureComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LigneEcritureComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LigneEcritureComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LigneEcritureComptable value)  $default,){
final _that = this;
switch (_that) {
case _LigneEcritureComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LigneEcritureComptable value)?  $default,){
final _that = this;
switch (_that) {
case _LigneEcritureComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String idCompteComptable,  double? debit,  double? credit,  String? idCentreAnalytique,  String? idTiers,  ModePaiement? modePaiement,  String? libelle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LigneEcritureComptable() when $default != null:
return $default(_that.id,_that.idCompteComptable,_that.debit,_that.credit,_that.idCentreAnalytique,_that.idTiers,_that.modePaiement,_that.libelle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String idCompteComptable,  double? debit,  double? credit,  String? idCentreAnalytique,  String? idTiers,  ModePaiement? modePaiement,  String? libelle)  $default,) {final _that = this;
switch (_that) {
case _LigneEcritureComptable():
return $default(_that.id,_that.idCompteComptable,_that.debit,_that.credit,_that.idCentreAnalytique,_that.idTiers,_that.modePaiement,_that.libelle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String idCompteComptable,  double? debit,  double? credit,  String? idCentreAnalytique,  String? idTiers,  ModePaiement? modePaiement,  String? libelle)?  $default,) {final _that = this;
switch (_that) {
case _LigneEcritureComptable() when $default != null:
return $default(_that.id,_that.idCompteComptable,_that.debit,_that.credit,_that.idCentreAnalytique,_that.idTiers,_that.modePaiement,_that.libelle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LigneEcritureComptable implements LigneEcritureComptable {
  const _LigneEcritureComptable({required this.id, required this.idCompteComptable, this.debit, this.credit, this.idCentreAnalytique, this.idTiers, this.modePaiement, this.libelle});
  factory _LigneEcritureComptable.fromJson(Map<String, dynamic> json) => _$LigneEcritureComptableFromJson(json);

@override final  String id;
@override final  String idCompteComptable;
// reference a CompteComptable.id
@override final  double? debit;
@override final  double? credit;
@override final  String? idCentreAnalytique;
// reference a CentreAnalytique.id
@override final  String? idTiers;
// reference a Tiers.id
@override final  ModePaiement? modePaiement;
// si pertinent pour la ligne
@override final  String? libelle;

/// Create a copy of LigneEcritureComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LigneEcritureComptableCopyWith<_LigneEcritureComptable> get copyWith => __$LigneEcritureComptableCopyWithImpl<_LigneEcritureComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LigneEcritureComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LigneEcritureComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.idCompteComptable, idCompteComptable) || other.idCompteComptable == idCompteComptable)&&(identical(other.debit, debit) || other.debit == debit)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.idCentreAnalytique, idCentreAnalytique) || other.idCentreAnalytique == idCentreAnalytique)&&(identical(other.idTiers, idTiers) || other.idTiers == idTiers)&&(identical(other.modePaiement, modePaiement) || other.modePaiement == modePaiement)&&(identical(other.libelle, libelle) || other.libelle == libelle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,idCompteComptable,debit,credit,idCentreAnalytique,idTiers,modePaiement,libelle);

@override
String toString() {
  return 'LigneEcritureComptable(id: $id, idCompteComptable: $idCompteComptable, debit: $debit, credit: $credit, idCentreAnalytique: $idCentreAnalytique, idTiers: $idTiers, modePaiement: $modePaiement, libelle: $libelle)';
}


}

/// @nodoc
abstract mixin class _$LigneEcritureComptableCopyWith<$Res> implements $LigneEcritureComptableCopyWith<$Res> {
  factory _$LigneEcritureComptableCopyWith(_LigneEcritureComptable value, $Res Function(_LigneEcritureComptable) _then) = __$LigneEcritureComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, String idCompteComptable, double? debit, double? credit, String? idCentreAnalytique, String? idTiers, ModePaiement? modePaiement, String? libelle
});




}
/// @nodoc
class __$LigneEcritureComptableCopyWithImpl<$Res>
    implements _$LigneEcritureComptableCopyWith<$Res> {
  __$LigneEcritureComptableCopyWithImpl(this._self, this._then);

  final _LigneEcritureComptable _self;
  final $Res Function(_LigneEcritureComptable) _then;

/// Create a copy of LigneEcritureComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? idCompteComptable = null,Object? debit = freezed,Object? credit = freezed,Object? idCentreAnalytique = freezed,Object? idTiers = freezed,Object? modePaiement = freezed,Object? libelle = freezed,}) {
  return _then(_LigneEcritureComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,idCompteComptable: null == idCompteComptable ? _self.idCompteComptable : idCompteComptable // ignore: cast_nullable_to_non_nullable
as String,debit: freezed == debit ? _self.debit : debit // ignore: cast_nullable_to_non_nullable
as double?,credit: freezed == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as double?,idCentreAnalytique: freezed == idCentreAnalytique ? _self.idCentreAnalytique : idCentreAnalytique // ignore: cast_nullable_to_non_nullable
as String?,idTiers: freezed == idTiers ? _self.idTiers : idTiers // ignore: cast_nullable_to_non_nullable
as String?,modePaiement: freezed == modePaiement ? _self.modePaiement : modePaiement // ignore: cast_nullable_to_non_nullable
as ModePaiement?,libelle: freezed == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$EcritureComptable {

 String get id; DateTime get date; String get idJournal;// reference a JournalComptable.id
 String? get referencePiece;// reference interne / piece justificative
 String get libelle;// libelle general de l'ecriture
 List<LigneEcritureComptable> get lignes;// Rattachement a une assemblee / centre principal
 String? get idAssembleeLocale; String? get idCentreAnalytiquePrincipal;// Statut de l'ecriture (brouillon / validee / cloturee)
 StatutEcriture get statut;// Validation
 String? get createdBy; String? get validatedBy; DateTime? get validatedAt;
/// Create a copy of EcritureComptable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EcritureComptableCopyWith<EcritureComptable> get copyWith => _$EcritureComptableCopyWithImpl<EcritureComptable>(this as EcritureComptable, _$identity);

  /// Serializes this EcritureComptable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EcritureComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.idJournal, idJournal) || other.idJournal == idJournal)&&(identical(other.referencePiece, referencePiece) || other.referencePiece == referencePiece)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&const DeepCollectionEquality().equals(other.lignes, lignes)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idCentreAnalytiquePrincipal, idCentreAnalytiquePrincipal) || other.idCentreAnalytiquePrincipal == idCentreAnalytiquePrincipal)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.validatedBy, validatedBy) || other.validatedBy == validatedBy)&&(identical(other.validatedAt, validatedAt) || other.validatedAt == validatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,idJournal,referencePiece,libelle,const DeepCollectionEquality().hash(lignes),idAssembleeLocale,idCentreAnalytiquePrincipal,statut,createdBy,validatedBy,validatedAt);

@override
String toString() {
  return 'EcritureComptable(id: $id, date: $date, idJournal: $idJournal, referencePiece: $referencePiece, libelle: $libelle, lignes: $lignes, idAssembleeLocale: $idAssembleeLocale, idCentreAnalytiquePrincipal: $idCentreAnalytiquePrincipal, statut: $statut, createdBy: $createdBy, validatedBy: $validatedBy, validatedAt: $validatedAt)';
}


}

/// @nodoc
abstract mixin class $EcritureComptableCopyWith<$Res>  {
  factory $EcritureComptableCopyWith(EcritureComptable value, $Res Function(EcritureComptable) _then) = _$EcritureComptableCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, String idJournal, String? referencePiece, String libelle, List<LigneEcritureComptable> lignes, String? idAssembleeLocale, String? idCentreAnalytiquePrincipal, StatutEcriture statut, String? createdBy, String? validatedBy, DateTime? validatedAt
});




}
/// @nodoc
class _$EcritureComptableCopyWithImpl<$Res>
    implements $EcritureComptableCopyWith<$Res> {
  _$EcritureComptableCopyWithImpl(this._self, this._then);

  final EcritureComptable _self;
  final $Res Function(EcritureComptable) _then;

/// Create a copy of EcritureComptable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? idJournal = null,Object? referencePiece = freezed,Object? libelle = null,Object? lignes = null,Object? idAssembleeLocale = freezed,Object? idCentreAnalytiquePrincipal = freezed,Object? statut = null,Object? createdBy = freezed,Object? validatedBy = freezed,Object? validatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,idJournal: null == idJournal ? _self.idJournal : idJournal // ignore: cast_nullable_to_non_nullable
as String,referencePiece: freezed == referencePiece ? _self.referencePiece : referencePiece // ignore: cast_nullable_to_non_nullable
as String?,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,lignes: null == lignes ? _self.lignes : lignes // ignore: cast_nullable_to_non_nullable
as List<LigneEcritureComptable>,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idCentreAnalytiquePrincipal: freezed == idCentreAnalytiquePrincipal ? _self.idCentreAnalytiquePrincipal : idCentreAnalytiquePrincipal // ignore: cast_nullable_to_non_nullable
as String?,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutEcriture,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,validatedBy: freezed == validatedBy ? _self.validatedBy : validatedBy // ignore: cast_nullable_to_non_nullable
as String?,validatedAt: freezed == validatedAt ? _self.validatedAt : validatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EcritureComptable].
extension EcritureComptablePatterns on EcritureComptable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EcritureComptable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EcritureComptable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EcritureComptable value)  $default,){
final _that = this;
switch (_that) {
case _EcritureComptable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EcritureComptable value)?  $default,){
final _that = this;
switch (_that) {
case _EcritureComptable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  String idJournal,  String? referencePiece,  String libelle,  List<LigneEcritureComptable> lignes,  String? idAssembleeLocale,  String? idCentreAnalytiquePrincipal,  StatutEcriture statut,  String? createdBy,  String? validatedBy,  DateTime? validatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EcritureComptable() when $default != null:
return $default(_that.id,_that.date,_that.idJournal,_that.referencePiece,_that.libelle,_that.lignes,_that.idAssembleeLocale,_that.idCentreAnalytiquePrincipal,_that.statut,_that.createdBy,_that.validatedBy,_that.validatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  String idJournal,  String? referencePiece,  String libelle,  List<LigneEcritureComptable> lignes,  String? idAssembleeLocale,  String? idCentreAnalytiquePrincipal,  StatutEcriture statut,  String? createdBy,  String? validatedBy,  DateTime? validatedAt)  $default,) {final _that = this;
switch (_that) {
case _EcritureComptable():
return $default(_that.id,_that.date,_that.idJournal,_that.referencePiece,_that.libelle,_that.lignes,_that.idAssembleeLocale,_that.idCentreAnalytiquePrincipal,_that.statut,_that.createdBy,_that.validatedBy,_that.validatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  String idJournal,  String? referencePiece,  String libelle,  List<LigneEcritureComptable> lignes,  String? idAssembleeLocale,  String? idCentreAnalytiquePrincipal,  StatutEcriture statut,  String? createdBy,  String? validatedBy,  DateTime? validatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EcritureComptable() when $default != null:
return $default(_that.id,_that.date,_that.idJournal,_that.referencePiece,_that.libelle,_that.lignes,_that.idAssembleeLocale,_that.idCentreAnalytiquePrincipal,_that.statut,_that.createdBy,_that.validatedBy,_that.validatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EcritureComptable implements EcritureComptable {
  const _EcritureComptable({required this.id, required this.date, required this.idJournal, this.referencePiece, required this.libelle, required final  List<LigneEcritureComptable> lignes, this.idAssembleeLocale, this.idCentreAnalytiquePrincipal, this.statut = StatutEcriture.brouillon, this.createdBy, this.validatedBy, this.validatedAt}): _lignes = lignes;
  factory _EcritureComptable.fromJson(Map<String, dynamic> json) => _$EcritureComptableFromJson(json);

@override final  String id;
@override final  DateTime date;
@override final  String idJournal;
// reference a JournalComptable.id
@override final  String? referencePiece;
// reference interne / piece justificative
@override final  String libelle;
// libelle general de l'ecriture
 final  List<LigneEcritureComptable> _lignes;
// libelle general de l'ecriture
@override List<LigneEcritureComptable> get lignes {
  if (_lignes is EqualUnmodifiableListView) return _lignes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lignes);
}

// Rattachement a une assemblee / centre principal
@override final  String? idAssembleeLocale;
@override final  String? idCentreAnalytiquePrincipal;
// Statut de l'ecriture (brouillon / validee / cloturee)
@override@JsonKey() final  StatutEcriture statut;
// Validation
@override final  String? createdBy;
@override final  String? validatedBy;
@override final  DateTime? validatedAt;

/// Create a copy of EcritureComptable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EcritureComptableCopyWith<_EcritureComptable> get copyWith => __$EcritureComptableCopyWithImpl<_EcritureComptable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EcritureComptableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EcritureComptable&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.idJournal, idJournal) || other.idJournal == idJournal)&&(identical(other.referencePiece, referencePiece) || other.referencePiece == referencePiece)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&const DeepCollectionEquality().equals(other._lignes, _lignes)&&(identical(other.idAssembleeLocale, idAssembleeLocale) || other.idAssembleeLocale == idAssembleeLocale)&&(identical(other.idCentreAnalytiquePrincipal, idCentreAnalytiquePrincipal) || other.idCentreAnalytiquePrincipal == idCentreAnalytiquePrincipal)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.validatedBy, validatedBy) || other.validatedBy == validatedBy)&&(identical(other.validatedAt, validatedAt) || other.validatedAt == validatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,idJournal,referencePiece,libelle,const DeepCollectionEquality().hash(_lignes),idAssembleeLocale,idCentreAnalytiquePrincipal,statut,createdBy,validatedBy,validatedAt);

@override
String toString() {
  return 'EcritureComptable(id: $id, date: $date, idJournal: $idJournal, referencePiece: $referencePiece, libelle: $libelle, lignes: $lignes, idAssembleeLocale: $idAssembleeLocale, idCentreAnalytiquePrincipal: $idCentreAnalytiquePrincipal, statut: $statut, createdBy: $createdBy, validatedBy: $validatedBy, validatedAt: $validatedAt)';
}


}

/// @nodoc
abstract mixin class _$EcritureComptableCopyWith<$Res> implements $EcritureComptableCopyWith<$Res> {
  factory _$EcritureComptableCopyWith(_EcritureComptable value, $Res Function(_EcritureComptable) _then) = __$EcritureComptableCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, String idJournal, String? referencePiece, String libelle, List<LigneEcritureComptable> lignes, String? idAssembleeLocale, String? idCentreAnalytiquePrincipal, StatutEcriture statut, String? createdBy, String? validatedBy, DateTime? validatedAt
});




}
/// @nodoc
class __$EcritureComptableCopyWithImpl<$Res>
    implements _$EcritureComptableCopyWith<$Res> {
  __$EcritureComptableCopyWithImpl(this._self, this._then);

  final _EcritureComptable _self;
  final $Res Function(_EcritureComptable) _then;

/// Create a copy of EcritureComptable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? idJournal = null,Object? referencePiece = freezed,Object? libelle = null,Object? lignes = null,Object? idAssembleeLocale = freezed,Object? idCentreAnalytiquePrincipal = freezed,Object? statut = null,Object? createdBy = freezed,Object? validatedBy = freezed,Object? validatedAt = freezed,}) {
  return _then(_EcritureComptable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,idJournal: null == idJournal ? _self.idJournal : idJournal // ignore: cast_nullable_to_non_nullable
as String,referencePiece: freezed == referencePiece ? _self.referencePiece : referencePiece // ignore: cast_nullable_to_non_nullable
as String?,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,lignes: null == lignes ? _self._lignes : lignes // ignore: cast_nullable_to_non_nullable
as List<LigneEcritureComptable>,idAssembleeLocale: freezed == idAssembleeLocale ? _self.idAssembleeLocale : idAssembleeLocale // ignore: cast_nullable_to_non_nullable
as String?,idCentreAnalytiquePrincipal: freezed == idCentreAnalytiquePrincipal ? _self.idCentreAnalytiquePrincipal : idCentreAnalytiquePrincipal // ignore: cast_nullable_to_non_nullable
as String?,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutEcriture,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,validatedBy: freezed == validatedBy ? _self.validatedBy : validatedBy // ignore: cast_nullable_to_non_nullable
as String?,validatedAt: freezed == validatedAt ? _self.validatedAt : validatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

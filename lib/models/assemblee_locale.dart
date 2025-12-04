import 'package:freezed_annotation/freezed_annotation.dart';

part 'assemblee_locale.freezed.dart';
part 'assemblee_locale.g.dart';

@freezed
abstract class AssembleeLocale with _$AssembleeLocale {
  const AssembleeLocale._();

  const factory AssembleeLocale({
    required String id,
    required String nom,
    String? code,
    required String idDistrict,
    String? ville,
    String? quartier,
    String? adressePostale,
    String? telephone,
    String? email,
    String? idFidelePasteurResponsable,
  }) = _AssembleeLocale;

  factory AssembleeLocale.fromJson(Map<String, dynamic> json) =>
      _$AssembleeLocaleFromJson(json);
}

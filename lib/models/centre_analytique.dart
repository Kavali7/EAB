import 'package:freezed_annotation/freezed_annotation.dart';

import 'compta_enums.dart';

part 'centre_analytique.freezed.dart';
part 'centre_analytique.g.dart';

@freezed
abstract class CentreAnalytique with _$CentreAnalytique {
  const factory CentreAnalytique({
    required String id,
    required String code, // ex: "ASS-COT-CENTRE", "PROJ-EV-2025"
    required String nom, // ex: "Assemblee de Cotonou Centre", "Projet evangelisation 2025"
    required TypeCentreAnalytique type,
    String? description,
    // Pour plus tard : rattacher a une assemblee, un district, etc. si besoin
    String? idAssembleeLocale,
  }) = _CentreAnalytique;

  factory CentreAnalytique.fromJson(Map<String, dynamic> json) =>
      _$CentreAnalytiqueFromJson(json);
}

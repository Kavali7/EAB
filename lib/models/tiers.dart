import 'package:freezed_annotation/freezed_annotation.dart';

import 'compta_enums.dart';

part 'tiers.freezed.dart';
part 'tiers.g.dart';

@freezed
abstract class Tiers with _$Tiers {
  const factory Tiers({
    required String id,
    required String nom,
    required TypeTiers type,
    String? telephone,
    String? email,
    String? adresse,
    // Rattachement eventuel a une assemblee
    String? idAssembleeLocale,
    // Pour lier un tiers a un fidele existant (ex: membre)
    String? idFideleLie,
  }) = _Tiers;

  factory Tiers.fromJson(Map<String, dynamic> json) => _$TiersFromJson(json);
}

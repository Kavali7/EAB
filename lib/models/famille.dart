import 'package:freezed_annotation/freezed_annotation.dart';

part 'famille.freezed.dart';
part 'famille.g.dart';

@freezed
abstract class Famille with _$Famille {
  const factory Famille({
    required String id,
    required String nom,
    String? idEpoux,
    String? idEpouse,
    @Default(<String>[]) List<String> idsEnfants,
  }) = _Famille;

  factory Famille.fromJson(Map<String, dynamic> json) =>
      _$FamilleFromJson(json);
}

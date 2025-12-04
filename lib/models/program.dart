import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/constants.dart';

part 'program.freezed.dart';
part 'program.g.dart';

enum TypeVisite {
  fidele,
  autorite,
  partenaire,
  autreAssemblee,
  autre,
}

@freezed
abstract class Program with _$Program {
  const factory Program({
    required String id,
    required TypeProgramme type,
    required DateTime date,
    required String location,
    String? description,
    String? observations,
    @Default([]) List<String> participantIds,
    TypeVisite? typeVisite,
    int? nombreHommes,
    int? nombreFemmes,
    int? nombreGarcons,
    int? nombreFilles,
    int? conversionsHommes,
    int? conversionsFemmes,
    int? conversionsGarcons,
    int? conversionsFilles,
    int? nombreClassesEcoleDuDimanche,
    int? nombreMoniteursHommes,
    int? nombreMonitricesFemmes,
    String? derniereLeconEcoleDuDimanche,
    String? compteRenduVisite,
  }) = _Program;

  factory Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/constants.dart';

part 'program.freezed.dart';
part 'program.g.dart';

@freezed
abstract class Program with _$Program {
  const factory Program({
    required String id,
    required ProgramType type,
    required DateTime date,
    required String location,
    String? description,
    String? observations,
    @Default([]) List<String> participantIds,
  }) = _Program;

  factory Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);
}

import 'package:eab/core/constants.dart';
import 'package:eab/models/program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Program JSON keeps observations', () {
    final program = Program(
      id: 'p1',
      type: ProgramType.prayer,
      date: DateTime(2025, 1, 1, 18, 0),
      location: 'Temple central',
      description: 'Veillee',
      observations: 'Prevoir sono',
      participantIds: const ['m1', 'm2'],
    );
    final json = program.toJson();
    final restored = Program.fromJson(json);
    expect(restored.observations, 'Prevoir sono');
    expect(restored.participantIds.length, 2);
  });
}

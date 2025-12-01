import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/data_service.dart';
import '../models/program.dart';
import 'data_service_provider.dart';

final programsProvider = AsyncNotifierProvider<ProgramsNotifier, List<Program>>(
  ProgramsNotifier.new,
);

class ProgramsNotifier extends AsyncNotifier<List<Program>> {
  late final DataService _service;

  @override
  Future<List<Program>> build() async {
    _service = ref.read(dataServiceProvider);
    return _service.getPrograms();
  }

  Future<void> addProgram(Program program) async {
    await _service.addProgram(program);
    final current = state.value ?? [];
    state = AsyncData([...current, program]);
  }

  Future<void> updateProgram(Program program) async {
    await _service.updateProgram(program);
    final current = state.value ?? [];
    state = AsyncData([
      for (final p in current)
        if (p.id == program.id) program else p,
    ]);
  }

  Future<void> removeProgram(String id) async {
    await _service.deleteProgram(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
  }
}

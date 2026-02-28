/// Repository pour la feature Programmes.
library;

import '../../../core/services/data_service.dart';
import '../../../models/program.dart';

/// Repository des programmes — couche d'accès aux données.
class ProgramsRepository {
  const ProgramsRepository(this._dataService);

  final DataService _dataService;

  Future<List<Program>> list({String? search}) async {
    final all = await _dataService.getPrograms();
    if (search == null || search.isEmpty) return all;
    final q = search.toLowerCase();
    return all.where((p) => p.nom.toLowerCase().contains(q)).toList();
  }

  Future<void> add(Program program) => _dataService.addProgram(program);
  Future<void> update(Program program) => _dataService.updateProgram(program);
  Future<void> remove(String id) => _dataService.removeProgram(id);
}

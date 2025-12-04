import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/data_service.dart';
import '../models/famille.dart';
import 'data_service_provider.dart';

final familiesProvider =
    AsyncNotifierProvider<FamiliesNotifier, List<Famille>>(
  FamiliesNotifier.new,
);

class FamiliesNotifier extends AsyncNotifier<List<Famille>> {
  late final DataService _service;

  @override
  Future<List<Famille>> build() async {
    _service = ref.read(dataServiceProvider);
    return _service.getFamilies();
  }
}

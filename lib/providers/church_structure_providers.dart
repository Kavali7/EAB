import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assemblee_locale.dart';
import '../models/district_eglise.dart';
import '../models/region_eglise.dart';
import 'data_service_provider.dart';

final regionsProvider =
    AsyncNotifierProvider<RegionsNotifier, List<RegionEglise>>(
  RegionsNotifier.new,
);

class RegionsNotifier extends AsyncNotifier<List<RegionEglise>> {
  @override
  Future<List<RegionEglise>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getRegions();
  }
}

final districtsProvider =
    AsyncNotifierProvider<DistrictsNotifier, List<DistrictEglise>>(
  DistrictsNotifier.new,
);

class DistrictsNotifier extends AsyncNotifier<List<DistrictEglise>> {
  @override
  Future<List<DistrictEglise>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getDistricts();
  }
}

final assembleesLocalesProvider = AsyncNotifierProvider<
    AssembleesLocalesNotifier, List<AssembleeLocale>>(
  AssembleesLocalesNotifier.new,
);

class AssembleesLocalesNotifier
    extends AsyncNotifier<List<AssembleeLocale>> {
  @override
  Future<List<AssembleeLocale>> build() async {
    final dataService = ref.read(dataServiceProvider);
    return dataService.getAssembleesLocales();
  }
}

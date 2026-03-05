import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/error_reporting.dart';
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
    try {
      final dataService = ref.read(dataServiceProvider);
      return dataService.getRegions();
    } catch (e, st) {
      ErrorReporting.captureException(e, stackTrace: st, context: {'provider': 'regionsProvider'});
      rethrow;
    }
  }

  Future<void> ajouterRegion(RegionEglise region) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, region]);
  }

  Future<void> mettreAJourRegion(RegionEglise region) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((r) => r.id == region.id);
    if (index == -1) return;
    final maj = [...actuelle]..[index] = region;
    state = AsyncData(maj);
  }
}

final districtsProvider =
    AsyncNotifierProvider<DistrictsNotifier, List<DistrictEglise>>(
  DistrictsNotifier.new,
);

class DistrictsNotifier extends AsyncNotifier<List<DistrictEglise>> {
  @override
  Future<List<DistrictEglise>> build() async {
    try {
      final dataService = ref.read(dataServiceProvider);
      return dataService.getDistricts();
    } catch (e, st) {
      ErrorReporting.captureException(e, stackTrace: st, context: {'provider': 'districtsProvider'});
      rethrow;
    }
  }

  Future<void> ajouterDistrict(DistrictEglise district) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, district]);
  }

  Future<void> mettreAJourDistrict(DistrictEglise district) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((d) => d.id == district.id);
    if (index == -1) return;
    final maj = [...actuelle]..[index] = district;
    state = AsyncData(maj);
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
    try {
      final dataService = ref.read(dataServiceProvider);
      return dataService.getAssembleesLocales();
    } catch (e, st) {
      ErrorReporting.captureException(e, stackTrace: st, context: {'provider': 'assembleesLocalesProvider'});
      rethrow;
    }
  }

  Future<void> ajouterAssemblee(AssembleeLocale assemblee) async {
    final actuelle = state.value ?? [];
    state = AsyncData([...actuelle, assemblee]);
  }

  Future<void> mettreAJourAssemblee(AssembleeLocale assemblee) async {
    final actuelle = state.value ?? [];
    final index = actuelle.indexWhere((a) => a.id == assemblee.id);
    if (index == -1) return;
    final maj = [...actuelle]..[index] = assemblee;
    state = AsyncData(maj);
  }
}

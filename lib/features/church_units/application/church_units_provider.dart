import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/data_service_provider.dart';

import '../data/church_unit_model.dart';
import '../data/church_units_repository.dart';

final churchUnitsRepositoryProvider = Provider<ChurchUnitsRepository?>((ref) {
  final dataService = ref.read(dataServiceProvider);
  if (dataService is! SupabaseDataService) return null;
  return ChurchUnitsRepository(dataService);
});

final churchUnitTypesProvider = FutureProvider<List<ChurchUnitType>>((
  ref,
) async {
  final repository = ref.read(churchUnitsRepositoryProvider);
  if (repository == null) return _legacyTypes();
  final remoteTypes = await repository.fetchTypes();
  if (remoteTypes.isNotEmpty) return remoteTypes;
  return _legacyTypes();
});

final churchUnitsProvider = FutureProvider<List<ChurchUnit>>((ref) async {
  final dataService = ref.read(dataServiceProvider);

  if (dataService is SupabaseDataService) {
    final remoteUnits = await ChurchUnitsRepository(dataService).fetchUnits();
    if (remoteUnits.isNotEmpty) return remoteUnits;
  }

  return _legacyUnits(ref);
});

List<ChurchUnitType> _legacyTypes() {
  return const [
    ChurchUnitType(
      id: 'legacy_organization',
      organizationId: 'demo',
      code: 'organization',
      label: 'Organisation',
      levelOrder: 0,
      isLocal: false,
      isFinancialScope: true,
      canHaveMembers: false,
    ),
    ChurchUnitType(
      id: 'legacy_region',
      organizationId: 'demo',
      code: 'region',
      label: 'Region',
      levelOrder: 1,
      isLocal: false,
      isFinancialScope: false,
      canHaveMembers: false,
    ),
    ChurchUnitType(
      id: 'legacy_district',
      organizationId: 'demo',
      code: 'district',
      label: 'District',
      levelOrder: 2,
      isLocal: false,
      isFinancialScope: false,
      canHaveMembers: false,
    ),
    ChurchUnitType(
      id: 'legacy_local_church',
      organizationId: 'demo',
      code: 'local_church',
      label: 'Assemblee locale',
      levelOrder: 3,
      isLocal: true,
      isFinancialScope: true,
      canHaveMembers: true,
    ),
  ];
}

Future<List<ChurchUnit>> _legacyUnits(Ref ref) async {
  final dataService = ref.read(dataServiceProvider);
  final organizationId = dataService is SupabaseDataService
      ? (await ref.watch(currentOrganizationProvider.future))?.id ?? 'demo'
      : 'demo';

  final organizationName = dataService is SupabaseDataService
      ? (await ref.watch(currentOrganizationProvider.future))?.nom ??
            'Organisation demo'
      : 'Organisation demo';

  final regions = await ref.watch(regionsProvider.future);
  final districts = await ref.watch(districtsProvider.future);
  final assemblees = await ref.watch(assembleesLocalesProvider.future);

  final units = <ChurchUnit>[
    ChurchUnit.legacy(
      id: 'legacy_root_$organizationId',
      organizationId: organizationId,
      nom: organizationName,
      typeCode: 'organization',
      typeLabel: 'Organisation',
      levelOrder: 0,
      code: 'ORG_ROOT',
    ),
  ];

  for (final region in regions) {
    units.add(
      ChurchUnit.legacy(
        id: region.id,
        organizationId: organizationId,
        parentId: 'legacy_root_$organizationId',
        nom: region.nom,
        code: region.code,
        description: region.description,
        typeCode: 'region',
        typeLabel: 'Region',
        levelOrder: 1,
        legacyRegionId: region.id,
      ),
    );
  }

  for (final district in districts) {
    units.add(
      ChurchUnit.legacy(
        id: district.id,
        organizationId: organizationId,
        parentId: district.idRegion,
        nom: district.nom,
        code: district.code,
        description: district.description,
        typeCode: 'district',
        typeLabel: 'District',
        levelOrder: 2,
        legacyDistrictId: district.id,
      ),
    );
  }

  for (final assemblee in assemblees) {
    units.add(
      ChurchUnit.legacy(
        id: assemblee.id,
        organizationId: organizationId,
        parentId: assemblee.idDistrict,
        nom: assemblee.nom,
        code: assemblee.code,
        ville: assemblee.ville,
        quartier: assemblee.quartier,
        adresse: assemblee.adressePostale,
        telephone: assemblee.telephone,
        email: assemblee.email,
        typeCode: 'local_church',
        typeLabel: 'Assemblee locale',
        levelOrder: 3,
        legacyAssembleeId: assemblee.id,
      ),
    );
  }

  return units;
}

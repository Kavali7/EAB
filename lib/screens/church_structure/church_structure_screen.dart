import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/assemblee_locale.dart';
import '../../models/district_eglise.dart';
import '../../models/member.dart';
import '../../models/program.dart';
import '../../models/region_eglise.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/members_provider.dart';
import '../../providers/programs_provider.dart';
import '../../widgets/app_shell.dart';

class ChurchStructureScreen extends ConsumerStatefulWidget {
  const ChurchStructureScreen({super.key});

  @override
  ConsumerState<ChurchStructureScreen> createState() =>
      _ChurchStructureScreenState();
}

class _ChurchStructureScreenState extends ConsumerState<ChurchStructureScreen> {
  String? _selectedRegionId;
  String? _selectedDistrictId;
  String? _selectedAssembleeId;

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionsProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final membersAsync = ref.watch(membersProvider);
    final programsAsync = ref.watch(programsProvider);

    if (regionsAsync.isLoading ||
        districtsAsync.isLoading ||
        assembleesAsync.isLoading ||
        membersAsync.isLoading ||
        programsAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (regionsAsync.hasError ||
        districtsAsync.hasError ||
        assembleesAsync.hasError ||
        membersAsync.hasError ||
        programsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Erreur lors du chargement des donnees',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final regions = regionsAsync.value ?? [];
    final districts = districtsAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final members = membersAsync.value ?? [];
    final programs = programsAsync.value ?? [];

    final districtById = {for (final d in districts) d.id: d};
    final regionById = {for (final r in regions) r.id: r};

    final filteredDistricts = _selectedRegionId == null
        ? districts
        : districts.where((d) => d.idRegion == _selectedRegionId).toList();
    final filteredAssemblees = () {
      if (_selectedDistrictId != null) {
        return assemblees
            .where((a) => a.idDistrict == _selectedDistrictId)
            .toList();
      }
      if (_selectedRegionId != null) {
        final allowedDistricts = filteredDistricts.map((d) => d.id).toSet();
        return assemblees.where((a) => allowedDistricts.contains(a.idDistrict)).toList();
      }
      return assemblees;
    }();

    AssembleeLocale? selectedAssemblee;
    if (_selectedAssembleeId != null) {
      final found =
          assemblees.where((a) => a.id == _selectedAssembleeId).toList();
      if (found.isNotEmpty) {
        selectedAssemblee = found.first;
      }
    }
    final selectedDistrict = _selectedDistrictId != null
        ? districtById[_selectedDistrictId!]
        : null;
    final selectedRegion =
        _selectedRegionId != null ? regionById[_selectedRegionId!] : null;

    return AppShell(
      title: "Structure de l'Eglise",
      currentRoute: '/structure',
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildRegionsColumn(regions),
            ),
            Expanded(
              flex: 2,
              child: _buildDistrictsColumn(filteredDistricts),
            ),
            Expanded(
              flex: 3,
              child: _buildAssembleesColumn(filteredAssemblees, districtById),
            ),
            Expanded(
              flex: 4,
              child: _buildDetailsPanel(
                selectedRegion: selectedRegion,
                selectedDistrict: selectedDistrict,
                selectedAssemblee: selectedAssemblee,
                regionById: regionById,
                districtById: districtById,
                assemblees: assemblees,
                districts: districts,
                members: members,
                programs: programs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionsColumn(List<RegionEglise> regions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Regions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  final selected = region.id == _selectedRegionId;
                  return Card(
                    color: selected
                        ? ChurchTheme.gold.withValues(alpha: 0.12)
                        : null,
                    child: ListTile(
                      title: Text(region.nom),
                      subtitle:
                          region.code != null ? Text(region.code!) : null,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedRegionId =
                              selected ? null : region.id;
                          _selectedDistrictId = null;
                          _selectedAssembleeId = null;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictsColumn(List<DistrictEglise> districts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Districts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: districts.isEmpty
                  ? const Center(
                      child: Text('Selectionnez une region'),
                    )
                  : ListView.builder(
                      itemCount: districts.length,
                      itemBuilder: (context, index) {
                        final district = districts[index];
                        final selected = district.id == _selectedDistrictId;
                        return Card(
                          color:
                              selected ? ChurchTheme.gold.withValues(alpha: 0.12) : null,
                          child: ListTile(
                            title: Text(district.nom),
                            subtitle: district.code != null
                                ? Text(district.code!)
                                : null,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                _selectedDistrictId =
                                    selected ? null : district.id;
                                _selectedAssembleeId = null;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssembleesColumn(
    List<AssembleeLocale> assemblees,
    Map<String, DistrictEglise> districtById,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assemblees locales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: assemblees.isEmpty
                  ? const Center(child: Text('Selectionnez un district'))
                  : ListView.builder(
                      itemCount: assemblees.length,
                      itemBuilder: (context, index) {
                        final assembl = assemblees[index];
                        final selected =
                            assembl.id == _selectedAssembleeId;
                        final district = districtById[assembl.idDistrict];
                        final subtitleParts = <String>[];
                        if (assembl.ville != null) {
                          subtitleParts.add('Ville: ${assembl.ville}');
                        }
                        if (assembl.quartier != null &&
                            assembl.quartier!.isNotEmpty) {
                          subtitleParts.add('Quartier: ${assembl.quartier}');
                        }
                        if (district != null) {
                          subtitleParts.add('District: ${district.nom}');
                        }
                        return Card(
                          color: selected
                              ? ChurchTheme.gold.withValues(alpha: 0.12)
                              : null,
                          child: ListTile(
                            title: Text(assembl.nom),
                            subtitle: subtitleParts.isNotEmpty
                                ? Text(subtitleParts.join(' • '))
                                : null,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                _selectedAssembleeId =
                                    selected ? null : assembl.id;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel({
    required RegionEglise? selectedRegion,
    required DistrictEglise? selectedDistrict,
    required AssembleeLocale? selectedAssemblee,
    required Map<String, RegionEglise> regionById,
    required Map<String, DistrictEglise> districtById,
    required List<AssembleeLocale> assemblees,
    required List<DistrictEglise> districts,
    required List<Member> members,
    required List<Program> programs,
  }) {
    Widget buildStat(String label, String value, {IconData? icon}) {
      return Card(
        child: ListTile(
          leading: icon != null ? Icon(icon, color: ChurchTheme.navy) : null,
          title: Text(label),
          subtitle: Text(value),
        ),
      );
    }

    if (selectedAssemblee != null) {
      final district = districtById[selectedAssemblee.idDistrict];
      final region = district != null ? regionById[district.idRegion] : null;
      final membersForAssembly = members
          .where((m) => m.idAssembleeLocale == selectedAssemblee.id)
          .toList();
      final programsForAssembly = programs
          .where((p) => p.idAssembleeLocale == selectedAssemblee.id)
          .toList();
      final activeCount = membersForAssembly
          .where((m) => m.statut == StatutFidele.actif)
          .length;
      final officersCount =
          membersForAssembly.where((m) => m.estOfficier).length;
      final vulnerableCount =
          membersForAssembly.where((m) => m.vulnerabilites.isNotEmpty).length;
      final maleCount =
          membersForAssembly.where((m) => m.gender == Gender.male).length;
      final femaleCount =
          membersForAssembly.where((m) => m.gender == Gender.female).length;
      int countType(TypeProgramme type) =>
          programsForAssembly.where((p) => p.type == type).length;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedAssemblee.nom,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (selectedAssemblee.code != null)
                      'Code: ${selectedAssemblee.code}',
                    if (selectedAssemblee.ville != null)
                      'Ville: ${selectedAssemblee.ville}',
                    if (selectedAssemblee.quartier != null)
                      'Quartier: ${selectedAssemblee.quartier}',
                  ].where((e) => e.isNotEmpty).join(' • '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (selectedAssemblee.telephone != null ||
                    selectedAssemblee.email != null)
                  Text(
                    [
                      if (selectedAssemblee.telephone != null)
                        'Tel: ${selectedAssemblee.telephone}',
                      if (selectedAssemblee.email != null)
                        'Email: ${selectedAssemblee.email}',
                    ].where((e) => e.isNotEmpty).join(' • '),
                  ),
                const SizedBox(height: 8),
                Text(
                  'District: ${district?.nom ?? '--'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Region: ${region?.nom ?? '--'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                buildStat(
                  'Fideles',
                  '${membersForAssembly.length} (Actifs: $activeCount, Officiers: $officersCount, Vulnérables: $vulnerableCount)',
                  icon: Icons.people_alt_outlined,
                ),
                buildStat(
                  'Répartition H/F',
                  'H: $maleCount / F: $femaleCount',
                  icon: Icons.wc,
                ),
                buildStat(
                  'Programmes',
                  '${programsForAssembly.length} (Cultes: ${countType(TypeProgramme.culte)}, Évangelisations: ${countType(TypeProgramme.evangelisationMasse) + countType(TypeProgramme.evangelisationPorteAPorte)}, École du dimanche: ${countType(TypeProgramme.ecoleDuDimanche)})',
                  icon: Icons.event_note_outlined,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (selectedDistrict != null) {
      final region = regionById[selectedDistrict.idRegion];
      final assembleesForDistrict = assemblees
          .where((a) => a.idDistrict == selectedDistrict.id)
          .toList();
      final assembleeIds =
          assembleesForDistrict.map((a) => a.id).toSet();
      final membersForDistrict = members
          .where((m) => m.idAssembleeLocale != null && assembleeIds.contains(m.idAssembleeLocale))
          .toList();
      final programsForDistrict = programs
          .where((p) => p.idAssembleeLocale != null && assembleeIds.contains(p.idAssembleeLocale))
          .toList();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedDistrict.nom,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              if (selectedDistrict.code != null)
                Text('Code: ${selectedDistrict.code}'),
              const SizedBox(height: 6),
              Text('Region: ${region?.nom ?? '--'}'),
              const SizedBox(height: 12),
              buildStat(
                'Assemblées',
                assembleesForDistrict.length.toString(),
                icon: Icons.church_outlined,
              ),
              buildStat(
                'Fidèles',
                membersForDistrict.length.toString(),
                icon: Icons.people_alt_outlined,
              ),
              buildStat(
                'Programmes',
                programsForDistrict.length.toString(),
                icon: Icons.event_note_outlined,
              ),
            ],
          ),
        ),
      );
    }

    if (selectedRegion != null) {
      final districtsForRegion =
          districts.where((d) => d.idRegion == selectedRegion.id).toList();
      final districtIds = districtsForRegion.map((d) => d.id).toSet();
      final assembleesForRegion =
          assemblees.where((a) => districtIds.contains(a.idDistrict)).toList();
      final assembleeIds = assembleesForRegion.map((a) => a.id).toSet();
      final membersForRegion = members
          .where((m) => m.idAssembleeLocale != null && assembleeIds.contains(m.idAssembleeLocale))
          .toList();
      final programsForRegion = programs
          .where((p) => p.idAssembleeLocale != null && assembleeIds.contains(p.idAssembleeLocale))
          .toList();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedRegion.nom,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              if (selectedRegion.code != null)
                Text('Code: ${selectedRegion.code}'),
              const SizedBox(height: 12),
              buildStat(
                'Districts',
                districtsForRegion.length.toString(),
                icon: Icons.map_outlined,
              ),
              buildStat(
                'Assemblées',
                assembleesForRegion.length.toString(),
                icon: Icons.church_outlined,
              ),
              buildStat(
                'Fidèles',
                membersForRegion.length.toString(),
                icon: Icons.people_alt_outlined,
              ),
              buildStat(
                'Programmes',
                programsForRegion.length.toString(),
                icon: Icons.event_note_outlined,
              ),
            ],
          ),
        ),
      );
    }

    return const Card(
      child: Center(
        child: Text(
          'Selectionnez une region, un district ou une assemblee pour voir les details.',
        ),
      ),
    );
  }
}

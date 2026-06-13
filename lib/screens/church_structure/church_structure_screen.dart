import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../features/church_units/presentation/flexible_church_structure_panel.dart';
import '../../models/assemblee_locale.dart';
import '../../models/district_eglise.dart';
import '../../models/member.dart';
import '../../models/program.dart';
import '../../models/region_eglise.dart';
import '../../models/profil_utilisateur.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/members_provider.dart';
import '../../providers/programs_provider.dart';
import '../../providers/user_profile_providers.dart';
import '../../ui/ui.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';
import '../../widgets/error_retry_widget.dart';

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
  String? _profileAppliedId;
  Map<String, DistrictEglise> _latestDistrictById = {};

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionsProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final membersAsync = ref.watch(membersProvider);
    final programsAsync = ref.watch(programsProvider);
    final profilCourant = ref.watch(profilUtilisateurCourantProvider);
    final regionsNotifier = ref.read(regionsProvider.notifier);
    final districtsNotifier = ref.read(districtsProvider.notifier);
    final assembleesNotifier = ref.read(assembleesLocalesProvider.notifier);

    if (regionsAsync.isLoading ||
        districtsAsync.isLoading ||
        assembleesAsync.isLoading ||
        membersAsync.isLoading ||
        programsAsync.isLoading) {
      return const AppShell(
        title: "Structure de l'Eglise",
        currentRoute: '/structure',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (regionsAsync.hasError ||
        districtsAsync.hasError ||
        assembleesAsync.hasError ||
        membersAsync.hasError ||
        programsAsync.hasError) {
      final err =
          regionsAsync.error ??
          districtsAsync.error ??
          assembleesAsync.error ??
          membersAsync.error ??
          programsAsync.error;
      return AppShell(
        title: "Structure de l'Eglise",
        currentRoute: '/structure',
        body: ErrorRetryWidget(
          message: 'Erreur lors du chargement des données : $err',
          onRetry: () {
            ref.invalidate(regionsProvider);
            ref.invalidate(districtsProvider);
            ref.invalidate(assembleesLocalesProvider);
            ref.invalidate(membersProvider);
            ref.invalidate(programsProvider);
          },
        ),
      );
    }

    final regions = regionsAsync.value ?? [];
    final districts = districtsAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final members = membersAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    _latestDistrictById = {for (final d in districts) d.id: d};

    if (profilCourant != null && _profileAppliedId != profilCourant.id) {
      _applyProfileScope(profilCourant, districts, assemblees);
      _profileAppliedId = profilCourant.id;
    }

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
        return assemblees
            .where((a) => allowedDistricts.contains(a.idDistrict))
            .toList();
      }
      return assemblees;
    }();

    AssembleeLocale? selectedAssemblee;
    if (_selectedAssembleeId != null) {
      final found = assemblees
          .where((a) => a.id == _selectedAssembleeId)
          .toList();
      if (found.isNotEmpty) {
        selectedAssemblee = found.first;
      }
    }
    final selectedDistrict = _selectedDistrictId != null
        ? districtById[_selectedDistrictId!]
        : null;
    final selectedRegion = _selectedRegionId != null
        ? regionById[_selectedRegionId!]
        : null;

    return AppShell(
      title: "Structure de l'Eglise",
      currentRoute: '/structure',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final content = compact
              ? _buildCompactStructure(
                  regions: regions,
                  filteredDistricts: filteredDistricts,
                  filteredAssemblees: filteredAssemblees,
                  regionById: regionById,
                  districtById: districtById,
                  selectedRegion: selectedRegion,
                  selectedDistrict: selectedDistrict,
                  selectedAssemblee: selectedAssemblee,
                  regionsNotifier: regionsNotifier,
                  districtsNotifier: districtsNotifier,
                  assembleesNotifier: assembleesNotifier,
                  members: members,
                  programs: programs,
                  districts: districts,
                  assemblees: assemblees,
                  profil: profilCourant,
                )
              : _buildDesktopStructure(
                  regions: regions,
                  filteredDistricts: filteredDistricts,
                  filteredAssemblees: filteredAssemblees,
                  regionById: regionById,
                  districtById: districtById,
                  selectedRegion: selectedRegion,
                  selectedDistrict: selectedDistrict,
                  selectedAssemblee: selectedAssemblee,
                  regionsNotifier: regionsNotifier,
                  districtsNotifier: districtsNotifier,
                  assembleesNotifier: assembleesNotifier,
                  members: members,
                  programs: programs,
                  districts: districts,
                  assemblees: assemblees,
                  profil: profilCourant,
                );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopStructure({
    required List<RegionEglise> regions,
    required List<DistrictEglise> filteredDistricts,
    required List<AssembleeLocale> filteredAssemblees,
    required Map<String, RegionEglise> regionById,
    required Map<String, DistrictEglise> districtById,
    required RegionEglise? selectedRegion,
    required DistrictEglise? selectedDistrict,
    required AssembleeLocale? selectedAssemblee,
    required RegionsNotifier regionsNotifier,
    required DistrictsNotifier districtsNotifier,
    required AssembleesLocalesNotifier assembleesNotifier,
    required List<Member> members,
    required List<Program> programs,
    required List<DistrictEglise> districts,
    required List<AssembleeLocale> assemblees,
    required ProfilUtilisateur? profil,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ContextHeader(showPorteeComptable: false),
          const SizedBox(height: AppSpacing.cardGap),
          const FlexibleChurchStructurePanel(),
          const SizedBox(height: AppSpacing.cardGap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildRegionsColumn(regions, profil, regionsNotifier),
                ),
                const SizedBox(width: AppSpacing.cardGap),
                Expanded(
                  flex: 3,
                  child: _buildDistrictsColumn(
                    filteredDistricts,
                    profil,
                    districtsNotifier,
                    regionById,
                  ),
                ),
                const SizedBox(width: AppSpacing.cardGap),
                Expanded(
                  flex: 4,
                  child: _buildAssembleesColumn(
                    filteredAssemblees,
                    districtById,
                    profil,
                    assembleesNotifier,
                  ),
                ),
                const SizedBox(width: AppSpacing.cardGap),
                Expanded(
                  flex: 5,
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
                    profil: profil,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStructure({
    required List<RegionEglise> regions,
    required List<DistrictEglise> filteredDistricts,
    required List<AssembleeLocale> filteredAssemblees,
    required Map<String, RegionEglise> regionById,
    required Map<String, DistrictEglise> districtById,
    required RegionEglise? selectedRegion,
    required DistrictEglise? selectedDistrict,
    required AssembleeLocale? selectedAssemblee,
    required RegionsNotifier regionsNotifier,
    required DistrictsNotifier districtsNotifier,
    required AssembleesLocalesNotifier assembleesNotifier,
    required List<Member> members,
    required List<Program> programs,
    required List<DistrictEglise> districts,
    required List<AssembleeLocale> assemblees,
    required ProfilUtilisateur? profil,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ContextHeader(showPorteeComptable: false),
          const SizedBox(height: AppSpacing.cardGap),
          const FlexibleChurchStructurePanel(),
          const SizedBox(height: AppSpacing.cardGap),
          _buildMobileRegionsSection(regions, profil, regionsNotifier),
          const SizedBox(height: AppSpacing.cardGap),
          _buildMobileDistrictsSection(
            filteredDistricts,
            profil,
            districtsNotifier,
            regionById,
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _buildMobileAssembleesSection(
            filteredAssemblees,
            districtById,
            profil,
            assembleesNotifier,
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _buildDetailsPanel(
            selectedRegion: selectedRegion,
            selectedDistrict: selectedDistrict,
            selectedAssemblee: selectedAssemblee,
            regionById: regionById,
            districtById: districtById,
            assemblees: assemblees,
            districts: districts,
            members: members,
            programs: programs,
            profil: profil,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRegionsSection(
    List<RegionEglise> regions,
    ProfilUtilisateur? profil,
    RegionsNotifier regionsNotifier,
  ) {
    return _buildMobilePanel(
      title: 'Regions',
      icon: Icons.account_tree_outlined,
      actionTooltip: 'Ajouter une region',
      onAction: _peutGererRegions(profil)
          ? () => _openRegionDialog(notifier: regionsNotifier, profil: profil)
          : null,
      child: regions.isEmpty
          ? _buildEmptyState('Aucune region enregistree.')
          : Column(
              children: [
                for (final region in regions)
                  _buildRegionMobileTile(region, profil, regionsNotifier),
              ],
            ),
    );
  }

  Widget _buildMobileDistrictsSection(
    List<DistrictEglise> districts,
    ProfilUtilisateur? profil,
    DistrictsNotifier districtsNotifier,
    Map<String, RegionEglise> regionById,
  ) {
    return _buildMobilePanel(
      title: 'Districts',
      icon: Icons.map_outlined,
      actionTooltip: 'Ajouter un district',
      onAction: _peutAjouterDistrict(profil)
          ? () => _openDistrictDialog(
              notifier: districtsNotifier,
              profil: profil,
              regionById: regionById,
              regionPreferee: _selectedRegionId,
            )
          : null,
      child: districts.isEmpty
          ? _buildEmptyState(
              _selectedRegionId == null
                  ? 'Selectionnez une region pour filtrer les districts.'
                  : 'Aucun district dans cette region.',
            )
          : Column(
              children: [
                for (final district in districts)
                  _buildDistrictMobileTile(
                    district,
                    profil,
                    districtsNotifier,
                    regionById,
                  ),
              ],
            ),
    );
  }

  Widget _buildMobileAssembleesSection(
    List<AssembleeLocale> assemblees,
    Map<String, DistrictEglise> districtById,
    ProfilUtilisateur? profil,
    AssembleesLocalesNotifier assembleesNotifier,
  ) {
    return _buildMobilePanel(
      title: 'Assemblees locales',
      icon: Icons.church_outlined,
      actionTooltip: 'Ajouter une assemblee',
      onAction: _peutAjouterAssemblee(profil)
          ? () => _openAssembleeDialog(
              notifier: assembleesNotifier,
              profil: profil,
              districtPrefere: _selectedDistrictId,
              districtById: districtById,
            )
          : null,
      child: assemblees.isEmpty
          ? _buildEmptyState(
              _selectedDistrictId == null
                  ? 'Selectionnez un district pour cibler les assemblees.'
                  : 'Aucune assemblee dans ce district.',
            )
          : Column(
              children: [
                for (final assemblee in assemblees)
                  _buildAssembleeMobileTile(
                    assemblee,
                    districtById,
                    profil,
                    assembleesNotifier,
                  ),
              ],
            ),
    );
  }

  Widget _buildMobilePanel({
    required String title,
    required IconData icon,
    required String actionTooltip,
    required VoidCallback? onAction,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ChurchTheme.navy),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: actionTooltip,
                  icon: const Icon(Icons.add),
                  onPressed: onAction,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRegionMobileTile(
    RegionEglise region,
    ProfilUtilisateur? profil,
    RegionsNotifier regionsNotifier,
  ) {
    final selected = region.id == _selectedRegionId;
    final enabled = _canSelectRegion(region);
    return _buildSelectableTile(
      title: region.nom,
      subtitle: region.code,
      selected: selected,
      enabled: enabled,
      onTap: () {
        setState(() {
          _selectedRegionId = selected ? null : region.id;
          _selectedDistrictId = null;
          _selectedAssembleeId = null;
        });
      },
      onEdit: _peutGererRegions(profil)
          ? () => _openRegionDialog(
              notifier: regionsNotifier,
              profil: profil,
              region: region,
            )
          : null,
    );
  }

  Widget _buildDistrictMobileTile(
    DistrictEglise district,
    ProfilUtilisateur? profil,
    DistrictsNotifier districtsNotifier,
    Map<String, RegionEglise> regionById,
  ) {
    final selected = district.id == _selectedDistrictId;
    final enabled = _canSelectDistrict(district);
    final region = regionById[district.idRegion];
    return _buildSelectableTile(
      title: district.nom,
      subtitle: [
        if (district.code != null) district.code,
        if (region != null) 'Region: ${region.nom}',
      ].whereType<String>().join(' - '),
      selected: selected,
      enabled: enabled,
      onTap: () {
        setState(() {
          _selectedDistrictId = selected ? null : district.id;
          _selectedAssembleeId = null;
        });
      },
      onEdit: _peutGererDistricts(profil, district, regionById)
          ? () => _openDistrictDialog(
              notifier: districtsNotifier,
              profil: profil,
              regionById: regionById,
              district: district,
            )
          : null,
    );
  }

  Widget _buildAssembleeMobileTile(
    AssembleeLocale assemblee,
    Map<String, DistrictEglise> districtById,
    ProfilUtilisateur? profil,
    AssembleesLocalesNotifier assembleesNotifier,
  ) {
    final selected = assemblee.id == _selectedAssembleeId;
    final enabled = _canSelectAssemblee(assemblee);
    final district = districtById[assemblee.idDistrict];
    final subtitleParts = <String>[
      if (assemblee.code != null) assemblee.code!,
      if (assemblee.ville != null) 'Ville: ${assemblee.ville}',
      if (district != null) 'District: ${district.nom}',
    ];
    return _buildSelectableTile(
      title: assemblee.nom,
      subtitle: subtitleParts.join(' - '),
      selected: selected,
      enabled: enabled,
      onTap: () {
        setState(() {
          _selectedAssembleeId = selected ? null : assemblee.id;
        });
      },
      onEdit: _peutGererAssemblee(profil, assemblee)
          ? () => _openAssembleeDialog(
              notifier: assembleesNotifier,
              profil: profil,
              districtPrefere: _selectedDistrictId,
              districtById: districtById,
              assemblee: assemblee,
            )
          : null,
    );
  }

  Widget _buildSelectableTile({
    required String title,
    required String? subtitle,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
    required VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected ? ChurchTheme.gold.withValues(alpha: 0.14) : null,
        border: Border.all(
          color: selected
              ? ChurchTheme.gold.withValues(alpha: 0.7)
              : Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        selected: selected,
        enabled: enabled,
        trailing: IconButton(
          tooltip: 'Modifier',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ChurchTheme.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ChurchTheme.navy.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _buildRegionsColumn(
    List<RegionEglise> regions,
    ProfilUtilisateur? profil,
    RegionsNotifier regionsNotifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Regions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Ajouter une region',
                  icon: const Icon(Icons.add),
                  onPressed: _peutGererRegions(profil)
                      ? () => _openRegionDialog(
                          notifier: regionsNotifier,
                          profil: profil,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  final selected = region.id == _selectedRegionId;
                  final enabled = _canSelectRegion(region);
                  return Card(
                    color: selected
                        ? ChurchTheme.gold.withValues(alpha: 0.12)
                        : null,
                    child: ListTile(
                      title: Text(region.nom),
                      subtitle: region.code != null ? Text(region.code!) : null,
                      selected: selected,
                      enabled: enabled,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Modifier',
                        onPressed: _peutGererRegions(profil)
                            ? () => _openRegionDialog(
                                notifier: regionsNotifier,
                                profil: profil,
                                region: region,
                              )
                            : null,
                      ),
                      onTap: !enabled
                          ? null
                          : () {
                              setState(() {
                                _selectedRegionId = selected ? null : region.id;
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

  Widget _buildDistrictsColumn(
    List<DistrictEglise> districts,
    ProfilUtilisateur? profil,
    DistrictsNotifier districtsNotifier,
    Map<String, RegionEglise> regionById,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Districts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Ajouter un district',
                  icon: const Icon(Icons.add),
                  onPressed: _peutAjouterDistrict(profil)
                      ? () => _openDistrictDialog(
                          notifier: districtsNotifier,
                          profil: profil,
                          regionById: regionById,
                          regionPreferee: _selectedRegionId,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: districts.isEmpty
                  ? const Center(child: Text('Selectionnez une region'))
                  : ListView.builder(
                      itemCount: districts.length,
                      itemBuilder: (context, index) {
                        final district = districts[index];
                        final selected = district.id == _selectedDistrictId;
                        final enabled = _canSelectDistrict(district);
                        return Card(
                          color: selected
                              ? ChurchTheme.gold.withValues(alpha: 0.12)
                              : null,
                          child: ListTile(
                            title: Text(district.nom),
                            subtitle: district.code != null
                                ? Text(district.code!)
                                : null,
                            selected: selected,
                            enabled: enabled,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Modifier',
                              onPressed:
                                  _peutGererDistricts(
                                    profil,
                                    district,
                                    regionById,
                                  )
                                  ? () => _openDistrictDialog(
                                      notifier: districtsNotifier,
                                      profil: profil,
                                      regionById: regionById,
                                      district: district,
                                    )
                                  : null,
                            ),
                            onTap: !enabled
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDistrictId = selected
                                          ? null
                                          : district.id;
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
    ProfilUtilisateur? profil,
    AssembleesLocalesNotifier assembleesNotifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assemblees locales',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Ajouter une assemblee',
                  icon: const Icon(Icons.add),
                  onPressed: _peutAjouterAssemblee(profil)
                      ? () => _openAssembleeDialog(
                          notifier: assembleesNotifier,
                          profil: profil,
                          districtPrefere: _selectedDistrictId,
                          districtById: districtById,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: assemblees.isEmpty
                  ? const Center(child: Text('Selectionnez un district'))
                  : ListView.builder(
                      itemCount: assemblees.length,
                      itemBuilder: (context, index) {
                        final assembl = assemblees[index];
                        final selected = assembl.id == _selectedAssembleeId;
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
                        final enabled = _canSelectAssemblee(assembl);
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
                            enabled: enabled,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Modifier',
                              onPressed: _peutGererAssemblee(profil, assembl)
                                  ? () => _openAssembleeDialog(
                                      notifier: assembleesNotifier,
                                      profil: profil,
                                      districtPrefere: _selectedDistrictId,
                                      districtById: districtById,
                                      assemblee: assembl,
                                    )
                                  : null,
                            ),
                            onTap: !enabled
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAssembleeId = selected
                                          ? null
                                          : assembl.id;
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
    required ProfilUtilisateur? profil,
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
      final officersCount = membersForAssembly
          .where((m) => m.estOfficier)
          .length;
      final vulnerableCount = membersForAssembly
          .where((m) => m.vulnerabilites.isNotEmpty)
          .length;
      final maleCount = membersForAssembly
          .where((m) => m.gender == Gender.male)
          .length;
      final femaleCount = membersForAssembly
          .where((m) => m.gender == Gender.female)
          .length;
      int countType(TypeProgramme type) =>
          programsForAssembly.where((p) => p.type == type).length;
      Member? pasteur;
      if (selectedAssemblee.idFidelePasteurResponsable != null) {
        try {
          pasteur = membersForAssembly.firstWhere(
            (m) => m.id == selectedAssemblee.idFidelePasteurResponsable,
          );
        } catch (_) {
          pasteur = null;
        }
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profil != null) ...[
                  Text(
                    'Profil simulé : ${profil.nom}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                ],
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
                Text(
                  'Pasteur responsable:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(pasteur?.fullName ?? 'Aucun assigne'),
                if (_peutGererPasteur(profil, selectedAssemblee))
                  TextButton.icon(
                    onPressed: () => _openPasteurDialog(
                      selectedAssemblee,
                      membersForAssembly,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier le pasteur responsable'),
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
      final assembleeIds = assembleesForDistrict.map((a) => a.id).toSet();
      final membersForDistrict = members
          .where(
            (m) =>
                m.idAssembleeLocale != null &&
                assembleeIds.contains(m.idAssembleeLocale),
          )
          .toList();
      final programsForDistrict = programs
          .where(
            (p) =>
                p.idAssembleeLocale != null &&
                assembleeIds.contains(p.idAssembleeLocale),
          )
          .toList();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profil != null) ...[
                Text(
                  'Profil simulé : ${profil.nom}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                selectedDistrict.nom,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              if (selectedDistrict.code != null)
                Text('Code: ${selectedDistrict.code}'),
              const SizedBox(height: 6),
              Text('Region: ${region?.nom ?? '--'}'),
              const SizedBox(height: 6),
              Text('Assemblées: ${assembleesForDistrict.length}'),
              const SizedBox(height: 12),
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
      final districtsForRegion = districts
          .where((d) => d.idRegion == selectedRegion.id)
          .toList();
      final districtIds = districtsForRegion.map((d) => d.id).toSet();
      final assembleesForRegion = assemblees
          .where((a) => districtIds.contains(a.idDistrict))
          .toList();
      final assembleeIds = assembleesForRegion.map((a) => a.id).toSet();
      final membersForRegion = members
          .where(
            (m) =>
                m.idAssembleeLocale != null &&
                assembleeIds.contains(m.idAssembleeLocale),
          )
          .toList();
      final programsForRegion = programs
          .where(
            (p) =>
                p.idAssembleeLocale != null &&
                assembleeIds.contains(p.idAssembleeLocale),
          )
          .toList();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profil != null) ...[
                Text(
                  'Profil simulé : ${profil.nom}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
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

  void _applyProfileScope(
    ProfilUtilisateur profil,
    List<DistrictEglise> districts,
    List<AssembleeLocale> assemblees,
  ) {
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return;
      case RoleUtilisateur.responsableRegion:
        _selectedRegionId = profil.idRegion;
        _selectedDistrictId = null;
        _selectedAssembleeId = null;
        return;
      case RoleUtilisateur.surintendantDistrict:
        _selectedRegionId = profil.idRegion;
        _selectedDistrictId = profil.idDistrict;
        _selectedAssembleeId = null;
        return;
      case RoleUtilisateur.tresorierAssemblee:
        _selectedRegionId = profil.idRegion;
        _selectedDistrictId = profil.idDistrict;
        _selectedAssembleeId = profil.idAssembleeLocale;
        return;
    }
  }

  bool _canSelectRegion(RegionEglise region) {
    final profil = ref.read(profilUtilisateurCourantProvider);
    if (profil == null) return true;
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return true;
      case RoleUtilisateur.responsableRegion:
      case RoleUtilisateur.surintendantDistrict:
      case RoleUtilisateur.tresorierAssemblee:
        return profil.idRegion == region.id;
    }
  }

  bool _canSelectDistrict(DistrictEglise district) {
    final profil = ref.read(profilUtilisateurCourantProvider);
    if (profil == null) return true;
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return true;
      case RoleUtilisateur.responsableRegion:
        return profil.idRegion == district.idRegion;
      case RoleUtilisateur.surintendantDistrict:
        return profil.idDistrict == district.id;
      case RoleUtilisateur.tresorierAssemblee:
        return profil.idDistrict == district.id;
    }
  }

  bool _canSelectAssemblee(AssembleeLocale assemblee) {
    final profil = ref.read(profilUtilisateurCourantProvider);
    if (profil == null) return true;
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return true;
      case RoleUtilisateur.responsableRegion:
        return profil.idRegion != null &&
            _latestDistrictById[assemblee.idDistrict]?.idRegion ==
                profil.idRegion;
      case RoleUtilisateur.surintendantDistrict:
        return profil.idDistrict == assemblee.idDistrict;
      case RoleUtilisateur.tresorierAssemblee:
        return profil.idAssembleeLocale == assemblee.id;
    }
  }

  bool _peutGererRegions(ProfilUtilisateur? profil) {
    return profil?.role == RoleUtilisateur.adminNational;
  }

  bool _peutAjouterDistrict(ProfilUtilisateur? profil) {
    if (profil == null) return false;
    return profil.role == RoleUtilisateur.adminNational ||
        profil.role == RoleUtilisateur.responsableRegion;
  }

  bool _peutGererDistricts(
    ProfilUtilisateur? profil,
    DistrictEglise district,
    Map<String, RegionEglise> regionById,
  ) {
    if (profil == null) return false;
    if (profil.role == RoleUtilisateur.adminNational) return true;
    if (profil.role == RoleUtilisateur.responsableRegion) {
      final region = regionById[district.idRegion];
      return region != null && profil.idRegion == region.id;
    }
    return false;
  }

  bool _peutAjouterAssemblee(ProfilUtilisateur? profil) {
    if (profil == null) return false;
    return profil.role == RoleUtilisateur.adminNational ||
        profil.role == RoleUtilisateur.responsableRegion ||
        profil.role == RoleUtilisateur.surintendantDistrict;
  }

  bool _peutGererAssemblee(
    ProfilUtilisateur? profil,
    AssembleeLocale assemblee,
  ) {
    if (profil == null) return false;
    if (profil.role == RoleUtilisateur.adminNational) return true;
    if (profil.role == RoleUtilisateur.responsableRegion) {
      final regionId = _latestDistrictById[assemblee.idDistrict]?.idRegion;
      return regionId != null && regionId == profil.idRegion;
    }
    if (profil.role == RoleUtilisateur.surintendantDistrict) {
      return profil.idDistrict == assemblee.idDistrict;
    }
    return false;
  }

  bool _peutGererPasteur(ProfilUtilisateur? profil, AssembleeLocale assemblee) {
    if (profil == null) return false;
    if (profil.role == RoleUtilisateur.adminNational) return true;
    if (profil.role == RoleUtilisateur.responsableRegion) {
      final regionId = _latestDistrictById[assemblee.idDistrict]?.idRegion;
      return regionId != null && regionId == profil.idRegion;
    }
    if (profil.role == RoleUtilisateur.surintendantDistrict) {
      return profil.idDistrict == assemblee.idDistrict;
    }
    return false;
  }

  Future<void> _openRegionDialog({
    required RegionsNotifier notifier,
    required ProfilUtilisateur? profil,
    RegionEglise? region,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: region?.nom ?? '');
    final codeCtrl = TextEditingController(text: region?.code ?? '');
    final descCtrl = TextEditingController(text: region?.description ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => EabDialog(
        title: region == null ? 'Nouvelle region' : 'Modifier la region',
        width: 460,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Le nom est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code (optionnel)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          EabButton(
            label: region == null ? 'Ajouter' : 'Mettre a jour',
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (!formKey.currentState!.validate()) return;
              final newRegion = RegionEglise(
                id: region?.id ?? 'region_${const Uuid().v4()}',
                nom: nomCtrl.text.trim(),
                code: codeCtrl.text.trim().isEmpty
                    ? null
                    : codeCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              );
              if (region == null) {
                await notifier.ajouterRegion(newRegion);
              } else {
                await notifier.mettreAJourRegion(newRegion);
              }
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openDistrictDialog({
    required DistrictsNotifier notifier,
    required Map<String, RegionEglise> regionById,
    required ProfilUtilisateur? profil,
    DistrictEglise? district,
    String? regionPreferee,
  }) async {
    final regions = regionById.values.toList();
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: district?.nom ?? '');
    final codeCtrl = TextEditingController(text: district?.code ?? '');
    String? selectedRegionId = district?.idRegion ?? regionPreferee;

    await showDialog<void>(
      context: context,
      builder: (context) => EabDialog(
        title: district == null ? 'Nouveau district' : 'Modifier le district',
        width: 460,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRegionId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Region'),
                items: regions
                    .map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.nom)),
                    )
                    .toList(),
                onChanged: (value) => selectedRegionId = value,
                validator: (v) => v == null ? 'Choisir une region' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Le nom est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code (optionnel)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          EabButton(
            label: district == null ? 'Ajouter' : 'Mettre a jour',
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (!formKey.currentState!.validate()) return;
              final newDistrict = DistrictEglise(
                id: district?.id ?? 'district_${const Uuid().v4()}',
                nom: nomCtrl.text.trim(),
                code: codeCtrl.text.trim().isEmpty
                    ? null
                    : codeCtrl.text.trim(),
                idRegion: selectedRegionId!,
                description: null,
              );
              if (district == null) {
                await notifier.ajouterDistrict(newDistrict);
              } else {
                await notifier.mettreAJourDistrict(newDistrict);
              }
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openAssembleeDialog({
    required AssembleesLocalesNotifier notifier,
    required Map<String, DistrictEglise> districtById,
    required ProfilUtilisateur? profil,
    String? districtPrefere,
    AssembleeLocale? assemblee,
  }) async {
    final districts = districtById.values.toList();
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: assemblee?.nom ?? '');
    final codeCtrl = TextEditingController(text: assemblee?.code ?? '');
    final villeCtrl = TextEditingController(text: assemblee?.ville ?? '');
    final quartierCtrl = TextEditingController(text: assemblee?.quartier ?? '');
    final adresseCtrl = TextEditingController(
      text: assemblee?.adressePostale ?? '',
    );
    final telCtrl = TextEditingController(text: assemblee?.telephone ?? '');
    final emailCtrl = TextEditingController(text: assemblee?.email ?? '');
    String? selectedDistrictId = assemblee?.idDistrict ?? districtPrefere;

    await showDialog<void>(
      context: context,
      builder: (context) => EabDialog(
        title: assemblee == null
            ? 'Nouvelle assemblee'
            : 'Modifier l assemblee',
        width: 540,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedDistrictId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'District'),
                items: districts
                    .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.nom)),
                    )
                    .toList(),
                onChanged: (value) => selectedDistrictId = value,
                validator: (v) => v == null ? 'Choisir un district' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Le nom est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code (optionnel)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: villeCtrl,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quartierCtrl,
                decoration: const InputDecoration(labelText: 'Quartier'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: adresseCtrl,
                decoration: const InputDecoration(labelText: 'Adresse postale'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telCtrl,
                decoration: const InputDecoration(labelText: 'Telephone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          EabButton(
            label: assemblee == null ? 'Ajouter' : 'Mettre a jour',
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (!formKey.currentState!.validate()) return;
              final newAssemblee = AssembleeLocale(
                id: assemblee?.id ?? 'assemblee_${const Uuid().v4()}',
                nom: nomCtrl.text.trim(),
                code: codeCtrl.text.trim().isEmpty
                    ? null
                    : codeCtrl.text.trim(),
                idDistrict: selectedDistrictId!,
                ville: villeCtrl.text.trim().isEmpty
                    ? null
                    : villeCtrl.text.trim(),
                quartier: quartierCtrl.text.trim().isEmpty
                    ? null
                    : quartierCtrl.text.trim(),
                adressePostale: adresseCtrl.text.trim().isEmpty
                    ? null
                    : adresseCtrl.text.trim(),
                telephone: telCtrl.text.trim().isEmpty
                    ? null
                    : telCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty
                    ? null
                    : emailCtrl.text.trim(),
                idFidelePasteurResponsable:
                    assemblee?.idFidelePasteurResponsable,
              );
              if (assemblee == null) {
                await notifier.ajouterAssemblee(newAssemblee);
              } else {
                await notifier.mettreAJourAssemblee(newAssemblee);
              }
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openPasteurDialog(
    AssembleeLocale assemblee,
    List<Member> membersForAssembly,
  ) async {
    final candidats = membersForAssembly
        .where((m) => m.role == RoleFidele.pasteur || m.estOfficier)
        .toList();
    final options = candidats.isNotEmpty ? candidats : membersForAssembly;
    String? selectedId = assemblee.idFidelePasteurResponsable;
    await showDialog<void>(
      context: context,
      builder: (context) => EabDialog(
        title: 'Modifier le pasteur responsable',
        width: 460,
        content: DropdownButtonFormField<String>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Fidele'),
          items: options
              .map(
                (m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)),
              )
              .toList(),
          onChanged: (value) => selectedId = value,
        ),
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          EabButton(
            label: 'Enregistrer',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final updated = assemblee.copyWith(
                idFidelePasteurResponsable: selectedId,
              );
              await ref
                  .read(assembleesLocalesProvider.notifier)
                  .mettreAJourAssemblee(updated);
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }
}

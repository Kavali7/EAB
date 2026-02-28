/// Filtres hiérarchiques Région → District → Assemblée.
///
/// Pattern partagé entre Members, Programs, Accounting.
/// Extrait les dropdowns de filtrage qui étaient dupliqués
/// dans chaque écran.
library;

import 'package:flutter/material.dart';

import '../../models/region_eglise.dart';
import '../../models/district_eglise.dart';
import '../../models/assemblee_locale.dart';
import '../theme/app_spacing.dart';

/// Callback retournant les IDs sélectionnés.
typedef HierarchyFilterCallback = void Function({
  String? regionId,
  String? districtId,
  String? assembleeId,
});

/// Filtres hiérarchiques Région / District / Assemblée.
class EabHierarchyFilter extends StatelessWidget {
  const EabHierarchyFilter({
    super.key,
    required this.regions,
    required this.districts,
    required this.assemblees,
    this.selectedRegionId,
    this.selectedDistrictId,
    this.selectedAssembleeId,
    required this.onChanged,
    this.showAssembleeFilter = true,
  });

  final List<RegionEglise> regions;
  final List<DistrictEglise> districts;
  final List<AssembleeLocale> assemblees;
  final String? selectedRegionId;
  final String? selectedDistrictId;
  final String? selectedAssembleeId;
  final HierarchyFilterCallback onChanged;

  /// Permet de masquer le filtre assemblée (ex: dans la vue structure).
  final bool showAssembleeFilter;

  List<DistrictEglise> get _filteredDistricts {
    if (selectedRegionId == null) return districts;
    return districts.where((d) => d.idRegion == selectedRegionId).toList();
  }

  List<AssembleeLocale> get _filteredAssemblees {
    if (selectedDistrictId == null) {
      if (selectedRegionId == null) return assemblees;
      final districtIds = _filteredDistricts.map((d) => d.id).toSet();
      return assemblees
          .where((a) => districtIds.contains(a.idDistrict))
          .toList();
    }
    return assemblees
        .where((a) => a.idDistrict == selectedDistrictId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        // Filtre Région
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedRegionId,
            decoration: const InputDecoration(
              labelText: 'Région',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.inputPaddingH,
                vertical: AppSpacing.inputPaddingV,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toutes')),
              ...regions.map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.nom),
                  )),
            ],
            onChanged: (val) => onChanged(
              regionId: val,
              districtId: null,
              assembleeId: null,
            ),
          ),
        ),
        // Filtre District
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: selectedDistrictId,
            decoration: const InputDecoration(
              labelText: 'District',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.inputPaddingH,
                vertical: AppSpacing.inputPaddingV,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tous')),
              ..._filteredDistricts.map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.nom),
                  )),
            ],
            onChanged: (val) => onChanged(
              regionId: selectedRegionId,
              districtId: val,
              assembleeId: null,
            ),
          ),
        ),
        // Filtre Assemblée
        if (showAssembleeFilter)
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String?>(
              initialValue: selectedAssembleeId,
              decoration: const InputDecoration(
                labelText: 'Assemblée',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.inputPaddingH,
                  vertical: AppSpacing.inputPaddingV,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes')),
                ..._filteredAssemblees.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.nom),
                    )),
              ],
              onChanged: (val) => onChanged(
                regionId: selectedRegionId,
                districtId: selectedDistrictId,
                assembleeId: val,
              ),
            ),
          ),
      ],
    );
  }
}

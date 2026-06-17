import 'package:eab/features/church_units/data/church_unit_model.dart';

/// Perimetre central utilise par les listes et KPI visibles.
/// Garde les ecrans alignes entre l'ancienne assemblee et la hierarchie flexible.
class ChurchUnitScope {
  ChurchUnitScope._({
    required this.activeChurchUnitId,
    required this.activeAssembleeId,
    required this.unitById,
    required this.unitIds,
    required this.legacyAssembleeIds,
  });

  factory ChurchUnitScope.fromActiveContext({
    required List<ChurchUnit> units,
    required String? activeChurchUnitId,
    required String? activeAssembleeId,
  }) {
    final unitById = {for (final unit in units) unit.id: unit};
    final unitIds = <String>{};
    final legacyAssembleeIds = <String>{};

    if (activeAssembleeId != null && activeAssembleeId.isNotEmpty) {
      legacyAssembleeIds.add(activeAssembleeId);
    }

    if (activeChurchUnitId != null && activeChurchUnitId.isNotEmpty) {
      final byParent = <String?, List<ChurchUnit>>{};
      for (final unit in units) {
        byParent.putIfAbsent(unit.parentId, () => <ChurchUnit>[]).add(unit);
      }

      void visit(String id) {
        if (!unitIds.add(id)) return;
        final unit = unitById[id];
        final legacyId = unit?.legacyAssembleeId;
        if (legacyId != null && legacyId.isNotEmpty) {
          legacyAssembleeIds.add(legacyId);
        }
        for (final child in byParent[id] ?? const <ChurchUnit>[]) {
          visit(child.id);
        }
      }

      visit(activeChurchUnitId);
    }

    return ChurchUnitScope._(
      activeChurchUnitId: activeChurchUnitId,
      activeAssembleeId: activeAssembleeId,
      unitById: unitById,
      unitIds: unitIds,
      legacyAssembleeIds: legacyAssembleeIds,
    );
  }

  final String? activeChurchUnitId;
  final String? activeAssembleeId;
  final Map<String, ChurchUnit> unitById;
  final Set<String> unitIds;
  final Set<String> legacyAssembleeIds;

  bool get hasActiveFilter =>
      (activeChurchUnitId != null && activeChurchUnitId!.isNotEmpty) ||
      (activeAssembleeId != null && activeAssembleeId!.isNotEmpty);

  bool contains({String? churchUnitId, String? legacyAssembleeId}) {
    if (!hasActiveFilter) return true;

    if (churchUnitId != null && unitIds.contains(churchUnitId)) {
      return true;
    }

    if (legacyAssembleeId != null &&
        legacyAssembleeIds.contains(legacyAssembleeId)) {
      return true;
    }

    final linkedUnit = churchUnitId == null ? null : unitById[churchUnitId];
    final linkedLegacyId = linkedUnit?.legacyAssembleeId;
    if (linkedLegacyId != null && legacyAssembleeIds.contains(linkedLegacyId)) {
      return true;
    }

    return false;
  }
}

import '../data/church_unit_model.dart';

List<ChurchUnit> accountingScopeUnits(List<ChurchUnit> units) {
  final result =
      units
          .where(
            (unit) =>
                unit.active &&
                (unit.isFinancialScope || unit.canHaveMembers || unit.isLocal),
          )
          .toList()
        ..sort((a, b) {
          final level = a.levelOrder.compareTo(b.levelOrder);
          if (level != 0) return level;
          return a.nom.compareTo(b.nom);
        });
  return result;
}

ChurchUnit? churchUnitForLegacyAssemblee(
  List<ChurchUnit> units,
  String? legacyAssembleeId,
) {
  if (legacyAssembleeId == null || legacyAssembleeId.isEmpty) return null;
  for (final unit in units) {
    if (unit.legacyAssembleeId == legacyAssembleeId) return unit;
  }
  return null;
}

String? churchUnitIdForLegacyAssemblee(
  List<ChurchUnit> units,
  String? legacyAssembleeId,
) {
  return churchUnitForLegacyAssemblee(units, legacyAssembleeId)?.id;
}

String? legacyAssembleeIdForChurchUnit(
  List<ChurchUnit> units,
  String? churchUnitId,
) {
  if (churchUnitId == null || churchUnitId.isEmpty) return null;
  for (final unit in units) {
    if (unit.id == churchUnitId) return unit.legacyAssembleeId;
  }
  return null;
}

String churchUnitLabel(ChurchUnit unit) {
  final code = unit.code == null || unit.code!.trim().isEmpty
      ? ''
      : ' - ${unit.code}';
  return '${unit.nom}$code';
}

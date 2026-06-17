import 'package:eab/core/utils/church_unit_scope.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchUnitScope', () {
    test('sans perimetre actif, ne filtre aucun enregistrement', () {
      final scope = ChurchUnitScope.fromActiveContext(
        units: _hierarchy,
        activeChurchUnitId: null,
        activeAssembleeId: null,
      );

      expect(scope.hasActiveFilter, isFalse);
      expect(scope.contains(churchUnitId: 'unknown'), isTrue);
      expect(scope.contains(legacyAssembleeId: 'legacy-unknown'), isTrue);
    });

    test('inclut une unite active et tous ses descendants', () {
      final scope = ChurchUnitScope.fromActiveContext(
        units: _hierarchy,
        activeChurchUnitId: 'district-1',
        activeAssembleeId: 'legacy-district-1',
      );

      expect(
        scope.unitIds,
        containsAll(['district-1', 'local-1', 'section-1']),
      );
      expect(scope.contains(churchUnitId: 'district-1'), isTrue);
      expect(scope.contains(churchUnitId: 'local-1'), isTrue);
      expect(scope.contains(churchUnitId: 'section-1'), isTrue);
      expect(scope.contains(churchUnitId: 'local-2'), isFalse);
    });

    test('conserve les anciennes donnees rattachees par assemblee legacy', () {
      final scope = ChurchUnitScope.fromActiveContext(
        units: _hierarchy,
        activeChurchUnitId: 'district-1',
        activeAssembleeId: 'legacy-district-1',
      );

      expect(scope.contains(legacyAssembleeId: 'legacy-local-1'), isTrue);
      expect(scope.contains(legacyAssembleeId: 'legacy-section-1'), isTrue);
      expect(scope.contains(legacyAssembleeId: 'legacy-local-2'), isFalse);
    });

    test('retrouve une ancienne assemblee depuis churchUnitId seul', () {
      final scope = ChurchUnitScope.fromActiveContext(
        units: _hierarchy,
        activeChurchUnitId: null,
        activeAssembleeId: 'legacy-local-1',
      );

      expect(scope.contains(churchUnitId: 'local-1'), isTrue);
      expect(scope.contains(churchUnitId: 'section-1'), isFalse);
      expect(scope.contains(churchUnitId: 'local-2'), isFalse);
    });

    test('exclut un rattachement inconnu quand un perimetre est actif', () {
      final scope = ChurchUnitScope.fromActiveContext(
        units: _hierarchy,
        activeChurchUnitId: 'local-1',
        activeAssembleeId: 'legacy-local-1',
      );

      expect(scope.contains(churchUnitId: 'missing'), isFalse);
      expect(scope.contains(legacyAssembleeId: 'missing'), isFalse);
      expect(scope.contains(), isFalse);
    });
  });
}

final _hierarchy = [
  _unit(
    id: 'national',
    nom: 'National',
    typeCode: 'organization',
    typeLabel: 'Organisation',
    levelOrder: 0,
  ),
  _unit(
    id: 'region-1',
    parentId: 'national',
    nom: 'Region 1',
    typeCode: 'region',
    typeLabel: 'Region',
    levelOrder: 1,
  ),
  _unit(
    id: 'district-1',
    parentId: 'region-1',
    nom: 'District 1',
    typeCode: 'district',
    typeLabel: 'District',
    levelOrder: 2,
    legacyAssembleeId: 'legacy-district-1',
  ),
  _unit(
    id: 'local-1',
    parentId: 'district-1',
    nom: 'Locale 1',
    typeCode: 'local_church',
    typeLabel: 'Assemblee locale',
    levelOrder: 3,
    legacyAssembleeId: 'legacy-local-1',
  ),
  _unit(
    id: 'section-1',
    parentId: 'local-1',
    nom: 'Section 1',
    typeCode: 'section',
    typeLabel: 'Section',
    levelOrder: 4,
    legacyAssembleeId: 'legacy-section-1',
  ),
  _unit(
    id: 'local-2',
    parentId: 'district-2',
    nom: 'Locale 2',
    typeCode: 'local_church',
    typeLabel: 'Assemblee locale',
    levelOrder: 3,
    legacyAssembleeId: 'legacy-local-2',
  ),
];

ChurchUnit _unit({
  required String id,
  required String nom,
  required String typeCode,
  required String typeLabel,
  required int levelOrder,
  String? parentId,
  String? legacyAssembleeId,
}) {
  return ChurchUnit(
    id: id,
    organizationId: 'org',
    typeId: 'type-$typeCode',
    nom: nom,
    typeCode: typeCode,
    typeLabel: typeLabel,
    levelOrder: levelOrder,
    isLocal: typeCode == 'local_church',
    isFinancialScope: true,
    canHaveMembers: true,
    canHaveCashAccounts: true,
    canHaveBankAccounts: true,
    canHaveMobileMoneyAccounts: true,
    canCreatePrograms: true,
    canLaunchContributions: true,
    canValidateFinances: true,
    canConsolidateFinances: true,
    canNotifyDescendants: true,
    canViewDescendants: true,
    active: true,
    parentId: parentId,
    legacyAssembleeId: legacyAssembleeId,
  );
}

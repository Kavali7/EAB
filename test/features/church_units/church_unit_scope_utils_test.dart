import 'package:eab/features/church_units/application/church_unit_scope_utils.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userScopeUnits', () {
    test('includes every active hierarchy level ordered by level and name', () {
      final units = [
        _unit(
          id: 'inactive',
          nom: 'Inactive',
          typeLabel: 'Region',
          levelOrder: 1,
          active: false,
        ),
        _unit(
          id: 'district-b',
          nom: 'B District',
          typeLabel: 'District',
          levelOrder: 2,
        ),
        _unit(
          id: 'region',
          nom: 'Atlantique',
          typeLabel: 'Region',
          levelOrder: 1,
        ),
        _unit(
          id: 'district-a',
          nom: 'A District',
          typeLabel: 'District',
          levelOrder: 2,
        ),
      ];

      expect(userScopeUnits(units).map((unit) => unit.id), [
        'region',
        'district-a',
        'district-b',
      ]);
    });
  });
}

ChurchUnit _unit({
  required String id,
  required String nom,
  required String typeLabel,
  required int levelOrder,
  bool active = true,
}) {
  return ChurchUnit(
    id: id,
    organizationId: 'org',
    typeId: 'type-$id',
    nom: nom,
    typeCode: typeLabel.toLowerCase(),
    typeLabel: typeLabel,
    levelOrder: levelOrder,
    isLocal: false,
    isFinancialScope: false,
    canHaveMembers: false,
    active: active,
  );
}

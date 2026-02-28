import 'package:eab/core/utils/case_converters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('snakeToCamel', () {
    test('convertit les clés simples', () {
      final result = snakeToCamel({
        'id': '123',
        'full_name': 'Jean Dupont',
        'id_region': 'r1',
      });
      expect(result, {
        'id': '123',
        'fullName': 'Jean Dupont',
        'idRegion': 'r1',
      });
    });

    test('convertit récursivement les Maps imbriqués', () {
      final result = snakeToCamel({
        'organization_id': 'org1',
        'nested_data': {
          'id_assemblee_locale': 'a1',
          'date_creation': '2026-01-01',
        },
      });
      expect(result['nestedData'], isA<Map>());
      expect(
        (result['nestedData'] as Map)['idAssembleeLocale'],
        'a1',
      );
    });

    test('convertit les listes de Maps', () {
      final result = snakeToCamel({
        'lignes_ecritures': [
          {'id_compte_comptable': 'c1', 'debit': 100},
          {'id_compte_comptable': 'c2', 'credit': 100},
        ],
      });
      final lignes = result['lignesEcritures'] as List;
      expect(lignes.length, 2);
      expect((lignes[0] as Map)['idCompteComptable'], 'c1');
    });

    test('ne modifie pas les clés déjà en camelCase', () {
      final result = snakeToCamel({'id': '123', 'nom': 'Test'});
      expect(result, {'id': '123', 'nom': 'Test'});
    });
  });

  group('camelToSnake', () {
    test('convertit les clés simples', () {
      final result = camelToSnake({
        'id': '123',
        'fullName': 'Jean Dupont',
        'idRegion': 'r1',
      });
      expect(result, {
        'id': '123',
        'full_name': 'Jean Dupont',
        'id_region': 'r1',
      });
    });

    test('convertit récursivement les Maps imbriqués', () {
      final result = camelToSnake({
        'organizationId': 'org1',
        'nestedData': {
          'idAssembleeLocale': 'a1',
        },
      });
      expect(result['nested_data'], isA<Map>());
      expect(
        (result['nested_data'] as Map)['id_assemblee_locale'],
        'a1',
      );
    });

    test('ne modifie pas les clés déjà en snake_case', () {
      final result = camelToSnake({'id': '123', 'nom': 'Test'});
      expect(result, {'id': '123', 'nom': 'Test'});
    });
  });

  group('snakeValueToCamel', () {
    test('convertit les valeurs enum multi-mots', () {
      expect(snakeValueToCamel('admin_national'), 'adminNational');
      expect(snakeValueToCamel('responsable_region'), 'responsableRegion');
      expect(
        snakeValueToCamel('evangelisation_masse'),
        'evangelisationMasse',
      );
      expect(
        snakeValueToCamel('tresorier_assemblee'),
        'tresorierAssemblee',
      );
    });

    test('ne modifie pas les valeurs sans underscore', () {
      expect(snakeValueToCamel('actif'), 'actif');
      expect(snakeValueToCamel('membre'), 'membre');
      expect(snakeValueToCamel('caisse'), 'caisse');
    });
  });

  group('mapStatutMatrimonialToEnglish', () {
    test('mappe celibataire → single', () {
      expect(mapStatutMatrimonialToEnglish('celibataire'), 'single');
    });

    test('mappe marie → married', () {
      expect(mapStatutMatrimonialToEnglish('marie'), 'married');
    });

    test('mappe divorce et separe → divorced', () {
      expect(mapStatutMatrimonialToEnglish('divorce'), 'divorced');
      expect(mapStatutMatrimonialToEnglish('separe'), 'divorced');
    });

    test('mappe veuf et veuve → widowed', () {
      expect(mapStatutMatrimonialToEnglish('veuf'), 'widowed');
      expect(mapStatutMatrimonialToEnglish('veuve'), 'widowed');
    });

    test('retourne single par défaut pour null ou valeur inconnue', () {
      expect(mapStatutMatrimonialToEnglish(null), 'single');
      expect(mapStatutMatrimonialToEnglish('inconnu'), 'single');
    });
  });
}

/// Tests unitaires pour les enums comptables.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:eab/models/compta_enums.dart';

void main() {
  group('StatutExercice', () {
    test('a 3 valeurs', () {
      expect(StatutExercice.values.length, 3);
    });

    test('contient brouillon, ouvert, cloture', () {
      expect(StatutExercice.values, containsAll([
        StatutExercice.brouillon,
        StatutExercice.ouvert,
        StatutExercice.cloture,
      ]));
    });

    test('name correspond aux valeurs DB', () {
      expect(StatutExercice.brouillon.name, 'brouillon');
      expect(StatutExercice.ouvert.name, 'ouvert');
      expect(StatutExercice.cloture.name, 'cloture');
    });
  });

  group('StatutEcriture', () {
    test('a 3 valeurs', () {
      expect(StatutEcriture.values.length, 3);
    });

    test('name correspond aux valeurs DB', () {
      expect(StatutEcriture.brouillon.name, 'brouillon');
      expect(StatutEcriture.validee.name, 'validee');
      expect(StatutEcriture.cloturee.name, 'cloturee');
    });
  });

  group('NatureCompte', () {
    test('a toutes les natures SYCEBNL', () {
      expect(NatureCompte.values, containsAll([
        NatureCompte.actif,
        NatureCompte.passif,
        NatureCompte.charge,
        NatureCompte.produit,
      ]));
    });
  });

  group('TypeJournalComptable', () {
    test('contient caisse, banque, OD', () {
      expect(TypeJournalComptable.values, containsAll([
        TypeJournalComptable.caisse,
        TypeJournalComptable.banque,
        TypeJournalComptable.operationsDiverses,
      ]));
    });
  });
}

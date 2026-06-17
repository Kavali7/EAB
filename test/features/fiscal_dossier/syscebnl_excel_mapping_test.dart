import 'package:flutter_test/flutter_test.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';

void main() {
  group('SyscebnlFiscalExcelMapper', () {
    test('separe les immobilisations brutes et les amortissements', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance([
        const SyscebnlBalanceLine(
          numero: '21',
          intitule: 'Terrains',
          nature: 'actif',
          totalDebit: 500000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '213',
          intitule: 'Batiments',
          nature: 'actif',
          totalDebit: 2000000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '2813',
          intitule: 'Amortissement batiments',
          nature: 'passif',
          totalDebit: 0,
          totalCredit: 300000,
        ),
        const SyscebnlBalanceLine(
          numero: '2183',
          intitule: 'Mobilier',
          nature: 'actif',
          totalDebit: 250000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '245',
          intitule: 'Vehicule',
          nature: 'actif',
          totalDebit: 900000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '26',
          intitule: 'Titres de participation',
          nature: 'actif',
          totalDebit: 150000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '27',
          intitule: 'Depot et cautionnement',
          nature: 'actif',
          totalDebit: 75000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '28183',
          intitule: 'Amortissement mobilier',
          nature: 'passif',
          totalDebit: 0,
          totalCredit: 50000,
        ),
      ]);

      expect(mapping.valueFor('ACTIF', 'D16'), 500000);
      expect(mapping.valueFor('ACTIF', 'D18'), 2000000);
      expect(mapping.valueFor('ACTIF', 'E18'), 300000);
      expect(mapping.valueFor('ACTIF', 'D21'), 250000);
      expect(mapping.valueFor('ACTIF', 'E21'), 50000);
      expect(mapping.valueFor('ACTIF', 'D22'), 900000);
      expect(mapping.valueFor('ACTIF', 'D25'), 150000);
      expect(mapping.valueFor('ACTIF', 'D26'), 75000);
    });

    test('separe creances actives et dettes passives de la classe 4', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance([
        const SyscebnlBalanceLine(
          numero: '409',
          intitule: 'Avances fournisseurs',
          nature: 'actif',
          totalDebit: 50000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '411',
          intitule: 'Membres / adherents',
          nature: 'actif',
          totalDebit: 120000,
          totalCredit: 20000,
        ),
        const SyscebnlBalanceLine(
          numero: '401',
          intitule: 'Fournisseurs',
          nature: 'passif',
          totalDebit: 10000,
          totalCredit: 90000,
        ),
        const SyscebnlBalanceLine(
          numero: '419',
          intitule: 'Avances recues',
          nature: 'passif',
          totalDebit: 0,
          totalCredit: 40000,
        ),
        const SyscebnlBalanceLine(
          numero: '431',
          intitule: 'Organismes sociaux',
          nature: 'passif',
          totalDebit: 0,
          totalCredit: 35000,
        ),
      ]);

      expect(mapping.valueFor('ACTIF', 'D31'), 50000);
      expect(mapping.valueFor('ACTIF', 'D32'), 100000);
      expect(mapping.valueFor('PASSIF', 'D30'), 80000);
      expect(mapping.valueFor('PASSIF', 'D29'), 40000);
      expect(mapping.valueFor('PASSIF', 'D31'), 35000);
    });

    test('alimente le resultat selon les produits et charges SYSCEBNL', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance([
        const SyscebnlBalanceLine(
          numero: '701',
          intitule: 'Dimes',
          nature: 'produit',
          totalDebit: 0,
          totalCredit: 400000,
        ),
        const SyscebnlBalanceLine(
          numero: '702',
          intitule: 'Offrandes de culte',
          nature: 'produit',
          totalDebit: 0,
          totalCredit: 250000,
        ),
        const SyscebnlBalanceLine(
          numero: '741',
          intitule: 'Subvention exploitation',
          nature: 'produit',
          totalDebit: 0,
          totalCredit: 50000,
        ),
        const SyscebnlBalanceLine(
          numero: '601',
          intitule: 'Fournitures liees',
          nature: 'charge',
          totalDebit: 70000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '605',
          intitule: 'Autres achats',
          nature: 'charge',
          totalDebit: 35000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '613',
          intitule: 'Loyers et locations',
          nature: 'charge',
          totalDebit: 80000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '624',
          intitule: 'Transports',
          nature: 'charge',
          totalDebit: 45000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '631',
          intitule: 'Impots et taxes',
          nature: 'charge',
          totalDebit: 15000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '645',
          intitule: 'Indemnites et aides',
          nature: 'charge',
          totalDebit: 30000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '6811',
          intitule: 'Dotations aux amortissements',
          nature: 'charge',
          totalDebit: 12000,
          totalCredit: 0,
        ),
        const SyscebnlBalanceLine(
          numero: '771',
          intitule: 'Revenus financiers',
          nature: 'produit',
          totalDebit: 0,
          totalCredit: 9000,
        ),
      ]);

      expect(mapping.valueFor('RESULTAT', 'E20'), 650000);
      expect(mapping.valueFor('RESULTAT', 'E19'), 50000);
      expect(mapping.valueFor('RESULTAT', 'E22'), 70000);
      expect(mapping.valueFor('RESULTAT', 'E24'), 35000);
      expect(mapping.valueFor('RESULTAT', 'E26'), 45000);
      expect(mapping.valueFor('RESULTAT', 'E27'), 80000);
      expect(mapping.valueFor('RESULTAT', 'E28'), 15000);
      expect(mapping.valueFor('RESULTAT', 'E29'), 30000);
      expect(mapping.valueFor('RESULTAT', 'E34'), 12000);
      expect(mapping.valueFor('RESULTAT', 'E36'), 9000);
      expect(mapping.formulaFor('PASSIF', 'D19'), '=RESULTAT!E50');
      expect(
        mapping.formulaFor('TFT', 'H14'),
        '=RESULTAT!E50+RESULTAT!E34-RESULTAT!E33-RESULTAT!E37',
      );
    });

    test('neutralise les anciennes cellules sources du modele', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance(const []);

      expect(mapping.valueFor('ACTIF', 'D22'), 0);
      expect(mapping.valueFor('ACTIF', 'G32'), 0);
      expect(mapping.valueFor('PASSIF', 'D18'), 0);
      expect(mapping.valueFor('PASSIF', 'E36'), 0);
      expect(mapping.valueFor('RESULTAT', 'E9'), 0);
      expect(mapping.valueFor('RESULTAT', 'E49'), 0);
      expect(mapping.valueFor('TFT', 'H17'), 0);
      expect(mapping.valueFor('TFT', 'I40'), 0);
    });
  });
}

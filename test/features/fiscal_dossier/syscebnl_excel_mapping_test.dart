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

    test('alimente les colonnes comparatives depuis la balance N-1', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance(
        const [
          SyscebnlBalanceLine(
            numero: '512',
            intitule: 'Banque',
            nature: 'actif',
            totalDebit: 150000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '411',
            intitule: 'Creances membres',
            nature: 'actif',
            totalDebit: 25000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 175000,
          ),
        ],
        previousLines: const [
          SyscebnlBalanceLine(
            numero: '512',
            intitule: 'Banque',
            nature: 'actif',
            totalDebit: 100000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '411',
            intitule: 'Creances membres',
            nature: 'actif',
            totalDebit: 10000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 110000,
          ),
        ],
      );

      expect(mapping.valueFor('ACTIF', 'D36'), 0);
      expect(mapping.valueFor('ACTIF', 'D37'), 150000);
      expect(mapping.valueFor('ACTIF', 'G32'), 10000);
      expect(mapping.valueFor('ACTIF', 'G36'), 0);
      expect(mapping.valueFor('ACTIF', 'G37'), 100000);
      expect(mapping.valueFor('RESULTAT', 'F20'), 110000);
      expect(mapping.valueFor('TFT', 'H11'), 100000);
      expect(mapping.valueFor('TFT', 'H17'), 15000);
      expect(mapping.formulaFor('PASSIF', 'E19'), '=RESULTAT!F50');
      expect(
        mapping.formulaFor('TFT', 'I14'),
        '=RESULTAT!F50+RESULTAT!F34-RESULTAT!F33-RESULTAT!F37',
      );
    });

    test('alimente les annexes fiscales prioritaires depuis les balances', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance(
        const [
          SyscebnlBalanceLine(
            numero: '201',
            intitule: 'Frais de developpement',
            nature: 'actif',
            totalDebit: 3000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '213',
            intitule: 'Batiments',
            nature: 'actif',
            totalDebit: 10000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '214',
            intitule: 'Amenagements',
            nature: 'actif',
            totalDebit: 400,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '2813',
            intitule: 'Amortissements batiments',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 1000,
          ),
          SyscebnlBalanceLine(
            numero: '26',
            intitule: 'Titres de participation',
            nature: 'actif',
            totalDebit: 150,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '27',
            intitule: 'Depot',
            nature: 'actif',
            totalDebit: 75,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '31',
            intitule: 'Stocks',
            nature: 'actif',
            totalDebit: 500,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '411',
            intitule: 'Creances membres',
            nature: 'actif',
            totalDebit: 1000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '421',
            intitule: 'Creances personnel',
            nature: 'actif',
            totalDebit: 50,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '431',
            intitule: 'Creances sociales',
            nature: 'actif',
            totalDebit: 20,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '441',
            intitule: 'Creances Etat',
            nature: 'actif',
            totalDebit: 60,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '451',
            intitule: 'Creances entites liees',
            nature: 'actif',
            totalDebit: 70,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '471',
            intitule: 'Autres debiteurs',
            nature: 'actif',
            totalDebit: 80,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '5121',
            intitule: 'Banque',
            nature: 'actif',
            totalDebit: 900,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '531',
            intitule: 'Caisse',
            nature: 'actif',
            totalDebit: 120,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '55',
            intitule: 'Mobile money',
            nature: 'actif',
            totalDebit: 60,
            totalCredit: 0,
          ),
        ],
        previousLines: const [
          SyscebnlBalanceLine(
            numero: '201',
            intitule: 'Frais de developpement',
            nature: 'actif',
            totalDebit: 2000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '213',
            intitule: 'Batiments',
            nature: 'actif',
            totalDebit: 8000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '214',
            intitule: 'Amenagements',
            nature: 'actif',
            totalDebit: 500,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '2813',
            intitule: 'Amortissements batiments',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 700,
          ),
          SyscebnlBalanceLine(
            numero: '26',
            intitule: 'Titres de participation',
            nature: 'actif',
            totalDebit: 100,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '31',
            intitule: 'Stocks',
            nature: 'actif',
            totalDebit: 300,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '411',
            intitule: 'Creances membres',
            nature: 'actif',
            totalDebit: 800,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '421',
            intitule: 'Creances personnel',
            nature: 'actif',
            totalDebit: 40,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '431',
            intitule: 'Creances sociales',
            nature: 'actif',
            totalDebit: 10,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '5121',
            intitule: 'Banque',
            nature: 'actif',
            totalDebit: 700,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '531',
            intitule: 'Caisse',
            nature: 'actif',
            totalDebit: 90,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '55',
            intitule: 'Mobile money',
            nature: 'actif',
            totalDebit: 30,
            totalCredit: 0,
          ),
        ],
      );

      expect(mapping.valueFor('NOTE 3A', 'B23'), 8000);
      expect(mapping.valueFor('NOTE 3A', 'C23'), 2000);
      expect(mapping.valueFor('NOTE 3A', 'F25'), 100);
      expect(mapping.valueFor('NOTE 3A', 'H23'), 10000);
      expect(mapping.formulaFor('NOTE 3A', 'H20'), '=SUM(H21:H27)');
      expect(mapping.valueFor('NOTE 3C', 'B22'), 700);
      expect(mapping.valueFor('NOTE 3C', 'C22'), 300);
      expect(mapping.formulaFor('NOTE 3C', 'E22'), '=B22+C22-D22');
      expect(mapping.valueFor('NOTE 4', 'B13'), 150);
      expect(mapping.valueFor('NOTE 4', 'C13'), 100);
      expect(mapping.valueFor('NOTE 4', 'B17'), 75);
      expect(mapping.valueFor('NOTE 6', 'B12'), 500);
      expect(mapping.valueFor('NOTE 6', 'C12'), 300);
      expect(mapping.valueFor('NOTE 7', 'B12'), 1000);
      expect(mapping.valueFor('NOTE 7', 'C12'), 800);
      expect(mapping.valueFor('NOTE 7', 'E12'), 1000);
      expect(mapping.valueFor('NOTE 8', 'B14'), 50);
      expect(mapping.valueFor('NOTE 8', 'C14'), 40);
      expect(mapping.valueFor('NOTE 8', 'E20'), 80);
      expect(mapping.valueFor('NOTE 11', 'C12'), 900);
      expect(mapping.valueFor('NOTE 11', 'D12'), 700);
      expect(mapping.valueFor('NOTE 11', 'C21'), 120);
      expect(mapping.valueFor('NOTE 11', 'C22'), 60);
    });

    test('alimente les notes de dettes et de resultat depuis SYSCEBNL', () {
      final mapping = SyscebnlFiscalExcelMapper.fromBalance(
        const [
          SyscebnlBalanceLine(
            numero: '160',
            intitule: 'Emprunt bancaire',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 5000,
          ),
          SyscebnlBalanceLine(
            numero: '190',
            intitule: 'Provision risques',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 400,
          ),
          SyscebnlBalanceLine(
            numero: '401',
            intitule: 'Fournisseur',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 900,
          ),
          SyscebnlBalanceLine(
            numero: '409',
            intitule: 'Avance fournisseur',
            nature: 'actif',
            totalDebit: 120,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '421',
            intitule: 'Personnel du',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 70,
          ),
          SyscebnlBalanceLine(
            numero: '431',
            intitule: 'Organismes sociaux',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 80,
          ),
          SyscebnlBalanceLine(
            numero: '441',
            intitule: 'Etat taxes',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 90,
          ),
          SyscebnlBalanceLine(
            numero: '451',
            intitule: 'Entites liees',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 100,
          ),
          SyscebnlBalanceLine(
            numero: '471',
            intitule: 'Crediteurs divers',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 110,
          ),
          SyscebnlBalanceLine(
            numero: '512',
            intitule: 'Banque decouvert',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 130,
          ),
          SyscebnlBalanceLine(
            numero: '531',
            intitule: 'Tresorerie passive',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 40,
          ),
          SyscebnlBalanceLine(
            numero: '721',
            intitule: 'Production immobilisee',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 30,
          ),
          SyscebnlBalanceLine(
            numero: '741',
            intitule: 'Subvention',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 200,
          ),
          SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 1000,
          ),
          SyscebnlBalanceLine(
            numero: '601',
            intitule: 'Fournitures',
            nature: 'charge',
            totalDebit: 300,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '605',
            intitule: 'Autres achats',
            nature: 'charge',
            totalDebit: 40,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '624',
            intitule: 'Transports',
            nature: 'charge',
            totalDebit: 50,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '613',
            intitule: 'Location',
            nature: 'charge',
            totalDebit: 60,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '615',
            intitule: 'Maintenance',
            nature: 'charge',
            totalDebit: 70,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '626',
            intitule: 'Telecom',
            nature: 'charge',
            totalDebit: 80,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '627',
            intitule: 'Frais bancaires',
            nature: 'charge',
            totalDebit: 90,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '611',
            intitule: 'Autres services',
            nature: 'charge',
            totalDebit: 20,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '631',
            intitule: 'Impots directs',
            nature: 'charge',
            totalDebit: 12,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '632',
            intitule: 'Impots indirects',
            nature: 'charge',
            totalDebit: 13,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '633',
            intitule: 'Enregistrement',
            nature: 'charge',
            totalDebit: 14,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '637',
            intitule: 'Penalites',
            nature: 'charge',
            totalDebit: 15,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '638',
            intitule: 'Autres taxes',
            nature: 'charge',
            totalDebit: 16,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '654',
            intitule: 'Pertes creances',
            nature: 'charge',
            totalDebit: 25,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '645',
            intitule: 'Aides',
            nature: 'charge',
            totalDebit: 35,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '646',
            intitule: 'Autres charges diverses',
            nature: 'charge',
            totalDebit: 10,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '661',
            intitule: 'Remunerations',
            nature: 'charge',
            totalDebit: 100,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '664',
            intitule: 'Charges sociales',
            nature: 'charge',
            totalDebit: 30,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '668',
            intitule: 'Autres charges sociales',
            nature: 'charge',
            totalDebit: 8,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '667',
            intitule: 'Personnel exterieur',
            nature: 'charge',
            totalDebit: 12,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '666',
            intitule: 'Autres charges personnel',
            nature: 'charge',
            totalDebit: 5,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '671',
            intitule: 'Interets emprunts',
            nature: 'charge',
            totalDebit: 9,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '672',
            intitule: 'Autres interets',
            nature: 'charge',
            totalDebit: 7,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '676',
            intitule: 'Pertes change',
            nature: 'charge',
            totalDebit: 6,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '691',
            intitule: 'Dotations financieres',
            nature: 'charge',
            totalDebit: 4,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '771',
            intitule: 'Interets recus',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 11,
          ),
          SyscebnlBalanceLine(
            numero: '772',
            intitule: 'Revenus placements',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 13,
          ),
          SyscebnlBalanceLine(
            numero: '797',
            intitule: 'Reprises financieres',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 14,
          ),
          SyscebnlBalanceLine(
            numero: '801',
            intitule: 'Charges HAO',
            nature: 'charge',
            totalDebit: 21,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '831',
            intitule: 'Produits HAO',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 23,
          ),
        ],
        previousLines: const [
          SyscebnlBalanceLine(
            numero: '160',
            intitule: 'Emprunt bancaire',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 3000,
          ),
          SyscebnlBalanceLine(
            numero: '401',
            intitule: 'Fournisseur',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 700,
          ),
          SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 800,
          ),
          SyscebnlBalanceLine(
            numero: '741',
            intitule: 'Subvention',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 150,
          ),
          SyscebnlBalanceLine(
            numero: '601',
            intitule: 'Fournitures',
            nature: 'charge',
            totalDebit: 250,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '613',
            intitule: 'Location',
            nature: 'charge',
            totalDebit: 45,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '661',
            intitule: 'Remunerations',
            nature: 'charge',
            totalDebit: 90,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '664',
            intitule: 'Charges sociales',
            nature: 'charge',
            totalDebit: 20,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '671',
            intitule: 'Interets emprunts',
            nature: 'charge',
            totalDebit: 5,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '771',
            intitule: 'Interets recus',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 4,
          ),
        ],
      );

      expect(mapping.valueFor('NOTE 16A', 'B8'), 5000);
      expect(mapping.valueFor('NOTE 16A', 'C8'), 3000);
      expect(mapping.valueFor('NOTE 16A', 'F8'), 5000);
      expect(mapping.valueFor('NOTE 16A', 'B38'), 400);
      expect(mapping.valueFor('NOTE 17', 'B10'), 900);
      expect(mapping.valueFor('NOTE 17', 'C10'), 700);
      expect(mapping.valueFor('NOTE 17', 'B17'), 120);
      expect(mapping.valueFor('NOTE 18', 'B12'), 70);
      expect(mapping.valueFor('NOTE 18', 'F12'), 70);
      expect(mapping.valueFor('NOTE 18', 'B14'), 80);
      expect(mapping.valueFor('NOTE 18', 'B20'), 90);
      expect(mapping.valueFor('NOTE 19', 'B12'), 100);
      expect(mapping.valueFor('NOTE 19', 'B17'), 110);
      expect(mapping.valueFor('NOTE 19', 'F17'), 110);
      expect(mapping.formulaFor('NOTE 19', 'B24'), '=SUM(B17:B23)');
      expect(mapping.valueFor('NOTE 20', 'B17'), 130);
      expect(mapping.valueFor('NOTE 20', 'B21'), 40);
      expect(mapping.valueFor('NOTE 21', 'B35'), 30);
      expect(mapping.valueFor('NOTE 21', 'B36'), 200);
      expect(mapping.valueFor('NOTE 21', 'B37'), 1000);
      expect(mapping.valueFor('NOTE 21', 'C37'), 800);
      expect(mapping.formulaFor('NOTE 21', 'B38'), '=SUM(B35:B37)');
      expect(mapping.valueFor('NOTE 22', 'B16'), 300);
      expect(mapping.valueFor('NOTE 22', 'C16'), 250);
      expect(mapping.valueFor('NOTE 22', 'B31'), 40);
      expect(mapping.valueFor('NOTE 23', 'B14'), 50);
      expect(mapping.valueFor('NOTE 24', 'B11'), 60);
      expect(mapping.valueFor('NOTE 24', 'C11'), 45);
      expect(mapping.valueFor('NOTE 24', 'B13'), 70);
      expect(mapping.valueFor('NOTE 24', 'B17'), 80);
      expect(mapping.valueFor('NOTE 24', 'B18'), 90);
      expect(mapping.valueFor('NOTE 24', 'B23'), 20);
      expect(mapping.valueFor('NOTE 25', 'B11'), 12);
      expect(mapping.valueFor('NOTE 25', 'B12'), 13);
      expect(mapping.valueFor('NOTE 25', 'B13'), 14);
      expect(mapping.valueFor('NOTE 25', 'B14'), 15);
      expect(mapping.valueFor('NOTE 25', 'B15'), 16);
      expect(mapping.valueFor('NOTE 26', 'B10'), 25);
      expect(mapping.valueFor('NOTE 26', 'B15'), 35);
      expect(mapping.valueFor('NOTE 26', 'B16'), 10);
      expect(mapping.valueFor('NOTE 27A', 'B11'), 100);
      expect(mapping.valueFor('NOTE 27A', 'C11'), 90);
      expect(mapping.valueFor('NOTE 27A', 'B13'), 38);
      expect(mapping.valueFor('NOTE 27A', 'B15'), 12);
      expect(mapping.valueFor('NOTE 27A', 'B16'), 5);
      expect(mapping.valueFor('NOTE 29', 'B10'), 9);
      expect(mapping.valueFor('NOTE 29', 'C10'), 5);
      expect(mapping.valueFor('NOTE 29', 'B13'), 7);
      expect(mapping.valueFor('NOTE 29', 'B15'), 6);
      expect(mapping.valueFor('NOTE 29', 'B19'), 4);
      expect(mapping.valueFor('NOTE 29', 'B22'), 11);
      expect(mapping.valueFor('NOTE 29', 'C22'), 4);
      expect(mapping.valueFor('NOTE 29', 'B25'), 13);
      expect(mapping.valueFor('NOTE 29', 'B30'), 14);
      expect(mapping.valueFor('NOTE 30', 'B10'), 21);
      expect(mapping.valueFor('NOTE 30', 'B20'), 23);
      expect(mapping.formulaFor('NOTE 31', 'B18'), "='NOTE 21'!B40");
      expect(mapping.formulaFor('NOTE 31', 'B22'), '=RESULTAT!E50');
      expect(
        mapping.formulaFor('NOTE 31', 'B29'),
        "='NOTE 27A'!B11+'NOTE 27A'!B12",
      );
    });
  });
}

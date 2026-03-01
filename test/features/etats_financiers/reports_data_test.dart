/// Tests unitaires pour les data classes des reports.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:eab/features/etats_financiers/data/reports_repository.dart';

void main() {
  group('LigneBalance', () {
    test('fromJson parses all fields', () {
      final json = {
        'compte_id': '123',
        'numero': '5121',
        'intitule': 'Caisse centrale',
        'nature': 'actif',
        'niveau': 3,
        'total_debit': 150000.50,
        'total_credit': 80000.0,
        'solde_debiteur': 70000.50,
        'solde_crediteur': 0,
      };

      final l = LigneBalance.fromJson(json);
      expect(l.numero, '5121');
      expect(l.intitule, 'Caisse centrale');
      expect(l.nature, 'actif');
      expect(l.niveau, 3);
      expect(l.totalDebit, closeTo(150000.50, 0.01));
      expect(l.totalCredit, closeTo(80000.0, 0.01));
      expect(l.soldeDebiteur, closeTo(70000.50, 0.01));
      expect(l.soldeCrediteur, closeTo(0, 0.01));
    });

    test('fromJson handles null amounts as 0', () {
      final json = {
        'compte_id': '123',
        'numero': '5121',
        'intitule': 'Test',
        'nature': 'actif',
        'niveau': null,
        'total_debit': null,
        'total_credit': null,
        'solde_debiteur': null,
        'solde_crediteur': null,
      };

      final l = LigneBalance.fromJson(json);
      expect(l.totalDebit, 0);
      expect(l.totalCredit, 0);
      expect(l.niveau, 1); // default
    });
  });

  group('LigneResultat', () {
    test('fromJson parses produits and charges', () {
      final produit = LigneResultat.fromJson({
        'section': 'produits',
        'numero': '7011',
        'intitule': 'Dons reçus',
        'montant': 500000,
      });
      expect(produit.section, 'produits');
      expect(produit.montant, 500000);

      final charge = LigneResultat.fromJson({
        'section': 'charges',
        'numero': '6011',
        'intitule': 'Loyer',
        'montant': 200000,
      });
      expect(charge.section, 'charges');
    });
  });

  group('LigneBilan', () {
    test('fromJson parses actif/passif with sous-sections', () {
      final actif = LigneBilan.fromJson({
        'section': 'actif',
        'sous_section': 'immobilisations',
        'numero': '2311',
        'intitule': 'Bâtiment église',
        'solde': 15000000,
      });
      expect(actif.section, 'actif');
      expect(actif.sousSection, 'immobilisations');
      expect(actif.solde, 15000000);
    });
  });

  group('LigneGrandLivre', () {
    test('fromJson parses with date', () {
      final l = LigneGrandLivre.fromJson({
        'compte_numero': '5121',
        'compte_intitule': 'Caisse',
        'ecriture_date': '2026-01-15',
        'ecriture_libelle': 'Offrande dimanche',
        'reference_piece': 'CAI-2026-000001',
        'journal_code': 'CAI',
        'ligne_libelle': 'Offrande',
        'debit': 50000,
        'credit': 0,
        'solde_cumule': 50000,
      });
      expect(l.compteNumero, '5121');
      expect(l.ecritureDate, DateTime(2026, 1, 15));
      expect(l.referencePiece, 'CAI-2026-000001');
      expect(l.debit, 50000);
      expect(l.soldeCumule, 50000);
    });
  });

  group('Balance verification', () {
    test('total débits == total crédits (loi comptable)', () {
      // Simule des lignes de balance
      final balance = [
        LigneBalance.fromJson({
          'compte_id': '1', 'numero': '5121', 'intitule': 'Caisse',
          'nature': 'actif', 'niveau': 3,
          'total_debit': 100000, 'total_credit': 30000,
          'solde_debiteur': 70000, 'solde_crediteur': 0,
        }),
        LigneBalance.fromJson({
          'compte_id': '2', 'numero': '7011', 'intitule': 'Dons',
          'nature': 'produit', 'niveau': 3,
          'total_debit': 0, 'total_credit': 70000,
          'solde_debiteur': 0, 'solde_crediteur': 70000,
        }),
      ];

      final totalD = balance.fold(0.0, (s, l) => s + l.totalDebit);
      final totalC = balance.fold(0.0, (s, l) => s + l.totalCredit);
      expect(totalD, closeTo(totalC, 0.01),
          reason: 'Total débits doit égaler total crédits');
    });
  });
}

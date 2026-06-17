import 'package:flutter_test/flutter_test.dart';

import 'package:eab/features/fiscal_dossier/services/fiscal_export_adjustments.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';

void main() {
  group('FiscalExportAdjustmentEngine', () {
    test('applique une ecriture debit credit equilibree avant mapping', () {
      final result = FiscalExportAdjustmentEngine.apply(
        balanceLines: const [
          SyscebnlBalanceLine(
            numero: '512',
            intitule: 'Banque',
            nature: 'actif',
            totalDebit: 1000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 1000,
          ),
        ],
        adjustments: [
          FiscalExportAdjustment.balancedEntry(
            id: 'adj_1',
            label: 'Correction facture',
            reason: 'Presentation fiscale uniquement',
            debitAccountNumber: '613',
            debitAccountLabel: 'Locations',
            creditAccountNumber: '401',
            creditAccountLabel: 'Fournisseurs',
            amount: 200,
          ),
        ],
      );

      final mapping = SyscebnlFiscalExcelMapper.fromBalance(result.lines);

      expect(result.adjustmentCount, 1);
      expect(result.totalDebit, 1200);
      expect(result.totalCredit, 1200);
      expect(mapping.valueFor('RESULTAT', 'E27'), 200);
      expect(mapping.valueFor('PASSIF', 'D30'), 200);
    });

    test('reclasse un montant debit sans casser l equilibre', () {
      final result = FiscalExportAdjustmentEngine.apply(
        balanceLines: const [
          SyscebnlBalanceLine(
            numero: '101',
            intitule: 'Fonds associatifs',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 1500,
          ),
          SyscebnlBalanceLine(
            numero: '213',
            intitule: 'Batiments',
            nature: 'actif',
            totalDebit: 1000,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '2183',
            intitule: 'Mobilier',
            nature: 'actif',
            totalDebit: 500,
            totalCredit: 0,
          ),
        ],
        adjustments: [
          FiscalExportAdjustment.debitReclassification(
            id: 'adj_2',
            label: 'Reclassement immobilisation',
            reason: 'Correction de presentation',
            sourceAccountNumber: '213',
            sourceAccountLabel: 'Batiments',
            targetAccountNumber: '2183',
            targetAccountLabel: 'Mobilier',
            amount: 200,
          ),
        ],
      );

      final mapping = SyscebnlFiscalExcelMapper.fromBalance(result.lines);

      expect(result.totalDebit, 1500);
      expect(result.totalCredit, 1500);
      expect(mapping.valueFor('ACTIF', 'D18'), 800);
      expect(mapping.valueFor('ACTIF', 'D21'), 700);
    });

    test('refuse un ajustement non equilibre', () {
      expect(
        () => FiscalExportAdjustmentEngine.apply(
          balanceLines: const [
            SyscebnlBalanceLine(
              numero: '512',
              intitule: 'Banque',
              nature: 'actif',
              totalDebit: 1000,
              totalCredit: 0,
            ),
            SyscebnlBalanceLine(
              numero: '701',
              intitule: 'Dimes',
              nature: 'produit',
              totalDebit: 0,
              totalCredit: 1000,
            ),
          ],
          adjustments: [
            FiscalExportAdjustment(
              id: 'adj_3',
              label: 'Erreur',
              reason: 'Debit seul',
              createdAt: DateTime.utc(2026),
              lines: const [
                FiscalExportAdjustmentLine(
                  accountNumber: '613',
                  accountLabel: 'Locations',
                  debitDelta: 100,
                ),
                FiscalExportAdjustmentLine(
                  accountNumber: '401',
                  accountLabel: 'Fournisseurs',
                  creditDelta: 90,
                ),
              ],
            ),
          ],
        ),
        throwsStateError,
      );
    });

    test('refuse un reclassement qui rend un compte negatif', () {
      expect(
        () => FiscalExportAdjustmentEngine.apply(
          balanceLines: const [
            SyscebnlBalanceLine(
              numero: '101',
              intitule: 'Fonds associatifs',
              nature: 'passif',
              totalDebit: 0,
              totalCredit: 500,
            ),
            SyscebnlBalanceLine(
              numero: '213',
              intitule: 'Batiments',
              nature: 'actif',
              totalDebit: 500,
              totalCredit: 0,
            ),
          ],
          adjustments: [
            FiscalExportAdjustment.debitReclassification(
              id: 'adj_4',
              label: 'Reclassement impossible',
              reason: 'Montant superieur au compte source',
              sourceAccountNumber: '213',
              sourceAccountLabel: 'Batiments',
              targetAccountNumber: '2183',
              targetAccountLabel: 'Mobilier',
              amount: 700,
            ),
          ],
        ),
        throwsStateError,
      );
    });
  });
}

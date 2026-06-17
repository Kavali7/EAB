import 'package:flutter_test/flutter_test.dart';

import 'package:eab/features/fiscal_dossier/services/fiscal_export_adjustments.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_preflight_service.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';

void main() {
  group('FiscalExportPreflightEngine', () {
    test('bloque un dossier sans perimetre fiscal', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: null,
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        balanceLines: const [],
        adjustments: const [],
        values: const {},
      );

      expect(report.canExport, isFalse);
      expect(report.blockingCount, greaterThanOrEqualTo(1));
      expect(
        report.issues.map((issue) => issue.code),
        contains('missing_scope'),
      );
    });

    test('bloque une balance non equilibree', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
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
            totalCredit: 900,
          ),
        ],
        adjustments: const [],
        values: const {},
      );

      expect(report.canExport, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains('adjustment_or_balance_error'),
      );
    });

    test('autorise une balance equilibree avec avertissement N-1', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
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
            id: 'adj-1',
            label: 'Correction',
            reason: 'Controle export',
            debitAccountNumber: '613',
            debitAccountLabel: 'Services',
            creditAccountNumber: '401',
            creditAccountLabel: 'Fournisseurs',
            amount: 100,
          ),
        ],
        values: const {},
      );

      expect(report.canExport, isTrue);
      expect(report.totalDebit, 1100);
      expect(report.totalCredit, 1100);
      expect(report.adjustmentCount, 1);
      expect(report.nonZeroInjectedCellCount, greaterThan(0));
      expect(
        report.issues.map((issue) => issue.code),
        contains('missing_previous_year'),
      );
      expect(
        report.issues.map((issue) => issue.code),
        contains('adjustments_present'),
      );
    });
  });
}

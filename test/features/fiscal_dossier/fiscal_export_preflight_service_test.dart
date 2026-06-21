import 'package:flutter_test/flutter_test.dart';

import 'package:eab/features/etats_financiers/data/reports_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_balance_loader.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_adjustments.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_preflight_service.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';
import 'package:eab/features/organization/data/organization_model.dart';

void main() {
  group('FiscalExportPreflightEngine', () {
    test('bloque un dossier sans perimetre fiscal', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: null,
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        previousDateDebut: DateTime.utc(2025),
        previousDateFin: DateTime.utc(2025, 12, 31),
        balanceLines: const [],
        previousBalanceLines: const [],
        adjustments: const [],
      );

      expect(report.canExport, isFalse);
      expect(report.blockingCount, greaterThanOrEqualTo(1));
      expect(
        report.issues.map((issue) => issue.code),
        contains('missing_scope'),
      );
    });

    test('bloque une identite fiscale essentielle incomplete', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        previousDateDebut: DateTime.utc(2025),
        previousDateFin: DateTime.utc(2025, 12, 31),
        balanceLines: _balancedLines,
        previousBalanceLines: const [],
        adjustments: const [],
        fiscalIdentityIssues:
            FiscalExportPreflightEngine.buildFiscalIdentityIssues(
              const Organization(id: 'org-1', nom: 'Eglise Test'),
            ),
      );

      expect(report.canExport, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains('incomplete_fiscal_identity'),
      );
    });

    test(
      'valide le controle identite fiscale quand les champs sont complets',
      () {
        final issues = FiscalExportPreflightEngine.buildFiscalIdentityIssues(
          const Organization(
            id: 'org-1',
            nom: 'Eglise Test',
            parametres: {
              OrganizationFiscalProfile.paramKey: {
                'ifu': '1202600000001',
                'registration_number': 'ASS-2026-001',
                'tax_center': 'Centre des impots',
                'deposit_center': 'Centre de depot',
                'head_office_address': '01 BP 100 Cotonou',
                'activity_description': 'Activites cultuelles',
                'legal_representative_name': 'Responsable Test',
                'legal_representative_title': 'President',
                'legal_representative_phone': '+229 01 00 00 00 00',
                'accountant_name': 'Comptable Test',
                'accountant_title': 'Comptable responsable',
                'accountant_email': 'comptable@test.local',
                'bank_name': 'Banque Test',
                'bank_account_label': 'Compte principal',
                'bank_account_number': 'BJ66TEST000000000001',
              },
            },
          ),
        );

        expect(
          issues.where(
            (issue) => issue.severity == FiscalPreflightSeverity.blocking,
          ),
          isEmpty,
        );
        expect(
          issues.map((issue) => issue.code),
          contains('fiscal_identity_ready'),
        );
      },
    );

    test('bloque une balance non equilibree', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        previousDateDebut: DateTime.utc(2025),
        previousDateFin: DateTime.utc(2025, 12, 31),
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
        previousBalanceLines: const [],
        adjustments: const [],
      );

      expect(report.canExport, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains('adjustment_or_balance_error'),
      );
    });

    test('bloque une periode dont la date de debut depasse la date de fin', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026, 12, 31),
        dateFin: DateTime.utc(2026),
        previousDateDebut: DateTime.utc(2025, 12, 31),
        previousDateFin: DateTime.utc(2025),
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
        previousBalanceLines: const [],
        adjustments: const [],
      );

      expect(report.canExport, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains('invalid_period'),
      );
    });

    test('autorise une balance equilibree avec avertissement N-1', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        previousDateDebut: DateTime.utc(2025),
        previousDateFin: DateTime.utc(2025, 12, 31),
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
        previousBalanceLines: const [],
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
      expect(
        report.issues.map((issue) => issue.code),
        contains('fiscal_excel_mapping_coverage'),
      );
    });

    test('signale un comparatif N-1 charge quand la balance existe', () {
      final report = FiscalExportPreflightEngine.build(
        churchUnitId: 'unit-1',
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        previousDateDebut: DateTime.utc(2025),
        previousDateFin: DateTime.utc(2025, 12, 31),
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
        previousBalanceLines: const [
          SyscebnlBalanceLine(
            numero: '512',
            intitule: 'Banque',
            nature: 'actif',
            totalDebit: 800,
            totalCredit: 0,
          ),
          SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 800,
          ),
        ],
        adjustments: const [],
      );

      expect(report.canExport, isTrue);
      expect(report.previousBalanceLineCount, 2);
      expect(
        report.issues.map((issue) => issue.code),
        contains('previous_year_loaded'),
      );
      expect(
        report.issues.map((issue) => issue.code),
        isNot(contains('missing_previous_year')),
      );
    });
  });

  group('FiscalExportBalanceLoader', () {
    test('utilise la balance importee rattachee au dossier courant', () async {
      final loader = FiscalExportBalanceLoader(
        fetchBalanceGenerale:
            (orgId, {churchUnitId, dateDebut, dateFin}) async {
              if (dateDebut?.year == 2025) {
                return const [
                  LigneBalance(
                    compteId: 'prev-512',
                    numero: '512',
                    intitule: 'Banque N-1',
                    nature: 'actif',
                    niveau: 1,
                    totalDebit: 800,
                    totalCredit: 0,
                    soldeDebiteur: 800,
                    soldeCrediteur: 0,
                  ),
                  LigneBalance(
                    compteId: 'prev-701',
                    numero: '701',
                    intitule: 'Dimes N-1',
                    nature: 'produit',
                    niveau: 1,
                    totalDebit: 0,
                    totalCredit: 800,
                    soldeDebiteur: 0,
                    soldeCrediteur: 800,
                  ),
                ];
              }
              return const [];
            },
        fetchImportLines: (importId) async => const [
          ImportedTrialBalanceLine(
            id: 'line-512',
            importId: 'import-1',
            accountNumber: '512',
            accountLabel: 'Banque',
            debit: 1000,
            credit: 0,
          ),
          ImportedTrialBalanceLine(
            id: 'line-701',
            importId: 'import-1',
            accountNumber: '701',
            accountLabel: 'Dimes',
            debit: 0,
            credit: 1000,
          ),
        ],
      );

      final data = await loader.load(
        dossier: _dossier(importId: 'import-1'),
        dateDebut: DateTime.utc(2026),
        dateFin: DateTime.utc(2026, 12, 31),
        previousDateDebut: DateTime.utc(2025),
        previousDateFin: DateTime.utc(2025, 12, 31),
      );

      expect(data.usedImportedCurrentBalance, isTrue);
      expect(data.currentLines, hasLength(2));
      expect(data.currentLines.first.numero, '512');
      expect(data.currentLines.first.nature, 'actif');
      expect(data.previousLines, hasLength(2));
    });

    test(
      'garde la balance comptable quand aucun import nest rattache',
      () async {
        final loader = FiscalExportBalanceLoader(
          fetchBalanceGenerale:
              (orgId, {churchUnitId, dateDebut, dateFin}) async {
                return const [
                  LigneBalance(
                    compteId: '512',
                    numero: '512',
                    intitule: 'Banque',
                    nature: 'actif',
                    niveau: 1,
                    totalDebit: 1000,
                    totalCredit: 0,
                    soldeDebiteur: 1000,
                    soldeCrediteur: 0,
                  ),
                  LigneBalance(
                    compteId: '701',
                    numero: '701',
                    intitule: 'Dimes',
                    nature: 'produit',
                    niveau: 1,
                    totalDebit: 0,
                    totalCredit: 1000,
                    soldeDebiteur: 0,
                    soldeCrediteur: 1000,
                  ),
                ];
              },
          fetchImportLines: (_) async => const [],
        );

        final data = await loader.load(
          dossier: _dossier(),
          dateDebut: DateTime.utc(2026),
          dateFin: DateTime.utc(2026, 12, 31),
          previousDateDebut: DateTime.utc(2025),
          previousDateFin: DateTime.utc(2025, 12, 31),
        );

        expect(data.usedImportedCurrentBalance, isFalse);
        expect(data.currentLines, hasLength(2));
        expect(data.currentLines.last.numero, '701');
      },
    );
  });
}

FiscalDossier _dossier({String? importId}) {
  return FiscalDossier(
    id: 'dossier-1',
    organizationId: 'org-1',
    churchUnitId: 'unit-1',
    templateId: 'template-1',
    importId: importId,
    status: FiscalDossierStatus.inProgress,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

const _balancedLines = [
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
];

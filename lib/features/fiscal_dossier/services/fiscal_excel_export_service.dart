import 'package:flutter/services.dart';

import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/etats_financiers/data/reports_repository.dart';
import 'package:eab/features/fiscal_dossier/data/fiscal_dossier_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/organization/data/organization_model.dart';

import 'fiscal_export_balance_loader.dart';
import 'fiscal_export_adjustments.dart';
import 'fiscal_excel_template_writer.dart';
import 'fiscal_excel_sanitization.dart';
import 'fiscal_organization_identity.dart';
import 'syscebnl_excel_mapping.dart';

class FiscalExcelExport {
  const FiscalExcelExport({
    required this.bytes,
    required this.filename,
    required this.audit,
  });

  final Uint8List bytes;
  final String filename;
  final FiscalExcelExportAudit audit;
}

class FiscalExcelExportAudit {
  const FiscalExcelExportAudit({
    required this.organizationId,
    required this.churchUnitId,
    required this.dateDebut,
    required this.dateFin,
    required this.previousDateDebut,
    required this.previousDateFin,
    required this.balanceLineCount,
    required this.previousBalanceLineCount,
    required this.adjustmentCount,
    required this.adjustmentLineCount,
    required this.totalDebit,
    required this.totalCredit,
    required this.injectedCellCount,
    required this.usedImportedCurrentBalance,
  });

  final String organizationId;
  final String churchUnitId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime previousDateDebut;
  final DateTime previousDateFin;
  final int balanceLineCount;
  final int previousBalanceLineCount;
  final int adjustmentCount;
  final int adjustmentLineCount;
  final double totalDebit;
  final double totalCredit;
  final int injectedCellCount;
  final bool usedImportedCurrentBalance;
}

class FiscalExcelExportService {
  FiscalExcelExportService(
    ReportsRepository reportsRepository,
    FiscalDossierRepository fiscalRepository,
  ) : _balanceLoader = FiscalExportBalanceLoader.fromRepositories(
        reportsRepository,
        fiscalRepository,
      );

  static const templateAssetPath =
      'assets/templates/fiscal_syscebnl_template.xlsx';

  final FiscalExportBalanceLoader _balanceLoader;

  Future<FiscalExcelExport> buildDossierExport({
    required FiscalDossier dossier,
    required Organization organization,
    required Map<String, dynamic> values,
    ChurchUnit? churchUnit,
  }) async {
    final churchUnitId = dossier.churchUnitId;
    if (churchUnitId == null || churchUnitId.trim().isEmpty) {
      throw StateError(
        'Export Excel refuse : le dossier fiscal doit etre rattache a un '
        'perimetre d eglise explicite.',
      );
    }

    final dateFin =
        _dateValue(values['exercice.date_fin']) ??
        _fallbackDateFin(dossier, values);
    final dateDebut =
        _dateValue(values['exercice.date_debut']) ??
        DateTime(dateFin.year, 1, 1);
    if (dateDebut.isAfter(dateFin)) {
      throw StateError(
        'Export Excel refuse : la date de debut est posterieure a la date de fin.',
      );
    }

    final previousPeriod = _previousPeriod(dateDebut, dateFin);
    final balanceData = await _balanceLoader.load(
      dossier: dossier,
      dateDebut: dateDebut,
      dateFin: dateFin,
      previousDateDebut: previousPeriod.start,
      previousDateFin: previousPeriod.end,
    );

    final adjustments = FiscalExportAdjustmentCodec.decode(
      values[FiscalExportAdjustmentCodec.fieldKey],
    );
    final adjustedBalance = FiscalExportAdjustmentEngine.apply(
      balanceLines: balanceData.currentLines,
      adjustments: adjustments,
    );
    final previousAdjustedBalance = balanceData.previousLines.isEmpty
        ? null
        : FiscalExportAdjustmentEngine.apply(
            balanceLines: balanceData.previousLines,
            adjustments: const [],
          );
    final mapping = SyscebnlFiscalExcelMapper.fromBalance(
      adjustedBalance.lines,
      previousLines: previousAdjustedBalance?.lines ?? const [],
    );
    final identity = FiscalOrganizationIdentity.from(
      organization: organization,
      values: values,
      periodStart: dateDebut,
      periodEnd: dateFin,
      previousPeriodEnd: previousPeriod.end,
      churchUnit: churchUnit,
    );
    final templateBytes = await rootBundle.load(templateAssetPath);
    final bytes = FiscalExcelTemplateWriter.write(
      templateBytes: templateBytes.buffer.asUint8List(),
      mapping: mapping,
      definedNames: identity.definedNames(),
      textReplacements: {
        ...syscebnlFiscalExcelTextReplacements,
        ...identity.textReplacements(),
      },
      forbiddenTextPatterns: syscebnlFiscalExcelForbiddenPatterns,
      neutralizeNumericSheetPatterns:
          syscebnlFiscalExcelNeutralizedSheetPatterns,
    );

    return FiscalExcelExport(
      bytes: bytes,
      filename: _filename(organization, churchUnit, dateFin),
      audit: FiscalExcelExportAudit(
        organizationId: dossier.organizationId,
        churchUnitId: churchUnitId,
        dateDebut: dateDebut,
        dateFin: dateFin,
        previousDateDebut: previousPeriod.start,
        previousDateFin: previousPeriod.end,
        balanceLineCount: balanceData.currentLines.length,
        previousBalanceLineCount: balanceData.previousLines.length,
        adjustmentCount: adjustedBalance.adjustmentCount,
        adjustmentLineCount: adjustedBalance.adjustmentLineCount,
        totalDebit: adjustedBalance.totalDebit,
        totalCredit: adjustedBalance.totalCredit,
        injectedCellCount: mapping.values.length + mapping.formulas.length,
        usedImportedCurrentBalance: balanceData.usedImportedCurrentBalance,
      ),
    );
  }

  static DateTime? _dateValue(dynamic value) {
    final raw = _stringValue(value);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static DateTime _fallbackDateFin(
    FiscalDossier dossier,
    Map<String, dynamic> values,
  ) {
    final raw = [
      _stringValue(values['exercice.label']),
      dossier.label,
    ].whereType<String>().join(' ');
    final match = RegExp(r'(20\d{2})').firstMatch(raw);
    final year = match == null
        ? DateTime.now().year
        : int.parse(match.group(1)!);
    return DateTime(year, 12, 31);
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static _FiscalPeriod _previousPeriod(DateTime start, DateTime end) {
    return _FiscalPeriod(_shiftOneYearBack(start), _shiftOneYearBack(end));
  }

  static DateTime _shiftOneYearBack(DateTime date) {
    final targetYear = date.year - 1;
    final day = date.day
        .clamp(1, _lastDayOfMonth(targetYear, date.month))
        .toInt();
    return DateTime(targetYear, date.month, day);
  }

  static int _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static String _filename(
    Organization organization,
    ChurchUnit? churchUnit,
    DateTime dateFin,
  ) {
    final sigle =
        (organization.sigle?.trim().isNotEmpty == true
                ? organization.sigle
                : organization.nom)
            ?.trim();
    final unit = churchUnit == null ? 'perimetre' : churchUnit.nom;
    final base = [
      'dossier_fiscal_syscebnl',
      sigle,
      unit,
      dateFin.year.toString(),
    ].whereType<String>().join('_');
    return '${_slug(base)}.xlsx';
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class _FiscalPeriod {
  const _FiscalPeriod(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

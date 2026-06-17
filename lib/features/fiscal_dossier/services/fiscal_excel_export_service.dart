import 'package:flutter/services.dart';

import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/etats_financiers/data/reports_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/organization/data/organization_model.dart';

import 'fiscal_excel_template_writer.dart';
import 'fiscal_excel_sanitization.dart';
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
    required this.balanceLineCount,
    required this.injectedCellCount,
  });

  final String organizationId;
  final String churchUnitId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int balanceLineCount;
  final int injectedCellCount;
}

class FiscalExcelExportService {
  const FiscalExcelExportService(this._reportsRepository);

  static const templateAssetPath =
      'assets/templates/fiscal_syscebnl_template.xlsx';

  final ReportsRepository _reportsRepository;

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

    final balance = await _reportsRepository.fetchBalanceGenerale(
      dossier.organizationId,
      churchUnitId: churchUnitId,
      dateDebut: dateDebut,
      dateFin: dateFin,
    );

    final mapping = SyscebnlFiscalExcelMapper.fromBalance(
      balance.map(_toSyscebnlLine).toList(growable: false),
    );
    final templateBytes = await rootBundle.load(templateAssetPath);
    final bytes = FiscalExcelTemplateWriter.write(
      templateBytes: templateBytes.buffer.asUint8List(),
      mapping: mapping,
      definedNames: _definedNames(
        organization,
        values,
        dateDebut,
        dateFin,
        churchUnit,
      ),
      textReplacements: syscebnlFiscalExcelTextReplacements,
      forbiddenTextPatterns: syscebnlFiscalExcelForbiddenPatterns,
    );

    return FiscalExcelExport(
      bytes: bytes,
      filename: _filename(organization, churchUnit, dateFin),
      audit: FiscalExcelExportAudit(
        organizationId: dossier.organizationId,
        churchUnitId: churchUnitId,
        dateDebut: dateDebut,
        dateFin: dateFin,
        balanceLineCount: balance.length,
        injectedCellCount: mapping.values.length + mapping.formulas.length,
      ),
    );
  }

  static SyscebnlBalanceLine _toSyscebnlLine(LigneBalance line) {
    final nature = line.nature.trim().toLowerCase();
    return SyscebnlBalanceLine(
      numero: line.numero,
      intitule: line.intitule,
      nature: nature.isNotEmpty ? nature : _natureFromBalance(line),
      totalDebit: line.totalDebit,
      totalCredit: line.totalCredit,
    );
  }

  static String _natureFromBalance(LigneBalance line) {
    if (line.soldeDebiteur > line.soldeCrediteur) return 'actif';
    if (line.soldeCrediteur > line.soldeDebiteur) return 'passif';
    return '';
  }

  static Map<String, String> _definedNames(
    Organization organization,
    Map<String, dynamic> values,
    DateTime dateDebut,
    DateTime dateFin,
    ChurchUnit? churchUnit,
  ) {
    final orgName = _stringValue(values['org.name']) ?? organization.nom;
    final orgSigle = _stringValue(values['org.sigle']) ?? organization.sigle;
    final orgNif = _stringValue(values['org.nif']) ?? '';
    final orgAddress =
        _stringValue(values['org.address']) ?? organization.adresse ?? '';
    final currency = _stringValue(values['currency']) ?? organization.devise;
    final exerciceLabel =
        _stringValue(values['exercice.label']) ?? 'Exercice ${dateFin.year}';

    return {
      '_soNom': orgName,
      '_soId': orgNif,
      '_soSigle': orgSigle ?? '',
      '_soAdresse': orgAddress,
      '_Perimetre': churchUnit == null
          ? 'Perimetre non renseigne'
          : '${churchUnit.typeLabel} - ${churchUnit.nom}',
      '_Devise': currency,
      '_ExerClos': '$exerciceLabel clos le ${_formatDate(dateFin)}',
      '_ExerDeb': _formatDate(dateDebut),
      '_ExerFin': _formatDate(dateFin),
      '_ExerFin1': _formatDate(DateTime(dateFin.year - 1, 12, 31)),
      '_Duree': 'Duree (en mois) ${_monthDuration(dateDebut, dateFin)}',
    };
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

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static int _monthDuration(DateTime start, DateTime end) {
    final months = (end.year - start.year) * 12 + end.month - start.month + 1;
    return months < 1 ? 1 : months;
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

import 'package:eab/features/etats_financiers/data/reports_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';

import 'fiscal_export_adjustments.dart';
import 'syscebnl_excel_mapping.dart';

enum FiscalPreflightSeverity { blocking, warning, info }

class FiscalExportPreflightIssue {
  const FiscalExportPreflightIssue({
    required this.code,
    required this.severity,
    required this.title,
    required this.detail,
  });

  final String code;
  final FiscalPreflightSeverity severity;
  final String title;
  final String detail;
}

class FiscalExportPreflightReport {
  const FiscalExportPreflightReport({
    required this.dateDebut,
    required this.dateFin,
    required this.balanceLineCount,
    required this.adjustmentCount,
    required this.adjustmentLineCount,
    required this.totalDebit,
    required this.totalCredit,
    required this.injectedCellCount,
    required this.neutralizedCellCount,
    required this.nonZeroInjectedCellCount,
    required this.issues,
  });

  final DateTime dateDebut;
  final DateTime dateFin;
  final int balanceLineCount;
  final int adjustmentCount;
  final int adjustmentLineCount;
  final double totalDebit;
  final double totalCredit;
  final int injectedCellCount;
  final int neutralizedCellCount;
  final int nonZeroInjectedCellCount;
  final List<FiscalExportPreflightIssue> issues;

  bool get canExport => !issues.any(
    (issue) => issue.severity == FiscalPreflightSeverity.blocking,
  );

  int get blockingCount => _count(FiscalPreflightSeverity.blocking);
  int get warningCount => _count(FiscalPreflightSeverity.warning);
  int get infoCount => _count(FiscalPreflightSeverity.info);

  int _count(FiscalPreflightSeverity severity) {
    return issues.where((issue) => issue.severity == severity).length;
  }
}

class FiscalExportPreflightEngine {
  const FiscalExportPreflightEngine._();

  static FiscalExportPreflightReport build({
    required String? churchUnitId,
    required DateTime dateDebut,
    required DateTime dateFin,
    required List<SyscebnlBalanceLine> balanceLines,
    required List<FiscalExportAdjustment> adjustments,
    required Map<String, dynamic> values,
  }) {
    final issues = <FiscalExportPreflightIssue>[];

    if (churchUnitId == null || churchUnitId.trim().isEmpty) {
      issues.add(
        const FiscalExportPreflightIssue(
          code: 'missing_scope',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Perimetre fiscal absent',
          detail:
              'Le dossier doit etre rattache a une unite d eglise explicite avant export.',
        ),
      );
    }

    if (dateDebut.isAfter(dateFin)) {
      issues.add(
        const FiscalExportPreflightIssue(
          code: 'invalid_period',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Periode incoherente',
          detail:
              'La date de debut de l exercice ne peut pas etre posterieure a la date de fin.',
        ),
      );
    }

    if (balanceLines.isEmpty) {
      issues.add(
        const FiscalExportPreflightIssue(
          code: 'empty_balance',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Balance vide',
          detail:
              'Aucune ligne de balance n est disponible pour le perimetre et la periode.',
        ),
      );
    }

    FiscalExportAdjustmentResult? adjustedBalance;
    try {
      adjustedBalance = FiscalExportAdjustmentEngine.apply(
        balanceLines: balanceLines,
        adjustments: adjustments,
      );
    } catch (error) {
      issues.add(
        FiscalExportPreflightIssue(
          code: 'adjustment_or_balance_error',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Equilibre comptable refuse',
          detail: error.toString(),
        ),
      );
    }

    final lines = adjustedBalance?.lines ?? balanceLines;
    final mapping = SyscebnlFiscalExcelMapper.fromBalance(lines);
    final neutralizedCells = mapping.values
        .where((value) => value.fieldKey.endsWith('.zero'))
        .length;
    final injectedCells = mapping.values.length + mapping.formulas.length;
    final nonZeroInjectedCells = mapping.values
        .where(
          (value) => !value.fieldKey.endsWith('.zero') && value.value.abs() > 0,
        )
        .length;

    if (balanceLines.isNotEmpty && nonZeroInjectedCells == 0) {
      issues.add(
        const FiscalExportPreflightIssue(
          code: 'no_mapped_amount',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Aucune cellule fiscale alimentee',
          detail:
              'La balance contient des lignes, mais aucune cellule SYSCEBNL principale ne recoit de montant.',
        ),
      );
    }

    if (!_hasPreviousYear(values)) {
      issues.add(
        const FiscalExportPreflightIssue(
          code: 'missing_previous_year',
          severity: FiscalPreflightSeverity.warning,
          title: 'Comparatif N-1 absent',
          detail:
              'Les colonnes comparatives N-1 sont neutralisees a zero tant que les donnees N-1 ne sont pas branchees.',
        ),
      );
    }

    if (adjustments.isNotEmpty) {
      issues.add(
        FiscalExportPreflightIssue(
          code: 'adjustments_present',
          severity: FiscalPreflightSeverity.info,
          title: 'Ajustements export appliques',
          detail:
              '${adjustments.length} ajustement(s) seront appliques uniquement au fichier genere.',
        ),
      );
    }

    if (neutralizedCells > 0) {
      issues.add(
        FiscalExportPreflightIssue(
          code: 'template_cells_neutralized',
          severity: FiscalPreflightSeverity.info,
          title: 'Valeurs du modele neutralisees',
          detail:
              '$neutralizedCells cellule(s) source du modele sont forcees a zero pour eviter les anciens chiffres d exemple.',
        ),
      );
    }

    return FiscalExportPreflightReport(
      dateDebut: dateDebut,
      dateFin: dateFin,
      balanceLineCount: balanceLines.length,
      adjustmentCount: adjustedBalance?.adjustmentCount ?? adjustments.length,
      adjustmentLineCount: adjustedBalance?.adjustmentLineCount ?? 0,
      totalDebit: adjustedBalance?.totalDebit ?? _totalDebit(balanceLines),
      totalCredit: adjustedBalance?.totalCredit ?? _totalCredit(balanceLines),
      injectedCellCount: injectedCells,
      neutralizedCellCount: neutralizedCells,
      nonZeroInjectedCellCount: nonZeroInjectedCells,
      issues: issues,
    );
  }

  static bool _hasPreviousYear(Map<String, dynamic> values) {
    final explicit = values['export.previous_year_available'];
    if (explicit == true || explicit == 'true') return true;
    return values.keys.any(
      (key) =>
          key.startsWith('n1.') ||
          key.startsWith('previous.') ||
          key == 'exercice.date_fin_n1',
    );
  }

  static double _totalDebit(List<SyscebnlBalanceLine> lines) {
    return _round(lines.fold<double>(0, (sum, line) => sum + line.totalDebit));
  }

  static double _totalCredit(List<SyscebnlBalanceLine> lines) {
    return _round(lines.fold<double>(0, (sum, line) => sum + line.totalCredit));
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}

class FiscalExportPreflightService {
  const FiscalExportPreflightService(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  Future<FiscalExportPreflightReport> buildReport({
    required FiscalDossier dossier,
    required Map<String, dynamic> values,
  }) async {
    final dateFin =
        _dateValue(values['exercice.date_fin']) ??
        _fallbackDateFin(dossier, values);
    final dateDebut =
        _dateValue(values['exercice.date_debut']) ??
        DateTime(dateFin.year, 1, 1);
    final churchUnitId = dossier.churchUnitId;
    final balance = churchUnitId == null || churchUnitId.trim().isEmpty
        ? const <LigneBalance>[]
        : await _reportsRepository.fetchBalanceGenerale(
            dossier.organizationId,
            churchUnitId: churchUnitId,
            dateDebut: dateDebut,
            dateFin: dateFin,
          );

    return FiscalExportPreflightEngine.build(
      churchUnitId: churchUnitId,
      dateDebut: dateDebut,
      dateFin: dateFin,
      balanceLines: balance.map(_toSyscebnlLine).toList(growable: false),
      adjustments: FiscalExportAdjustmentCodec.decode(
        values[FiscalExportAdjustmentCodec.fieldKey],
      ),
      values: values,
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
}

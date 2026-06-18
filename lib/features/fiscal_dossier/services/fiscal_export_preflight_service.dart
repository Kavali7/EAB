import 'package:eab/features/etats_financiers/data/reports_repository.dart';
import 'package:eab/features/fiscal_dossier/data/fiscal_dossier_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/organization/data/organization_model.dart';

import 'fiscal_export_balance_loader.dart';
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
    required this.previousDateDebut,
    required this.previousDateFin,
    required this.balanceLineCount,
    required this.previousBalanceLineCount,
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
  final DateTime previousDateDebut;
  final DateTime previousDateFin;
  final int balanceLineCount;
  final int previousBalanceLineCount;
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
    required DateTime previousDateDebut,
    required DateTime previousDateFin,
    required List<SyscebnlBalanceLine> balanceLines,
    required List<SyscebnlBalanceLine> previousBalanceLines,
    required List<FiscalExportAdjustment> adjustments,
    bool usedImportedCurrentBalance = false,
    List<FiscalExportPreflightIssue> fiscalIdentityIssues = const [],
  }) {
    final issues = <FiscalExportPreflightIssue>[...fiscalIdentityIssues];

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
    FiscalExportAdjustmentResult? previousAdjustedBalance;
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

    if (previousBalanceLines.isNotEmpty) {
      try {
        previousAdjustedBalance = FiscalExportAdjustmentEngine.apply(
          balanceLines: previousBalanceLines,
          adjustments: const [],
        );
      } catch (error) {
        issues.add(
          FiscalExportPreflightIssue(
            code: 'previous_balance_error',
            severity: FiscalPreflightSeverity.blocking,
            title: 'Balance N-1 incoherente',
            detail:
                'La balance comparative N-1 existe mais elle n est pas exploitable : $error',
          ),
        );
      }
    }

    final lines = adjustedBalance?.lines ?? balanceLines;
    final previousLines =
        previousAdjustedBalance?.lines ?? previousBalanceLines;
    final mapping = SyscebnlFiscalExcelMapper.fromBalance(
      lines,
      previousLines: previousLines,
    );
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

    if (previousBalanceLines.isEmpty) {
      issues.add(
        FiscalExportPreflightIssue(
          code: 'missing_previous_year',
          severity: FiscalPreflightSeverity.warning,
          title: 'Comparatif N-1 absent',
          detail:
              'Aucune balance N-1 trouvee pour la periode ${_formatDate(previousDateDebut)} - ${_formatDate(previousDateFin)}. Les colonnes comparatives N-1 restent a zero.',
        ),
      );
    } else {
      issues.add(
        FiscalExportPreflightIssue(
          code: 'previous_year_loaded',
          severity: FiscalPreflightSeverity.info,
          title: 'Comparatif N-1 charge',
          detail:
              '${previousBalanceLines.length} ligne(s) de balance N-1 chargee(s) pour la periode ${_formatDate(previousDateDebut)} - ${_formatDate(previousDateFin)}.',
        ),
      );
    }

    if (usedImportedCurrentBalance) {
      issues.add(
        FiscalExportPreflightIssue(
          code: 'imported_balance_loaded',
          severity: FiscalPreflightSeverity.info,
          title: 'Balance importee utilisee',
          detail:
              '${balanceLines.length} ligne(s) de balance importee alimentent l exercice courant.',
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

    issues.add(
      const FiscalExportPreflightIssue(
        code: 'annex_examples_neutralized',
        severity: FiscalPreflightSeverity.info,
        title: 'Annexes protegees',
        detail:
            'Les montants d exemple des fiches et notes annexes du modele seront neutralises avant generation.',
      ),
    );
    issues.add(
      FiscalExportPreflightIssue(
        code: 'fiscal_excel_mapping_coverage',
        severity: FiscalPreflightSeverity.info,
        title: 'Couverture du modele Excel',
        detail:
            '${SyscebnlFiscalExcelMapper.automatedSheetNames.length} feuille(s) alimentee(s) automatiquement depuis le SYSCEBNL. '
            '${SyscebnlFiscalExcelMapper.manualReviewSheetNames.length} feuille(s) qualitative(s) ou sans source comptable fiable restent a revue manuelle si applicables : '
            '${_previewSheets(SyscebnlFiscalExcelMapper.manualReviewSheetNames)}.',
      ),
    );

    return FiscalExportPreflightReport(
      dateDebut: dateDebut,
      dateFin: dateFin,
      previousDateDebut: previousDateDebut,
      previousDateFin: previousDateFin,
      balanceLineCount: balanceLines.length,
      previousBalanceLineCount: previousBalanceLines.length,
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

  static List<FiscalExportPreflightIssue> buildFiscalIdentityIssues(
    Organization? organization,
  ) {
    if (organization == null) {
      return const [
        FiscalExportPreflightIssue(
          code: 'missing_organization',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Organisation introuvable',
          detail:
              'Impossible de controler l identite fiscale sans organisation courante.',
        ),
      ];
    }

    final fiscal = organization.fiscalProfile;
    final blockingMissing = <String>[
      if (_isBlank(organization.nom)) 'nom de l organisation',
      if (_isBlank(fiscal.ifu)) 'numero IFU',
      if (_isBlank(fiscal.taxCenter)) 'centre des impots',
      if (_isBlank(fiscal.headOfficeAddress ?? organization.adresse))
        'siege fiscal',
      if (_isBlank(fiscal.legalRepresentativeName)) 'nom du representant legal',
      if (_isBlank(fiscal.legalRepresentativeTitle))
        'qualite du representant legal',
      if (_isBlank(fiscal.accountantName)) 'nom du comptable responsable',
      if (_isBlank(fiscal.accountantTitle)) 'qualite du comptable responsable',
    ];

    final recommendedMissing = <String>[
      if (_isBlank(fiscal.registrationNumber)) 'reference administrative',
      if (_isBlank(fiscal.depositCenter)) 'centre de depot',
      if (_isBlank(fiscal.activityDescription)) 'activite principale',
      if (_isBlank(fiscal.legalRepresentativePhone))
        'telephone du representant legal',
      if (_isBlank(fiscal.accountantPhone) && _isBlank(fiscal.accountantEmail))
        'contact du comptable',
      if (_isBlank(fiscal.bankName)) 'banque de reference',
      if (_isBlank(fiscal.bankAccountLabel)) 'compte ou intitule bancaire',
    ];

    return [
      if (blockingMissing.isNotEmpty)
        FiscalExportPreflightIssue(
          code: 'incomplete_fiscal_identity',
          severity: FiscalPreflightSeverity.blocking,
          title: 'Identite fiscale incomplete',
          detail:
              'Renseignez dans Parametres organisation : ${blockingMissing.join(', ')}.',
        ),
      if (recommendedMissing.isNotEmpty)
        FiscalExportPreflightIssue(
          code: 'recommended_fiscal_identity_fields',
          severity: FiscalPreflightSeverity.warning,
          title: 'Informations fiscales recommandees',
          detail:
              'Pour un dossier plus complet, ajoutez aussi : ${recommendedMissing.join(', ')}.',
        ),
      if (blockingMissing.isEmpty)
        const FiscalExportPreflightIssue(
          code: 'fiscal_identity_ready',
          severity: FiscalPreflightSeverity.info,
          title: 'Identite fiscale prete',
          detail:
              'Les champs fiscaux essentiels de l organisation sont renseignes.',
        ),
    ];
  }

  static double _totalDebit(List<SyscebnlBalanceLine> lines) {
    return _round(lines.fold<double>(0, (sum, line) => sum + line.totalDebit));
  }

  static double _totalCredit(List<SyscebnlBalanceLine> lines) {
    return _round(lines.fold<double>(0, (sum, line) => sum + line.totalCredit));
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _previewSheets(List<String> sheets) {
    const maxVisibleSheets = 8;
    final visible = sheets.take(maxVisibleSheets).join(', ');
    final remaining = sheets.length - maxVisibleSheets;
    if (remaining <= 0) return visible;
    return '$visible, +$remaining autre(s)';
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;
}

class FiscalExportPreflightService {
  FiscalExportPreflightService(
    ReportsRepository reportsRepository,
    FiscalDossierRepository fiscalRepository,
  ) : _balanceLoader = FiscalExportBalanceLoader.fromRepositories(
        reportsRepository,
        fiscalRepository,
      );

  final FiscalExportBalanceLoader _balanceLoader;

  Future<FiscalExportPreflightReport> buildReport({
    required FiscalDossier dossier,
    required Map<String, dynamic> values,
    Organization? organization,
  }) async {
    final dateFin =
        _dateValue(values['exercice.date_fin']) ??
        _fallbackDateFin(dossier, values);
    final dateDebut =
        _dateValue(values['exercice.date_debut']) ??
        DateTime(dateFin.year, 1, 1);
    final churchUnitId = dossier.churchUnitId;
    final previousPeriod = _previousPeriod(dateDebut, dateFin);
    final balanceData = await _balanceLoader.load(
      dossier: dossier,
      dateDebut: dateDebut,
      dateFin: dateFin,
      previousDateDebut: previousPeriod.start,
      previousDateFin: previousPeriod.end,
    );

    return FiscalExportPreflightEngine.build(
      churchUnitId: churchUnitId,
      dateDebut: dateDebut,
      dateFin: dateFin,
      previousDateDebut: previousPeriod.start,
      previousDateFin: previousPeriod.end,
      balanceLines: balanceData.currentLines,
      previousBalanceLines: balanceData.previousLines,
      adjustments: FiscalExportAdjustmentCodec.decode(
        values[FiscalExportAdjustmentCodec.fieldKey],
      ),
      usedImportedCurrentBalance: balanceData.usedImportedCurrentBalance,
      fiscalIdentityIssues:
          FiscalExportPreflightEngine.buildFiscalIdentityIssues(organization),
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

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}

class _FiscalPeriod {
  const _FiscalPeriod(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

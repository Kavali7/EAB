import 'package:eab/features/etats_financiers/data/reports_repository.dart';
import 'package:eab/features/fiscal_dossier/data/fiscal_dossier_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';

import 'syscebnl_excel_mapping.dart';

typedef FetchBalanceGenerale =
    Future<List<LigneBalance>> Function(
      String orgId, {
      String? churchUnitId,
      DateTime? dateDebut,
      DateTime? dateFin,
    });

typedef FetchImportedTrialBalanceLines =
    Future<List<ImportedTrialBalanceLine>> Function(String importId);

class FiscalExportBalanceData {
  const FiscalExportBalanceData({
    required this.currentLines,
    required this.previousLines,
    required this.usedImportedCurrentBalance,
  });

  final List<SyscebnlBalanceLine> currentLines;
  final List<SyscebnlBalanceLine> previousLines;
  final bool usedImportedCurrentBalance;
}

class FiscalExportBalanceLoader {
  const FiscalExportBalanceLoader({
    required this.fetchBalanceGenerale,
    required this.fetchImportLines,
  });

  factory FiscalExportBalanceLoader.fromRepositories(
    ReportsRepository reportsRepository,
    FiscalDossierRepository fiscalRepository,
  ) {
    return FiscalExportBalanceLoader(
      fetchBalanceGenerale: reportsRepository.fetchBalanceGenerale,
      fetchImportLines: fiscalRepository.getImportLines,
    );
  }

  final FetchBalanceGenerale fetchBalanceGenerale;
  final FetchImportedTrialBalanceLines fetchImportLines;

  Future<FiscalExportBalanceData> load({
    required FiscalDossier dossier,
    required DateTime dateDebut,
    required DateTime dateFin,
    required DateTime previousDateDebut,
    required DateTime previousDateFin,
  }) async {
    final churchUnitId = dossier.churchUnitId?.trim();
    if (churchUnitId == null || churchUnitId.isEmpty) {
      return const FiscalExportBalanceData(
        currentLines: [],
        previousLines: [],
        usedImportedCurrentBalance: false,
      );
    }

    final importedLines = await _loadImportedLines(dossier.importId);
    final useImportedCurrent = importedLines.isNotEmpty;
    final currentLines = useImportedCurrent
        ? importedLines
        : await _loadAccountingLines(
            orgId: dossier.organizationId,
            churchUnitId: churchUnitId,
            dateDebut: dateDebut,
            dateFin: dateFin,
          );
    final previousLines = await _loadAccountingLines(
      orgId: dossier.organizationId,
      churchUnitId: churchUnitId,
      dateDebut: previousDateDebut,
      dateFin: previousDateFin,
    );

    return FiscalExportBalanceData(
      currentLines: currentLines,
      previousLines: previousLines,
      usedImportedCurrentBalance: useImportedCurrent,
    );
  }

  Future<List<SyscebnlBalanceLine>> _loadAccountingLines({
    required String orgId,
    required String churchUnitId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    final balance = await fetchBalanceGenerale(
      orgId,
      churchUnitId: churchUnitId,
      dateDebut: dateDebut,
      dateFin: dateFin,
    );
    return balance
        .map(fromAccountingLine)
        .where(_hasUsableAmount)
        .toList(growable: false);
  }

  Future<List<SyscebnlBalanceLine>> _loadImportedLines(String? importId) async {
    final resolvedImportId = importId?.trim();
    if (resolvedImportId == null || resolvedImportId.isEmpty) {
      return const [];
    }
    final lines = await fetchImportLines(resolvedImportId);
    return lines
        .map(fromImportedLine)
        .where(_hasUsableAmount)
        .toList(growable: false);
  }

  static SyscebnlBalanceLine fromAccountingLine(LigneBalance line) {
    final nature = line.nature.trim().toLowerCase();
    return SyscebnlBalanceLine(
      numero: line.numero,
      intitule: line.intitule,
      nature: nature.isNotEmpty ? nature : _natureFromBalance(line),
      totalDebit: _round(line.totalDebit),
      totalCredit: _round(line.totalCredit),
    );
  }

  static SyscebnlBalanceLine fromImportedLine(ImportedTrialBalanceLine line) {
    final debit = _round(line.debit);
    final credit = _round(line.credit);
    return SyscebnlBalanceLine(
      numero: line.accountNumber.trim(),
      intitule: line.accountLabel?.trim().isNotEmpty == true
          ? line.accountLabel!.trim()
          : 'Compte ${line.accountNumber.trim()}',
      nature: _natureFromAccount(line.accountNumber, debit, credit),
      totalDebit: debit,
      totalCredit: credit,
    );
  }

  static String _natureFromBalance(LigneBalance line) {
    if (line.soldeDebiteur > line.soldeCrediteur) return 'actif';
    if (line.soldeCrediteur > line.soldeDebiteur) return 'passif';
    return _natureFromAccount(line.numero, line.totalDebit, line.totalCredit);
  }

  static String _natureFromAccount(
    String account,
    double debit,
    double credit,
  ) {
    final numero = account.trim();
    if (numero.startsWith('6')) return 'charge';
    if (numero.startsWith('7')) return 'produit';
    if (numero.startsWith('1')) return 'passif';
    if (numero.startsWith('2') || numero.startsWith('3')) return 'actif';
    if (numero.startsWith('4') || numero.startsWith('5')) {
      return debit >= credit ? 'actif' : 'passif';
    }
    if (numero.startsWith('8')) {
      return debit >= credit ? 'charge' : 'produit';
    }
    return debit >= credit ? 'actif' : 'passif';
  }

  static bool _hasUsableAmount(SyscebnlBalanceLine line) {
    return line.numero.trim().isNotEmpty &&
        (_round(line.totalDebit).abs() > 0 ||
            _round(line.totalCredit).abs() > 0);
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}

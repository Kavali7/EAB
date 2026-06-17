import 'package:flutter/material.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_preflight_service.dart';

class FiscalPreflightDialog extends StatelessWidget {
  const FiscalPreflightDialog({
    super.key,
    required this.report,
    this.allowExport = false,
    this.confirmLabel = 'Exporter Excel',
  });

  final FiscalExportPreflightReport report;
  final bool allowExport;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth < 780 ? screenWidth - 48 : 720.0;
    final canConfirm = allowExport && report.canExport;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            report.canExport ? Icons.check_circle_outline : Icons.error_outline,
            color: report.canExport ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              report.canExport
                  ? 'Controles export valides'
                  : 'Controles export bloques',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                    label: 'Bloquants',
                    value: '${report.blockingCount}',
                    color: AppColors.error,
                  ),
                  _MetricChip(
                    label: 'Avertissements',
                    value: '${report.warningCount}',
                    color: AppColors.warning,
                  ),
                  _MetricChip(
                    label: 'Infos',
                    value: '${report.infoCount}',
                    color: AppColors.primary,
                  ),
                  _MetricChip(
                    label: 'Balance',
                    value: '${report.balanceLineCount} lignes',
                    color: AppColors.primary,
                  ),
                  _MetricChip(
                    label: 'Balance N-1',
                    value: '${report.previousBalanceLineCount} lignes',
                    color: AppColors.primary,
                  ),
                  _MetricChip(
                    label: 'Cellules',
                    value:
                        '${report.nonZeroInjectedCellCount}/${report.injectedCellCount}',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (report.issues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Text(
                    'Aucune anomalie detectee pour cette generation.',
                  ),
                )
              else
                ...report.issues.map(_IssueTile.new),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(canConfirm ? 'Annuler' : 'Fermer'),
        ),
        if (canConfirm)
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.table_view_outlined, size: 18),
            label: Text(confirmLabel),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.canExport
                ? 'Le fichier Excel peut etre genere.'
                : 'Le fichier Excel ne doit pas etre genere tant que les points bloquants ne sont pas corriges.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Periode : ${_formatDate(report.dateDebut)} - ${_formatDate(report.dateFin)}',
          ),
          Text(
            'Comparatif N-1 : ${_formatDate(report.previousDateDebut)} - ${_formatDate(report.previousDateFin)}',
          ),
          Text(
            'Totaux controles : debit ${_formatAmount(report.totalDebit)} / credit ${_formatAmount(report.totalCredit)}',
          ),
          Text(
            'Ajustements export : ${report.adjustmentCount} ajustement(s), ${report.adjustmentLineCount} ligne(s).',
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _formatAmount(double value) {
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile(this.issue);

  final FiscalExportPreflightIssue issue;

  @override
  Widget build(BuildContext context) {
    final color = switch (issue.severity) {
      FiscalPreflightSeverity.blocking => AppColors.error,
      FiscalPreflightSeverity.warning => AppColors.warning,
      FiscalPreflightSeverity.info => AppColors.primary,
    };
    final icon = switch (issue.severity) {
      FiscalPreflightSeverity.blocking => Icons.block_outlined,
      FiscalPreflightSeverity.warning => Icons.warning_amber_outlined,
      FiscalPreflightSeverity.info => Icons.info_outline,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(issue.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

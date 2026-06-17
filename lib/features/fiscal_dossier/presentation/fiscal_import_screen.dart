/// Ecran d'import de balance CSV pour le module Dossier Fiscal.
///
/// Route : /fiscal-import-balance
/// Permet de coller un CSV, previsualiser, puis sauvegarder l'import.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/features/church_units/application/church_unit_scope_utils.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/fiscal_dossier/application/fiscal_providers.dart';
import 'package:eab/features/fiscal_dossier/data/csv_import_service.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

class FiscalImportScreen extends ConsumerStatefulWidget {
  const FiscalImportScreen({super.key});

  @override
  ConsumerState<FiscalImportScreen> createState() => _FiscalImportScreenState();
}

class _FiscalImportScreenState extends ConsumerState<FiscalImportScreen> {
  final _csvService = CsvImportService();
  final _fcfaFormat = NumberFormat('#,##0', 'fr_FR');
  final _pasteController = TextEditingController();
  final _exerciceController = TextEditingController();

  CsvImportResult? _parseResult;
  bool _isImporting = false;
  String? _selectedChurchUnitId;

  @override
  void dispose() {
    _pasteController.dispose();
    _exerciceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final churchUnits = userScopeUnits(
      ref.watch(churchUnitsProvider).value ?? [],
    );
    final activeUnitId = ref.watch(churchUnitActiveIdProvider);
    final selectedUnitId = _effectiveSelectedUnitId(churchUnits, activeUnitId);

    return AppShell(
      title: 'Import balance',
      currentRoute: '/fiscal-dossiers',
      showBackButton: true,
      backRoute: '/fiscal-dossiers',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final horizontalPadding = compact ? AppSpacing.md : AppSpacing.xl;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? AppSpacing.md : AppSpacing.xl,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EabPageHeader(
                  title: 'Importer une balance comptable',
                  subtitle: compact
                      ? 'Collez le CSV, analysez, puis sauvegardez.'
                      : 'Copiez-collez une balance depuis Excel ou un fichier CSV avant generation du dossier fiscal.',
                  icon: Icons.upload_file_outlined,
                ),
                SizedBox(
                  width: compact ? double.infinity : 440,
                  child: TextFormField(
                    controller: _exerciceController,
                    decoration: const InputDecoration(
                      labelText: 'Libelle de l\'exercice',
                      hintText: 'Ex: Exercice 2026',
                      prefixIcon: Icon(Icons.event_note_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: compact ? double.infinity : 520,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Perimetre de la balance',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    isExpanded: true,
                    items: [
                      for (final unit in churchUnits)
                        DropdownMenuItem(
                          value: unit.id,
                          child: Text(
                            churchUnitLabel(unit),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: churchUnits.isEmpty
                        ? null
                        : (value) =>
                              setState(() => _selectedChurchUnitId = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _parseResult == null
                      ? _buildPasteZone(compact)
                      : _buildPreview(compact),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _effectiveSelectedUnitId(
    List<ChurchUnit> units,
    String? activeUnitId,
  ) {
    if (_selectedChurchUnitId != null &&
        units.any((unit) => unit.id == _selectedChurchUnitId)) {
      return _selectedChurchUnitId;
    }
    if (activeUnitId != null && units.any((unit) => unit.id == activeUnitId)) {
      return activeUnitId;
    }
    return units.isEmpty ? null : units.first.id;
  }

  Widget _buildPasteZone(bool compact) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.content_paste_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Zone de collage CSV',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: _pasteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText:
                    'numero;intitule;debit;credit\n101;Capital;0;5000000\n2183;Materiel;1200000;0',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: compact ? double.infinity : null,
              child: ElevatedButton.icon(
                onPressed: _parseCsv,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Analyser le CSV'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _parseCsv() {
    final content = _pasteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collez d\'abord le contenu CSV.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = _csvService.parseBalance(content);
    setState(() => _parseResult = result);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPreview(bool compact) {
    final result = _parseResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewSummary(
          result: result,
          compact: compact,
          moneyFormat: _fcfaFormat,
        ),
        if (result.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ErrorBanner(message: result.error!),
        ],
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: result.lines.isEmpty
              ? const EmptyState(
                  message: 'Aucune ligne exploitable dans ce CSV.',
                  icon: Icons.table_rows_outlined,
                )
              : compact
              ? _buildMobilePreview(result)
              : _buildDesktopPreview(result),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildPreviewActions(result, compact),
      ],
    );
  }

  Widget _buildMobilePreview(CsvImportResult result) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: result.lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final line = result.lines[index];
        return _BalanceLineCard(
          index: index + 1,
          accountNumber: line.accountNumber,
          accountLabel: line.accountLabel,
          debit: _fcfaFormat.format(line.debit),
          credit: _fcfaFormat.format(line.credit),
        );
      },
    );
  }

  Widget _buildDesktopPreview(CsvImportResult result) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.primary.withValues(alpha: 0.06),
            ),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Compte')),
              DataColumn(label: Text('Intitule')),
              DataColumn(label: Text('Debit'), numeric: true),
              DataColumn(label: Text('Credit'), numeric: true),
            ],
            rows: result.lines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              return DataRow(
                color: WidgetStateProperty.all(
                  index.isEven ? Colors.white : const Color(0xFFF9FAFB),
                ),
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    Text(
                      line.accountNumber,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        line.accountLabel ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_fcfaFormat.format(line.debit))),
                  DataCell(Text(_fcfaFormat.format(line.credit))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewActions(CsvImportResult result, bool compact) {
    final canSave = result.error == null && !_isImporting;
    final retryButton = OutlinedButton.icon(
      onPressed: () => setState(() {
        _parseResult = null;
        _pasteController.clear();
      }),
      icon: const Icon(Icons.refresh, size: 18),
      label: Text(compact ? 'Refaire' : 'Recommencer'),
    );
    final saveButton = ElevatedButton.icon(
      onPressed: canSave ? _saveImport : null,
      icon: _isImporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined, size: 18),
      label: Text(_isImporting ? 'Import en cours...' : 'Sauvegarder'),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: retryButton),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: saveButton),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        retryButton,
        const SizedBox(width: AppSpacing.sm),
        saveButton,
      ],
    );
  }

  Future<void> _saveImport() async {
    final result = _parseResult;
    if (result == null || result.error != null) return;

    final org = ref.read(currentOrganizationProvider).value;
    final orgId = org?.id;
    final churchUnits = userScopeUnits(
      ref.read(churchUnitsProvider).value ?? [],
    );
    final selectedUnitId = _effectiveSelectedUnitId(
      churchUnits,
      ref.read(churchUnitActiveIdProvider),
    );
    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation non trouvee.')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      await repo.saveImport(
        organizationId: orgId,
        churchUnitId: selectedUnitId,
        exerciceLabel: _exerciceController.text.trim().isEmpty
            ? null
            : _exerciceController.text.trim(),
        filename: 'paste_import.csv',
        totalDebit: result.totalDebit,
        totalCredit: result.totalCredit,
        lineCount: result.lines.length,
        lines: result.lines.map((line) => line.toInsertMap()).toList(),
      );

      ref.invalidate(fiscalImportsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import enregistre - ${result.lines.length} lignes.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'import : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({
    required this.result,
    required this.compact,
    required this.moneyFormat,
  });

  final CsvImportResult result;
  final bool compact;
  final NumberFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricTile(
        label: 'Lignes',
        value: '${result.lines.length}',
        icon: Icons.format_list_numbered_outlined,
      ),
      _MetricTile(
        label: 'Debit',
        value: moneyFormat.format(result.totalDebit),
        icon: Icons.arrow_upward,
      ),
      _MetricTile(
        label: 'Credit',
        value: moneyFormat.format(result.totalCredit),
        icon: Icons.arrow_downward,
      ),
      _MetricTile(
        label: result.isBalanced ? 'Equilibree' : 'Ecart',
        value: result.isBalanced ? 'OK' : moneyFormat.format(result.difference),
        icon: result.isBalanced
            ? Icons.check_circle_outline
            : Icons.warning_amber_outlined,
        color: result.isBalanced ? AppColors.success : AppColors.error,
      ),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              SizedBox(width: 142, child: items[i]),
              if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceLineCard extends StatelessWidget {
  const _BalanceLineCard({
    required this.index,
    required this.accountNumber,
    required this.accountLabel,
    required this.debit,
    required this.credit,
  });

  final int index;
  final String accountNumber;
  final String? accountLabel;
  final String debit;
  final String credit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  accountNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if ((accountLabel ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              accountLabel!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _AmountPill(
                  label: 'Debit',
                  value: debit,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AmountPill(
                  label: 'Credit',
                  value: credit,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

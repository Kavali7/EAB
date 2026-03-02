/// Écran d'import de balance CSV pour le module Dossier Fiscal.
///
/// Route : /fiscal-import-balance
/// Permet de charger un fichier CSV, prévisualiser, et sauvegarder l'import.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/features/fiscal_dossier/data/csv_import_service.dart';
import 'package:eab/features/fiscal_dossier/application/fiscal_providers.dart';
import 'package:eab/features/organization/application/organization_providers.dart';

class FiscalImportScreen extends ConsumerStatefulWidget {
  const FiscalImportScreen({super.key});

  @override
  ConsumerState<FiscalImportScreen> createState() => _FiscalImportScreenState();
}

class _FiscalImportScreenState extends ConsumerState<FiscalImportScreen> {
  final _csvService = CsvImportService();
  final _fcfaFormat = NumberFormat('#,##0', 'fr_FR');
  final _pasteController = TextEditingController();

  CsvImportResult? _parseResult;
  bool _isImporting = false;
  String _exerciceLabel = '';

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Import Balance CSV',
      currentRoute: '/fiscal-dossiers',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EabPageHeader(
              title: 'Importer une balance comptable',
              subtitle:
                  'Collez ici le contenu CSV de votre balance (copier-coller depuis Excel ou fichier .csv).',
              icon: Icons.upload_file_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            // Exercice label
            SizedBox(
              width: 400,
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Libellé de l\'exercice (optionnel)',
                  hintText: 'Ex: Exercice 2026',
                ),
                onChanged: (v) => _exerciceLabel = v,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // CSV paste zone
            Expanded(
              flex: 2,
              child: _parseResult == null
                  ? _buildPasteZone()
                  : _buildPreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Collez le CSV ci-dessous :',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: _pasteController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText:
                  'numero;intitule;debit;credit\n101;Capital;0;5000000\n2183;Matériel;1200000;0\n...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _parseCsv,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Analyser le CSV'),
        ),
      ],
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
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPreview() {
    final result = _parseResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _infoChip(
                  '${result.lines.length} lignes',
                  Icons.list,
                ),
                const SizedBox(width: 16),
                _infoChip(
                  'Débit: ${_fcfaFormat.format(result.totalDebit)} FCFA',
                  Icons.arrow_upward,
                ),
                const SizedBox(width: 16),
                _infoChip(
                  'Crédit: ${_fcfaFormat.format(result.totalCredit)} FCFA',
                  Icons.arrow_downward,
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.isBalanced
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        result.isBalanced
                            ? Icons.check_circle
                            : Icons.warning,
                        size: 14,
                        color: result.isBalanced
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.isBalanced
                            ? 'Équilibrée'
                            : 'Écart: ${_fcfaFormat.format(result.difference)} FCFA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: result.isBalanced
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Table preview
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.06),
              ),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('N° Compte')),
                DataColumn(label: Text('Intitulé')),
                DataColumn(label: Text('Débit'), numeric: true),
                DataColumn(label: Text('Crédit'), numeric: true),
              ],
              rows: result.lines.asMap().entries.map((e) {
                final i = e.key;
                final line = e.value;
                return DataRow(
                  color: WidgetStateProperty.all(
                    i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                  ),
                  cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(line.accountNumber,
                        style:
                            const TextStyle(fontFamily: 'monospace'))),
                    DataCell(Text(line.accountLabel ?? '',
                        overflow: TextOverflow.ellipsis)),
                    DataCell(Text(
                      _fcfaFormat.format(line.debit),
                      textAlign: TextAlign.right,
                    )),
                    DataCell(Text(
                      _fcfaFormat.format(line.credit),
                      textAlign: TextAlign.right,
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Actions
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _parseResult = null;
                _pasteController.clear();
              }),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Recommencer'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: result.error != null || _isImporting
                  ? null
                  : _saveImport,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isImporting
                  ? 'Import en cours...'
                  : 'Sauvegarder l\'import'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Future<void> _saveImport() async {
    final result = _parseResult;
    if (result == null || result.error != null) return;

    final org = ref.read(currentOrganizationProvider).value;
    final orgId = org?.id;
    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation non trouvée.')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      await repo.saveImport(
        organizationId: orgId,
        exerciceLabel:
            _exerciceLabel.isEmpty ? null : _exerciceLabel,
        filename: 'paste_import.csv',
        totalDebit: result.totalDebit,
        totalCredit: result.totalCredit,
        lineCount: result.lines.length,
        lines: result.lines.map((l) => l.toInsertMap()).toList(),
      );

      ref.invalidate(fiscalImportsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Import enregistré ✓ — ${result.lines.length} lignes.'),
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
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}

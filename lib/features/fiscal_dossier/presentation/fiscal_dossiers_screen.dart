/// Écran de liste des dossiers fiscaux.
///
/// Route : /fiscal-dossiers
/// Fonctionnalités : liste DataGrid, création, suppression, navigation wizard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/fiscal_dossier/application/fiscal_providers.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/organization/application/organization_providers.dart';

class FiscalDossiersScreen extends ConsumerStatefulWidget {
  const FiscalDossiersScreen({super.key});

  @override
  ConsumerState<FiscalDossiersScreen> createState() =>
      _FiscalDossiersScreenState();
}

class _FiscalDossiersScreenState extends ConsumerState<FiscalDossiersScreen> {
  @override
  Widget build(BuildContext context) {
    final dossiersAsync = ref.watch(fiscalDossiersProvider);

    return AppShell(
      title: 'Dossiers Fiscaux',
      currentRoute: '/fiscal-dossiers',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dossier'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EabPageHeader(
              title: 'Dossiers Fiscaux SYSCEBNL',
              subtitle: 'Générez vos documents fiscaux multi-pages prêts à déposer.',
              icon: Icons.folder_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: dossiersAsync.when(
                data: (dossiers) => dossiers.isEmpty
                    ? const EmptyState(
                        message: 'Aucun dossier fiscal.',
                        icon: Icons.folder_off_outlined,
                      )
                    : _buildTable(dossiers),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorState(
                  message: 'Erreur : $e',
                  onRetry: () => ref.invalidate(fiscalDossiersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<FiscalDossier> dossiers) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.06),
        ),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Label')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Créé le')),
          DataColumn(label: Text('Actions')),
        ],
        rows: dossiers.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          return DataRow(
            color: WidgetStateProperty.all(
              i.isEven ? Colors.white : const Color(0xFFF9FAFB),
            ),
            cells: [
              DataCell(Text('${i + 1}')),
              DataCell(
                Text(
                  d.label ?? 'Dossier sans titre',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(_statusChip(d.status)),
              DataCell(Text(dateFormat.format(d.createdAt))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Ouvrir le wizard',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/fiscal-dossier/${d.id}',
                      );
                    },
                  ),
                  if (d.status == FiscalDossierStatus.draft)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDelete(d),
                    ),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _statusChip(FiscalDossierStatus status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case FiscalDossierStatus.draft:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
      case FiscalDossierStatus.inProgress:
        bgColor = AppColors.info.withValues(alpha: 0.15);
        textColor = AppColors.info;
      case FiscalDossierStatus.ready:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
      case FiscalDossierStatus.locked:
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
      case FiscalDossierStatus.submitted:
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final templates = ref.read(fiscalTemplatesProvider).value ?? [];
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun template fiscal disponible.')),
      );
      return;
    }

    String? selectedTemplateId = templates.first.id;
    String label = '';

    final org = ref.read(currentOrganizationProvider).value;
    final orgId = org?.id;

    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation non trouvée.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Nouveau dossier fiscal'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTemplateId,
                    decoration: const InputDecoration(labelText: 'Template'),
                    items: templates
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.label, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedTemplateId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Libellé du dossier',
                      hintText: 'Ex: Dossier fiscal 2026',
                    ),
                    onChanged: (v) => label = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedTemplateId == null) return;
                  final dossier = await ref
                      .read(fiscalDossiersProvider.notifier)
                      .createDossier(
                        organizationId: orgId,
                        templateId: selectedTemplateId!,
                        label: label.isEmpty ? null : label,
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    Navigator.of(context).pushNamed(
                      '/fiscal-dossier/${dossier.id}',
                    );
                  }
                },
                child: const Text('Créer'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _confirmDelete(FiscalDossier dossier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le dossier ?'),
        content: Text(
            'Le dossier "${dossier.label ?? ''}" sera supprimé définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(fiscalDossiersProvider.notifier)
          .deleteDossier(dossier.id);
    }
  }
}

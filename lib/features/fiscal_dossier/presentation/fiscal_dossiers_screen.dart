/// Ecran de liste des dossiers fiscaux.
///
/// Route : /fiscal-dossiers
/// Fonctionnalites : liste responsive, creation, suppression, navigation wizard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/core/utils/file_downloader.dart';
import 'package:eab/features/church_units/application/church_unit_scope_utils.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/fiscal_dossier/application/fiscal_providers.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/fiscal_dossier/presentation/widgets/fiscal_preflight_dialog.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

class FiscalDossiersScreen extends ConsumerStatefulWidget {
  const FiscalDossiersScreen({super.key});

  @override
  ConsumerState<FiscalDossiersScreen> createState() =>
      _FiscalDossiersScreenState();
}

class _FiscalDossiersScreenState extends ConsumerState<FiscalDossiersScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  String? _exportingDossierId;

  @override
  Widget build(BuildContext context) {
    final dossiersAsync = ref.watch(fiscalDossiersProvider);
    final importsAsync = ref.watch(fiscalImportsProvider);
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final activeUnitId = ref.watch(churchUnitActiveIdProvider);

    return AppShell(
      title: 'Dossier fiscal',
      currentRoute: '/fiscal-dossiers',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dossier'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final horizontalPadding = compact ? AppSpacing.md : AppSpacing.xl;
          final churchUnits = churchUnitsAsync.value ?? const <ChurchUnit>[];
          final activeUnit = _findUnit(churchUnits, activeUnitId);
          final scopedUnitIds = _unitScopeIds(churchUnits, activeUnit);
          final unitById = {for (final unit in churchUnits) unit.id: unit};
          final visibleDossiers = dossiersAsync.maybeWhen(
            data: (items) => _filterByScope(items, scopedUnitIds),
            orElse: () => const <FiscalDossier>[],
          );
          final visibleImports = importsAsync.maybeWhen(
            data: (items) => _filterImportsByScope(items, scopedUnitIds),
            orElse: () => const <ImportedTrialBalance>[],
          );

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
                if (compact)
                  _FiscalMobileHeader(
                    onImport: () => Navigator.of(
                      context,
                    ).pushNamed('/fiscal-import-balance'),
                  )
                else
                  EabPageHeader(
                    title: 'Dossiers fiscaux SYSCEBNL',
                    subtitle:
                        'Preparation, controle et export des documents fiscaux prets a deposer.',
                    icon: Icons.request_page_outlined,
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed('/fiscal-import-balance'),
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Importer balance'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nouveau dossier'),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                _FiscalSummaryStrip(
                  dossiers: visibleDossiers,
                  importCount: visibleImports.length,
                  compact: compact,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: dossiersAsync.when(
                    data: (dossiers) => compact
                        ? _buildMobileList(
                            _filterByScope(dossiers, scopedUnitIds),
                            unitById,
                          )
                        : _buildDesktopTable(
                            _filterByScope(dossiers, scopedUnitIds),
                            unitById,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ErrorState(
                      message: 'Erreur : $e',
                      onRetry: () => ref.invalidate(fiscalDossiersProvider),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(
    List<FiscalDossier> dossiers,
    Map<String, ChurchUnit> unitById,
  ) {
    return EabTable<FiscalDossier>(
      items: dossiers,
      emptyMessage: 'Aucun dossier fiscal.',
      emptyIcon: Icons.folder_off_outlined,
      onRowTap: _openDossier,
      columns: [
        EabColumn<FiscalDossier>(
          label: 'Dossier',
          flex: 2,
          sortKeyExtractor: (d) => d.label ?? '',
          cellBuilder: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                d.label ?? 'Dossier sans titre',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Mis a jour le ${_dateFormat.format(d.updatedAt)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        EabColumn<FiscalDossier>(
          label: 'Perimetre',
          flex: 1,
          sortKeyExtractor: (d) => _unitLabel(unitById, d.churchUnitId),
          cellBuilder: (d) => Text(
            _unitLabel(unitById, d.churchUnitId),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        EabColumn<FiscalDossier>(
          label: 'Statut',
          fixedWidth: 150,
          sortKeyExtractor: (d) => d.status.index,
          cellBuilder: (d) => _statusChip(d.status),
        ),
        EabColumn<FiscalDossier>(
          label: 'Creation',
          fixedWidth: 130,
          sortKeyExtractor: (d) => d.createdAt,
          cellBuilder: (d) => Text(
            _dateFormat.format(d.createdAt),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        EabColumn<FiscalDossier>(
          label: 'Actions',
          fixedWidth: 156,
          cellBuilder: (d) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: _exportingDossierId == d.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.table_view_outlined, size: 20),
                tooltip: 'Controler et exporter Excel',
                onPressed: _exportingDossierId == null
                    ? () => _exportExcel(d, unitById[d.churchUnitId])
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Ouvrir',
                onPressed: () => _openDossier(d),
              ),
              if (d.status == FiscalDossierStatus.draft)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  tooltip: 'Supprimer',
                  onPressed: () => _confirmDelete(d),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(
    List<FiscalDossier> dossiers,
    Map<String, ChurchUnit> unitById,
  ) {
    if (dossiers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 96),
        child: EmptyState(
          message:
              'Aucun dossier fiscal. Creez un dossier pour preparer les documents fiscaux.',
          icon: Icons.folder_off_outlined,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: dossiers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _DossierCard(
        dossier: dossiers[index],
        unitLabel: _unitLabel(unitById, dossiers[index].churchUnitId),
        dateFormat: _dateFormat,
        statusChip: _statusChip(dossiers[index].status),
        onOpen: () => _openDossier(dossiers[index]),
        onExportExcel: () => _exportExcel(
          dossiers[index],
          unitById[dossiers[index].churchUnitId],
        ),
        isExporting: _exportingDossierId == dossiers[index].id,
        onDelete: dossiers[index].status == FiscalDossierStatus.draft
            ? () => _confirmDelete(dossiers[index])
            : null,
      ),
    );
  }

  Future<void> _exportExcel(
    FiscalDossier dossier,
    ChurchUnit? churchUnit,
  ) async {
    if (_exportingDossierId != null) return;
    setState(() => _exportingDossierId = dossier.id);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final valuesMap = await repo.getValues(dossier.id);
      final flatValues = <String, dynamic>{};
      for (final entry in valuesMap.entries) {
        flatValues[entry.key] = entry.value.value;
      }

      final organization = await ref.read(currentOrganizationProvider.future);
      if (organization == null) {
        throw StateError('Organisation courante introuvable.');
      }
      final preflight = await ref
          .read(fiscalExportPreflightServiceProvider)
          .buildReport(
            dossier: dossier,
            values: flatValues,
            organization: organization,
          );

      if (!mounted) return;
      setState(() => _exportingDossierId = null);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => FiscalPreflightDialog(
          report: preflight,
          allowExport: preflight.canExport,
          confirmLabel: 'Telecharger Excel',
        ),
      );
      if (confirmed != true) return;

      if (!mounted) return;
      setState(() => _exportingDossierId = dossier.id);

      final resolvedUnit =
          churchUnit ??
          _findUnit(
            await ref.read(churchUnitsProvider.future),
            dossier.churchUnitId,
          );
      final export = await ref
          .read(fiscalExcelExportServiceProvider)
          .buildDossierExport(
            dossier: dossier,
            organization: organization,
            values: flatValues,
            churchUnit: resolvedUnit,
          );

      await downloadBytes(
        bytes: export.bytes,
        filename: export.filename,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (mounted) {
        final sourceLabel = export.audit.usedImportedCurrentBalance
            ? 'de la balance importee'
            : 'du perimetre fiscal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Excel SYSCEBNL genere : ${export.audit.balanceLineCount} lignes '
              '$sourceLabel, ${export.audit.adjustmentCount} '
              'ajustement(s), debit ${export.audit.totalDebit}, '
              'credit ${export.audit.totalCredit}.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showActionError(e, prefix: 'Erreur Excel');
    } finally {
      if (mounted) setState(() => _exportingDossierId = null);
    }
  }

  void _openDossier(FiscalDossier dossier) {
    Navigator.of(context).pushNamed('/fiscal-dossier/${dossier.id}');
  }

  Widget _statusChip(FiscalDossierStatus status) {
    final colors = switch (status) {
      FiscalDossierStatus.draft => (
        bg: Colors.grey.shade200,
        fg: Colors.grey.shade800,
      ),
      FiscalDossierStatus.inProgress => (
        bg: AppColors.info.withValues(alpha: 0.12),
        fg: AppColors.info,
      ),
      FiscalDossierStatus.ready => (
        bg: AppColors.success.withValues(alpha: 0.12),
        fg: AppColors.success,
      ),
      FiscalDossierStatus.locked => (
        bg: AppColors.warning.withValues(alpha: 0.16),
        fg: const Color(0xFF8A5B00),
      ),
      FiscalDossierStatus.submitted => (
        bg: AppColors.primary.withValues(alpha: 0.12),
        fg: AppColors.primary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.fg,
        ),
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
    final churchUnits = userScopeUnits(
      ref.read(churchUnitsProvider).value ?? [],
    );
    final activeUnitId = ref.read(churchUnitActiveIdProvider);
    String? selectedChurchUnitId =
        activeUnitId != null &&
            churchUnits.any((unit) => unit.id == activeUnitId)
        ? activeUnitId
        : churchUnits.isEmpty
        ? null
        : churchUnits.first.id;
    String label = '';

    final org = ref.read(currentOrganizationProvider).value;
    final orgId = org?.id;

    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation non trouvee.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return EabDialog(
              title: 'Nouveau dossier fiscal',
              width: 500,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTemplateId,
                    decoration: const InputDecoration(labelText: 'Template'),
                    isExpanded: true,
                    items: templates
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(
                              t.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedTemplateId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedChurchUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Perimetre',
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
                    validator: (value) =>
                        value == null ? 'Selectionnez un perimetre.' : null,
                    onChanged: churchUnits.isEmpty
                        ? null
                        : (v) => setDialogState(() => selectedChurchUnitId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Libelle du dossier',
                      hintText: 'Ex: Dossier fiscal 2026',
                    ),
                    onChanged: (v) => label = v,
                  ),
                ],
              ),
              actions: [
                EabButton(
                  label: 'Annuler',
                  variant: EabButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                EabButton(
                  label: 'Creer',
                  onPressed: () async {
                    if (selectedTemplateId == null) return;
                    final dossier = await ref
                        .read(fiscalDossiersProvider.notifier)
                        .createDossier(
                          organizationId: orgId,
                          templateId: selectedTemplateId!,
                          churchUnitId: selectedChurchUnitId,
                          label: label.trim().isEmpty ? null : label.trim(),
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) _openDossier(dossier);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(FiscalDossier dossier) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Supprimer le dossier ?',
      message:
          'Le dossier "${dossier.label ?? ''}" sera supprime definitivement.',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );

    if (confirmed == true) {
      await ref.read(fiscalDossiersProvider.notifier).deleteDossier(dossier.id);
    }
  }

  void _showActionError(Object error, {String prefix = 'Erreur'}) {
    if (!mounted) return;
    final raw = error.toString();
    final lower = raw.toLowerCase();
    final isPermissionError =
        raw.contains('42501') ||
        lower.contains('droit insuffisant') ||
        lower.contains('permission');
    final message = isPermissionError
        ? 'Action bloquee par les permissions hierarchiques de ce perimetre.'
        : '$prefix : $raw';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isPermissionError
            ? AppColors.warning
            : AppColors.error,
      ),
    );
  }

  ChurchUnit? _findUnit(List<ChurchUnit> units, String? id) {
    if (id == null) return null;
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  Set<String> _unitScopeIds(List<ChurchUnit> units, ChurchUnit? activeUnit) {
    if (activeUnit == null) return const {};
    if (!activeUnit.canViewDescendants) return {activeUnit.id};
    final byParent = <String?, List<ChurchUnit>>{};
    for (final unit in units) {
      byParent.putIfAbsent(unit.parentId, () => []).add(unit);
    }
    final result = <String>{};
    void visit(String id) {
      if (!result.add(id)) return;
      for (final child in byParent[id] ?? const <ChurchUnit>[]) {
        visit(child.id);
      }
    }

    visit(activeUnit.id);
    return result;
  }

  List<FiscalDossier> _filterByScope(
    List<FiscalDossier> dossiers,
    Set<String> scopedUnitIds,
  ) {
    if (scopedUnitIds.isEmpty) return dossiers;
    return dossiers
        .where(
          (dossier) =>
              dossier.churchUnitId == null ||
              scopedUnitIds.contains(dossier.churchUnitId),
        )
        .toList();
  }

  List<ImportedTrialBalance> _filterImportsByScope(
    List<ImportedTrialBalance> imports,
    Set<String> scopedUnitIds,
  ) {
    if (scopedUnitIds.isEmpty) return imports;
    return imports
        .where(
          (item) =>
              item.churchUnitId == null ||
              scopedUnitIds.contains(item.churchUnitId),
        )
        .toList();
  }

  String _unitLabel(Map<String, ChurchUnit> unitById, String? unitId) {
    if (unitId == null) return 'Perimetre non renseigne';
    final unit = unitById[unitId];
    if (unit == null) return 'Perimetre limite';
    return '${unit.typeLabel} - ${unit.nom}';
  }
}

class _FiscalSummaryStrip extends StatelessWidget {
  const _FiscalSummaryStrip({
    required this.dossiers,
    required this.importCount,
    required this.compact,
  });

  final List<FiscalDossier> dossiers;
  final int importCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final readyCount = dossiers
        .where(
          (d) =>
              d.status == FiscalDossierStatus.ready ||
              d.status == FiscalDossierStatus.locked ||
              d.status == FiscalDossierStatus.submitted,
        )
        .length;
    final draftCount = dossiers
        .where((d) => d.status == FiscalDossierStatus.draft)
        .length;

    final children = [
      _SummaryItem(
        label: 'Dossiers',
        value: '${dossiers.length}',
        icon: Icons.folder_copy_outlined,
      ),
      _SummaryItem(
        label: 'Brouillons',
        value: '$draftCount',
        icon: Icons.edit_note_outlined,
      ),
      _SummaryItem(
        label: 'Prets',
        value: '$readyCount',
        icon: Icons.verified_outlined,
      ),
      _SummaryItem(
        label: 'Imports',
        value: '$importCount',
        icon: Icons.upload_file_outlined,
      ),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              SizedBox(width: 132, child: children[i]),
              if (i < children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FiscalMobileHeader extends StatelessWidget {
  const _FiscalMobileHeader({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.request_page_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dossiers fiscaux SYSCEBNL',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Preparation et export des declarations.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Importer une balance'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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

class _DossierCard extends StatelessWidget {
  const _DossierCard({
    required this.dossier,
    required this.unitLabel,
    required this.dateFormat,
    required this.statusChip,
    required this.onOpen,
    required this.onExportExcel,
    required this.isExporting,
    this.onDelete,
  });

  final FiscalDossier dossier;
  final String unitLabel;
  final DateFormat dateFormat;
  final Widget statusChip;
  final VoidCallback onOpen;
  final VoidCallback onExportExcel;
  final bool isExporting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.request_page_outlined,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dossier.label ?? 'Dossier sans titre',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Cree le ${dateFormat.format(dossier.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unitLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  statusChip,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mis a jour le ${dateFormat.format(dossier.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Controler et exporter Excel',
                    onPressed: isExporting ? null : onExportExcel,
                    icon: isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_view_outlined, size: 20),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Ouvrir',
                    onPressed: onOpen,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                  ),
                  if (onDelete != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                      color: AppColors.error,
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

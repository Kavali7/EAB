/// Écran Wizard du Dossier Fiscal SYSCEBNL.
///
/// Route : /fiscal-dossier/:id
/// Desktop : sidebar pages + page renderer + header actions
/// Mobile : stepper vertical, 1 page à la fois, boutons sticky
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/core/utils/file_downloader.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/features/fiscal_dossier/application/fiscal_providers.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/fiscal_dossier/presentation/widgets/fiscal_field_widget.dart';
import 'package:eab/features/fiscal_dossier/presentation/widgets/fiscal_preflight_dialog.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_adjustments.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_pdf_service.dart';
import 'package:eab/features/organization/application/organization_providers.dart';

class FiscalWizardScreen extends ConsumerStatefulWidget {
  final String dossierId;
  const FiscalWizardScreen({super.key, required this.dossierId});

  @override
  ConsumerState<FiscalWizardScreen> createState() => _FiscalWizardScreenState();
}

class _FiscalWizardScreenState extends ConsumerState<FiscalWizardScreen> {
  int _selectedPage = 0;
  bool _isLoading = false;
  FiscalValidationResult? _lastValidation;
  final Map<String, dynamic> _localValues = {};

  @override
  Widget build(BuildContext context) {
    final dossierAsync = ref.watch(
      currentFiscalDossierProvider(widget.dossierId),
    );

    return dossierAsync.when(
      data: (dossier) {
        if (dossier == null) {
          return AppShell(
            title: 'Dossier introuvable',
            currentRoute: '/fiscal-dossiers',
            showBackButton: true,
            backRoute: '/fiscal-dossiers',
            body: const Center(child: Text('Dossier fiscal introuvable.')),
          );
        }
        return _buildWizard(dossier);
      },
      loading: () => AppShell(
        title: 'Chargement...',
        currentRoute: '/fiscal-dossiers',
        showBackButton: true,
        backRoute: '/fiscal-dossiers',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppShell(
        title: 'Erreur',
        currentRoute: '/fiscal-dossiers',
        showBackButton: true,
        backRoute: '/fiscal-dossiers',
        body: ErrorState(
          message: '$e',
          onRetry: () =>
              ref.invalidate(currentFiscalDossierProvider(widget.dossierId)),
        ),
      ),
    );
  }

  Widget _buildWizard(FiscalDossier dossier) {
    final pagesAsync = ref.watch(
      fiscalTemplatePagesProvider(dossier.templateId),
    );
    final valuesAsync = ref.watch(fiscalValuesProvider(dossier.id));

    return pagesAsync.when(
      data: (pages) => valuesAsync.when(
        data: (values) {
          // Merger valeurs DB dans les locales
          for (final entry in values.entries) {
            _localValues.putIfAbsent(entry.key, () => entry.value.value);
          }

          final isLocked =
              dossier.status == FiscalDossierStatus.locked ||
              dossier.status == FiscalDossierStatus.submitted;

          return AppShell(
            title: dossier.label ?? 'Dossier fiscal',
            currentRoute: '/fiscal-dossiers',
            showBackButton: true,
            backRoute: '/fiscal-dossiers',
            actions: _buildActions(dossier, isLocked),
            body: LayoutBuilder(
              builder: (ctx, constraints) {
                final isDesktop = constraints.maxWidth >= 800;
                if (isDesktop) {
                  return _buildDesktopLayout(dossier, pages, isLocked);
                } else {
                  return _buildMobileLayout(dossier, pages, isLocked);
                }
              },
            ),
          );
        },
        loading: () => AppShell(
          title: dossier.label ?? 'Dossier fiscal',
          currentRoute: '/fiscal-dossiers',
          showBackButton: true,
          backRoute: '/fiscal-dossiers',
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => AppShell(
          title: 'Erreur',
          currentRoute: '/fiscal-dossiers',
          showBackButton: true,
          backRoute: '/fiscal-dossiers',
          body: ErrorState(message: '$e'),
        ),
      ),
      loading: () => AppShell(
        title: 'Chargement...',
        currentRoute: '/fiscal-dossiers',
        showBackButton: true,
        backRoute: '/fiscal-dossiers',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppShell(
        title: 'Erreur',
        currentRoute: '/fiscal-dossiers',
        showBackButton: true,
        backRoute: '/fiscal-dossiers',
        body: ErrorState(message: '$e'),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Header Actions
  // ═════════════════════════════════════════════════════════════════════════

  List<Widget> _buildActions(FiscalDossier dossier, bool isLocked) {
    return [
      if (!isLocked) ...[
        // Pré-remplir
        TextButton.icon(
          onPressed: _isLoading ? null : () => _prefill(dossier),
          icon: const Icon(Icons.auto_fix_high, size: 18),
          label: const Text('Pré-remplir'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        const SizedBox(width: 4),
        // Valider
        TextButton.icon(
          onPressed: _isLoading ? null : () => _validate(dossier),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Valider'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: _isLoading ? null : () => _showAdjustmentsDialog(dossier),
          icon: const Icon(Icons.tune_outlined, size: 18),
          label: const Text('Ajustements'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        const SizedBox(width: 4),
      ],
      // Exporter PDF
      TextButton.icon(
        onPressed: _isLoading ? null : () => _showPreflightDialog(dossier),
        icon: const Icon(Icons.fact_check_outlined, size: 18),
        label: const Text('Controles'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      const SizedBox(width: 4),
      TextButton.icon(
        onPressed: _isLoading ? null : () => _exportPdf(dossier),
        icon: const Icon(Icons.picture_as_pdf, size: 18),
        label: const Text('PDF'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      const SizedBox(width: 4),
      TextButton.icon(
        onPressed: _isLoading ? null : () => _exportExcel(dossier),
        icon: const Icon(Icons.table_chart_outlined, size: 18),
        label: const Text('Excel'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      if (!isLocked) ...[
        const SizedBox(width: 4),
        // Verrouiller
        TextButton.icon(
          onPressed: _isLoading ? null : () => _lock(dossier),
          icon: const Icon(Icons.lock_outline, size: 18),
          label: const Text('Verrouiller'),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        ),
      ],
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
    ];
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Desktop layout : sidebar pages + page renderer
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopLayout(
    FiscalDossier dossier,
    List<FiscalTemplatePage> pages,
    bool isLocked,
  ) {
    if (pages.isEmpty) {
      return const Center(child: Text('Aucune page dans ce template.'));
    }
    final currentPage = pages[_selectedPage.clamp(0, pages.length - 1)];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar pages
        SizedBox(
          width: 240,
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pages.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final page = pages[i];
                final isSelected = i == _selectedPage;
                final hasError =
                    _lastValidation?.errors.any(
                      (e) => e.pageCode == page.code,
                    ) ??
                    false;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  leading: _pageIcon(page, hasError),
                  title: Text(
                    page.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: hasError
                      ? const Icon(Icons.error, color: Colors.red, size: 16)
                      : null,
                  onTap: () => setState(() => _selectedPage = i),
                );
              },
            ),
          ),
        ),
        // Page renderer
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: _renderPage(currentPage, dossier, isLocked),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Mobile layout : stepper
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(
    FiscalDossier dossier,
    List<FiscalTemplatePage> pages,
    bool isLocked,
  ) {
    if (pages.isEmpty) {
      return const Center(child: Text('Aucune page dans ce template.'));
    }

    final currentPage = pages[_selectedPage.clamp(0, pages.length - 1)];
    final canGoBack = _selectedPage > 0;
    final canGoNext = _selectedPage < pages.length - 1;

    return Column(
      children: [
        // Header with page indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.primary.withValues(alpha: 0.04),
          child: Row(
            children: [
              Text(
                'Page ${_selectedPage + 1} / ${pages.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentPage.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _buildMobileCommandBar(dossier, isLocked),
        // Page content
        Expanded(child: _renderPage(currentPage, dossier, isLocked)),
        // Sticky navigation buttons
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              if (canGoBack)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedPage--),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Précédent'),
                  ),
                ),
              if (canGoBack && (canGoNext || !isLocked))
                const SizedBox(width: 12),
              if (canGoNext)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!isLocked) {
                        await _saveCurrentPage(dossier);
                      }
                      setState(() => _selectedPage++);
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Suivant'),
                  ),
                ),
              if (!canGoNext && !isLocked)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _saveCurrentPage(dossier),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Enregistrer'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Page renderer
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildMobileCommandBar(FiscalDossier dossier, bool isLocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (!isLocked) ...[
              _CommandButton(
                label: 'Pre-remplir',
                icon: Icons.auto_fix_high,
                onPressed: _isLoading ? null : () => _prefill(dossier),
              ),
              const SizedBox(width: 8),
              _CommandButton(
                label: 'Valider',
                icon: Icons.check_circle_outline,
                onPressed: _isLoading ? null : () => _validate(dossier),
              ),
              const SizedBox(width: 8),
              _CommandButton(
                label: 'Ajustements',
                icon: Icons.tune_outlined,
                onPressed: _isLoading
                    ? null
                    : () => _showAdjustmentsDialog(dossier),
              ),
              const SizedBox(width: 8),
            ],
            _CommandButton(
              label: 'Controles',
              icon: Icons.fact_check_outlined,
              onPressed: _isLoading
                  ? null
                  : () => _showPreflightDialog(dossier),
            ),
            const SizedBox(width: 8),
            _CommandButton(
              label: 'PDF',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: _isLoading ? null : () => _exportPdf(dossier),
            ),
            const SizedBox(width: 8),
            _CommandButton(
              label: 'Excel',
              icon: Icons.table_chart_outlined,
              onPressed: _isLoading ? null : () => _exportExcel(dossier),
            ),
            if (!isLocked) ...[
              const SizedBox(width: 8),
              _CommandButton(
                label: 'Verrouiller',
                icon: Icons.lock_outline,
                onPressed: _isLoading ? null : () => _lock(dossier),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _renderPage(
    FiscalTemplatePage page,
    FiscalDossier dossier,
    bool isLocked,
  ) {
    // Grouper les champs par section
    final fields = page.fields;
    final sections = <String?, List<FiscalTemplateField>>{};
    for (final f in fields) {
      sections.putIfAbsent(f.section, () => []);
      sections[f.section]!.add(f);
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Text(
                page.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_lastValidation != null &&
                  _lastValidation!.errors.any(
                    (e) => e.pageCode == page.code,
                  )) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _lastValidation!.errors
                        .where((e) => e.pageCode == page.code)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const Divider(height: 24),
              // Sections with fields
              ...sections.entries.map((entry) {
                final sectionName = entry.key;
                final sectionFields = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionName != null && sectionName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        sectionName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    ...sectionFields.map(
                      (field) => FiscalFieldWidget(
                        field: field,
                        value: _localValues[field.fieldKey],
                        readOnly: isLocked,
                        onChanged: isLocked
                            ? null
                            : (v) {
                                setState(() {
                                  _localValues[field.fieldKey] = v;
                                });
                              },
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              // Save button (desktop only, mobile uses nav buttons)
              if (!isLocked)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _saveCurrentPage(dossier),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Enregistrer'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Actions
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _saveCurrentPage(FiscalDossier dossier) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      for (final entry in _localValues.entries) {
        await repo.saveValue(
          dossierId: dossier.id,
          organizationId: dossier.organizationId,
          fieldKey: entry.key,
          value: entry.value,
          source: 'manual',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistré ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showActionError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAdjustmentsDialog(FiscalDossier dossier) async {
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final valuesMap = await repo.getValues(dossier.id);
      final flatValues = <String, dynamic>{};
      for (final entry in valuesMap.entries) {
        flatValues[entry.key] = entry.value.value;
      }
      flatValues.addAll(_localValues);

      final initial = FiscalExportAdjustmentCodec.decode(
        flatValues[FiscalExportAdjustmentCodec.fieldKey],
      );
      if (!mounted) return;

      final updated = await showDialog<List<FiscalExportAdjustment>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FiscalAdjustmentDialog(initial: initial),
      );
      if (updated == null) return;

      FiscalExportAdjustmentEngine.validate(updated);
      final encoded = FiscalExportAdjustmentCodec.encode(updated);

      setState(() => _isLoading = true);
      await repo.saveValue(
        dossierId: dossier.id,
        organizationId: dossier.organizationId,
        fieldKey: FiscalExportAdjustmentCodec.fieldKey,
        value: encoded,
        source: 'export_adjustment',
      );
      _localValues[FiscalExportAdjustmentCodec.fieldKey] = encoded;
      ref.invalidate(fiscalValuesProvider(dossier.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${updated.length} ajustement(s) export enregistre(s).',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showActionError(e, prefix: 'Erreur ajustements');
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPreflightDialog(FiscalDossier dossier) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final valuesMap = await repo.getValues(dossier.id);
      final flatValues = <String, dynamic>{};
      for (final entry in valuesMap.entries) {
        flatValues[entry.key] = entry.value.value;
      }
      flatValues.addAll(_localValues);

      final report = await ref
          .read(fiscalExportPreflightServiceProvider)
          .buildReport(dossier: dossier, values: flatValues);

      if (!mounted) return;
      setState(() => _isLoading = false);
      await showDialog<void>(
        context: context,
        builder: (_) => FiscalPreflightDialog(report: report),
      );
    } catch (e) {
      _showActionError(e, prefix: 'Erreur controles');
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _prefill(FiscalDossier dossier) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final result = await repo.prefill(dossier.id);
      // Recharger les valeurs
      ref.invalidate(fiscalValuesProvider(dossier.id));
      ref.invalidate(currentFiscalDossierProvider(dossier.id));
      _localValues.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pré-remplissage terminé : ${result['filled']} champs remplis.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showActionError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validate(FiscalDossier dossier) async {
    // D'abord sauvegarder
    await _saveCurrentPage(dossier);

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final result = await repo.validate(dossier.id);
      setState(() => _lastValidation = result);
      ref.invalidate(currentFiscalDossierProvider(dossier.id));

      if (mounted) {
        if (result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Validation réussie ✓ — Dossier prêt.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.errorCount} erreur(s) de validation détectée(s).',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _showActionError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _lock(FiscalDossier dossier) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Verrouiller le dossier ?',
      message: 'Le dossier ne pourra plus etre modifie apres verrouillage.',
      confirmLabel: 'Verrouiller',
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final result = await repo.lock(dossier.id);
      ref.invalidate(currentFiscalDossierProvider(dossier.id));
      ref.invalidate(fiscalDossiersProvider);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dossier verrouillé ✓'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur de verrouillage.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _showActionError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf(FiscalDossier dossier) async {
    setState(() => _isLoading = true);
    try {
      // Charger les pages template
      final repo = ref.read(fiscalRepositoryProvider);
      final pages = await repo.getTemplatePages(dossier.templateId);
      final valuesMap = await repo.getValues(dossier.id);

      // Convertir les valeurs en map simple fieldKey -> value
      final flatValues = <String, dynamic>{};
      for (final entry in valuesMap.entries) {
        flatValues[entry.key] = entry.value.value;
      }
      // Merger les valeurs locales (non encore sauvegardées)
      flatValues.addAll(_localValues);

      // Déterminer le nom de l'org
      final orgName = dossier.label ?? 'Dossier fiscal';

      // Watermark si brouillon
      final watermark = dossier.status == FiscalDossierStatus.draft
          ? 'BROUILLON'
          : null;

      // Générer le PDF
      final doc = await FiscalPdfService.buildDossierPdf(
        orgName: orgName,
        pages: pages,
        values: flatValues,
        watermark: watermark,
      );

      // Ouvrir la prévisualisation
      await FiscalPdfService.preview(doc, 'Dossier Fiscal — $orgName');
    } catch (e) {
      _showActionError(e, prefix: 'Erreur PDF');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportExcel(FiscalDossier dossier) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(fiscalRepositoryProvider);
      final valuesMap = await repo.getValues(dossier.id);
      final flatValues = <String, dynamic>{};
      for (final entry in valuesMap.entries) {
        flatValues[entry.key] = entry.value.value;
      }
      flatValues.addAll(_localValues);

      final preflight = await ref
          .read(fiscalExportPreflightServiceProvider)
          .buildReport(dossier: dossier, values: flatValues);
      if (!preflight.canExport) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await showDialog<void>(
          context: context,
          builder: (_) => FiscalPreflightDialog(report: preflight),
        );
        return;
      }

      final organization = await ref.read(currentOrganizationProvider.future);
      if (organization == null) {
        throw StateError('Organisation courante introuvable.');
      }
      final units = await ref.read(churchUnitsProvider.future);
      final export = await ref
          .read(fiscalExcelExportServiceProvider)
          .buildDossierExport(
            dossier: dossier,
            organization: organization,
            values: flatValues,
            churchUnit: _findChurchUnit(units, dossier.churchUnitId),
          );

      await downloadBytes(
        bytes: export.bytes,
        filename: export.filename,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Excel SYSCEBNL genere : ${export.audit.balanceLineCount} lignes '
              'du perimetre fiscal, ${export.audit.adjustmentCount} '
              'ajustement(s), debit ${export.audit.totalDebit}, '
              'credit ${export.audit.totalCredit}, '
              'N-1 ${export.audit.previousBalanceLineCount} lignes.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showActionError(e, prefix: 'Erreur Excel');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═════════════════════════════════════════════════════════════════════════

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
        backgroundColor: isPermissionError ? Colors.orange : Colors.red,
      ),
    );
  }

  ChurchUnit? _findChurchUnit(List<ChurchUnit> units, String? id) {
    if (id == null) return null;
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  Widget _pageIcon(FiscalTemplatePage page, bool hasError) {
    if (hasError) {
      return const Icon(Icons.error_outline, size: 18, color: Colors.red);
    }
    switch (page.code) {
      case 'COVER':
        return const Icon(Icons.article_outlined, size: 18);
      case 'IDENTITY':
        return const Icon(Icons.badge_outlined, size: 18);
      case 'BILAN_ACTIF':
        return const Icon(Icons.account_balance_outlined, size: 18);
      case 'BILAN_PASSIF':
        return const Icon(Icons.account_balance_wallet_outlined, size: 18);
      case 'RESULTAT':
        return const Icon(Icons.trending_up_outlined, size: 18);
      default:
        return const Icon(Icons.description_outlined, size: 18);
    }
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _FiscalAdjustmentDialog extends StatefulWidget {
  const _FiscalAdjustmentDialog({required this.initial});

  final List<FiscalExportAdjustment> initial;

  @override
  State<_FiscalAdjustmentDialog> createState() =>
      _FiscalAdjustmentDialogState();
}

class _FiscalAdjustmentDialogState extends State<_FiscalAdjustmentDialog> {
  static const _balancedEntry = 'balanced_entry';
  static const _debitReclass = 'debit_reclass';
  static const _creditReclass = 'credit_reclass';

  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _reasonController = TextEditingController();
  final _sourceAccountController = TextEditingController();
  final _sourceLabelController = TextEditingController();
  final _targetAccountController = TextEditingController();
  final _targetLabelController = TextEditingController();
  final _amountController = TextEditingController();

  late final List<FiscalExportAdjustment> _adjustments;
  String _type = _balancedEntry;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adjustments = [...widget.initial];
  }

  @override
  void dispose() {
    _labelController.dispose();
    _reasonController.dispose();
    _sourceAccountController.dispose();
    _sourceLabelController.dispose();
    _targetAccountController.dispose();
    _targetLabelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustements d export'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'Ces ajustements ne modifient pas les ecritures. Ils '
                  's appliquent uniquement au fichier Excel/PDF genere et '
                  'doivent toujours rester equilibres.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              _buildExistingAdjustments(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type d ajustement',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _balancedEntry,
                          child: Text('Ecriture debit / credit'),
                        ),
                        DropdownMenuItem(
                          value: _debitReclass,
                          child: Text('Reclassement cote debit'),
                        ),
                        DropdownMenuItem(
                          value: _creditReclass,
                          child: Text('Reclassement cote credit'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                          _error = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _labelController,
                      label: 'Libelle de l ajustement',
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _reasonController,
                      label: 'Justification',
                      validator: _required,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _field(
                          controller: _sourceAccountController,
                          label: _sourceAccountLabel,
                          validator: _accountValidator,
                          width: 210,
                        ),
                        _field(
                          controller: _sourceLabelController,
                          label: 'Intitule source',
                          validator: _required,
                          width: 300,
                        ),
                        _field(
                          controller: _targetAccountController,
                          label: _targetAccountLabel,
                          validator: _accountValidator,
                          width: 210,
                        ),
                        _field(
                          controller: _targetLabelController,
                          label: 'Intitule cible',
                          validator: _required,
                          width: 300,
                        ),
                        _field(
                          controller: _amountController,
                          label: 'Montant',
                          validator: _amountValidator,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          width: 210,
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addAdjustment,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter l ajustement'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_adjustments),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildExistingAdjustments() {
    if (_adjustments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text('Aucun ajustement en attente.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_adjustments.length} ajustement(s) en attente',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._adjustments.map(
          (adjustment) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              title: Text(adjustment.label),
              subtitle: Text(_summary(adjustment)),
              trailing: IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _adjustments.remove(adjustment);
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  void _addAdjustment() {
    if (!_formKey.currentState!.validate()) return;
    try {
      final amount = fiscalExportAdjustmentAmountFromText(
        _amountController.text,
      );
      final id = 'adj_${DateTime.now().microsecondsSinceEpoch}';
      final adjustment = switch (_type) {
        _debitReclass => FiscalExportAdjustment.debitReclassification(
          id: id,
          label: _labelController.text.trim(),
          reason: _reasonController.text.trim(),
          sourceAccountNumber: _sourceAccountController.text.trim(),
          sourceAccountLabel: _sourceLabelController.text.trim(),
          targetAccountNumber: _targetAccountController.text.trim(),
          targetAccountLabel: _targetLabelController.text.trim(),
          amount: amount,
        ),
        _creditReclass => FiscalExportAdjustment.creditReclassification(
          id: id,
          label: _labelController.text.trim(),
          reason: _reasonController.text.trim(),
          sourceAccountNumber: _sourceAccountController.text.trim(),
          sourceAccountLabel: _sourceLabelController.text.trim(),
          targetAccountNumber: _targetAccountController.text.trim(),
          targetAccountLabel: _targetLabelController.text.trim(),
          amount: amount,
        ),
        _ => FiscalExportAdjustment.balancedEntry(
          id: id,
          label: _labelController.text.trim(),
          reason: _reasonController.text.trim(),
          debitAccountNumber: _sourceAccountController.text.trim(),
          debitAccountLabel: _sourceLabelController.text.trim(),
          creditAccountNumber: _targetAccountController.text.trim(),
          creditAccountLabel: _targetLabelController.text.trim(),
          amount: amount,
        ),
      };
      final updated = [..._adjustments, adjustment];
      FiscalExportAdjustmentEngine.validate(updated);
      setState(() {
        _adjustments
          ..clear()
          ..addAll(updated);
        _error = null;
      });
      _labelController.clear();
      _reasonController.clear();
      _sourceAccountController.clear();
      _sourceLabelController.clear();
      _targetAccountController.clear();
      _targetLabelController.clear();
      _amountController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String get _sourceAccountLabel {
    return switch (_type) {
      _balancedEntry => 'Compte a debiter',
      _debitReclass => 'Compte debit source',
      _creditReclass => 'Compte credit source',
      _ => 'Compte source',
    };
  }

  String get _targetAccountLabel {
    return switch (_type) {
      _balancedEntry => 'Compte a crediter',
      _debitReclass => 'Compte debit cible',
      _creditReclass => 'Compte credit cible',
      _ => 'Compte cible',
    };
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
    return null;
  }

  String? _accountValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^\d+').hasMatch(value!.trim())) {
      return 'Compte SYSCEBNL invalide';
    }
    return null;
  }

  String? _amountValidator(String? value) {
    try {
      fiscalExportAdjustmentAmountFromText(value ?? '');
      return null;
    } catch (_) {
      return 'Montant positif requis';
    }
  }

  String _summary(FiscalExportAdjustment adjustment) {
    final debit = adjustment.lines.fold<double>(
      0,
      (sum, line) => sum + line.debitDelta,
    );
    final credit = adjustment.lines.fold<double>(
      0,
      (sum, line) => sum + line.creditDelta,
    );
    return 'Debit ${debit.toStringAsFixed(2)} / Credit ${credit.toStringAsFixed(2)} - ${adjustment.reason}';
  }
}

/// Providers Riverpod pour le module Dossier Fiscal SYSCEBNL.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/features/etats_financiers/application/reports_providers.dart';
import 'package:eab/features/fiscal_dossier/data/fiscal_dossier_repository.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_export_service.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_preflight_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final fiscalRepositoryProvider = Provider<FiscalDossierRepository>((ref) {
  return FiscalDossierRepository(SupabaseDataService());
});

final fiscalExcelExportServiceProvider = Provider<FiscalExcelExportService>((
  ref,
) {
  return FiscalExcelExportService(ref.watch(reportsRepositoryProvider));
});

final fiscalExportPreflightServiceProvider =
    Provider<FiscalExportPreflightService>((ref) {
      return FiscalExportPreflightService(ref.watch(reportsRepositoryProvider));
    });

// ─────────────────────────────────────────────────────────────────────────────
// Templates
// ─────────────────────────────────────────────────────────────────────────────

/// Liste des templates actifs.
final fiscalTemplatesProvider = FutureProvider<List<FiscalTemplate>>((
  ref,
) async {
  final repo = ref.watch(fiscalRepositoryProvider);
  return repo.listTemplates();
});

// ─────────────────────────────────────────────────────────────────────────────
// Dossiers
// ─────────────────────────────────────────────────────────────────────────────

/// Liste des dossiers fiscaux.
final fiscalDossiersProvider =
    AsyncNotifierProvider<FiscalDossiersNotifier, List<FiscalDossier>>(
      FiscalDossiersNotifier.new,
    );

class FiscalDossiersNotifier extends AsyncNotifier<List<FiscalDossier>> {
  @override
  Future<List<FiscalDossier>> build() async {
    final repo = ref.watch(fiscalRepositoryProvider);
    return repo.listDossiers();
  }

  Future<FiscalDossier> createDossier({
    required String organizationId,
    required String templateId,
    String? churchUnitId,
    String? exerciceId,
    String? label,
  }) async {
    final repo = ref.read(fiscalRepositoryProvider);
    final dossier = await repo.createDossier(
      organizationId: organizationId,
      templateId: templateId,
      churchUnitId: churchUnitId,
      exerciceId: exerciceId,
      label: label,
    );
    ref.invalidateSelf();
    return dossier;
  }

  Future<void> deleteDossier(String dossierId) async {
    final repo = ref.read(fiscalRepositoryProvider);
    await repo.deleteDossier(dossierId);
    ref.invalidateSelf();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wizard state (dossier + pages + valeurs)
// ─────────────────────────────────────────────────────────────────────────────

/// Pages template chargées pour un dossier.
final fiscalTemplatePagesProvider =
    FutureProvider.family<List<FiscalTemplatePage>, String>((
      ref,
      templateId,
    ) async {
      final repo = ref.watch(fiscalRepositoryProvider);
      return repo.getTemplatePages(templateId);
    });

/// Valeurs du dossier courant.
final fiscalValuesProvider =
    FutureProvider.family<Map<String, FiscalDossierValue>, String>((
      ref,
      dossierId,
    ) async {
      final repo = ref.watch(fiscalRepositoryProvider);
      return repo.getValues(dossierId);
    });

/// Dossier courant (pour le wizard).
final currentFiscalDossierProvider =
    FutureProvider.family<FiscalDossier?, String>((ref, dossierId) async {
      final repo = ref.watch(fiscalRepositoryProvider);
      return repo.getDossier(dossierId);
    });

/// Page sélectionnée dans le wizard.
final selectedPageIndexProvider = NotifierProvider<SelectedPageNotifier, int>(
  SelectedPageNotifier.new,
);

class SelectedPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Balance
// ─────────────────────────────────────────────────────────────────────────────

/// Liste des imports.
final fiscalImportsProvider = FutureProvider<List<ImportedTrialBalance>>((
  ref,
) async {
  final repo = ref.watch(fiscalRepositoryProvider);
  return repo.listImports();
});

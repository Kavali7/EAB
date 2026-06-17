/// Repository Supabase pour le module Dossier Fiscal SYSCEBNL.
///
/// Gère : templates, dossiers, valeurs, import balance, et appels RPCs.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';

class FiscalDossierRepository {
  const FiscalDossierRepository(this._dataService);
  final SupabaseDataService _dataService;

  SupabaseClient get _sb => _dataService.client;

  // ─────────────────────────────────────────────────────────────────────────
  // Templates
  // ─────────────────────────────────────────────────────────────────────────

  /// Liste les templates fiscaux actifs.
  Future<List<FiscalTemplate>> listTemplates() async {
    final data = await _sb
        .from('fiscal_templates')
        .select()
        .eq('is_active', true)
        .order('code');
    return (data as List).map((e) => FiscalTemplate.fromJson(e)).toList();
  }

  /// Récupère les pages d'un template avec leurs champs.
  Future<List<FiscalTemplatePage>> getTemplatePages(String templateId) async {
    final pagesData = await _sb
        .from('fiscal_template_pages')
        .select()
        .eq('template_id', templateId)
        .order('page_order');

    final fieldsData = await _sb
        .from('fiscal_template_fields')
        .select()
        .inFilter(
          'page_id',
          (pagesData as List).map((p) => p['id'] as String).toList(),
        )
        .order('field_order');

    final fieldsByPage = <String, List<FiscalTemplateField>>{};
    for (final f in fieldsData as List) {
      final pageId = f['page_id'] as String;
      fieldsByPage.putIfAbsent(pageId, () => []);
      fieldsByPage[pageId]!.add(FiscalTemplateField.fromJson(f));
    }

    return pagesData.map((p) {
      final page = FiscalTemplatePage.fromJson(p);
      return page.copyWith(fields: fieldsByPage[page.id] ?? []);
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dossiers
  // ─────────────────────────────────────────────────────────────────────────

  /// Liste les dossiers fiscaux de l'organisation courante.
  Future<List<FiscalDossier>> listDossiers() async {
    final data = await _sb
        .from('fiscal_dossiers')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => FiscalDossier.fromJson(e)).toList();
  }

  /// Récupère un dossier par ID.
  Future<FiscalDossier?> getDossier(String dossierId) async {
    final data = await _sb
        .from('fiscal_dossiers')
        .select()
        .eq('id', dossierId)
        .maybeSingle();
    if (data == null) return null;
    return FiscalDossier.fromJson(data);
  }

  /// Crée un nouveau dossier fiscal.
  Future<FiscalDossier> createDossier({
    required String organizationId,
    required String templateId,
    String? churchUnitId,
    String? exerciceId,
    String? label,
  }) async {
    final data = await _sb
        .from('fiscal_dossiers')
        .insert({
          'organization_id': organizationId,
          if (churchUnitId != null) 'church_unit_id': churchUnitId,
          'template_id': templateId,
          if (exerciceId != null) 'exercice_id': exerciceId,
          'label': label ?? 'Nouveau dossier fiscal',
          'created_by': _sb.auth.currentUser?.id,
        })
        .select()
        .single();
    return FiscalDossier.fromJson(data);
  }

  /// Supprime un dossier (seulement si draft).
  Future<void> deleteDossier(String dossierId) async {
    await _sb.from('fiscal_dossiers').delete().eq('id', dossierId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Valeurs
  // ─────────────────────────────────────────────────────────────────────────

  /// Récupère toutes les valeurs d'un dossier.
  Future<Map<String, FiscalDossierValue>> getValues(String dossierId) async {
    final data = await _sb
        .from('fiscal_dossier_values')
        .select()
        .eq('dossier_id', dossierId);
    final map = <String, FiscalDossierValue>{};
    for (final row in data as List) {
      final v = FiscalDossierValue.fromJson(row);
      map[v.fieldKey] = v;
    }
    return map;
  }

  /// Sauvegarde une valeur (upsert).
  Future<void> saveValue({
    required String dossierId,
    required String organizationId,
    required String fieldKey,
    required dynamic value,
    String source = 'manual',
  }) async {
    await _sb.from('fiscal_dossier_values').upsert({
      'dossier_id': dossierId,
      'organization_id': organizationId,
      'field_key': fieldKey,
      'value': value,
      'source': source,
      'updated_by': _sb.auth.currentUser?.id,
    }, onConflict: 'dossier_id,field_key');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RPCs
  // ─────────────────────────────────────────────────────────────────────────

  /// Pré-remplit les champs depuis la comptabilité existante.
  Future<Map<String, dynamic>> prefill(String dossierId) async {
    final result = await _sb.rpc(
      'prefill_fiscal_dossier',
      params: {'p_dossier_id': dossierId},
    );
    return result as Map<String, dynamic>;
  }

  /// Pré-remplit depuis une balance importée.
  Future<Map<String, dynamic>> prefillFromImport(
    String dossierId,
    String importId,
  ) async {
    final result = await _sb.rpc(
      'prefill_fiscal_dossier_from_import',
      params: {'p_dossier_id': dossierId, 'p_import_id': importId},
    );
    return result as Map<String, dynamic>;
  }

  /// Valide le dossier (contrôles bloquants).
  Future<FiscalValidationResult> validate(String dossierId) async {
    final result = await _sb.rpc(
      'validate_fiscal_dossier',
      params: {'p_dossier_id': dossierId},
    );
    return FiscalValidationResult.fromJson(result as Map<String, dynamic>);
  }

  /// Verrouille le dossier.
  Future<Map<String, dynamic>> lock(String dossierId) async {
    final result = await _sb.rpc(
      'lock_fiscal_dossier',
      params: {'p_dossier_id': dossierId},
    );
    return result as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Import Balance CSV
  // ─────────────────────────────────────────────────────────────────────────

  /// Liste les balances importées.
  Future<List<ImportedTrialBalance>> listImports() async {
    final data = await _sb
        .from('imported_trial_balances')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => ImportedTrialBalance.fromJson(e)).toList();
  }

  /// Sauvegarde un import de balance.
  Future<ImportedTrialBalance> saveImport({
    required String organizationId,
    String? churchUnitId,
    required String? exerciceLabel,
    required String? filename,
    required double totalDebit,
    required double totalCredit,
    required int lineCount,
    required List<Map<String, dynamic>> lines,
  }) async {
    // 1) Insérer l'en-tête
    final headerData = await _sb
        .from('imported_trial_balances')
        .insert({
          'organization_id': organizationId,
          if (churchUnitId != null) 'church_unit_id': churchUnitId,
          'exercice_label': exerciceLabel,
          'filename': filename,
          'total_debit': totalDebit,
          'total_credit': totalCredit,
          'line_count': lineCount,
          'created_by': _sb.auth.currentUser?.id,
        })
        .select()
        .single();

    final importId = headerData['id'] as String;

    // 2) Insérer les lignes par lots de 100
    for (int i = 0; i < lines.length; i += 100) {
      final batch = lines
          .skip(i)
          .take(100)
          .map(
            (l) => {
              'import_id': importId,
              'organization_id': organizationId,
              ...l,
            },
          )
          .toList();
      await _sb.from('imported_trial_balance_lines').insert(batch);
    }

    return ImportedTrialBalance.fromJson(headerData);
  }

  /// Supprime un import.
  Future<void> deleteImport(String importId) async {
    await _sb.from('imported_trial_balances').delete().eq('id', importId);
  }
}

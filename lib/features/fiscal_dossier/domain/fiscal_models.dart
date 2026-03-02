/// Modèles de données pour le module Dossier Fiscal SYSCEBNL.
///
/// Classes : FiscalTemplate, FiscalTemplatePage, FiscalTemplateField,
///           FiscalDossier, FiscalDossierValue, FiscalValidationError,
///           FiscalValidationResult, ImportedTrialBalance, ImportedTrialBalanceLine.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum FiscalDossierStatus {
  draft,
  inProgress,
  ready,
  locked,
  submitted;

  static FiscalDossierStatus fromString(String s) {
    switch (s) {
      case 'draft':
        return FiscalDossierStatus.draft;
      case 'in_progress':
        return FiscalDossierStatus.inProgress;
      case 'ready':
        return FiscalDossierStatus.ready;
      case 'locked':
        return FiscalDossierStatus.locked;
      case 'submitted':
        return FiscalDossierStatus.submitted;
      default:
        return FiscalDossierStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case FiscalDossierStatus.draft:
        return 'draft';
      case FiscalDossierStatus.inProgress:
        return 'in_progress';
      case FiscalDossierStatus.ready:
        return 'ready';
      case FiscalDossierStatus.locked:
        return 'locked';
      case FiscalDossierStatus.submitted:
        return 'submitted';
    }
  }

  String get label {
    switch (this) {
      case FiscalDossierStatus.draft:
        return 'Brouillon';
      case FiscalDossierStatus.inProgress:
        return 'En cours';
      case FiscalDossierStatus.ready:
        return 'Prêt';
      case FiscalDossierStatus.locked:
        return 'Verrouillé';
      case FiscalDossierStatus.submitted:
        return 'Soumis';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template
// ─────────────────────────────────────────────────────────────────────────────

class FiscalTemplate {
  final String id;
  final String code;
  final String label;
  final int version;
  final bool isActive;

  const FiscalTemplate({
    required this.id,
    required this.code,
    required this.label,
    required this.version,
    required this.isActive,
  });

  factory FiscalTemplate.fromJson(Map<String, dynamic> j) => FiscalTemplate(
        id: j['id'] ?? '',
        code: j['code'] ?? '',
        label: j['label'] ?? '',
        version: j['version'] ?? 1,
        isActive: j['is_active'] ?? true,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Template Page
// ─────────────────────────────────────────────────────────────────────────────

class FiscalTemplatePage {
  final String id;
  final String templateId;
  final String code;
  final String title;
  final int pageOrder;
  final Map<String, dynamic> layout;
  final Map<String, dynamic> rules;
  final List<FiscalTemplateField> fields;

  const FiscalTemplatePage({
    required this.id,
    required this.templateId,
    required this.code,
    required this.title,
    required this.pageOrder,
    required this.layout,
    required this.rules,
    this.fields = const [],
  });

  FiscalTemplatePage copyWith({List<FiscalTemplateField>? fields}) =>
      FiscalTemplatePage(
        id: id,
        templateId: templateId,
        code: code,
        title: title,
        pageOrder: pageOrder,
        layout: layout,
        rules: rules,
        fields: fields ?? this.fields,
      );

  String get layoutType => layout['type'] as String? ?? 'form';

  factory FiscalTemplatePage.fromJson(Map<String, dynamic> j) =>
      FiscalTemplatePage(
        id: j['id'] ?? '',
        templateId: j['template_id'] ?? '',
        code: j['code'] ?? '',
        title: j['title'] ?? '',
        pageOrder: j['page_order'] ?? 0,
        layout:
            (j['layout'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        rules:
            (j['rules'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Template Field
// ─────────────────────────────────────────────────────────────────────────────

class FiscalTemplateField {
  final String id;
  final String pageId;
  final String fieldKey;
  final String label;
  final String fieldType; // money, text, date, select, bool, percent, integer
  final int fieldOrder;
  final String? section;
  final bool required;
  final dynamic defaultValue;
  final Map<String, dynamic>? compute;
  final Map<String, dynamic> ui;

  const FiscalTemplateField({
    required this.id,
    required this.pageId,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.fieldOrder,
    this.section,
    required this.required,
    this.defaultValue,
    this.compute,
    required this.ui,
  });

  bool get isComputed => compute != null;
  bool get isReadonly => ui['readonly'] == true || isComputed;
  bool get isBold => ui['bold'] == true;
  bool get isHighlighted => ui['highlight'] == true;
  String? get placeholder => ui['placeholder'] as String?;
  String? get hint => ui['hint'] as String?;
  List<String>? get selectOptions {
    final opts = ui['options'];
    if (opts is List) return opts.cast<String>();
    return null;
  }

  factory FiscalTemplateField.fromJson(Map<String, dynamic> j) =>
      FiscalTemplateField(
        id: j['id'] ?? '',
        pageId: j['page_id'] ?? '',
        fieldKey: j['field_key'] ?? '',
        label: j['label'] ?? '',
        fieldType: j['field_type'] ?? 'text',
        fieldOrder: j['field_order'] ?? 0,
        section: j['section'],
        required: j['required'] ?? false,
        defaultValue: j['default_value'],
        compute: j['compute'] as Map<String, dynamic>?,
        ui: (j['ui'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dossier Fiscal
// ─────────────────────────────────────────────────────────────────────────────

class FiscalDossier {
  final String id;
  final String organizationId;
  final String templateId;
  final String? exerciceId;
  final String? importId;
  final FiscalDossierStatus status;
  final String? label;
  final String? notes;
  final String? createdBy;
  final String? lockedBy;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FiscalDossier({
    required this.id,
    required this.organizationId,
    required this.templateId,
    this.exerciceId,
    this.importId,
    required this.status,
    this.label,
    this.notes,
    this.createdBy,
    this.lockedBy,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FiscalDossier.fromJson(Map<String, dynamic> j) => FiscalDossier(
        id: j['id'] ?? '',
        organizationId: j['organization_id'] ?? '',
        templateId: j['template_id'] ?? '',
        exerciceId: j['exercice_id'],
        importId: j['import_id'],
        status: FiscalDossierStatus.fromString(j['status'] ?? 'draft'),
        label: j['label'],
        notes: j['notes'],
        createdBy: j['created_by'],
        lockedBy: j['locked_by'],
        lockedAt:
            j['locked_at'] != null ? DateTime.parse(j['locked_at']) : null,
        createdAt: DateTime.parse(
            j['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(
            j['updated_at'] ?? DateTime.now().toIso8601String()),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dossier Value
// ─────────────────────────────────────────────────────────────────────────────

class FiscalDossierValue {
  final String id;
  final String dossierId;
  final String organizationId;
  final String fieldKey;
  final dynamic value;
  final String source; // manual, computed, imported

  const FiscalDossierValue({
    required this.id,
    required this.dossierId,
    required this.organizationId,
    required this.fieldKey,
    this.value,
    required this.source,
  });

  factory FiscalDossierValue.fromJson(Map<String, dynamic> j) =>
      FiscalDossierValue(
        id: j['id'] ?? '',
        dossierId: j['dossier_id'] ?? '',
        organizationId: j['organization_id'] ?? '',
        fieldKey: j['field_key'] ?? '',
        value: j['value'],
        source: j['source'] ?? 'manual',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation
// ─────────────────────────────────────────────────────────────────────────────

class FiscalValidationError {
  final String code;
  final String message;
  final String? pageCode;
  final String? fieldKey;

  const FiscalValidationError({
    required this.code,
    required this.message,
    this.pageCode,
    this.fieldKey,
  });

  factory FiscalValidationError.fromJson(Map<String, dynamic> j) =>
      FiscalValidationError(
        code: j['code'] ?? '',
        message: j['message'] ?? '',
        pageCode: j['page_code'],
        fieldKey: j['field_key'],
      );
}

class FiscalValidationResult {
  final bool ok;
  final int errorCount;
  final List<FiscalValidationError> errors;

  const FiscalValidationResult({
    required this.ok,
    required this.errorCount,
    required this.errors,
  });

  factory FiscalValidationResult.fromJson(Map<String, dynamic> j) =>
      FiscalValidationResult(
        ok: j['ok'] ?? false,
        errorCount: j['error_count'] ?? 0,
        errors: (j['errors'] as List?)
                ?.map((e) => FiscalValidationError.fromJson(e))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Balance CSV
// ─────────────────────────────────────────────────────────────────────────────

class ImportedTrialBalance {
  final String id;
  final String organizationId;
  final String? exerciceLabel;
  final String? filename;
  final double totalDebit;
  final double totalCredit;
  final int lineCount;
  final DateTime createdAt;

  const ImportedTrialBalance({
    required this.id,
    required this.organizationId,
    this.exerciceLabel,
    this.filename,
    required this.totalDebit,
    required this.totalCredit,
    required this.lineCount,
    required this.createdAt,
  });

  factory ImportedTrialBalance.fromJson(Map<String, dynamic> j) =>
      ImportedTrialBalance(
        id: j['id'] ?? '',
        organizationId: j['organization_id'] ?? '',
        exerciceLabel: j['exercice_label'],
        filename: j['filename'],
        totalDebit: (j['total_debit'] as num?)?.toDouble() ?? 0,
        totalCredit: (j['total_credit'] as num?)?.toDouble() ?? 0,
        lineCount: j['line_count'] ?? 0,
        createdAt: DateTime.parse(
            j['created_at'] ?? DateTime.now().toIso8601String()),
      );
}

class ImportedTrialBalanceLine {
  final String id;
  final String importId;
  final String accountNumber;
  final String? accountLabel;
  final double debit;
  final double credit;
  final double? solde;

  const ImportedTrialBalanceLine({
    required this.id,
    required this.importId,
    required this.accountNumber,
    this.accountLabel,
    required this.debit,
    required this.credit,
    this.solde,
  });

  factory ImportedTrialBalanceLine.fromJson(Map<String, dynamic> j) =>
      ImportedTrialBalanceLine(
        id: j['id'] ?? '',
        importId: j['import_id'] ?? '',
        accountNumber: j['account_number'] ?? '',
        accountLabel: j['account_label'],
        debit: (j['debit'] as num?)?.toDouble() ?? 0,
        credit: (j['credit'] as num?)?.toDouble() ?? 0,
        solde: (j['solde'] as num?)?.toDouble(),
      );
}

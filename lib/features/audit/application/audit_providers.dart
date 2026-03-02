/// Providers Riverpod pour le journal d'audit.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modèle d'une entrée d'audit.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.organizationId,
    this.userId,
    this.userEmail,
    this.userRole,
    this.tableName,
    this.recordId,
    this.oldData,
    this.newData,
    this.changes,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String?,
        userId: json['user_id'] as String?,
        userEmail: json['user_email'] as String?,
        userRole: json['user_role'] as String?,
        action: json['action'] as String,
        tableName: json['table_name'] as String?,
        recordId: json['record_id'] as String?,
        oldData: json['old_data'] as Map<String, dynamic>?,
        newData: json['new_data'] as Map<String, dynamic>?,
        changes: json['changes'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String? organizationId;
  final String? userId;
  final String? userEmail;
  final String? userRole;
  final String action;
  final String? tableName;
  final String? recordId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;
}

/// Filtre pour les logs d'audit.
class AuditFilter {
  const AuditFilter({this.action, this.tableName, this.userEmail});

  final String? action;
  final String? tableName;
  final String? userEmail;

  AuditFilter copyWith({
    String? Function()? action,
    String? Function()? tableName,
    String? Function()? userEmail,
  }) =>
      AuditFilter(
        action: action != null ? action() : this.action,
        tableName: tableName != null ? tableName() : this.tableName,
        userEmail: userEmail != null ? userEmail() : this.userEmail,
      );
}

/// Provider du filtre courant.
final auditFilterProvider = StateProvider<AuditFilter>(
  (_) => const AuditFilter(),
);

/// Provider des logs d'audit (avec filtre).
final auditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  final filter = ref.watch(auditFilterProvider);
  final client = Supabase.instance.client;

  var query = client
      .from('audit_logs')
      .select()
      .order('created_at', ascending: false)
      .limit(200);

  if (filter.action != null) {
    query = query.eq('action', filter.action!);
  }
  if (filter.tableName != null) {
    query = query.eq('table_name', filter.tableName!);
  }
  if (filter.userEmail != null) {
    query = query.ilike('user_email', '%${filter.userEmail!}%');
  }

  final data = await query;
  return (data as List).map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>)).toList();
});

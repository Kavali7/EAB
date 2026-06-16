class HierarchyPermission {
  const HierarchyPermission({
    required this.domainCode,
    required this.domainLabel,
    required this.actionCode,
    required this.actionLabel,
    required this.allowed,
    required this.source,
    required this.requiresDescendantAcceptance,
    required this.acceptanceStatus,
  });

  final String domainCode;
  final String domainLabel;
  final String actionCode;
  final String actionLabel;
  final bool allowed;
  final String source;
  final bool requiresDescendantAcceptance;
  final String acceptanceStatus;

  bool get hasOverride => source == 'override';
  bool get isPending => acceptanceStatus == 'pending';

  factory HierarchyPermission.fromJson(Map<String, dynamic> json) {
    return HierarchyPermission(
      domainCode: json['domain_code'] as String? ?? '',
      domainLabel: json['domain_label'] as String? ?? 'Domaine',
      actionCode: json['action_code'] as String? ?? '',
      actionLabel: json['action_label'] as String? ?? 'Action',
      allowed: json['allowed'] as bool? ?? false,
      source: json['source'] as String? ?? 'none',
      requiresDescendantAcceptance:
          json['requires_descendant_acceptance'] as bool? ?? false,
      acceptanceStatus: json['acceptance_status'] as String? ?? 'not_required',
    );
  }
}

class UnitPermissionOverride {
  const UnitPermissionOverride({
    required this.id,
    required this.ancestorUnitId,
    required this.descendantUnitId,
    required this.domainCode,
    required this.domainLabel,
    required this.actionCode,
    required this.actionLabel,
    required this.allowed,
    required this.requiresDescendantAcceptance,
    required this.acceptanceStatus,
    this.reason,
  });

  final String id;
  final String ancestorUnitId;
  final String descendantUnitId;
  final String domainCode;
  final String domainLabel;
  final String actionCode;
  final String actionLabel;
  final bool allowed;
  final bool requiresDescendantAcceptance;
  final String acceptanceStatus;
  final String? reason;

  bool get isPending => acceptanceStatus == 'pending';
  bool get isAccepted => acceptanceStatus == 'accepted';
  bool get isRejected => acceptanceStatus == 'rejected';

  factory UnitPermissionOverride.fromJson(Map<String, dynamic> json) {
    final domain = _nestedJson(json['domain']);
    final action = _nestedJson(json['action']);
    return UnitPermissionOverride(
      id: json['id'] as String,
      ancestorUnitId: json['ancestor_unit_id'] as String? ?? '',
      descendantUnitId: json['descendant_unit_id'] as String? ?? '',
      domainCode: domain['code'] as String? ?? '',
      domainLabel: domain['label'] as String? ?? 'Domaine',
      actionCode: action['code'] as String? ?? '',
      actionLabel: action['label'] as String? ?? 'Action',
      allowed: json['allowed'] as bool? ?? false,
      requiresDescendantAcceptance:
          json['requires_descendant_acceptance'] as bool? ?? false,
      acceptanceStatus: json['acceptance_status'] as String? ?? 'not_required',
      reason: json['reason'] as String?,
    );
  }
}

Map<String, dynamic> _nestedJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

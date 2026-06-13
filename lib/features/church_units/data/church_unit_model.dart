class ChurchUnitType {
  const ChurchUnitType({
    required this.id,
    required this.organizationId,
    required this.code,
    required this.label,
    required this.levelOrder,
    required this.isLocal,
    required this.isFinancialScope,
    required this.canHaveMembers,
  });

  final String id;
  final String organizationId;
  final String code;
  final String label;
  final int levelOrder;
  final bool isLocal;
  final bool isFinancialScope;
  final bool canHaveMembers;

  factory ChurchUnitType.fromJson(Map<String, dynamic> json) {
    return ChurchUnitType(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      code: json['code'] as String? ?? 'unit',
      label: json['label'] as String? ?? 'Unite',
      levelOrder: json['level_order'] as int? ?? 0,
      isLocal: json['is_local'] as bool? ?? false,
      isFinancialScope: json['is_financial_scope'] as bool? ?? false,
      canHaveMembers: json['can_have_members'] as bool? ?? false,
    );
  }
}

class ChurchUnit {
  const ChurchUnit({
    required this.id,
    required this.organizationId,
    required this.typeId,
    required this.nom,
    required this.typeCode,
    required this.typeLabel,
    required this.levelOrder,
    required this.isLocal,
    required this.isFinancialScope,
    required this.canHaveMembers,
    required this.active,
    this.parentId,
    this.code,
    this.description,
    this.ville,
    this.quartier,
    this.adresse,
    this.telephone,
    this.email,
    this.legacyRegionId,
    this.legacyDistrictId,
    this.legacyAssembleeId,
  });

  final String id;
  final String organizationId;
  final String typeId;
  final String nom;
  final String typeCode;
  final String typeLabel;
  final int levelOrder;
  final bool isLocal;
  final bool isFinancialScope;
  final bool canHaveMembers;
  final bool active;
  final String? parentId;
  final String? code;
  final String? description;
  final String? ville;
  final String? quartier;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? legacyRegionId;
  final String? legacyDistrictId;
  final String? legacyAssembleeId;

  factory ChurchUnit.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as Map<String, dynamic>?) ?? const {};
    return ChurchUnit(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      typeId: json['type_id'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      nom: json['nom'] as String? ?? 'Unite',
      code: json['code'] as String?,
      description: json['description'] as String?,
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      adresse: json['adresse'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      active: json['active'] as bool? ?? true,
      legacyRegionId: json['legacy_region_id'] as String?,
      legacyDistrictId: json['legacy_district_id'] as String?,
      legacyAssembleeId: json['legacy_assemblee_id'] as String?,
      typeCode: type['code'] as String? ?? 'unit',
      typeLabel: type['label'] as String? ?? 'Unite',
      levelOrder: type['level_order'] as int? ?? 0,
      isLocal: type['is_local'] as bool? ?? false,
      isFinancialScope: type['is_financial_scope'] as bool? ?? false,
      canHaveMembers: type['can_have_members'] as bool? ?? false,
    );
  }

  factory ChurchUnit.legacy({
    required String id,
    required String organizationId,
    required String nom,
    required String typeCode,
    required String typeLabel,
    required int levelOrder,
    String? parentId,
    String? code,
    String? description,
    String? ville,
    String? quartier,
    String? adresse,
    String? telephone,
    String? email,
    String? legacyRegionId,
    String? legacyDistrictId,
    String? legacyAssembleeId,
  }) {
    return ChurchUnit(
      id: id,
      organizationId: organizationId,
      typeId: 'legacy_$typeCode',
      nom: nom,
      typeCode: typeCode,
      typeLabel: typeLabel,
      levelOrder: levelOrder,
      isLocal: typeCode == 'local_church',
      isFinancialScope:
          typeCode == 'organization' || typeCode == 'local_church',
      canHaveMembers: typeCode == 'local_church',
      active: true,
      parentId: parentId,
      code: code,
      description: description,
      ville: ville,
      quartier: quartier,
      adresse: adresse,
      telephone: telephone,
      email: email,
      legacyRegionId: legacyRegionId,
      legacyDistrictId: legacyDistrictId,
      legacyAssembleeId: legacyAssembleeId,
    );
  }
}

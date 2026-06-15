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
    required this.canHaveCashAccounts,
    required this.canHaveBankAccounts,
    required this.canHaveMobileMoneyAccounts,
    required this.canCreatePrograms,
    required this.canLaunchContributions,
    required this.canValidateFinances,
    required this.canConsolidateFinances,
    required this.canNotifyDescendants,
    required this.canViewDescendants,
  });

  final String id;
  final String organizationId;
  final String code;
  final String label;
  final int levelOrder;
  final bool isLocal;
  final bool isFinancialScope;
  final bool canHaveMembers;
  final bool canHaveCashAccounts;
  final bool canHaveBankAccounts;
  final bool canHaveMobileMoneyAccounts;
  final bool canCreatePrograms;
  final bool canLaunchContributions;
  final bool canValidateFinances;
  final bool canConsolidateFinances;
  final bool canNotifyDescendants;
  final bool canViewDescendants;

  bool get canHaveFinancialAccounts =>
      canHaveCashAccounts || canHaveBankAccounts || canHaveMobileMoneyAccounts;

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
      canHaveCashAccounts: json['can_have_cash_accounts'] as bool? ?? false,
      canHaveBankAccounts: json['can_have_bank_accounts'] as bool? ?? false,
      canHaveMobileMoneyAccounts:
          json['can_have_mobile_money_accounts'] as bool? ?? false,
      canCreatePrograms: json['can_create_programs'] as bool? ?? false,
      canLaunchContributions:
          json['can_launch_contributions'] as bool? ?? false,
      canValidateFinances: json['can_validate_finances'] as bool? ?? false,
      canConsolidateFinances:
          json['can_consolidate_finances'] as bool? ?? false,
      canNotifyDescendants: json['can_notify_descendants'] as bool? ?? false,
      canViewDescendants: json['can_view_descendants'] as bool? ?? true,
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
    required this.canHaveCashAccounts,
    required this.canHaveBankAccounts,
    required this.canHaveMobileMoneyAccounts,
    required this.canCreatePrograms,
    required this.canLaunchContributions,
    required this.canValidateFinances,
    required this.canConsolidateFinances,
    required this.canNotifyDescendants,
    required this.canViewDescendants,
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
  final bool canHaveCashAccounts;
  final bool canHaveBankAccounts;
  final bool canHaveMobileMoneyAccounts;
  final bool canCreatePrograms;
  final bool canLaunchContributions;
  final bool canValidateFinances;
  final bool canConsolidateFinances;
  final bool canNotifyDescendants;
  final bool canViewDescendants;
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

  bool get canHaveFinancialAccounts =>
      canHaveCashAccounts || canHaveBankAccounts || canHaveMobileMoneyAccounts;

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
      canHaveCashAccounts: type['can_have_cash_accounts'] as bool? ?? false,
      canHaveBankAccounts: type['can_have_bank_accounts'] as bool? ?? false,
      canHaveMobileMoneyAccounts:
          type['can_have_mobile_money_accounts'] as bool? ?? false,
      canCreatePrograms: type['can_create_programs'] as bool? ?? false,
      canLaunchContributions:
          type['can_launch_contributions'] as bool? ?? false,
      canValidateFinances: type['can_validate_finances'] as bool? ?? false,
      canConsolidateFinances:
          type['can_consolidate_finances'] as bool? ?? false,
      canNotifyDescendants: type['can_notify_descendants'] as bool? ?? false,
      canViewDescendants: type['can_view_descendants'] as bool? ?? true,
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
      canHaveCashAccounts:
          typeCode == 'organization' || typeCode == 'local_church',
      canHaveBankAccounts:
          typeCode == 'organization' || typeCode == 'local_church',
      canHaveMobileMoneyAccounts:
          typeCode == 'organization' || typeCode == 'local_church',
      canCreatePrograms: true,
      canLaunchContributions: true,
      canValidateFinances: typeCode != 'local_church',
      canConsolidateFinances: typeCode != 'local_church',
      canNotifyDescendants: typeCode != 'local_church',
      canViewDescendants: true,
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

class ChurchUnitFinancialAccount {
  const ChurchUnitFinancialAccount({
    required this.id,
    required this.organizationId,
    required this.churchUnitId,
    required this.type,
    required this.label,
    required this.currency,
    required this.openingBalance,
    required this.active,
    this.provider,
    this.accountNumber,
    this.phoneNumber,
    this.journalId,
    this.comptableAccountId,
  });

  final String id;
  final String organizationId;
  final String churchUnitId;
  final String type;
  final String label;
  final String? provider;
  final String? accountNumber;
  final String? phoneNumber;
  final String currency;
  final double openingBalance;
  final String? journalId;
  final String? comptableAccountId;
  final bool active;

  factory ChurchUnitFinancialAccount.fromJson(Map<String, dynamic> json) {
    return ChurchUnitFinancialAccount(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      churchUnitId: json['church_unit_id'] as String? ?? '',
      type: json['type'] as String? ?? 'cash',
      label: json['label'] as String? ?? 'Compte financier',
      provider: json['provider'] as String?,
      accountNumber: json['account_number'] as String?,
      phoneNumber: json['phone_number'] as String?,
      currency: json['currency'] as String? ?? 'FCFA',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      journalId: json['journal_id'] as String?,
      comptableAccountId: json['comptable_account_id'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  String get typeLabel {
    return switch (type) {
      'bank' => 'Banque',
      'mobile_money' => 'Mobile Money',
      _ => 'Caisse',
    };
  }
}

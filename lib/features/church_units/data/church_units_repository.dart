import 'package:eab/core/services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'church_unit_model.dart';

class ChurchUnitsRepository {
  ChurchUnitsRepository(this._dataService);

  final SupabaseDataService _dataService;

  Future<List<ChurchUnitType>> fetchTypes() async {
    try {
      final response = await _dataService.client
          .from('church_unit_types')
          .select()
          .order('level_order', ascending: true)
          .order('label', ascending: true);

      return (response as List)
          .map((json) => ChurchUnitType.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingFlexibleSchema(e)) return const [];
      rethrow;
    }
  }

  Future<List<ChurchUnit>> fetchUnits() async {
    try {
      final response = await _dataService.client
          .from('church_units')
          .select('''
            id,
            organization_id,
            type_id,
            parent_id,
            nom,
            code,
            description,
            ville,
            quartier,
            adresse,
            telephone,
            email,
            active,
            legacy_region_id,
            legacy_district_id,
            legacy_assemblee_id,
            type:church_unit_types(
              code,
              label,
              level_order,
              is_local,
              is_financial_scope,
              can_have_members,
              can_have_cash_accounts,
              can_have_bank_accounts,
              can_have_mobile_money_accounts,
              can_create_programs,
              can_launch_contributions,
              can_validate_finances,
              can_consolidate_finances,
              can_notify_descendants,
              can_view_descendants
            )
          ''')
          .eq('active', true)
          .order('nom', ascending: true);

      final units = (response as List)
          .map((json) => ChurchUnit.fromJson(json as Map<String, dynamic>))
          .toList();
      units.sort((a, b) {
        final level = a.levelOrder.compareTo(b.levelOrder);
        if (level != 0) return level;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });
      return units;
    } on PostgrestException catch (e) {
      if (_isMissingFlexibleSchema(e)) return const [];
      rethrow;
    }
  }

  Future<void> createType({
    required String organizationId,
    required String code,
    required String label,
    required int levelOrder,
    required bool isLocal,
    required bool isFinancialScope,
    required bool canHaveMembers,
    required bool canHaveCashAccounts,
    required bool canHaveBankAccounts,
    required bool canHaveMobileMoneyAccounts,
    required bool canCreatePrograms,
    required bool canLaunchContributions,
    required bool canValidateFinances,
    required bool canConsolidateFinances,
    required bool canNotifyDescendants,
    required bool canViewDescendants,
  }) async {
    await _dataService.client.from('church_unit_types').insert({
      'organization_id': organizationId,
      'code': code,
      'label': label,
      'level_order': levelOrder,
      'is_local': isLocal,
      'is_financial_scope': isFinancialScope,
      'can_have_members': canHaveMembers,
      'can_have_cash_accounts': canHaveCashAccounts,
      'can_have_bank_accounts': canHaveBankAccounts,
      'can_have_mobile_money_accounts': canHaveMobileMoneyAccounts,
      'can_create_programs': canCreatePrograms,
      'can_launch_contributions': canLaunchContributions,
      'can_validate_finances': canValidateFinances,
      'can_consolidate_finances': canConsolidateFinances,
      'can_notify_descendants': canNotifyDescendants,
      'can_view_descendants': canViewDescendants,
    });
  }

  Future<void> updateType({
    required String id,
    required String code,
    required String label,
    required int levelOrder,
    required bool isLocal,
    required bool isFinancialScope,
    required bool canHaveMembers,
    required bool canHaveCashAccounts,
    required bool canHaveBankAccounts,
    required bool canHaveMobileMoneyAccounts,
    required bool canCreatePrograms,
    required bool canLaunchContributions,
    required bool canValidateFinances,
    required bool canConsolidateFinances,
    required bool canNotifyDescendants,
    required bool canViewDescendants,
  }) async {
    await _dataService.client
        .from('church_unit_types')
        .update({
          'code': code,
          'label': label,
          'level_order': levelOrder,
          'is_local': isLocal,
          'is_financial_scope': isFinancialScope,
          'can_have_members': canHaveMembers,
          'can_have_cash_accounts': canHaveCashAccounts,
          'can_have_bank_accounts': canHaveBankAccounts,
          'can_have_mobile_money_accounts': canHaveMobileMoneyAccounts,
          'can_create_programs': canCreatePrograms,
          'can_launch_contributions': canLaunchContributions,
          'can_validate_finances': canValidateFinances,
          'can_consolidate_finances': canConsolidateFinances,
          'can_notify_descendants': canNotifyDescendants,
          'can_view_descendants': canViewDescendants,
        })
        .eq('id', id);
  }

  Future<void> deleteType(String id) async {
    await _dataService.client.from('church_unit_types').delete().eq('id', id);
  }

  Future<void> createUnit({
    required String organizationId,
    required String typeId,
    required String nom,
    String? parentId,
    String? code,
    String? description,
    String? ville,
    String? quartier,
    String? adresse,
    String? telephone,
    String? email,
  }) async {
    await _dataService.client.from('church_units').insert({
      'organization_id': organizationId,
      'type_id': typeId,
      'parent_id': parentId,
      'nom': nom,
      'code': _blankToNull(code),
      'description': _blankToNull(description),
      'ville': _blankToNull(ville),
      'quartier': _blankToNull(quartier),
      'adresse': _blankToNull(adresse),
      'telephone': _blankToNull(telephone),
      'email': _blankToNull(email),
    });
  }

  Future<void> updateUnit({
    required String id,
    required String typeId,
    required String nom,
    String? parentId,
    String? code,
    String? description,
    String? ville,
    String? quartier,
    String? adresse,
    String? telephone,
    String? email,
  }) async {
    await _dataService.client
        .from('church_units')
        .update({
          'type_id': typeId,
          'parent_id': parentId,
          'nom': nom,
          'code': _blankToNull(code),
          'description': _blankToNull(description),
          'ville': _blankToNull(ville),
          'quartier': _blankToNull(quartier),
          'adresse': _blankToNull(adresse),
          'telephone': _blankToNull(telephone),
          'email': _blankToNull(email),
        })
        .eq('id', id);
  }

  Future<void> archiveUnit(String id) async {
    await _dataService.client
        .from('church_units')
        .update({'active': false})
        .eq('id', id);
  }

  Future<List<ChurchUnitFinancialAccount>> fetchFinancialAccounts() async {
    try {
      final response = await _dataService.client
          .from('church_unit_financial_accounts')
          .select()
          .eq('active', true)
          .order('type', ascending: true)
          .order('label', ascending: true);

      return (response as List)
          .map(
            (json) => ChurchUnitFinancialAccount.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingFinancialAccountsSchema(e)) return const [];
      rethrow;
    }
  }

  Future<void> createFinancialAccount({
    required String organizationId,
    required String churchUnitId,
    required String type,
    required String label,
    String? provider,
    String? accountNumber,
    String? phoneNumber,
    String currency = 'FCFA',
    double openingBalance = 0,
  }) async {
    await _dataService.client.from('church_unit_financial_accounts').insert({
      'organization_id': organizationId,
      'church_unit_id': churchUnitId,
      'type': type,
      'label': label,
      'provider': _blankToNull(provider),
      'account_number': _blankToNull(accountNumber),
      'phone_number': _blankToNull(phoneNumber),
      'currency': currency.trim().isEmpty ? 'FCFA' : currency.trim(),
      'opening_balance': openingBalance,
    });
  }

  Future<void> updateFinancialAccount({
    required String id,
    required String type,
    required String label,
    String? provider,
    String? accountNumber,
    String? phoneNumber,
    String currency = 'FCFA',
    double openingBalance = 0,
  }) async {
    await _dataService.client
        .from('church_unit_financial_accounts')
        .update({
          'type': type,
          'label': label,
          'provider': _blankToNull(provider),
          'account_number': _blankToNull(accountNumber),
          'phone_number': _blankToNull(phoneNumber),
          'currency': currency.trim().isEmpty ? 'FCFA' : currency.trim(),
          'opening_balance': openingBalance,
        })
        .eq('id', id);
  }

  Future<void> archiveFinancialAccount(String id) async {
    await _dataService.client
        .from('church_unit_financial_accounts')
        .update({'active': false})
        .eq('id', id);
  }

  bool _isMissingFlexibleSchema(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == '42P01' ||
        message.contains('church_units') ||
        message.contains('church_unit_types');
  }

  bool _isMissingFinancialAccountsSchema(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == '42P01' ||
        message.contains('church_unit_financial_accounts');
  }

  String? _blankToNull(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }
}

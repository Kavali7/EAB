/// Repository pour la gestion des organisations.
library;

import 'dart:typed_data';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'hierarchy_permission_models.dart';
import 'organization_model.dart';

class OrganizationRepository {
  OrganizationRepository(this._dataService);

  final SupabaseDataService _dataService;
  static const _logoExtensions = {'png', 'jpg', 'jpeg', 'webp', 'svg'};

  /// Récupère l'organisation courante.
  Future<Organization?> fetchCurrentOrganization() async {
    final data = await _dataService.client
        .from('organizations')
        .select()
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return Organization.fromJson(data);
  }

  /// Liste les organisations visibles par le proprietaire plateforme.
  ///
  /// Le client ne lit pas directement la table `organizations` pour cette
  /// console : le backend expose uniquement le RPC dedie, protege par
  /// `is_platform_owner()`.
  Future<List<Organization>> fetchPlatformOrganizations() async {
    final result = await _dataService.client.rpc('platform_list_organizations');
    if (result is! List) return const [];
    return result
        .map(
          (json) =>
              Organization.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList(growable: false);
  }

  /// Met à jour les informations de l'organisation.
  Future<void> updateOrganization(Organization org) async {
    await _dataService.client
        .from('organizations')
        .update(org.toUpdateJson())
        .eq('id', org.id);
  }

  /// Met a jour uniquement l'URL du logo de l'organisation.
  Future<void> updateOrganizationLogo({
    required String orgId,
    required String? logoUrl,
  }) async {
    await _dataService.client
        .from('organizations')
        .update({'logo_url': logoUrl})
        .eq('id', orgId);
  }

  /// Met a jour uniquement la politique mobile d'une organisation.
  Future<void> updateOrganizationMobileAccess({
    required String orgId,
    required OrganizationMobileAccessPolicy policy,
  }) async {
    await _dataService.client.rpc(
      'platform_update_organization_mobile_access',
      params: {
        'p_org_id': orgId,
        'p_mode': policy.mode,
        'p_allowed_routes': policy.allowedRoutes,
      },
    );
  }

  /// Upload le logo dans le bucket public organization-assets.
  Future<String> uploadOrganizationLogo({
    required String orgId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final safeExtension = extension.toLowerCase() == 'jpeg'
        ? 'jpg'
        : extension.toLowerCase();
    final objectPath = '$orgId/branding/logo.$safeExtension';
    final bucket = _dataService.client.storage.from('organization-assets');

    await bucket.uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: contentType,
        cacheControl: '3600',
      ),
    );

    try {
      await deleteOrganizationLogoFiles(
        orgId: orgId,
        exceptExtension: safeExtension,
      );
    } catch (e) {
      if (!_isIgnorableStorageCleanupError(e)) rethrow;
    }

    final publicUrl = bucket.getPublicUrl(objectPath);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteOrganizationLogoFiles({
    required String orgId,
    String? exceptExtension,
  }) async {
    final skip = exceptExtension?.toLowerCase();
    final paths = _logoExtensions
        .where((extension) => extension != skip)
        .map((extension) => '$orgId/branding/logo.$extension')
        .toList();
    if (paths.isEmpty) return;

    await _dataService.client.storage.from('organization-assets').remove(paths);
  }

  /// Met à jour les couleurs du thème.
  Future<void> updateTheme({
    required String orgId,
    required String? couleurPrimaire,
    required String? couleurSecondaire,
  }) async {
    await _dataService.client
        .from('organizations')
        .update({
          'couleur_primaire': couleurPrimaire,
          'couleur_secondaire': couleurSecondaire,
        })
        .eq('id', orgId);
  }

  /// Marque des etapes d'onboarding comme completees.
  Future<void> completeOnboardingSteps({
    required String orgId,
    required List<String> completedSteps,
  }) async {
    if (completedSteps.isEmpty) return;

    try {
      await _dataService.client.rpc(
        'complete_organization_onboarding_steps',
        params: {'p_org_id': orgId, 'p_completed_steps': completedSteps},
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' ||
          e.message.contains('complete_organization_onboarding_steps')) {
        return;
      }
      rethrow;
    }
  }

  /// Invite un utilisateur par email.
  Future<void> inviteUser({
    required String orgId,
    required String email,
    required String role,
    String? primaryChurchUnitId,
    bool canManageChildren = false,
  }) async {
    await _dataService.client.rpc(
      'invite_user_to_org',
      params: {
        'p_org_id': orgId,
        'p_email': email,
        'p_role': role,
        'p_primary_church_unit_id': primaryChurchUnitId,
        'p_can_manage_children': canManageChildren,
      },
    );
  }

  Future<List<HierarchyPermission>> fetchEffectiveHierarchyPermissions({
    required String ancestorUnitId,
    required String descendantUnitId,
  }) async {
    try {
      final result = await _dataService.client.rpc(
        'get_effective_church_unit_permissions',
        params: {
          'p_ancestor_unit_id': ancestorUnitId,
          'p_descendant_unit_id': descendantUnitId,
        },
      );
      if (result is! List) return const [];
      return result
          .map(
            (json) => HierarchyPermission.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingHierarchyPermissionSchema(e)) return const [];
      rethrow;
    }
  }

  Future<String> setHierarchyPermissionOverride({
    required String ancestorUnitId,
    required String descendantUnitId,
    required String domainCode,
    required String actionCode,
    required bool allowed,
    required bool requiresDescendantAcceptance,
    String? reason,
  }) async {
    final result = await _dataService.client.rpc(
      'set_church_unit_permission_override',
      params: {
        'p_ancestor_unit_id': ancestorUnitId,
        'p_descendant_unit_id': descendantUnitId,
        'p_domain_code': domainCode,
        'p_action_code': actionCode,
        'p_allowed': allowed,
        'p_requires_descendant_acceptance': requiresDescendantAcceptance,
        'p_reason': _nullIfBlank(reason),
      },
    );
    return result?.toString() ?? '';
  }

  Future<List<UnitPermissionOverride>> fetchUnitPermissionOverrides() async {
    try {
      final response = await _dataService.client
          .from('church_unit_permission_overrides')
          .select('''
            id,
            ancestor_unit_id,
            descendant_unit_id,
            allowed,
            requires_descendant_acceptance,
            acceptance_status,
            reason,
            domain:church_permission_domains(code,label),
            action:church_permission_actions(code,label)
          ''')
          .eq('requires_descendant_acceptance', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                UnitPermissionOverride.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingHierarchyPermissionSchema(e)) return const [];
      rethrow;
    }
  }

  Future<void> respondHierarchyPermissionOverride({
    required String overrideId,
    required bool accept,
    String? reason,
  }) async {
    await _dataService.client.rpc(
      'respond_church_unit_permission_override',
      params: {
        'p_override_id': overrideId,
        'p_accept': accept,
        'p_reason': _nullIfBlank(reason),
      },
    );
  }

  /// Cree une organisation autonome pour un utilisateur sans tenant.
  Future<Map<String, dynamic>> createOrganizationOnboarding({
    required String name,
    String? sigle,
    String? description,
    String structureModel = 'single',
    String? rootUnitName,
    String? primaryColor,
    String? secondaryColor,
    String? logoUrl,
    Map<String, dynamic> contact = const {},
    List<String> skipSteps = const [],
    List<Map<String, dynamic>> customLevels = const [],
  }) async {
    final result = await _dataService.client.rpc(
      'create_organization_onboarding',
      params: {
        'p_name': name,
        'p_sigle': _nullIfBlank(sigle),
        'p_description': _nullIfBlank(description),
        'p_structure_model': structureModel,
        'p_root_unit_name': _nullIfBlank(rootUnitName),
        'p_primary_color': _nullIfBlank(primaryColor),
        'p_secondary_color': _nullIfBlank(secondaryColor),
        'p_logo_url': _nullIfBlank(logoUrl),
        'p_contact': contact,
        'p_skip_steps': skipSteps,
        'p_custom_levels': customLevels,
      },
    );

    if (result is Map<String, dynamic>) return result;
    if (result is Map) return Map<String, dynamic>.from(result);
    return <String, dynamic>{};
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isIgnorableStorageCleanupError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('not found') ||
        message.contains('does not exist') ||
        message.contains('resource was not found') ||
        message.contains('object not found');
  }

  bool _isMissingHierarchyPermissionSchema(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST202' ||
        message.contains('get_effective_church_unit_permissions') ||
        message.contains('church_unit_permission_overrides') ||
        message.contains('church_hierarchy_permission_rules') ||
        message.contains('permission schema');
  }
}

/// Repository pour la gestion des organisations.
library;

import 'dart:typed_data';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    await deleteOrganizationLogoFiles(
      orgId: orgId,
      exceptExtension: safeExtension,
    );

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
}

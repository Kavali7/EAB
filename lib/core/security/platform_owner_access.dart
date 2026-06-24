/// Platform owner access helpers.
///
/// This is intentionally separate from church roles such as `admin_national`.
/// A platform owner is a technical/business administrator of the SaaS itself,
/// identified through Supabase Auth app metadata.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformOwnerAccess {
  const PlatformOwnerAccess._();

  static bool isCurrentUserOwner(SupabaseClient client) {
    return isOwnerUser(client.auth.currentUser);
  }

  static bool isOwnerUser(User? user) {
    if (user == null) return false;
    return isOwnerIdentity(appMetadata: user.appMetadata);
  }

  static bool isOwnerIdentity({required Map<String, dynamic>? appMetadata}) {
    final metadata = appMetadata ?? const <String, dynamic>{};
    return _metadataGrantsOwner(metadata);
  }

  static bool _metadataGrantsOwner(Map<String, dynamic> metadata) {
    return _truthy(metadata['platform_owner']) ||
        _truthy(metadata['is_platform_owner']) ||
        _roleIsOwner(metadata['role']) ||
        _roleIsOwner(metadata['app_role']);
  }

  static bool _roleIsOwner(Object? value) {
    final role = value?.toString().trim().toLowerCase();
    return role == 'platform_owner' ||
        role == 'platform_admin' ||
        role == 'owner';
  }

  static bool _truthy(Object? value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}

/// Repository pour la gestion des organisations.
library;

import 'package:eab/core/services/supabase_data_service.dart';
import 'organization_model.dart';

class OrganizationRepository {
  OrganizationRepository(this._dataService);

  final SupabaseDataService _dataService;

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
        .update(org.toJson())
        .eq('id', org.id);
  }

  /// Met à jour les couleurs du thème.
  Future<void> updateTheme({
    required String orgId,
    required String? couleurPrimaire,
    required String? couleurSecondaire,
  }) async {
    await _dataService.client.from('organizations').update({
      'couleur_primaire': couleurPrimaire,
      'couleur_secondaire': couleurSecondaire,
    }).eq('id', orgId);
  }

  /// Invite un utilisateur par email.
  Future<void> inviteUser({
    required String orgId,
    required String email,
    required String role,
  }) async {
    // Appel RPC pour inviter un utilisateur
    await _dataService.client.rpc('invite_user_to_org', params: {
      'p_org_id': orgId,
      'p_email': email,
      'p_role': role,
    });
  }
}

/// Providers Riverpod pour la gestion des organisations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:eab/providers/data_service_provider.dart';
import '../data/organization_model.dart';
import '../data/organization_repository.dart';

/// Repository provider.
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  final ds = ref.read(dataServiceProvider) as SupabaseDataService;
  return OrganizationRepository(ds);
});

/// Organisation courante (chargée une fois au login).
final currentOrganizationProvider =
    AsyncNotifierProvider<CurrentOrganizationNotifier, Organization?>(
  CurrentOrganizationNotifier.new,
);

class CurrentOrganizationNotifier extends AsyncNotifier<Organization?> {
  @override
  Future<Organization?> build() async {
    final repo = ref.read(organizationRepositoryProvider);
    return repo.fetchCurrentOrganization();
  }

  /// Recharge les données de l'organisation.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(organizationRepositoryProvider);
      return repo.fetchCurrentOrganization();
    });
  }
}

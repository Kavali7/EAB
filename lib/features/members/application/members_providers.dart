/// Providers Riverpod pour la feature Membres.
///
/// Fournit le repository et un provider pour la liste filtrée des membres.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/data_service_provider.dart';
import 'package:eab/models/member.dart';
import '../data/members_repository.dart';

/// Repository injecté via le DataService courant.
final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  final ds = ref.watch(dataServiceProvider);
  return MembersRepository(ds);
});

/// Liste des membres avec recherche optionnelle (auto-dispose).
final membersListProvider =
    FutureProvider.autoDispose.family<List<Member>, String?>((ref, query) async {
  final repo = ref.watch(membersRepositoryProvider);
  return repo.list(search: query);
});

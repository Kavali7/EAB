/// Repository pour la feature Membres.
///
/// Encapsule l'accès aux données des fidèles via [DataService].
/// Ce wrapper permet de spécialiser la logique de requête
/// (filtrage, recherche, pagination) sans modifier le DataService.
library;

import 'package:eab/core/services/data_service.dart';
import 'package:eab/models/member.dart';

/// Repository des membres — couche d'accès aux données.
class MembersRepository {
  const MembersRepository(this._dataService);

  final DataService _dataService;

  /// Récupère tous les membres et filtre côté client.
  Future<List<Member>> list({String? search}) async {
    final all = await _dataService.getMembers();
    if (search == null || search.isEmpty) return all;
    final q = search.toLowerCase();
    return all.where((m) => m.fullName.toLowerCase().contains(q)).toList();
  }

  /// Ajoute un nouveau membre.
  Future<void> add(Member member) => _dataService.addMember(member);

  /// Met à jour un membre existant.
  Future<void> update(Member member) => _dataService.updateMember(member);

  /// Supprime un membre par son ID.
  Future<void> remove(String id) => _dataService.deleteMember(id);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/data_service.dart';
import '../models/member.dart';
import 'data_service_provider.dart';

final membersProvider = AsyncNotifierProvider<MembersNotifier, List<Member>>(
  MembersNotifier.new,
);

class MembersNotifier extends AsyncNotifier<List<Member>> {
  late final DataService _service;

  @override
  Future<List<Member>> build() async {
    _service = ref.read(dataServiceProvider);
    return _service.getMembers();
  }

  Future<void> addMember(Member member) async {
    await _service.addMember(member);
    final current = state.value ?? [];
    state = AsyncData([...current, member]);
  }

  Future<void> updateMember(Member member) async {
    await _service.updateMember(member);
    final current = state.value ?? [];
    state = AsyncData([
      for (final m in current)
        if (m.id == member.id) member else m,
    ]);
  }

  Future<void> removeMember(String id) async {
    await _service.deleteMember(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((m) => m.id != id).toList());
  }
}

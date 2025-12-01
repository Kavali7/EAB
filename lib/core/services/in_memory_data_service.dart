import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../models/accounting_entry.dart';
import '../../models/member.dart';
import '../../models/program.dart';
import 'data_service.dart';

class InMemoryDataService implements DataService {
  InMemoryDataService() {
    _seed();
  }

  final _members = <Member>[];
  final _programs = <Program>[];
  final _entries = <AccountingEntry>[];
  final _uuid = const Uuid();

  void _seed() {
    if (_members.isNotEmpty) return;
    final m1 = Member(
      id: _uuid.v4(),
      fullName: 'Paul Adokpo',
      gender: Gender.male,
      birthDate: DateTime(1988, 6, 12),
      maritalStatus: MaritalStatus.married,
      baptismDate: DateTime(2010, 9, 4),
      phone: '+229 61000001',
      email: 'paul.adokpo@example.com',
      address: 'Porto-Novo',
    );
    final m2 = Member(
      id: _uuid.v4(),
      fullName: 'Celine Houenou',
      gender: Gender.female,
      birthDate: DateTime(1992, 11, 2),
      maritalStatus: MaritalStatus.single,
      baptismDate: DateTime(2015, 2, 14),
      phone: '+229 62000002',
      email: 'celine.houenou@example.com',
      address: 'Cotonou',
    );
    final m3 = Member(
      id: _uuid.v4(),
      fullName: 'Samuel Tossou',
      gender: Gender.male,
      birthDate: DateTime(1999, 4, 18),
      maritalStatus: MaritalStatus.single,
      baptismDate: DateTime(2023, 8, 21),
      phone: '+229 63000003',
      address: 'Parakou',
    );
    _members.addAll([m1, m2, m3]);

    _programs.addAll([
      Program(
        id: _uuid.v4(),
        type: ProgramType.prayer,
        date: DateTime.now().add(const Duration(days: 3)),
        location: 'Temple central',
        description: 'Veillee de priere et intercession',
        observations: 'Mettre l accent sur les nouveaux convertis',
        participantIds: [m1.id, m2.id],
      ),
      Program(
        id: _uuid.v4(),
        type: ProgramType.evangelization,
        date: DateTime.now().add(const Duration(days: 14)),
        location: 'Marché de Calavi',
        description: 'Campagne d’evangelisation locale',
        observations: 'Prevoir sono mobile',
        participantIds: [m1.id],
      ),
    ]);

    _entries.addAll([
      AccountingEntry(
        id: _uuid.v4(),
        date: DateTime.now().subtract(const Duration(days: 3)),
        amount: 150000,
        type: AccountingType.income,
        category: 'Dimes',
        description: 'Collecte principale du culte',
        paymentMethod: 'Especes',
      ),
      AccountingEntry(
        id: _uuid.v4(),
        date: DateTime.now().subtract(const Duration(days: 2)),
        amount: 40000,
        type: AccountingType.expense,
        category: 'Facture electricite',
        description: 'Reglement facture SBEE',
        paymentMethod: 'Virement',
      ),
      AccountingEntry(
        id: _uuid.v4(),
        date: DateTime.now().subtract(const Duration(days: 15)),
        amount: 90000,
        type: AccountingType.income,
        category: 'Offrandes ordinaires',
        description: 'Culte jeunesse',
        paymentMethod: 'Especes',
      ),
      AccountingEntry(
        id: _uuid.v4(),
        date: DateTime.now().subtract(const Duration(days: 20)),
        amount: 25000,
        type: AccountingType.expense,
        category: 'Achat de chaises',
        description: 'Achat pour salle des enfants',
        paymentMethod: 'Mobile money',
      ),
    ]);
  }

  @override
  Future<void> addAccountingEntry(AccountingEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<void> addMember(Member member) async {
    _members.add(member);
  }

  @override
  Future<void> addProgram(Program program) async {
    _programs.add(program);
  }

  @override
  Future<void> deleteAccountingEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteMember(String id) async {
    _members.removeWhere((m) => m.id == id);
    // Remove orphaned participant ids.
    for (var i = 0; i < _programs.length; i++) {
      final program = _programs[i];
      _programs[i] = program.copyWith(
        participantIds: program.participantIds
            .where((pid) => pid != id)
            .toList(),
      );
    }
  }

  @override
  Future<void> deleteProgram(String id) async {
    _programs.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<AccountingEntry>> getAccountingEntries() async {
    return List<AccountingEntry>.unmodifiable(_entries);
  }

  @override
  Future<List<Member>> getMembers() async {
    return List<Member>.unmodifiable(_members);
  }

  @override
  Future<List<Program>> getPrograms() async {
    return List<Program>.unmodifiable(_programs);
  }

  @override
  Future<void> updateAccountingEntry(AccountingEntry entry) async {
    _entries
      ..removeWhere((e) => e.id == entry.id)
      ..add(entry);
  }

  @override
  Future<void> updateMember(Member member) async {
    _members
      ..removeWhere((m) => m.id == member.id)
      ..add(member);
  }

  @override
  Future<void> updateProgram(Program program) async {
    _programs
      ..removeWhere((p) => p.id == program.id)
      ..add(program);
  }
}

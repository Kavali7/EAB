import '../../models/accounting_entry.dart';
import '../../models/member.dart';
import '../../models/program.dart';
import 'data_service.dart';

/// Placeholder for the future Supabase/PostgreSQL implementation.
class SupabaseDataService implements DataService {
  const SupabaseDataService();

  Never _notImplemented() =>
      throw UnimplementedError('Supabase integration sera branchee plus tard.');

  @override
  Future<void> addAccountingEntry(AccountingEntry entry) async =>
      _notImplemented();

  @override
  Future<void> addMember(Member member) async => _notImplemented();

  @override
  Future<void> addProgram(Program program) async => _notImplemented();

  @override
  Future<void> deleteAccountingEntry(String id) async => _notImplemented();

  @override
  Future<void> deleteMember(String id) async => _notImplemented();

  @override
  Future<void> deleteProgram(String id) async => _notImplemented();

  @override
  Future<List<AccountingEntry>> getAccountingEntries() async =>
      _notImplemented();

  @override
  Future<List<Member>> getMembers() async => _notImplemented();

  @override
  Future<List<Program>> getPrograms() async => _notImplemented();

  @override
  Future<void> updateAccountingEntry(AccountingEntry entry) async =>
      _notImplemented();

  @override
  Future<void> updateMember(Member member) async => _notImplemented();

  @override
  Future<void> updateProgram(Program program) async => _notImplemented();
}

import '../../models/accounting_entry.dart';
import '../../models/member.dart';
import '../../models/program.dart';

abstract class DataService {
  Future<List<Member>> getMembers();
  Future<void> addMember(Member member);
  Future<void> updateMember(Member member);
  Future<void> deleteMember(String id);

  Future<List<Program>> getPrograms();
  Future<void> addProgram(Program program);
  Future<void> updateProgram(Program program);
  Future<void> deleteProgram(String id);

  Future<List<AccountingEntry>> getAccountingEntries();
  Future<void> addAccountingEntry(AccountingEntry entry);
  Future<void> updateAccountingEntry(AccountingEntry entry);
  Future<void> deleteAccountingEntry(String id);
}

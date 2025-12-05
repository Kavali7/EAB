import '../../models/accounting_entry.dart';
import '../../models/famille.dart';
import '../../models/member.dart';
import '../../models/region_eglise.dart';
import '../../models/district_eglise.dart';
import '../../models/assemblee_locale.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/program.dart';
import 'data_service.dart';

/// Placeholder for the future Supabase/PostgreSQL implementation.
class SupabaseDataService implements DataService {
  const SupabaseDataService();

  Never _notImplemented() =>
      throw UnimplementedError('Supabase integration sera branchee plus tard.');

  @override
  Future<List<Famille>> getFamilies() async => _notImplemented();

  @override
  Future<List<RegionEglise>> getRegions() async => _notImplemented();

  @override
  Future<List<DistrictEglise>> getDistricts() async => _notImplemented();

  @override
  Future<List<AssembleeLocale>> getAssembleesLocales() async =>
      _notImplemented();

  @override
  Future<List<ProfilUtilisateur>> getProfilsUtilisateurs() =>
      throw UnimplementedError(
        'getProfilsUtilisateurs() non implemente pour Supabase (simulation uniquement).',
      );

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

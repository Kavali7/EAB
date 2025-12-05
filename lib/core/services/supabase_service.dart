import '../../models/accounting_entry.dart';
import '../../models/famille.dart';
import '../../models/member.dart';
import '../../models/region_eglise.dart';
import '../../models/district_eglise.dart';
import '../../models/assemblee_locale.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/program.dart';
import '../../models/compte_comptable.dart';
import '../../models/journal_comptable.dart';
import '../../models/centre_analytique.dart';
import '../../models/tiers.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/budget_comptable.dart';
import '../../models/immobilisation_comptable.dart';
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

  @override
  Future<List<CompteComptable>> getComptesComptables() {
    throw UnimplementedError(
      'getComptesComptables() non implemente pour Supabase.',
    );
  }

  @override
  Future<List<JournalComptable>> getJournauxComptables() {
    throw UnimplementedError(
      'getJournauxComptables() non implemente pour Supabase.',
    );
  }

  @override
  Future<List<CentreAnalytique>> getCentresAnalytiques() {
    throw UnimplementedError(
      'getCentresAnalytiques() non implemente pour Supabase.',
    );
  }

  @override
  Future<List<Tiers>> getTiers() {
    throw UnimplementedError(
      'getTiers() non implemente pour Supabase.',
    );
  }

  @override
  Future<List<EcritureComptable>> getEcrituresComptables() {
    throw UnimplementedError(
      'getEcrituresComptables() non implemente pour Supabase.',
    );
  }

  @override
  Future<List<BudgetComptable>> getBudgetsComptables() {
    throw UnimplementedError(
      'getBudgetsComptables() non implemente pour Supabase (phase frontend uniquement).',
    );
  }

  @override
  Future<List<LigneBudgetComptable>> getLignesBudgetsComptables() {
    throw UnimplementedError(
      'getLignesBudgetsComptables() non implemente pour Supabase (phase frontend uniquement).',
    );
  }

  @override
  Future<List<ImmobilisationComptable>> getImmobilisationsComptables() {
    throw UnimplementedError(
      'getImmobilisationsComptables() non implemente pour Supabase (phase frontend uniquement).',
    );
  }
}

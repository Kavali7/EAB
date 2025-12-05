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

abstract class DataService {
  Future<List<Famille>> getFamilies();
  Future<List<RegionEglise>> getRegions();
  Future<List<DistrictEglise>> getDistricts();
  Future<List<AssembleeLocale>> getAssembleesLocales();
  Future<List<ProfilUtilisateur>> getProfilsUtilisateurs();

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

  Future<List<CompteComptable>> getComptesComptables();
  Future<List<JournalComptable>> getJournauxComptables();
  Future<List<CentreAnalytique>> getCentresAnalytiques();
  Future<List<Tiers>> getTiers();
  Future<List<EcritureComptable>> getEcrituresComptables();
  Future<List<BudgetComptable>> getBudgetsComptables();
  Future<List<LigneBudgetComptable>> getLignesBudgetsComptables();
}

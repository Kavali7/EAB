import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/product_branding.dart';
import '../core/theme.dart';
import '../providers/accounting_providers.dart';
import '../providers/church_structure_providers.dart';
import '../providers/families_provider.dart';
import '../providers/members_provider.dart';
import '../providers/programs_provider.dart';
import '../providers/user_profile_providers.dart';
import '../features/church_units/application/church_units_provider.dart';
import '../features/organization/application/organization_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/accounting/accounting_screen.dart';
import '../features/dashboard/presentation/dashboard_screen_v2.dart';
import '../features/members/presentation/members_screen_v2.dart';
import '../features/programs/presentation/programs_screen_v2.dart';
import '../screens/church_structure/church_structure_screen.dart';
import '../screens/accounting/accounting_settings_screen.dart';
import '../screens/accounting/accounting_budgets_screen.dart';
import '../screens/accounting/accounting_immobilisations_screen.dart';
import '../screens/accounting/accounting_treasury_screen.dart';
import '../screens/accounting/accounting_reconciliation_screen.dart';
import '../screens/accounting/accounting_reports_screen.dart';
import '../screens/reports/rapport_mensuel_eab_screen.dart';
import '../features/exercices/presentation/exercices_screen.dart';
import '../features/etats_financiers/presentation/etats_financiers_screen.dart';
import '../features/organization/presentation/organization_settings_screen.dart';
import '../features/dashboard_finance/dashboard_finance_screen.dart';
import '../features/audit/presentation/audit_log_screen.dart';
import '../features/programs/presentation/calendar_screen.dart';
import '../features/fiscal_dossier/presentation/fiscal_dossiers_screen.dart';
import '../features/fiscal_dossier/presentation/fiscal_wizard_screen.dart';
import '../features/fiscal_dossier/presentation/fiscal_import_screen.dart';

class ChurchApp extends ConsumerStatefulWidget {
  const ChurchApp({super.key});

  @override
  ConsumerState<ChurchApp> createState() => _ChurchAppState();
}

class _ChurchAppState extends ConsumerState<ChurchApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    // Écouter les changements d'état d'auth (login, logout, token refresh)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final hasSession = data.session != null;

      // Ignorer TOKEN_REFRESH pour ne pas forcer de redirect
      if (event == AuthChangeEvent.tokenRefreshed) return;

      if (event == AuthChangeEvent.signedOut && _isLoggedIn) {
        setState(() => _isLoggedIn = false);
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else if (event == AuthChangeEvent.signedIn && !_isLoggedIn) {
        // Invalider TOUS les providers pour forcer le rechargement
        // avec la nouvelle session authentifiée
        _invalidateAllProviders();

        setState(() => _isLoggedIn = true);
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      } else if (hasSession && !_isLoggedIn) {
        // Fallback : si on a une session mais l'état dit non-connecté
        _invalidateAllProviders();
        setState(() => _isLoggedIn = true);
      }
    });
  }

  /// Invalide tous les providers data pour forcer le rechargement
  /// après un changement d'état d'authentification.
  void _invalidateAllProviders() {
    ref.invalidate(profilsUtilisateursProvider);
    ref.invalidate(membersProvider);
    ref.invalidate(programsProvider);
    ref.invalidate(familiesProvider);
    ref.invalidate(regionsProvider);
    ref.invalidate(districtsProvider);
    ref.invalidate(assembleesLocalesProvider);
    ref.invalidate(churchUnitsProvider);
    ref.invalidate(ecrituresComptablesProvider);
    ref.invalidate(journauxComptablesProvider);
    ref.invalidate(comptesComptablesProvider);
    ref.invalidate(centresAnalytiquesProvider);
    ref.invalidate(tiersProvider);
    ref.invalidate(budgetsComptablesProvider);
    ref.invalidate(lignesBudgetsProvider);
    ref.invalidate(immobilisationsComptablesProvider);
    ref.invalidate(currentOrganizationProvider);
    // Réinitialiser le profil courant et l'assemblée active
    // (invalidate appelle build() qui retourne null)
    ref.invalidate(profilUtilisateurCourantProvider);
    ref.invalidate(assembleeActiveIdProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ProductBranding.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildAppTheme(),
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 599, name: MOBILE),
            Breakpoint(start: 600, end: 1023, name: TABLET),
            Breakpoint(start: 1024, end: 1440, name: DESKTOP),
            Breakpoint(start: 1441, end: double.infinity, name: 'XL'),
          ],
        );
      },
      initialRoute: _isLoggedIn ? '/' : '/login',
      routes: {
        // Auth
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        // App
        '/': (_) => const DashboardScreenV2(),
        '/members': (_) => const MembersScreenV2(),
        '/programs': (_) => const ProgramsScreenV2(),
        '/accounting': (_) => const AccountingScreen(),
        '/structure': (_) => const ChurchStructureScreen(),
        '/accounting-settings': (_) => const AccountingSettingsScreen(),
        '/accounting-budgets': (_) => const AccountingBudgetsScreen(),
        '/accounting-immobilisations': (_) =>
            const AccountingImmobilisationsScreen(),
        '/accounting-treasury': (_) => const AccountingTreasuryScreen(),
        '/accounting-reconciliation': (_) =>
            const AccountingReconciliationScreen(),
        '/accounting-reports': (_) => const AccountingReportsScreen(),
        '/accounting-exercices': (_) => const ExercicesScreen(),
        '/etats-financiers': (_) => const EtatsFinanciersScreen(),
        '/organization-settings': (_) => const OrganizationSettingsScreen(),
        '/dashboard-finance': (_) => const DashboardFinanceScreen(),
        '/reports-rapport-mensuel': (_) => const RapportMensuelEabScreen(),
        '/audit-log': (_) => const AuditLogScreen(),
        '/calendar': (_) => const CalendarScreen(),
        '/fiscal-dossiers': (_) => const FiscalDossiersScreen(),
        '/fiscal-import-balance': (_) => const FiscalImportScreen(),
      },
      onGenerateRoute: (settings) {
        // Route paramétrée : /fiscal-dossier/:id
        final uri = Uri.parse(settings.name ?? '');
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments[0] == 'fiscal-dossier') {
          final dossierId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => FiscalWizardScreen(dossierId: dossierId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

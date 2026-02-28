import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
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

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur est connecté
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return MaterialApp(
      title: 'EAB - Gestion',
      debugShowCheckedModeBanner: false,
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
      initialRoute: isLoggedIn ? '/' : '/login',
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
        '/reports-rapport-mensuel': (_) => const RapportMensuelEabScreen(),
      },
    );
  }
}


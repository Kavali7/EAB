import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/theme.dart';
import 'screens/accounting/accounting_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/members/members_screen.dart';
import 'screens/programs/programs_screen.dart';
import 'screens/church_structure/church_structure_screen.dart';
import 'screens/accounting/accounting_settings_screen.dart';
import 'screens/accounting/accounting_budgets_screen.dart';
import 'screens/accounting/accounting_immobilisations_screen.dart';
import 'screens/accounting/accounting_treasury_screen.dart';
import 'screens/accounting/accounting_reconciliation_screen.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion EAB',
      debugShowCheckedModeBanner: false,
      theme: ChurchTheme.lightTheme,
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
      routes: {
        '/': (_) => const DashboardScreen(),
        '/members': (_) => const MembersScreen(),
        '/programs': (_) => const ProgramsScreen(),
        '/accounting': (_) => const AccountingScreen(),
        '/structure': (_) => const ChurchStructureScreen(),
        '/accounting-settings': (_) => const AccountingSettingsScreen(),
        '/accounting-budgets': (_) => const AccountingBudgetsScreen(),
        '/accounting-immobilisations': (_) =>
            const AccountingImmobilisationsScreen(),
        '/accounting-treasury': (_) => const AccountingTreasuryScreen(),
        '/accounting-reconciliation': (_) =>
            const AccountingReconciliationScreen(),
      },
    );
  }
}

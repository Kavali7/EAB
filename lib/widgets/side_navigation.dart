import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../features/organization/application/organization_providers.dart';

class SideNavigation extends ConsumerWidget {
  const SideNavigation({super.key, required this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final orgName = orgAsync.value?.nom ?? 'EAB';
    const items = [
      _NavItem('Tableau de bord', '/', Icons.dashboard_outlined),
      _NavItem('Dashboard financier', '/dashboard-finance', Icons.insights),
      _NavItem('Fideles', '/members', Icons.people_alt_outlined),
      _NavItem('Programmes', '/programs', Icons.event_note_outlined),
      _NavItem('Structure de l\'Eglise', '/structure', Icons.account_tree_outlined),
      _NavItem(
        'Comptabilite',
        '/accounting',
        Icons.account_balance_wallet_outlined,
      ),
      _NavItem(
        'Tresorerie',
        '/accounting-treasury',
        Icons.account_balance_wallet,
      ),
      _NavItem(
        'Rapprochement bancaire',
        '/accounting-reconciliation',
        Icons.compare_arrows,
      ),
      _NavItem(
        'Etats & exports',
        '/accounting-reports',
        Icons.assessment_outlined,
      ),
      _NavItem(
        'Rapport mensuel EAB',
        '/reports-rapport-mensuel',
        Icons.description_outlined,
      ),
      _NavItem(
        'Budgets',
        '/accounting-budgets',
        Icons.insert_chart_outlined,
      ),
      _NavItem(
        'Immobilisations',
        '/accounting-immobilisations',
        Icons.inventory_2_outlined,
      ),
      _NavItem(
        'Parametrage comptable',
        '/accounting-settings',
        Icons.tune,
      ),
      _NavItem(
        'Exercices comptables',
        '/accounting-exercices',
        Icons.calendar_today_outlined,
      ),
      _NavItem(
        'États financiers',
        '/etats-financiers',
        Icons.bar_chart_outlined,
      ),
      _NavItem(
        'Organisation',
        '/organization-settings',
        Icons.settings_outlined,
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  orgName,
                  style: TextStyle(
                    color: ChurchTheme.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              ...items.map((item) {
                final selected = currentRoute == item.route;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: selected ? ChurchTheme.gold : Colors.grey[700],
                  ),
                  title: Text(item.label),
                  selected: selected,
                  onTap: () {
                    if (currentRoute == item.route) return;
                    Navigator.of(context).pushReplacementNamed(item.route);
                  },
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Déconnexion',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}


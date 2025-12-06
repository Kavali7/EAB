import 'package:flutter/material.dart';
import '../core/theme.dart';

class SideNavigation extends StatelessWidget {
  const SideNavigation({super.key, required this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem('Tableau de bord', '/', Icons.dashboard_outlined),
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
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'EAB',
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
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

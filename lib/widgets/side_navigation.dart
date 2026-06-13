import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../features/organization/application/organization_providers.dart';
import '../ui/theme/organisation_branding.dart';

class SideNavigation extends ConsumerWidget {
  const SideNavigation({super.key, required this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final branding = OrganisationBranding.fromOrganization(orgAsync.value);

    return Container(
      color: AppColors.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  _BrandMark(branding: branding),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branding.sigle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          branding.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.sidebarMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x1FFFFFFF)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: const [
                  _NavSection(
                    label: 'Pilotage',
                    items: [
                      _NavItem(
                        'Tableau de bord',
                        '/',
                        Icons.dashboard_outlined,
                      ),
                      _NavItem(
                        'Finance',
                        '/dashboard-finance',
                        Icons.insights_outlined,
                      ),
                      _NavItem(
                        'Calendrier',
                        '/calendar',
                        Icons.calendar_month_outlined,
                      ),
                    ],
                  ),
                  _NavSection(
                    label: 'Vie de l\'eglise',
                    items: [
                      _NavItem(
                        'Fideles',
                        '/members',
                        Icons.people_alt_outlined,
                      ),
                      _NavItem(
                        'Programmes',
                        '/programs',
                        Icons.event_note_outlined,
                      ),
                      _NavItem(
                        'Structure',
                        '/structure',
                        Icons.account_tree_outlined,
                      ),
                      _NavItem(
                        'Rapport mensuel',
                        '/reports-rapport-mensuel',
                        Icons.description_outlined,
                      ),
                    ],
                  ),
                  _NavSection(
                    label: 'Comptabilite',
                    items: [
                      _NavItem(
                        'Ecritures',
                        '/accounting',
                        Icons.account_balance_wallet_outlined,
                      ),
                      _NavItem(
                        'Tresorerie',
                        '/accounting-treasury',
                        Icons.payments_outlined,
                      ),
                      _NavItem(
                        'Rapprochement',
                        '/accounting-reconciliation',
                        Icons.compare_arrows,
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
                        'Etats & exports',
                        '/accounting-reports',
                        Icons.assessment_outlined,
                      ),
                      _NavItem(
                        'Etats financiers',
                        '/etats-financiers',
                        Icons.bar_chart_outlined,
                      ),
                      _NavItem(
                        'Exercices',
                        '/accounting-exercices',
                        Icons.event_available_outlined,
                      ),
                    ],
                  ),
                  _NavSection(
                    label: 'Conformite',
                    items: [
                      _NavItem(
                        'Dossier fiscal',
                        '/fiscal-dossiers',
                        Icons.request_page_outlined,
                      ),
                      _NavItem(
                        'Journal d\'audit',
                        '/audit-log',
                        Icons.history_outlined,
                      ),
                    ],
                  ),
                  _NavSection(
                    label: 'Administration',
                    items: [
                      _NavItem(
                        'Organisation',
                        '/organization-settings',
                        Icons.settings_outlined,
                      ),
                      _NavItem(
                        'Parametrage comptable',
                        '/accounting-settings',
                        Icons.tune,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x1FFFFFFF)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _LogoutTile(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.branding});

  final OrganisationBranding branding;

  @override
  Widget build(BuildContext context) {
    final logoUrl = branding.logoUrl;
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AppRadius.mdAll,
      ),
      child: logoUrl == null
          ? const Icon(Icons.church, color: AppColors.primaryDark, size: 24)
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.church,
                color: AppColors.primaryDark,
                size: 24,
              ),
            ),
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({required this.label, required this.items});

  final String label;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final navigation = context.findAncestorWidgetOfExactType<SideNavigation>();
    final currentRoute = navigation?.currentRoute;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.sidebarMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          for (final item in items)
            _NavTile(item: item, selected: currentRoute == item.route),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFD6E1E6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? const Color(0xFF164557) : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: () {
            if (selected) return;
            Navigator.of(context).pushReplacementNamed(item.route);
          },
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: selected
                  ? Border.all(color: const Color(0x334FC3D7))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x12FFFFFF),
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFFFB4A8), size: 20),
              SizedBox(width: 10),
              Text(
                'Deconnexion',
                style: TextStyle(
                  color: Color(0xFFFFD3CC),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

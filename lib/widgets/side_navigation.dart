import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/security/platform_owner_access.dart';
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
    final isPlatformOwner = PlatformOwnerAccess.isCurrentUserOwner(
      Supabase.instance.client,
    );
    final mobilePolicy = orgAsync.value?.mobileAccessPolicy;
    final mobileAllowedRoutes =
        MediaQuery.of(context).size.width < 700 &&
            (mobilePolicy?.isRestricted ?? false)
        ? mobilePolicy!.allowedRoutes
        : null;
    final colors = Theme.of(context).colorScheme;
    final sidebarColor = Color.lerp(colors.primary, Colors.black, 0.42)!;

    return Container(
      color: sidebarColor,
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
                children: [
                  _NavMenuGroup(
                    label: 'Pilotage',
                    caption: 'Vue globale',
                    icon: Icons.space_dashboard_outlined,
                    allowedRoutes: mobileAllowedRoutes,
                    items: [
                      _NavItem(
                        'Tableau de bord',
                        '/',
                        Icons.dashboard_outlined,
                      ),
                      _NavItem(
                        'Synthese finance',
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
                  _NavMenuGroup(
                    label: 'Vie de l\'eglise',
                    caption: 'Fideles et activites',
                    icon: Icons.church_outlined,
                    allowedRoutes: mobileAllowedRoutes,
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
                  _NavMenuGroup(
                    label: 'Finance & collectes',
                    caption: 'Encaissements et suivi',
                    icon: Icons.savings_outlined,
                    allowedRoutes: mobileAllowedRoutes,
                    items: [
                      _NavItem(
                        'Collectes & promesses',
                        '/financial-campaigns',
                        Icons.savings_outlined,
                      ),
                      _NavItem(
                        'Tresorerie',
                        '/accounting-treasury',
                        Icons.payments_outlined,
                      ),
                      _NavItem(
                        'Budgets',
                        '/accounting-budgets',
                        Icons.insert_chart_outlined,
                      ),
                    ],
                  ),
                  _NavMenuGroup(
                    label: 'Comptabilite',
                    caption: 'SYSCEBNL et controles',
                    icon: Icons.account_balance_outlined,
                    allowedRoutes: mobileAllowedRoutes,
                    items: [
                      _NavItem(
                        'Ecritures',
                        '/accounting',
                        Icons.account_balance_wallet_outlined,
                      ),
                      _NavItem(
                        'Rapprochement',
                        '/accounting-reconciliation',
                        Icons.compare_arrows,
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
                        'Exercices',
                        '/accounting-exercices',
                        Icons.event_available_outlined,
                      ),
                    ],
                  ),
                  _NavMenuGroup(
                    label: 'Fiscalite & rapports',
                    caption: 'Documents officiels',
                    icon: Icons.fact_check_outlined,
                    allowedRoutes: mobileAllowedRoutes,
                    items: [
                      _NavItem(
                        'Etats financiers',
                        '/etats-financiers',
                        Icons.bar_chart_outlined,
                      ),
                      _NavItem(
                        'Dossier fiscal',
                        '/fiscal-dossiers',
                        Icons.request_page_outlined,
                      ),
                      _NavItem(
                        'Import balance',
                        '/fiscal-import-balance',
                        Icons.upload_file_outlined,
                      ),
                    ],
                  ),
                  _NavMenuGroup(
                    label: 'Administration',
                    caption: 'Reglages et securite',
                    icon: Icons.admin_panel_settings_outlined,
                    allowedRoutes: mobileAllowedRoutes,
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
                      _NavItem(
                        'Journal d\'audit',
                        '/audit-log',
                        Icons.history_outlined,
                      ),
                    ],
                  ),
                  if (isPlatformOwner)
                    _NavMenuGroup(
                      label: 'Proprietaire',
                      caption: 'Pilotage plateforme',
                      icon: Icons.verified_user_outlined,
                      allowedRoutes: mobileAllowedRoutes,
                      items: [
                        _NavItem(
                          'Console plateforme',
                          '/platform-admin',
                          Icons.admin_panel_settings_outlined,
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: AppRadius.mdAll,
      ),
      child: logoUrl == null
          ? Icon(Icons.church, color: colors.onSecondary, size: 24)
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.church, color: colors.onSecondary, size: 24),
            ),
    );
  }
}

class _NavMenuGroup extends StatelessWidget {
  const _NavMenuGroup({
    required this.label,
    required this.caption,
    required this.icon,
    required this.items,
    this.allowedRoutes,
  });

  final String label;
  final String caption;
  final IconData icon;
  final List<_NavItem> items;
  final List<String>? allowedRoutes;

  @override
  Widget build(BuildContext context) {
    final navigation = context.findAncestorWidgetOfExactType<SideNavigation>();
    final currentRoute = navigation?.currentRoute;
    final visibleItems = allowedRoutes == null
        ? items
        : items
              .where((item) => _routeAllowed(item.route, allowedRoutes!))
              .toList(growable: false);

    if (visibleItems.isEmpty) return const SizedBox.shrink();
    final selected = visibleItems.any((item) {
      return _routeSelected(currentRoute, item.route);
    });
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.035),
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected
                ? colors.secondary.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.secondary.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: selected
                          ? colors.secondary
                          : AppColors.sidebarMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.sidebarMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    children: [
                      for (final item in visibleItems)
                        _NavTile(
                          item: item,
                          selected: _routeSelected(currentRoute, item.route),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _routeAllowed(String route, List<String> routes) {
    for (final allowed in routes) {
      if (route == allowed) return true;
    }
    return false;
  }

  bool _routeSelected(String? currentRoute, String route) {
    final current = currentRoute == null || currentRoute.isEmpty
        ? '/'
        : currentRoute;
    if (route == '/') return current == '/';
    return current == route || current.startsWith('$route/');
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? Colors.white : const Color(0xFFD6E1E6);
    final selectedBg = Color.lerp(colors.primary, Colors.black, 0.22)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? selectedBg : Colors.transparent,
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
                  ? Border.all(color: colors.secondary.withValues(alpha: 0.45))
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
                    decoration: BoxDecoration(
                      color: colors.secondary,
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

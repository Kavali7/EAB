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
    final isMobile = MediaQuery.of(context).size.width < 700;
    final mobileAllowedRoutes =
        isMobile && (mobilePolicy?.isRestricted ?? false)
        ? mobilePolicy!.allowedRoutes
        : null;
    final groups = _navigationGroups(isPlatformOwner);
    final sidebarColor = Color.lerp(
      Theme.of(context).colorScheme.primary,
      Colors.black,
      0.42,
    )!;

    if (MediaQuery.of(context).size.width >= 1100) {
      return _DesktopNavigation(
        branding: branding,
        groups: groups,
        currentRoute: currentRoute,
        sidebarColor: sidebarColor,
      );
    }

    return _CompactNavigation(
      branding: branding,
      groups: groups,
      currentRoute: currentRoute,
      allowedRoutes: mobileAllowedRoutes,
      sidebarColor: sidebarColor,
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.branding,
    required this.groups,
    required this.currentRoute,
    required this.sidebarColor,
  });

  final OrganisationBranding branding;
  final List<_NavMenuData> groups;
  final String? currentRoute;
  final Color sidebarColor;

  @override
  Widget build(BuildContext context) {
    final activeGroup = _activeGroup(groups, currentRoute);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _DesktopModuleRail(
              branding: branding,
              groups: groups,
              activeGroup: activeGroup,
              currentRoute: currentRoute,
              sidebarColor: sidebarColor,
            ),
            Expanded(
              child: _DesktopCommandPanel(
                branding: branding,
                group: activeGroup,
                currentRoute: currentRoute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NavMenuData _activeGroup(List<_NavMenuData> groups, String? currentRoute) {
    for (final group in groups) {
      if (group.items.any((item) => _routeSelected(currentRoute, item.route))) {
        return group;
      }
    }
    return groups.first;
  }
}

class _DesktopModuleRail extends StatelessWidget {
  const _DesktopModuleRail({
    required this.branding,
    required this.groups,
    required this.activeGroup,
    required this.currentRoute,
    required this.sidebarColor,
  });

  final OrganisationBranding branding;
  final List<_NavMenuData> groups;
  final _NavMenuData activeGroup;
  final String? currentRoute;
  final Color sidebarColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 74,
      color: sidebarColor,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Tooltip(
            message: branding.nom,
            child: _BrandMark(branding: branding, compact: true),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final group = groups[index];
                final selected = group == activeGroup;
                return Tooltip(
                  message: group.label,
                  waitDuration: const Duration(milliseconds: 350),
                  child: Material(
                    color: selected
                        ? colors.secondary.withValues(alpha: 0.24)
                        : Colors.transparent,
                    borderRadius: AppRadius.mdAll,
                    child: InkWell(
                      borderRadius: AppRadius.mdAll,
                      onTap: () {
                        final target = group.items.first.route;
                        if (_routeSelected(currentRoute, target)) return;
                        Navigator.of(context).pushReplacementNamed(target);
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: selected
                                ? colors.secondary.withValues(alpha: 0.42)
                                : Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          group.icon,
                          size: 22,
                          color: selected
                              ? Colors.white
                              : AppColors.sidebarMuted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 12),
            child: Tooltip(
              message: 'Deconnexion',
              child: Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
                child: InkWell(
                  borderRadius: AppRadius.mdAll,
                  onTap: () => _signOut(context),
                  child: const SizedBox(
                    height: 44,
                    child: Icon(
                      Icons.logout,
                      color: Color(0xFFFFC7BD),
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopCommandPanel extends StatelessWidget {
  const _DesktopCommandPanel({
    required this.branding,
    required this.group,
    required this.currentRoute,
  });

  final OrganisationBranding branding;
  final _NavMenuData group;
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branding.sigle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                branding.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: _ModuleHeader(group: group),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (final item in group.items)
                _DesktopCommandTile(
                  item: item,
                  selected: _routeSelected(currentRoute, item.route),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.06),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.keyboard_command_key, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ctrl + K  Recherche globale',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.group});

  final _NavMenuData group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(group.icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle,
              ),
              Text(
                group.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopCommandTile extends StatelessWidget {
  const _DesktopCommandTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.09)
            : Colors.transparent,
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
              border: Border.all(
                color: selected
                    ? colors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceElevated,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    item.icon,
                    size: 17,
                    color: selected ? colors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
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

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.branding,
    required this.groups,
    required this.currentRoute,
    required this.allowedRoutes,
    required this.sidebarColor,
  });

  final OrganisationBranding branding;
  final List<_NavMenuData> groups;
  final String? currentRoute;
  final List<String>? allowedRoutes;
  final Color sidebarColor;

  @override
  Widget build(BuildContext context) {
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
                          style: const TextStyle(
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
                  for (final group in groups)
                    _NavMenuGroup(
                      data: group,
                      currentRoute: currentRoute,
                      allowedRoutes: allowedRoutes,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x1FFFFFFF)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _LogoutTile(onTap: () => _signOut(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.branding, this.compact = false});

  final OrganisationBranding branding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoUrl = branding.logoUrl;
    final colors = Theme.of(context).colorScheme;
    final size = compact ? 42.0 : 42.0;

    return Container(
      width: size,
      height: size,
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
    required this.data,
    required this.currentRoute,
    this.allowedRoutes,
  });

  final _NavMenuData data;
  final String? currentRoute;
  final List<String>? allowedRoutes;

  @override
  Widget build(BuildContext context) {
    final visibleItems = allowedRoutes == null
        ? data.items
        : data.items
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
                      data.icon,
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
                          data.label,
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
                          data.caption,
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

class _NavMenuData {
  const _NavMenuData({
    required this.label,
    required this.caption,
    required this.icon,
    required this.items,
  });

  final String label;
  final String caption;
  final IconData icon;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

List<_NavMenuData> _navigationGroups(bool isPlatformOwner) => [
  const _NavMenuData(
    label: 'Accueil',
    caption: 'Pilotage general',
    icon: Icons.space_dashboard_outlined,
    items: [
      _NavItem('Tableau de bord', '/', Icons.dashboard_outlined),
      _NavItem(
        'Synthese finance',
        '/dashboard-finance',
        Icons.insights_outlined,
      ),
      _NavItem('Calendrier', '/calendar', Icons.calendar_month_outlined),
    ],
  ),
  const _NavMenuData(
    label: 'Vie de l\'eglise',
    caption: 'Fideles et activites',
    icon: Icons.church_outlined,
    items: [
      _NavItem('Fideles', '/members', Icons.people_alt_outlined),
      _NavItem('Programmes', '/programs', Icons.event_note_outlined),
      _NavItem('Structure', '/structure', Icons.account_tree_outlined),
      _NavItem(
        'Rapport mensuel',
        '/reports-rapport-mensuel',
        Icons.description_outlined,
      ),
    ],
  ),
  const _NavMenuData(
    label: 'Finances',
    caption: 'Collectes et tresorerie',
    icon: Icons.savings_outlined,
    items: [
      _NavItem(
        'Collectes & promesses',
        '/financial-campaigns',
        Icons.savings_outlined,
      ),
      _NavItem('Tresorerie', '/accounting-treasury', Icons.payments_outlined),
      _NavItem('Budgets', '/accounting-budgets', Icons.insert_chart_outlined),
    ],
  ),
  const _NavMenuData(
    label: 'Comptabilite',
    caption: 'SYSCEBNL et controles',
    icon: Icons.account_balance_outlined,
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
  const _NavMenuData(
    label: 'Fiscalite',
    caption: 'Documents officiels',
    icon: Icons.fact_check_outlined,
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
  const _NavMenuData(
    label: 'Administration',
    caption: 'Reglages et securite',
    icon: Icons.admin_panel_settings_outlined,
    items: [
      _NavItem(
        'Organisation',
        '/organization-settings',
        Icons.settings_outlined,
      ),
      _NavItem('Parametrage comptable', '/accounting-settings', Icons.tune),
      _NavItem('Journal d\'audit', '/audit-log', Icons.history_outlined),
    ],
  ),
  if (isPlatformOwner)
    const _NavMenuData(
      label: 'Proprietaire',
      caption: 'Pilotage plateforme',
      icon: Icons.verified_user_outlined,
      items: [
        _NavItem(
          'Console plateforme',
          '/platform-admin',
          Icons.admin_panel_settings_outlined,
        ),
      ],
    ),
];

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

Future<void> _signOut(BuildContext context) async {
  await Supabase.instance.client.auth.signOut();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

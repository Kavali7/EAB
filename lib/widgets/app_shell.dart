import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/notifications/presentation/notification_panel.dart';
import '../features/search/presentation/global_search_dialog.dart';
import '../models/assemblee_locale.dart';
import '../models/district_eglise.dart';
import '../models/profil_utilisateur.dart';
import '../models/region_eglise.dart';
import '../providers/church_structure_providers.dart';
import '../providers/user_profile_providers.dart';
import 'side_navigation.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.floatingActionButton,
    this.actions,
    this.bottom,
    this.showBackButton = false,
    this.backRoute,
    this.backTooltip = 'Retour',
  });

  final String title;
  final Widget body;
  final String currentRoute;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final String? backRoute;
  final String backTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilsAsync = ref.watch(profilsUtilisateursProvider);
    final profilCourant = ref.watch(profilUtilisateurCourantProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final regionsAsync = ref.watch(regionsProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);

    profilsAsync.whenData((profils) {
      if (profilCourant == null && profils.isNotEmpty) {
        final defaultProfil = profils.firstWhere(
          (p) => p.id == 'profil_tresorier_cotonou_centre',
          orElse: () => profils.first,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(profilUtilisateurCourantProvider.notifier)
              .setProfil(defaultProfil);
        });
      }
    });

    final assembleesAutorisees = _assembleesAutorisees(
      profilCourant,
      assembleesAsync.value ?? const [],
      districtsAsync.value ?? const [],
      regionsAsync.value ?? const [],
    );
    if (assembleeActiveId == null && assembleesAutorisees.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(assembleeActiveIdProvider.notifier)
            .setAssemblee(assembleesAutorisees.first.id);
      });
    }

    final selectedAssemblee = _selectedAssemblee(
      assembleesAutorisees,
      assembleeActiveId,
    );
    final isWide = MediaQuery.of(context).size.width >= 1100;
    final effectiveShowBackButton = showBackButton || currentRoute != '/';
    final effectiveBackRoute = backRoute ?? '/';

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showGlobalSearch(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          drawer: isWide
              ? null
              : Drawer(
                  width: 300,
                  child: SideNavigation(currentRoute: currentRoute),
                ),
          body: Row(
            children: [
              if (isWide)
                SizedBox(
                  width: 286,
                  child: SideNavigation(currentRoute: currentRoute),
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: title,
                      bottom: bottom,
                      isWide: isWide,
                      profilsAsync: profilsAsync,
                      profilCourant: profilCourant,
                      assembleesAutorisees: assembleesAutorisees,
                      selectedAssemblee: selectedAssemblee,
                      canChangeAssemblee: _peutChangerAssemblee(profilCourant),
                      actions: actions,
                      showBackButton: effectiveShowBackButton,
                      backRoute: effectiveBackRoute,
                      backTooltip: backTooltip,
                      onSelectProfil: (profil) {
                        ref
                            .read(profilUtilisateurCourantProvider.notifier)
                            .setProfil(profil);
                      },
                      onSelectAssemblee: (id) {
                        ref
                            .read(assembleeActiveIdProvider.notifier)
                            .setAssemblee(id);
                      },
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: AppColors.background,
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }

  AssembleeLocale? _selectedAssemblee(
    List<AssembleeLocale> assemblees,
    String? activeId,
  ) {
    if (assemblees.isEmpty) return null;
    if (activeId == null) return assemblees.first;
    return assemblees.firstWhere(
      (a) => a.id == activeId,
      orElse: () => assemblees.first,
    );
  }

  List<AssembleeLocale> _assembleesAutorisees(
    ProfilUtilisateur? profil,
    List<AssembleeLocale> assemblees,
    List<DistrictEglise> districts,
    List<RegionEglise> regions,
  ) {
    if (profil == null) return [];
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return assemblees;
      case RoleUtilisateur.responsableRegion:
        final idRegion = profil.idRegion;
        if (idRegion == null) return [];
        final districtIds = districts
            .where((d) => d.idRegion == idRegion)
            .map((d) => d.id)
            .toSet();
        return assemblees
            .where((a) => districtIds.contains(a.idDistrict))
            .toList();
      case RoleUtilisateur.surintendantDistrict:
        final idDistrict = profil.idDistrict;
        if (idDistrict == null) return [];
        return assemblees.where((a) => a.idDistrict == idDistrict).toList();
      case RoleUtilisateur.tresorierAssemblee:
        final idAss = profil.idAssembleeLocale;
        if (idAss == null) return [];
        return assemblees.where((a) => a.id == idAss).toList();
    }
  }

  bool _peutChangerAssemblee(ProfilUtilisateur? profil) {
    if (profil == null) return false;
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
      case RoleUtilisateur.responsableRegion:
      case RoleUtilisateur.surintendantDistrict:
        return true;
      case RoleUtilisateur.tresorierAssemblee:
        return false;
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.bottom,
    required this.isWide,
    required this.profilsAsync,
    required this.profilCourant,
    required this.assembleesAutorisees,
    required this.selectedAssemblee,
    required this.canChangeAssemblee,
    required this.onSelectProfil,
    required this.onSelectAssemblee,
    required this.showBackButton,
    required this.backTooltip,
    this.actions,
    this.backRoute,
  });

  final String title;
  final PreferredSizeWidget? bottom;
  final bool isWide;
  final AsyncValue<List<ProfilUtilisateur>> profilsAsync;
  final ProfilUtilisateur? profilCourant;
  final List<AssembleeLocale> assembleesAutorisees;
  final AssembleeLocale? selectedAssemblee;
  final bool canChangeAssemblee;
  final ValueChanged<ProfilUtilisateur> onSelectProfil;
  final ValueChanged<String> onSelectAssemblee;
  final bool showBackButton;
  final String backTooltip;
  final List<Widget>? actions;
  final String? backRoute;

  @override
  Widget build(BuildContext context) {
    final bar = Material(
      color: AppColors.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  return Row(
                    children: [
                      if (!isWide) ...[
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            tooltip: 'Menu',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (showBackButton) ...[
                        IconButton.filledTonal(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: backTooltip,
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            if (navigator.canPop()) {
                              navigator.pop();
                            } else if (backRoute != null) {
                              navigator.pushReplacementNamed(backRoute!);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 21,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selectedAssemblee?.nom ??
                                  'Aucune assemblee selectionnee',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!compact) ...[
                        _ContextPill(
                          icon: Icons.location_city_outlined,
                          label: selectedAssemblee?.code ?? 'Assemblee',
                          value: selectedAssemblee?.ville ?? 'Contexte',
                          items: assembleesAutorisees,
                          enabled: canChangeAssemblee,
                          onSelected: onSelectAssemblee,
                        ),
                        const SizedBox(width: 10),
                        _ProfilePill(
                          profilsAsync: profilsAsync,
                          profilCourant: profilCourant,
                          onSelected: onSelectProfil,
                        ),
                        const SizedBox(width: 8),
                        ...?actions,
                      ],
                      Builder(
                        builder: (btnContext) => IconButton.filledTonal(
                          icon: const NotificationBadge(
                            child: Icon(Icons.notifications_outlined),
                          ),
                          tooltip: 'Notifications',
                          onPressed: () => showNotificationPanel(btnContext),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.search),
                        tooltip: 'Recherche globale',
                        onPressed: () => showGlobalSearch(context),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );

    return bar;
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<AssembleeLocale> items;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: 'Changer d\'assemblee',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(value: item.id, child: Text(item.nom)),
      ],
      child: _PillSurface(icon: icon, label: label, value: value),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.profilsAsync,
    required this.profilCourant,
    required this.onSelected,
  });

  final AsyncValue<List<ProfilUtilisateur>> profilsAsync;
  final ProfilUtilisateur? profilCourant;
  final ValueChanged<ProfilUtilisateur> onSelected;

  @override
  Widget build(BuildContext context) {
    return profilsAsync.when(
      data: (profils) {
        if (profils.isEmpty) return const SizedBox.shrink();
        return PopupMenuButton<ProfilUtilisateur>(
          tooltip: 'Changer de profil',
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final profil in profils)
              PopupMenuItem(value: profil, child: Text(profil.nom)),
          ],
          child: _PillSurface(
            icon: Icons.person_outline,
            label: profilCourant?.nom ?? 'Profil',
            value: _roleLabel(profilCourant?.role),
          ),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  String _roleLabel(RoleUtilisateur? role) {
    if (role == null) return 'Non connecte';
    switch (role) {
      case RoleUtilisateur.adminNational:
        return 'Admin national';
      case RoleUtilisateur.responsableRegion:
        return 'Responsable region';
      case RoleUtilisateur.surintendantDistrict:
        return 'Surintendant';
      case RoleUtilisateur.tresorierAssemblee:
        return 'Tresorier';
    }
  }
}

class _PillSurface extends StatelessWidget {
  const _PillSurface({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

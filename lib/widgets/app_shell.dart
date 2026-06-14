import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/church_units/application/church_units_provider.dart';
import '../features/church_units/data/church_unit_model.dart';
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
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final churchUnitActiveId = ref.watch(churchUnitActiveIdProvider);

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
    final churchUnitsAutorisees = _churchUnitsAutorisees(
      profilCourant,
      churchUnitsAsync.value ?? const [],
    );
    final selectedChurchUnit = _selectedChurchUnit(
      churchUnitsAutorisees,
      churchUnitActiveId,
    );
    if ((churchUnitActiveId == null ||
            !churchUnitsAutorisees.any((u) => u.id == churchUnitActiveId)) &&
        churchUnitsAutorisees.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final defaultUnit = churchUnitsAutorisees.first;
        ref
            .read(churchUnitActiveIdProvider.notifier)
            .setChurchUnit(defaultUnit.id);
        ref
            .read(assembleeActiveIdProvider.notifier)
            .setAssemblee(defaultUnit.legacyAssembleeId);
      });
    } else if (selectedChurchUnit != null &&
        assembleeActiveId != selectedChurchUnit.legacyAssembleeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(assembleeActiveIdProvider.notifier)
            .setAssemblee(selectedChurchUnit.legacyAssembleeId);
      });
    } else if (assembleeActiveId == null && assembleesAutorisees.isNotEmpty) {
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
                      contextUnits: churchUnitsAutorisees,
                      selectedContextUnit: selectedChurchUnit,
                      selectedAssemblee: selectedAssemblee,
                      canChangeContext: _peutChangerContexte(profilCourant),
                      actions: actions,
                      showBackButton: effectiveShowBackButton,
                      backRoute: effectiveBackRoute,
                      backTooltip: backTooltip,
                      onSelectProfil: (profil) {
                        ref
                            .read(profilUtilisateurCourantProvider.notifier)
                            .setProfil(profil);
                        ref
                            .read(churchUnitActiveIdProvider.notifier)
                            .setChurchUnit(profil.primaryChurchUnitId);
                        ref
                            .read(assembleeActiveIdProvider.notifier)
                            .setAssemblee(profil.idAssembleeLocale);
                      },
                      onSelectContextUnit: (id) {
                        final unit = churchUnitsAutorisees.firstWhere(
                          (u) => u.id == id,
                          orElse: () => churchUnitsAutorisees.first,
                        );
                        ref
                            .read(churchUnitActiveIdProvider.notifier)
                            .setChurchUnit(id);
                        ref
                            .read(assembleeActiveIdProvider.notifier)
                            .setAssemblee(unit.legacyAssembleeId);
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

  ChurchUnit? _selectedChurchUnit(List<ChurchUnit> units, String? activeId) {
    if (units.isEmpty) return null;
    if (activeId == null) return units.first;
    return units.firstWhere((u) => u.id == activeId, orElse: () => units.first);
  }

  List<ChurchUnit> _churchUnitsAutorisees(
    ProfilUtilisateur? profil,
    List<ChurchUnit> units,
  ) {
    if (profil == null) return [];
    final activeUnits = units.where((u) => u.active).toList();
    if (activeUnits.isEmpty) return [];

    if (profil.role == RoleUtilisateur.adminNational) {
      return _sortUnits(activeUnits);
    }

    final primaryId = profil.primaryChurchUnitId;
    if (primaryId != null && primaryId.isNotEmpty) {
      return _sortUnits(_unitAndDescendants(activeUnits, primaryId));
    }

    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return _sortUnits(activeUnits);
      case RoleUtilisateur.responsableRegion:
        final idRegion = profil.idRegion;
        if (idRegion == null) return [];
        return _sortUnits(
          activeUnits.where((u) => u.legacyRegionId == idRegion).toList(),
        );
      case RoleUtilisateur.surintendantDistrict:
        final idDistrict = profil.idDistrict;
        if (idDistrict == null) return [];
        return _sortUnits(
          activeUnits.where((u) => u.legacyDistrictId == idDistrict).toList(),
        );
      case RoleUtilisateur.tresorierAssemblee:
        final idAss = profil.idAssembleeLocale;
        if (idAss == null) return [];
        return _sortUnits(
          activeUnits.where((u) => u.legacyAssembleeId == idAss).toList(),
        );
    }
  }

  List<ChurchUnit> _unitAndDescendants(List<ChurchUnit> units, String rootId) {
    final byParent = <String?, List<ChurchUnit>>{};
    for (final unit in units) {
      byParent.putIfAbsent(unit.parentId, () => []).add(unit);
    }

    final result = <ChurchUnit>[];
    final visited = <String>{};
    void visit(String id) {
      if (!visited.add(id)) return;
      ChurchUnit? unit;
      for (final candidate in units) {
        if (candidate.id == id) {
          unit = candidate;
          break;
        }
      }
      if (unit != null) result.add(unit);
      for (final child in byParent[id] ?? const <ChurchUnit>[]) {
        visit(child.id);
      }
    }

    visit(rootId);
    return result;
  }

  List<ChurchUnit> _sortUnits(List<ChurchUnit> units) {
    return [...units]..sort((a, b) {
      final level = a.levelOrder.compareTo(b.levelOrder);
      if (level != 0) return level;
      return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
    });
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

  bool _peutChangerContexte(ProfilUtilisateur? profil) {
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
    required this.contextUnits,
    required this.selectedContextUnit,
    required this.selectedAssemblee,
    required this.canChangeContext,
    required this.onSelectProfil,
    required this.onSelectContextUnit,
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
  final List<ChurchUnit> contextUnits;
  final ChurchUnit? selectedContextUnit;
  final AssembleeLocale? selectedAssemblee;
  final bool canChangeContext;
  final ValueChanged<ProfilUtilisateur> onSelectProfil;
  final ValueChanged<String> onSelectContextUnit;
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
                              selectedContextUnit?.nom ??
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
                          label:
                              selectedContextUnit?.code ??
                              selectedAssemblee?.code ??
                              'Perimetre',
                          value:
                              selectedContextUnit?.typeLabel ??
                              selectedAssemblee?.ville ??
                              'Contexte',
                          items: contextUnits,
                          enabled: canChangeContext,
                          onSelected: onSelectContextUnit,
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
  final List<ChurchUnit> items;
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
          PopupMenuItem(
            value: item.id,
            child: Text('${item.typeLabel} - ${item.nom}'),
          ),
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

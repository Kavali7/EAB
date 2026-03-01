import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/profil_utilisateur.dart';
import '../models/assemblee_locale.dart';
import '../models/district_eglise.dart';
import '../models/region_eglise.dart';
import '../providers/user_profile_providers.dart';
import '../providers/church_structure_providers.dart';
import '../features/search/presentation/global_search_dialog.dart';
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
  });

  final String title;
  final Widget body;
  final String currentRoute;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

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
        Future(() {
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
      Future(() {
        ref
            .read(assembleeActiveIdProvider.notifier)
            .setAssemblee(assembleesAutorisees.first.id);
      });
    }

    final profileAction = profilsAsync.when<List<Widget>>(
      data: (profils) {
        if (profils.isEmpty) return const [];
        final current = ref.watch(profilUtilisateurCourantProvider);
        return [
          DropdownButtonHideUnderline(
            child: DropdownButton<ProfilUtilisateur>(
              value: current,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              iconDisabledColor: Colors.white70,
              dropdownColor: Colors.white,
              items: profils
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.nom),
                    ),
                  )
                  .toList(),
              onChanged: (p) {
                if (p != null) {
                  ref.read(profilUtilisateurCourantProvider.notifier).setProfil(p);
                }
              },
            ),
          ),
        ];
      },
      error: (_, __) => const [],
      loading: () => const [],
    );

    final assembleeAction = assembleesAsync.when<List<Widget>>(
      data: (_) {
        if (assembleesAutorisees.isEmpty) return const [];
        final currentId = ref.watch(assembleeActiveIdProvider) ??
            assembleesAutorisees.first.id;
        final selected = assembleesAutorisees
            .firstWhere((a) => a.id == currentId, orElse: () => assembleesAutorisees.first);
        final canChange = _peutChangerAssemblee(profilCourant);
        return [
          const SizedBox(width: 8),
          const Text('Assemblee active:'),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected.id,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              iconDisabledColor: Colors.white70,
              dropdownColor: Colors.white,
              items: assembleesAutorisees
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.nom),
                    ),
                  )
                  .toList(),
              onChanged: canChange
                  ? (value) {
                      if (value != null) {
                        ref
                            .read(assembleeActiveIdProvider.notifier)
                            .setAssemblee(value);
                      }
                    }
                  : null,
            ),
          ),
        ];
      },
      error: (_, __) => const [],
      loading: () => const [],
    );

    final isWide = MediaQuery.of(context).size.width >= 1000;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            () => showGlobalSearch(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (profileAction.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 6),
                    ...profileAction,
                  ],
                ),
              ),
            ),
          if (assembleeAction.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.location_city_outlined, size: 18),
                    const SizedBox(width: 6),
                    ...assembleeAction,
                  ],
                ),
              ),
            ),
          ...?actions,
          // Bouton recherche globale (Ctrl+K)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Recherche globale (Ctrl+K)',
            onPressed: () => showGlobalSearch(context),
          ),
        ],
        bottom: bottom,
      ),
      drawer: isWide
          ? null
          : Drawer(child: SideNavigation(currentRoute: currentRoute)),
      body: Row(
        children: [
          if (isWide)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Material(
                elevation: 1,
                color: Colors.white,
                child: SafeArea(
                  child: SideNavigation(currentRoute: currentRoute),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: Container(
              color: ChurchTheme.cloud,
              child: Padding(padding: const EdgeInsets.all(12), child: body),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    ),
    ),
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
        return assemblees.where((a) => districtIds.contains(a.idDistrict)).toList();
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

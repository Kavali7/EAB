import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/profil_utilisateur.dart';
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

    profilsAsync.whenData((profils) {
      if (profilCourant == null && profils.isNotEmpty) {
        final defaultProfil = profils.firstWhere(
          (p) => p.id == 'profil_tresorier_cotonou_centre',
          orElse: () => profils.first,
        );
        ref
            .read(profilUtilisateurCourantProvider.notifier)
            .setProfil(defaultProfil);
      }
    });

    final profileAction = profilsAsync.when<List<Widget>>(
      data: (profils) {
        if (profils.isEmpty) return const [];
        final current = ref.watch(profilUtilisateurCourantProvider);
        return [
          DropdownButtonHideUnderline(
            child: DropdownButton<ProfilUtilisateur>(
              value: current,
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

    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
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
          ...?actions,
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
    );
  }
}

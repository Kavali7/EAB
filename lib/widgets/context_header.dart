import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/assemblee_locale.dart';
import '../models/compta_enums.dart';
import '../models/profil_utilisateur.dart';
import '../providers/accounting_providers.dart';
import '../providers/church_structure_providers.dart';
import '../providers/user_profile_providers.dart';

class ContextHeader extends ConsumerWidget {
  const ContextHeader({
    super.key,
    this.showPorteeComptable = false,
    this.showAsCard = true,
  });

  final bool showPorteeComptable;
  final bool showAsCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilUtilisateurCourantProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final portee =
        showPorteeComptable ? ref.watch(porteeComptableProvider) : null;

    return assembleesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (assemblees) {
        AssembleeLocale? assembleeActive;
        if (assembleeActiveId != null) {
          try {
            assembleeActive = assemblees
                .firstWhere((a) => a.id == assembleeActiveId);
          } catch (_) {
            assembleeActive = null;
          }
        }
        assembleeActive ??= assemblees.isNotEmpty ? assemblees.first : null;

        final roleLabel = _roleLabel(profil?.role);
        final porteeLabel =
            showPorteeComptable && portee != null ? _porteeLabel(portee) : null;

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profil connecte', style: AppTextStyles.secondary),
                  Text(
                    profil?.nom ?? 'Non connecte',
                    style: AppTextStyles.body,
                  ),
                  if (roleLabel != null)
                    Text('Role : $roleLabel', style: AppTextStyles.secondary),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assemblee active',
                      style: AppTextStyles.secondary),
                  Text(
                    assembleeActive != null
                        ? assembleeActive.nom
                        : 'Aucune assemblee selectionnee',
                    style: AppTextStyles.body,
                  ),
                  if (assembleeActive?.code != null &&
                      (assembleeActive!.code?.isNotEmpty ?? false))
                    Text('Code : ${assembleeActive.code}',
                        style: AppTextStyles.secondary),
                  if (assembleeActive?.ville != null)
                    Text('Ville : ${assembleeActive!.ville}',
                        style: AppTextStyles.secondary),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (porteeLabel != null)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portee comptable',
                        style: AppTextStyles.secondary),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(porteeLabel),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      labelStyle: AppTextStyles.body,
                      avatar: const Icon(
                        Icons.layers,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

        if (!showAsCard) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: content,
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: content,
          ),
        );
      },
    );
  }

  String? _roleLabel(RoleUtilisateur? role) {
    if (role == null) return null;
    switch (role) {
      case RoleUtilisateur.adminNational:
        return 'Administrateur national';
      case RoleUtilisateur.responsableRegion:
        return 'Responsable de region';
      case RoleUtilisateur.surintendantDistrict:
        return 'Surintendant de district';
      case RoleUtilisateur.tresorierAssemblee:
        return 'Tresorier d\'assemblee';
    }
  }

  String _porteeLabel(PorteeComptable p) {
    switch (p) {
      case PorteeComptable.assemblee:
        return 'Assemblee';
      case PorteeComptable.district:
        return 'District';
      case PorteeComptable.region:
        return 'Region';
      case PorteeComptable.national:
        return 'National';
    }
  }
}

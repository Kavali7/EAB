import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eab/core/security/platform_owner_access.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/features/organization/data/organization_model.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/section_card.dart';

class PlatformAdminScreen extends ConsumerStatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  ConsumerState<PlatformAdminScreen> createState() =>
      _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends ConsumerState<PlatformAdminScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _savingOrgId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text.trim().toLowerCase();
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = PlatformOwnerAccess.isCurrentUserOwner(
      Supabase.instance.client,
    );

    return AppShell(
      title: 'Console proprietaire',
      currentRoute: '/platform-admin',
      showBackButton: true,
      body: isOwner ? _ownerBody() : const _OwnerOnlyView(),
    );
  }

  Widget _ownerBody() {
    final organizationsAsync = ref.watch(platformOrganizationsProvider);

    return organizationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message:
            'Impossible de charger les organisations. Verifiez que les migrations proprietaire plateforme sont appliquees.',
        detail: error.toString(),
        onRetry: () => ref.invalidate(platformOrganizationsProvider),
      ),
      data: (organizations) {
        final filtered = _filter(organizations);
        final restrictedCount = organizations
            .where((org) => org.mobileAccessPolicy.isRestricted)
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(platformOrganizationsProvider);
            await ref.read(platformOrganizationsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _HeaderSummary(
                total: organizations.length,
                restricted: restrictedCount,
              ),
              const SizedBox(height: AppSpacing.cardGap),
              SectionCard(
                title: 'Organisations clientes',
                actions: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    onPressed: () =>
                        ref.invalidate(platformOrganizationsProvider),
                  ),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Rechercher une organisation',
                          hintText: 'Nom, sigle, email ou ville',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (filtered.isEmpty)
                      const EmptyState(
                        message:
                            'Aucune organisation ne correspond a cette recherche.',
                        icon: Icons.business_outlined,
                      )
                    else
                      ...filtered.map(_organizationTile),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Organization> _filter(List<Organization> organizations) {
    if (_query.isEmpty) return organizations;
    return organizations
        .where((org) {
          final haystack = [
            org.nom,
            org.sigle,
            org.email,
            org.adresse,
            org.telephone,
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(_query);
        })
        .toList(growable: false);
  }

  Widget _organizationTile(Organization org) {
    final policy = org.mobileAccessPolicy;
    final saving = _savingOrgId == org.id;
    final restricted = policy.isRestricted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.divider),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final info = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrganizationLogo(org: org),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if ((org.sigle ?? '').isNotEmpty) org.sigle!,
                          if ((org.adresse ?? '').isNotEmpty) org.adresse!,
                          if ((org.email ?? '').isNotEmpty) org.email!,
                        ].join('  |  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _ModeChip(restricted: restricted),
                          if (restricted)
                            _InfoChip(
                              icon: Icons.fact_check_outlined,
                              label:
                                  '${policy.allowedRoutes.length} routes autorisees',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
            final action = EabButton(
              label: saving ? 'Enregistrement' : 'Configurer',
              icon: saving
                  ? Icons.hourglass_empty
                  : Icons.phone_android_outlined,
              variant: EabButtonVariant.outline,
              isLoading: saving,
              onPressed: saving ? null : () => _openPolicyDialog(org),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: AppSpacing.md),
                  action,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: info),
                const SizedBox(width: AppSpacing.md),
                action,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPolicyDialog(Organization org) async {
    final next = await showDialog<OrganizationMobileAccessPolicy>(
      context: context,
      builder: (context) => _MobilePolicyDialog(org: org),
    );
    if (next == null) return;

    setState(() => _savingOrgId = org.id);
    try {
      await ref
          .read(organizationRepositoryProvider)
          .updateOrganizationMobileAccess(orgId: org.id, policy: next);
      ref.invalidate(platformOrganizationsProvider);
      ref.invalidate(currentOrganizationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Politique mobile mise a jour pour ${org.nom}.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Mise a jour impossible : $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingOrgId = null);
    }
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({required this.total, required this.restricted});

  final int total;
  final int restricted;

  @override
  Widget build(BuildContext context) {
    final full = total - restricted;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final cards = [
          _SummaryCard(
            icon: Icons.business_outlined,
            label: 'Organisations',
            value: total.toString(),
          ),
          _SummaryCard(
            icon: Icons.desktop_windows_outlined,
            label: 'Mobile complet',
            value: full.toString(),
          ),
          _SummaryCard(
            icon: Icons.phone_android_outlined,
            label: 'Mobile simplifie',
            value: restricted.toString(),
          ),
        ];
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.heading2),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePolicyDialog extends StatefulWidget {
  const _MobilePolicyDialog({required this.org});

  final Organization org;

  @override
  State<_MobilePolicyDialog> createState() => _MobilePolicyDialogState();
}

class _MobilePolicyDialogState extends State<_MobilePolicyDialog> {
  late String _mode;
  late Set<String> _routes;

  @override
  void initState() {
    super.initState();
    final policy = widget.org.mobileAccessPolicy;
    _mode = policy.mode;
    _routes = {
      '/',
      ...policy.allowedRoutes.where((route) => route.trim().isNotEmpty),
    };
  }

  @override
  Widget build(BuildContext context) {
    final restricted = _mode == OrganizationMobileAccessPolicy.modeRestricted;
    return AlertDialog(
      title: Text('Acces mobile - ${widget.org.sigle ?? widget.org.nom}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeChoiceTile(
                selected: _mode == OrganizationMobileAccessPolicy.modeFull,
                title: 'Mobile complet',
                description:
                    'Tous les modules restent disponibles sur telephone.',
                icon: Icons.desktop_windows_outlined,
                onTap: () => setState(
                  () => _mode = OrganizationMobileAccessPolicy.modeFull,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ModeChoiceTile(
                selected:
                    _mode == OrganizationMobileAccessPolicy.modeRestricted,
                title: 'Mobile simplifie',
                description:
                    'Seuls les modules coches restent accessibles sur telephone.',
                icon: Icons.phone_android_outlined,
                onTap: () => setState(
                  () => _mode = OrganizationMobileAccessPolicy.modeRestricted,
                ),
              ),
              if (restricted) ...[
                const Divider(height: AppSpacing.xl),
                Text(
                  'Modules autorises sur telephone',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._mobileRouteOptions.map((option) {
                  final mandatory = option.route == '/';
                  return CheckboxListTile(
                    value: _routes.contains(option.route),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(option.label),
                    subtitle: Text(option.description),
                    secondary: Icon(option.icon),
                    onChanged: mandatory
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _routes.add(option.route);
                              } else {
                                _routes.remove(option.route);
                              }
                            });
                          },
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
          onPressed: () {
            final routes = _mode == OrganizationMobileAccessPolicy.modeFull
                ? OrganizationMobileAccessPolicy.defaultAllowedRoutes
                : _sortedRoutes(_routes);
            Navigator.of(context).pop(
              OrganizationMobileAccessPolicy(
                mode: _mode,
                allowedRoutes: routes,
              ),
            );
          },
        ),
      ],
    );
  }

  List<String> _sortedRoutes(Set<String> routes) {
    final known = _mobileRouteOptions
        .map((option) => option.route)
        .where(routes.contains)
        .toList();
    final extra = routes.where((route) => !known.contains(route)).toList()
      ..sort();
    return [...known, ...extra];
  }
}

class _ModeChoiceTile extends StatelessWidget {
  const _ModeChoiceTile({
    required this.selected,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? colors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colors.primary : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationLogo extends StatelessWidget {
  const _OrganizationLogo({required this.org});

  final Organization org;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final logoUrl = org.logoUrl;
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.mdAll,
      ),
      child: logoUrl == null || logoUrl.isEmpty
          ? Icon(Icons.business_outlined, color: colors.primary)
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.business_outlined, color: colors.primary),
            ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.restricted});

  final bool restricted;

  @override
  Widget build(BuildContext context) {
    return _InfoChip(
      icon: restricted
          ? Icons.phone_android_outlined
          : Icons.desktop_windows_outlined,
      label: restricted ? 'Mobile simplifie' : 'Mobile complet',
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _OwnerOnlyView extends StatelessWidget {
  const _OwnerOnlyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SectionCard(
            title: 'Acces reserve',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 42),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Cette console est reservee au proprietaire plateforme.',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Le compte doit porter le marqueur Supabase Auth app_metadata platform_owner. Les roles internes d une eglise ne donnent pas cet acces.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SectionCard(
            title: 'Chargement impossible',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                Text(detail, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.md),
                EabButton(
                  label: 'Reessayer',
                  icon: Icons.refresh,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileRouteOption {
  const _MobileRouteOption({
    required this.route,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String route;
  final String label;
  final String description;
  final IconData icon;
}

const _mobileRouteOptions = [
  _MobileRouteOption(
    route: '/',
    label: 'Tableau de bord',
    description: 'Synthese rapide et actions principales.',
    icon: Icons.dashboard_outlined,
  ),
  _MobileRouteOption(
    route: '/members',
    label: 'Fideles',
    description: 'Consultation et saisie des fideles.',
    icon: Icons.people_alt_outlined,
  ),
  _MobileRouteOption(
    route: '/programs',
    label: 'Programmes',
    description: 'Activites, programmes et suivi terrain.',
    icon: Icons.event_note_outlined,
  ),
  _MobileRouteOption(
    route: '/calendar',
    label: 'Calendrier',
    description: 'Vue calendrier des activites.',
    icon: Icons.calendar_month_outlined,
  ),
  _MobileRouteOption(
    route: '/reports-rapport-mensuel',
    label: 'Rapport mensuel',
    description: 'Saisie des rapports mensuels essentiels.',
    icon: Icons.description_outlined,
  ),
  _MobileRouteOption(
    route: '/financial-campaigns',
    label: 'Collectes et promesses',
    description: 'Cotisations, promesses et mouvements simples.',
    icon: Icons.savings_outlined,
  ),
  _MobileRouteOption(
    route: '/accounting',
    label: 'Ecritures',
    description: 'Saisie comptable controlee.',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _MobileRouteOption(
    route: '/accounting-treasury',
    label: 'Tresorerie',
    description: 'Caisses, banques et soldes utiles.',
    icon: Icons.payments_outlined,
  ),
  _MobileRouteOption(
    route: '/structure',
    label: 'Structure',
    description: 'Lecture de la hierarchie de l eglise.',
    icon: Icons.account_tree_outlined,
  ),
  _MobileRouteOption(
    route: '/organization-settings',
    label: 'Parametres organisation',
    description: 'Informations utiles a l organisation.',
    icon: Icons.settings_outlined,
  ),
];

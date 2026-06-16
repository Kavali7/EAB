import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/operational_finance/application/operational_finance_providers.dart';
import 'package:eab/features/operational_finance/data/operational_finance_models.dart';
import 'package:eab/models/centre_analytique.dart';
import 'package:eab/models/compte_comptable.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/journal_comptable.dart';
import 'package:eab/models/member.dart';
import 'package:eab/models/profil_utilisateur.dart';
import 'package:eab/models/program.dart';
import 'package:eab/models/tiers.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/error_retry_widget.dart';

class OperationalFinanceScreen extends ConsumerStatefulWidget {
  const OperationalFinanceScreen({super.key});

  @override
  ConsumerState<OperationalFinanceScreen> createState() =>
      _OperationalFinanceScreenState();
}

class _OperationalFinanceScreenState
    extends ConsumerState<OperationalFinanceScreen> {
  String? _selectedCampaignId;

  @override
  Widget build(BuildContext context) {
    final operationsAsync = ref.watch(operationalFinanceProvider);
    final unitsAsync = ref.watch(churchUnitsProvider);
    final accountsAsync = ref.watch(churchUnitFinancialAccountsProvider);
    final programsAsync = ref.watch(programsProvider);
    final membersAsync = ref.watch(membersProvider);
    final journalsAsync = ref.watch(journauxComptablesProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final centresAsync = ref.watch(centresAnalytiquesProvider);
    final tiersAsync = ref.watch(tiersProvider);
    final currentProfile = ref.watch(profilUtilisateurCourantProvider);
    final activeUnitId = ref.watch(churchUnitActiveIdProvider);

    final isLoading =
        (operationsAsync.isLoading && !operationsAsync.hasValue) ||
        (unitsAsync.isLoading && !unitsAsync.hasValue) ||
        (accountsAsync.isLoading && !accountsAsync.hasValue);
    final firstError =
        operationsAsync.error ?? unitsAsync.error ?? accountsAsync.error;

    return AppShell(
      title: 'Collectes & promesses',
      currentRoute: '/financial-campaigns',
      showBackButton: true,
      backRoute: '/dashboard-finance',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : firstError != null
          ? ErrorRetryWidget(
              message: 'Erreur lors du chargement financier : $firstError',
              onRetry: () {
                ref.invalidate(operationalFinanceProvider);
                ref.invalidate(churchUnitsProvider);
                ref.invalidate(churchUnitFinancialAccountsProvider);
              },
            )
          : _buildContent(
              operations: operationsAsync.value ??
                  const OperationalFinanceState(
                    campaigns: [],
                    pledges: [],
                    movements: [],
                  ),
              units: unitsAsync.value ?? const [],
              accounts: accountsAsync.value ?? const [],
              programs: programsAsync.value ?? const [],
              members: membersAsync.value ?? const [],
              journals: journalsAsync.value ?? const [],
              comptes: comptesAsync.value ?? const [],
              centres: centresAsync.value ?? const [],
              tiers: tiersAsync.value ?? const [],
              currentProfile: currentProfile,
              activeUnitId: activeUnitId,
            ),
    );
  }

  Widget _buildContent({
    required OperationalFinanceState operations,
    required List<ChurchUnit> units,
    required List<ChurchUnitFinancialAccount> accounts,
    required List<Program> programs,
    required List<Member> members,
    required List<JournalComptable> journals,
    required List<CompteComptable> comptes,
    required List<CentreAnalytique> centres,
    required List<Tiers> tiers,
    required ProfilUtilisateur? currentProfile,
    required String? activeUnitId,
  }) {
    final activeUnit = _findUnit(units, activeUnitId);
    final canValidateMovements = _canValidateAccounting(
      activeUnit,
      currentProfile,
    );
    final launchUnits = units.where((unit) => unit.canLaunchContributions).toList();
    final scopedUnitIds = _unitScopeIds(units, activeUnit);
    final scopedCampaigns = activeUnit == null
        ? operations.campaigns
        : operations.campaigns
              .where((campaign) => scopedUnitIds.contains(campaign.churchUnitId))
              .toList();
    final scopedAccounts = activeUnit == null
        ? accounts
        : accounts
              .where((account) => scopedUnitIds.contains(account.churchUnitId))
              .toList();
    final selectedCampaign = _selectedCampaign(scopedCampaigns);
    final campaignPledges = selectedCampaign == null
        ? const <FinancialPledge>[]
        : operations.pledges
              .where((pledge) => pledge.campagneId == selectedCampaign.id)
              .toList();
    final campaignMovements = selectedCampaign == null
        ? const <FinancialMovement>[]
        : operations.movements
              .where((movement) => movement.campagneId == selectedCampaign.id)
              .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: EdgeInsets.all(
                compact ? AppSpacing.lg : AppSpacing.pagePadding,
              ),
              children: [
                _HeaderActions(
                  compact: compact,
                  activeUnit: activeUnit,
                  canCreateCampaign: launchUnits.isNotEmpty,
                  onCreateCampaign: () => _openCampaignForm(
                    units: launchUnits,
                    programs: programs,
                    activeUnitId: activeUnit?.id,
                  ),
                  onCreatePledge: selectedCampaign == null
                      ? null
                      : () => _openPledgeForm(
                            campaigns: scopedCampaigns,
                            members: members,
                            selectedCampaignId: selectedCampaign.id,
                          ),
                  onCreateMovement: scopedAccounts.isEmpty
                      ? null
                      : () => _openMovementForm(
                            campaigns: scopedCampaigns,
                            pledges: operations.pledges,
                            accounts: scopedAccounts,
                            members: members,
                            selectedCampaignId: selectedCampaign?.id,
                          ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (activeUnit != null && scopedAccounts.isEmpty)
                  _SetupNotice(unit: activeUnit),
                if (activeUnit != null && scopedAccounts.isEmpty)
                  const SizedBox(height: AppSpacing.md),
                _KpiStrip(campaigns: scopedCampaigns),
                const SizedBox(height: AppSpacing.lg),
                if (compact)
                  Column(
                    children: [
                      _CampaignsPanel(
                        campaigns: scopedCampaigns,
                        activeUnit: activeUnit,
                        onSelect: (id) =>
                            setState(() => _selectedCampaignId = id),
                        selectedId: selectedCampaign?.id,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CampaignDetailPanel(
                        campaign: selectedCampaign,
                        pledges: campaignPledges,
                        movements: campaignMovements,
                        accounts: accounts,
                        members: members,
                        journals: journals,
                        comptes: comptes,
                        centres: centres,
                        tiers: tiers,
                        canValidateMovements: canValidateMovements,
                        onCreatePledge: selectedCampaign == null
                            ? null
                            : () => _openPledgeForm(
                                  campaigns: scopedCampaigns,
                                  members: members,
                                  selectedCampaignId: selectedCampaign.id,
                                ),
                        onCreateMovement: scopedAccounts.isEmpty
                            ? null
                            : () => _openMovementForm(
                                  campaigns: scopedCampaigns,
                                  pledges: operations.pledges,
                                  accounts: scopedAccounts,
                                  members: members,
                                  selectedCampaignId: selectedCampaign?.id,
                                ),
                        onCloseCampaign: selectedCampaign == null ||
                                selectedCampaign.statut == 'cloturee'
                            ? null
                            : () => _closeCampaign(selectedCampaign.id),
                        onValidateMovement: canValidateMovements
                            ? (movement) => _openValidationForm(
                                  movement: movement,
                                  accounts: accounts,
                                  journals: journals,
                                  comptes: comptes,
                                  centres: centres,
                                  tiers: tiers,
                                )
                            : null,
                        onRejectMovement: canValidateMovements
                            ? (movement) => _openRejectMovementDialog(movement)
                            : null,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _CampaignsPanel(
                          campaigns: scopedCampaigns,
                          activeUnit: activeUnit,
                          onSelect: (id) =>
                              setState(() => _selectedCampaignId = id),
                          selectedId: selectedCampaign?.id,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 5,
                        child: _CampaignDetailPanel(
                          campaign: selectedCampaign,
                          pledges: campaignPledges,
                          movements: campaignMovements,
                          accounts: accounts,
                          members: members,
                          journals: journals,
                          comptes: comptes,
                          centres: centres,
                          tiers: tiers,
                          canValidateMovements: canValidateMovements,
                          onCreatePledge: selectedCampaign == null
                              ? null
                              : () => _openPledgeForm(
                                    campaigns: scopedCampaigns,
                                    members: members,
                                    selectedCampaignId: selectedCampaign.id,
                                  ),
                          onCreateMovement: scopedAccounts.isEmpty
                              ? null
                              : () => _openMovementForm(
                                    campaigns: scopedCampaigns,
                                    pledges: operations.pledges,
                                    accounts: scopedAccounts,
                                    members: members,
                                    selectedCampaignId: selectedCampaign?.id,
                                  ),
                          onCloseCampaign: selectedCampaign == null ||
                                  selectedCampaign.statut == 'cloturee'
                              ? null
                              : () => _closeCampaign(selectedCampaign.id),
                          onValidateMovement: canValidateMovements
                              ? (movement) => _openValidationForm(
                                    movement: movement,
                                    accounts: accounts,
                                    journals: journals,
                                    comptes: comptes,
                                    centres: centres,
                                    tiers: tiers,
                                  )
                              : null,
                          onRejectMovement: canValidateMovements
                              ? (movement) =>
                                    _openRejectMovementDialog(movement)
                              : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  FinancialCampaignSummary? _selectedCampaign(
    List<FinancialCampaignSummary> campaigns,
  ) {
    if (campaigns.isEmpty) return null;
    if (_selectedCampaignId == null) return campaigns.first;
    return campaigns.firstWhere(
      (campaign) => campaign.id == _selectedCampaignId,
      orElse: () => campaigns.first,
    );
  }

  ChurchUnit? _findUnit(List<ChurchUnit> units, String? id) {
    if (id == null) return units.isEmpty ? null : units.first;
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return units.isEmpty ? null : units.first;
  }

  bool _canValidateAccounting(
    ChurchUnit? activeUnit,
    ProfilUtilisateur? profile,
  ) {
    if (profile == null) return false;
    if (activeUnit?.canValidateFinances == true ||
        activeUnit?.canConsolidateFinances == true) {
      return true;
    }
    return switch (profile.role) {
      RoleUtilisateur.adminNational ||
      RoleUtilisateur.responsableRegion ||
      RoleUtilisateur.surintendantDistrict => true,
      RoleUtilisateur.tresorierAssemblee => false,
    };
  }

  Set<String> _unitScopeIds(List<ChurchUnit> units, ChurchUnit? activeUnit) {
    if (activeUnit == null) return units.map((unit) => unit.id).toSet();
    if (!activeUnit.canViewDescendants) return {activeUnit.id};
    final byParent = <String?, List<ChurchUnit>>{};
    for (final unit in units) {
      byParent.putIfAbsent(unit.parentId, () => []).add(unit);
    }
    final result = <String>{};
    void visit(String id) {
      if (!result.add(id)) return;
      for (final child in byParent[id] ?? const <ChurchUnit>[]) {
        visit(child.id);
      }
    }

    visit(activeUnit.id);
    return result;
  }

  Future<void> _openCampaignForm({
    required List<ChurchUnit> units,
    required List<Program> programs,
    required String? activeUnitId,
  }) async {
    await EabDialog.show<void>(
      context,
      title: 'Nouvelle campagne',
      width: 720,
      content: _CampaignForm(
        units: units,
        programs: programs,
        activeUnitId: activeUnitId,
      ),
    );
  }

  Future<void> _openPledgeForm({
    required List<FinancialCampaignSummary> campaigns,
    required List<Member> members,
    required String? selectedCampaignId,
  }) async {
    await EabDialog.show<void>(
      context,
      title: 'Nouvelle promesse',
      width: 680,
      content: _PledgeForm(
        campaigns: campaigns,
        members: members,
        selectedCampaignId: selectedCampaignId,
      ),
    );
  }

  Future<void> _openMovementForm({
    required List<FinancialCampaignSummary> campaigns,
    required List<FinancialPledge> pledges,
    required List<ChurchUnitFinancialAccount> accounts,
    required List<Member> members,
    required String? selectedCampaignId,
  }) async {
    await EabDialog.show<void>(
      context,
      title: 'Encaisser / decaisser',
      width: 720,
      content: _MovementForm(
        campaigns: campaigns,
        pledges: pledges,
        accounts: accounts,
        members: members,
        selectedCampaignId: selectedCampaignId,
      ),
    );
  }

  Future<void> _openValidationForm({
    required FinancialMovement movement,
    required List<ChurchUnitFinancialAccount> accounts,
    required List<JournalComptable> journals,
    required List<CompteComptable> comptes,
    required List<CentreAnalytique> centres,
    required List<Tiers> tiers,
  }) async {
    await EabDialog.show<void>(
      context,
      title: 'Validation comptable',
      width: 760,
      content: _MovementValidationForm(
        movement: movement,
        accounts: accounts,
        journals: journals,
        comptes: comptes,
        centres: centres,
        tiers: tiers,
      ),
    );
  }

  Future<void> _openRejectMovementDialog(FinancialMovement movement) async {
    await EabDialog.show<void>(
      context,
      title: 'Rejeter le mouvement',
      width: 560,
      content: _RejectMovementForm(movement: movement),
    );
  }

  Future<void> _closeCampaign(String campaignId) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Cloturer la campagne',
      message:
          'La campagne restera consultable, mais elle sera marquee comme cloturee.',
      confirmLabel: 'Cloturer',
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(operationalFinanceProvider.notifier)
          .closeCampaign(campaignId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campagne cloturee.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.compact,
    required this.activeUnit,
    required this.canCreateCampaign,
    required this.onCreateCampaign,
    required this.onCreatePledge,
    required this.onCreateMovement,
  });

  final bool compact;
  final ChurchUnit? activeUnit;
  final bool canCreateCampaign;
  final VoidCallback onCreateCampaign;
  final VoidCallback? onCreatePledge;
  final VoidCallback? onCreateMovement;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      EabButton(
        label: 'Campagne',
        icon: Icons.flag_outlined,
        onPressed: canCreateCampaign ? onCreateCampaign : null,
      ),
      EabButton(
        label: 'Promesse',
        icon: Icons.volunteer_activism_outlined,
        variant: EabButtonVariant.outline,
        onPressed: onCreatePledge,
      ),
      EabButton(
        label: 'Mouvement',
        icon: Icons.payments_outlined,
        variant: EabButtonVariant.secondary,
        onPressed: onCreateMovement,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: AppRadius.mdAll,
              ),
              child: const Icon(Icons.savings_outlined, color: AppColors.info),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suivi operationnel', style: AppTextStyles.heading3),
                  Text(
                    activeUnit == null
                        ? 'Collectes, promesses et mouvements de toutes les unites accessibles.'
                        : '${activeUnit!.typeLabel} - ${activeUnit!.nom}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons
                .map(
                  (button) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: button,
                  ),
                )
                .toList(),
          )
        else
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: buttons),
      ],
    );
  }
}

class _SetupNotice extends StatelessWidget {
  const _SetupNotice({required this.unit});

  final ChurchUnit unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${unit.nom} n a pas encore de caisse, banque ou MoMo actif. Configurez un compte financier dans Structure pour enregistrer des mouvements.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/structure'),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Structure'),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.campaigns});

  final List<FinancialCampaignSummary> campaigns;

  @override
  Widget build(BuildContext context) {
    final active = campaigns.where((c) => c.statut == 'active').length;
    final promised = campaigns.fold<double>(0, (sum, c) => sum + c.montantPromis);
    final collected = campaigns.fold<double>(
      0,
      (sum, c) => sum + c.montantEncaisse,
    );
    final validated = campaigns.fold<double>(
      0,
      (sum, c) => sum + c.montantValide,
    );
    final items = [
      _KpiItem('Campagnes actives', active.toString(), Icons.flag_outlined),
      _KpiItem('Promesses', currencyFormatter.format(promised), Icons.handshake),
      _KpiItem('Encaisse', currencyFormatter.format(collected), Icons.payments),
      _KpiItem('Valide', currencyFormatter.format(validated), Icons.verified),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.sm)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _KpiTile(item: item)),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignsPanel extends StatelessWidget {
  const _CampaignsPanel({
    required this.campaigns,
    required this.activeUnit,
    required this.selectedId,
    required this.onSelect,
  });

  final List<FinancialCampaignSummary> campaigns;
  final ChurchUnit? activeUnit;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campagnes', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              activeUnit == null
                  ? 'Toutes les campagnes accessibles.'
                  : 'Campagnes rattachees a ${activeUnit!.nom}.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (campaigns.isEmpty)
              const EmptyState(
                icon: Icons.flag_outlined,
                message: 'Aucune campagne financiere pour ce perimetre.',
              )
            else
              Column(
                children: [
                  for (final campaign in campaigns)
                    _CampaignCard(
                      campaign: campaign,
                      selected: selectedId == campaign.id,
                      onTap: () => onSelect(campaign.id),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.selected,
    required this.onTap,
  });

  final FinancialCampaignSummary campaign;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = campaign.tauxObjectif;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected ? AppColors.infoLight.withValues(alpha: 0.6) : null,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: selected ? AppColors.info : AppColors.divider,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      campaign.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusBadge(label: _statusLabel(campaign.statut)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_campaignTypeLabel(campaign.type)} | ${dateFormatter.format(campaign.dateDebut)}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _AmountMetric(
                      label: 'Promis',
                      value: campaign.montantPromis,
                    ),
                  ),
                  Expanded(
                    child: _AmountMetric(
                      label: 'Encaisse',
                      value: campaign.montantEncaisse,
                    ),
                  ),
                ],
              ),
              if (campaign.objectifMontant != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  backgroundColor: AppColors.divider,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Objectif : ${currencyFormatter.format(campaign.objectifMontant)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignDetailPanel extends StatelessWidget {
  const _CampaignDetailPanel({
    required this.campaign,
    required this.pledges,
    required this.movements,
    required this.accounts,
    required this.members,
    required this.journals,
    required this.comptes,
    required this.centres,
    required this.tiers,
    required this.canValidateMovements,
    required this.onCreatePledge,
    required this.onCreateMovement,
    required this.onCloseCampaign,
    required this.onValidateMovement,
    required this.onRejectMovement,
  });

  final FinancialCampaignSummary? campaign;
  final List<FinancialPledge> pledges;
  final List<FinancialMovement> movements;
  final List<ChurchUnitFinancialAccount> accounts;
  final List<Member> members;
  final List<JournalComptable> journals;
  final List<CompteComptable> comptes;
  final List<CentreAnalytique> centres;
  final List<Tiers> tiers;
  final bool canValidateMovements;
  final VoidCallback? onCreatePledge;
  final VoidCallback? onCreateMovement;
  final VoidCallback? onCloseCampaign;
  final ValueChanged<FinancialMovement>? onValidateMovement;
  final ValueChanged<FinancialMovement>? onRejectMovement;

  @override
  Widget build(BuildContext context) {
    if (campaign == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: EmptyState(
            icon: Icons.savings_outlined,
            message: 'Selectionnez ou creez une campagne pour voir le detail.',
          ),
        ),
      );
    }

    final memberById = {for (final member in members) member.id: member};
    final accountById = {for (final account in accounts) account.id: account};
    final totalPledges = pledges.fold<double>(
      0,
      (sum, pledge) => sum + pledge.montantPromis,
    );
    final totalMovements = movements.fold<double>(
      0,
      (sum, movement) =>
          sum + (movement.type == 'decaissement' ? -movement.montant : movement.montant),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campaign!.titre, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _campaignTypeLabel(campaign!.type),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: _statusLabel(campaign!.statut)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _AmountMetric(label: 'Promis', value: totalPledges)),
                Expanded(child: _AmountMetric(label: 'Net', value: totalMovements)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                EabButton(
                  label: 'Promesse',
                  icon: Icons.volunteer_activism_outlined,
                  size: EabButtonSize.small,
                  variant: EabButtonVariant.outline,
                  onPressed: onCreatePledge,
                ),
                EabButton(
                  label: 'Mouvement',
                  icon: Icons.payments_outlined,
                  size: EabButtonSize.small,
                  variant: EabButtonVariant.secondary,
                  onPressed: onCreateMovement,
                ),
                EabButton(
                  label: 'Cloturer',
                  icon: Icons.lock_outline,
                  size: EabButtonSize.small,
                  variant: EabButtonVariant.ghost,
                  onPressed: onCloseCampaign,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Promesses', style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.sm),
            if (pledges.isEmpty)
              _InlineEmpty(message: 'Aucune promesse enregistree.')
            else
              Column(
                children: [
                  for (final pledge in pledges)
                    _PledgeTile(
                      pledge: pledge,
                      contributor: _contributorLabel(pledge, memberById),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mouvements', style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.sm),
            if (movements.isEmpty)
              _InlineEmpty(message: 'Aucun mouvement enregistre.')
            else
              Column(
                children: [
                  for (final movement in movements)
                    _MovementTile(
                      movement: movement,
                      account: accountById[movement.financialAccountId],
                      contributor: _movementContributorLabel(
                        movement,
                        memberById,
                      ),
                      canValidate:
                          canValidateMovements &&
                          movement.statut == 'soumis' &&
                          journals.isNotEmpty &&
                          comptes.isNotEmpty,
                      onValidate: onValidateMovement == null
                          ? null
                          : () => onValidateMovement!(movement),
                      onReject: onRejectMovement == null
                          ? null
                          : () => onRejectMovement!(movement),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PledgeTile extends StatelessWidget {
  const _PledgeTile({required this.pledge, required this.contributor});

  final FinancialPledge pledge;
  final String contributor;

  @override
  Widget build(BuildContext context) {
    return _LineTile(
      icon: Icons.handshake_outlined,
      title: contributor,
      subtitle:
          '${dateFormatter.format(pledge.datePromesse)} | ${_statusLabel(pledge.statut)}',
      trailing: currencyFormatter.format(pledge.montantPromis),
      color: pledge.statut == 'reglee' ? AppColors.success : AppColors.info,
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.movement,
    required this.account,
    required this.contributor,
    required this.canValidate,
    required this.onValidate,
    required this.onReject,
  });

  final FinancialMovement movement;
  final ChurchUnitFinancialAccount? account;
  final String contributor;
  final bool canValidate;
  final VoidCallback? onValidate;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isOut = movement.type == 'decaissement';
    final color = isOut ? AppColors.error : AppColors.success;
    return _LineTile(
      icon: isOut ? Icons.north_east_outlined : Icons.south_west_outlined,
      title: movement.libelle,
      subtitle: [
        dateFormatter.format(movement.dateMouvement),
        account?.label ?? 'Compte',
        contributor,
        _statusLabel(movement.statut),
        if (movement.rejetMotif?.trim().isNotEmpty ?? false)
          movement.rejetMotif!.trim(),
      ].join(' | '),
      trailing:
          '${isOut ? '-' : '+'}${currencyFormatter.format(movement.montant)}',
      color: color,
      actions: canValidate
          ? [
              IconButton(
                tooltip: 'Valider en comptabilite',
                onPressed: onValidate,
                icon: const Icon(Icons.fact_check_outlined),
              ),
              IconButton(
                tooltip: 'Rejeter',
                onPressed: onReject,
                color: AppColors.error,
                icon: const Icon(Icons.block_outlined),
              ),
            ]
          : null,
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
    this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.xs),
            ...actions!,
          ],
        ],
      ),
    );
  }
}

class _CampaignForm extends ConsumerStatefulWidget {
  const _CampaignForm({
    required this.units,
    required this.programs,
    required this.activeUnitId,
  });

  final List<ChurchUnit> units;
  final List<Program> programs;
  final String? activeUnitId;

  @override
  ConsumerState<_CampaignForm> createState() => _CampaignFormState();
}

class _CampaignFormState extends ConsumerState<_CampaignForm> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _objectifController = TextEditingController();
  String? _unitId;
  String? _programId;
  String _type = 'cotisation';
  String _periodicite = 'ponctuelle';
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unitId = widget.units.any((unit) => unit.id == widget.activeUnitId)
        ? widget.activeUnitId
        : (widget.units.isEmpty ? null : widget.units.first.id);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _objectifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programs = widget.programs
        .where((program) => _unitId == null || program.churchUnitId == _unitId)
        .toList();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _unitId,
            decoration: const InputDecoration(labelText: 'Unite responsable'),
            items: [
              for (final unit in widget.units)
                DropdownMenuItem(
                  value: unit.id,
                  child: Text('${unit.typeLabel} - ${unit.nom}'),
                ),
            ],
            validator: (value) =>
                value == null ? 'Selectionnez une unite.' : null,
            onChanged: (value) => setState(() {
              _unitId = value;
              _programId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _titreController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Cotisation construction, soutien programme, offrande speciale...',
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Titre requis.' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Nature'),
            items: [
              for (final entry in _campaignTypes.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _programId,
            decoration: const InputDecoration(labelText: 'Programme rattache'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Aucun programme'),
              ),
              for (final program in programs)
                DropdownMenuItem<String?>(
                  value: program.id,
                  child: Text(_programLabel(program)),
                ),
            ],
            onChanged: (value) => setState(() => _programId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _objectifController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Objectif financier',
              hintText: 'Ex. 250000',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _periodicite,
            decoration: const InputDecoration(labelText: 'Periodicite'),
            items: const [
              DropdownMenuItem(value: 'ponctuelle', child: Text('Ponctuelle')),
              DropdownMenuItem(value: 'hebdomadaire', child: Text('Hebdomadaire')),
              DropdownMenuItem(value: 'mensuelle', child: Text('Mensuelle')),
              DropdownMenuItem(value: 'trimestrielle', child: Text('Trimestrielle')),
              DropdownMenuItem(value: 'annuelle', child: Text('Annuelle')),
            ],
            onChanged: (value) =>
                setState(() => _periodicite = value ?? _periodicite),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _DatePickButton(
                label: 'Debut',
                value: _dateDebut,
                onPicked: (value) {
                  if (value != null) setState(() => _dateDebut = value);
                },
              ),
              _DatePickButton(
                label: 'Fin',
                value: _dateFin,
                allowClear: true,
                onPicked: (value) => setState(() => _dateFin = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Precisez l usage attendu et les consignes utiles.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EabButton(
            label: 'Creer la campagne',
            icon: Icons.save_outlined,
            isLoading: _saving,
            fullWidth: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(operationalFinanceProvider.notifier).createCampaign(
            churchUnitId: _unitId!,
            titre: _titreController.text,
            type: _type,
            programmeId: _programId,
            description: _descriptionController.text,
            objectifMontant: _parseMoney(_objectifController.text),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            periodicite: _periodicite,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campagne creee.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PledgeForm extends ConsumerStatefulWidget {
  const _PledgeForm({
    required this.campaigns,
    required this.members,
    required this.selectedCampaignId,
  });

  final List<FinancialCampaignSummary> campaigns;
  final List<Member> members;
  final String? selectedCampaignId;

  @override
  ConsumerState<_PledgeForm> createState() => _PledgeFormState();
}

class _PledgeFormState extends ConsumerState<_PledgeForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _contributorController = TextEditingController();
  final _notesController = TextEditingController();
  String? _campaignId;
  String? _memberId;
  DateTime _datePromesse = DateTime.now();
  DateTime? _dateEcheance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _campaignId =
        widget.campaigns.any((campaign) => campaign.id == widget.selectedCampaignId)
        ? widget.selectedCampaignId
        : (widget.campaigns.isEmpty ? null : widget.campaigns.first.id);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _contributorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _campaignId,
            decoration: const InputDecoration(labelText: 'Campagne'),
            items: [
              for (final campaign in widget.campaigns)
                DropdownMenuItem(value: campaign.id, child: Text(campaign.titre)),
            ],
            validator: (value) =>
                value == null ? 'Selectionnez une campagne.' : null,
            onChanged: (value) => setState(() => _campaignId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _memberId,
            decoration: const InputDecoration(labelText: 'Fidele'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Contributeur libre'),
              ),
              for (final member in widget.members)
                DropdownMenuItem<String?>(
                  value: member.id,
                  child: Text(member.fullName),
                ),
            ],
            onChanged: (value) => setState(() => _memberId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _contributorController,
            decoration: const InputDecoration(
              labelText: 'Nom du contributeur',
              hintText: 'Obligatoire si aucun fidele n est selectionne.',
            ),
            validator: (value) {
              if (_memberId != null) return null;
              return (value == null || value.trim().isEmpty)
                  ? 'Nom requis pour un contributeur libre.'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant promis',
              hintText: 'Ex. 50000',
            ),
            validator: (value) {
              final amount = _parseMoney(value);
              return amount == null || amount <= 0 ? 'Montant invalide.' : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _DatePickButton(
                label: 'Promesse',
                value: _datePromesse,
                onPicked: (value) {
                  if (value != null) setState(() => _datePromesse = value);
                },
              ),
              _DatePickButton(
                label: 'Echeance',
                value: _dateEcheance,
                allowClear: true,
                onPicked: (value) => setState(() => _dateEcheance = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Modalites, tranche prevue ou precision utile.',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EabButton(
            label: 'Enregistrer la promesse',
            icon: Icons.save_outlined,
            isLoading: _saving,
            fullWidth: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final campaign = widget.campaigns.firstWhere((c) => c.id == _campaignId);
    setState(() => _saving = true);
    try {
      await ref.read(operationalFinanceProvider.notifier).createPledge(
            campagneId: campaign.id,
            churchUnitId: campaign.churchUnitId,
            membreId: _memberId,
            contributeurNom: _contributorController.text,
            montantPromis: _parseMoney(_amountController.text)!,
            datePromesse: _datePromesse,
            dateEcheance: _dateEcheance,
            notes: _notesController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promesse enregistree.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MovementForm extends ConsumerStatefulWidget {
  const _MovementForm({
    required this.campaigns,
    required this.pledges,
    required this.accounts,
    required this.members,
    required this.selectedCampaignId,
  });

  final List<FinancialCampaignSummary> campaigns;
  final List<FinancialPledge> pledges;
  final List<ChurchUnitFinancialAccount> accounts;
  final List<Member> members;
  final String? selectedCampaignId;

  @override
  ConsumerState<_MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends ConsumerState<_MovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  final _contributorController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _campaignId;
  String? _pledgeId;
  String? _accountId;
  String? _memberId;
  String _movementType = 'encaissement';
  String _paymentMode = 'especes';
  DateTime _dateMouvement = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _campaignId =
        widget.campaigns.any((campaign) => campaign.id == widget.selectedCampaignId)
        ? widget.selectedCampaignId
        : (widget.campaigns.isEmpty ? null : widget.campaigns.first.id);
    _accountId = _accountsForCampaign().isEmpty
        ? (widget.accounts.isEmpty ? null : widget.accounts.first.id)
        : _accountsForCampaign().first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    _contributorController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaignPledges = widget.pledges
        .where((pledge) => pledge.campagneId == _campaignId)
        .toList();
    final accounts = _accountsForCampaign();
    if (_accountId != null && !accounts.any((account) => account.id == _accountId)) {
      _accountId = accounts.isEmpty ? null : accounts.first.id;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _campaignId,
            decoration: const InputDecoration(labelText: 'Campagne'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Hors campagne'),
              ),
              for (final campaign in widget.campaigns)
                DropdownMenuItem<String?>(
                  value: campaign.id,
                  child: Text(campaign.titre),
                ),
            ],
            onChanged: (value) => setState(() {
              _campaignId = value;
              _pledgeId = null;
              _accountId = _accountsForCampaign().isEmpty
                  ? null
                  : _accountsForCampaign().first.id;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _pledgeId,
            decoration: const InputDecoration(labelText: 'Promesse reglee'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Aucune promesse'),
              ),
              for (final pledge in campaignPledges)
                DropdownMenuItem<String?>(
                  value: pledge.id,
                  child: Text(
                    '${_pledgeContributor(pledge)} - ${currencyFormatter.format(pledge.montantPromis)}',
                  ),
                ),
            ],
            onChanged: (value) => setState(() {
              _pledgeId = value;
              final pledge = _findPledge(value);
              _memberId = pledge?.membreId;
              if (pledge?.contributeurNom != null) {
                _contributorController.text = pledge!.contributeurNom!;
              }
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            decoration: const InputDecoration(labelText: 'Compte financier'),
            items: [
              for (final account in accounts)
                DropdownMenuItem(
                  value: account.id,
                  child: Text('${account.typeLabel} - ${account.label}'),
                ),
            ],
            validator: (value) =>
                value == null ? 'Configurez ou selectionnez un compte.' : null,
            onChanged: (value) => setState(() => _accountId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _movementType,
            decoration: const InputDecoration(labelText: 'Type de mouvement'),
            items: const [
              DropdownMenuItem(value: 'encaissement', child: Text('Encaissement')),
              DropdownMenuItem(value: 'decaissement', child: Text('Decaissement')),
              DropdownMenuItem(value: 'ajustement', child: Text('Ajustement')),
            ],
            onChanged: (value) =>
                setState(() => _movementType = value ?? _movementType),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Libelle',
              hintText: 'Paiement cotisation, avance fournisseur, depot MoMo...',
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Libelle requis.' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant',
              hintText: 'Ex. 30000',
            ),
            validator: (value) {
              final amount = _parseMoney(value);
              return amount == null || amount <= 0 ? 'Montant invalide.' : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(labelText: 'Mode de paiement'),
            items: const [
              DropdownMenuItem(value: 'especes', child: Text('Especes')),
              DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              DropdownMenuItem(value: 'virement_bancaire', child: Text('Virement bancaire')),
              DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
              DropdownMenuItem(value: 'microfinance', child: Text('Microfinance')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (value) =>
                setState(() => _paymentMode = value ?? _paymentMode),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _memberId,
            decoration: const InputDecoration(labelText: 'Fidele'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Contributeur libre'),
              ),
              for (final member in widget.members)
                DropdownMenuItem<String?>(
                  value: member.id,
                  child: Text(member.fullName),
                ),
            ],
            onChanged: (value) => setState(() => _memberId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _contributorController,
            decoration: const InputDecoration(
              labelText: 'Contributeur / beneficiaire',
              hintText: 'Nom libre si aucun fidele n est selectionne.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference externe',
              hintText: 'Reference MoMo, numero cheque, recu...',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DatePickButton(
            label: 'Date',
            value: _dateMouvement,
            onPicked: (value) {
              if (value != null) setState(() => _dateMouvement = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          EabButton(
            label: 'Enregistrer le mouvement',
            icon: Icons.save_outlined,
            isLoading: _saving,
            fullWidth: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  List<ChurchUnitFinancialAccount> _accountsForCampaign() {
    final campaign = _findCampaign(_campaignId);
    if (campaign == null) return widget.accounts;
    return widget.accounts
        .where((account) => account.churchUnitId == campaign.churchUnitId)
        .toList();
  }

  FinancialCampaignSummary? _findCampaign(String? id) {
    if (id == null) return null;
    for (final campaign in widget.campaigns) {
      if (campaign.id == id) return campaign;
    }
    return null;
  }

  FinancialPledge? _findPledge(String? id) {
    if (id == null) return null;
    for (final pledge in widget.pledges) {
      if (pledge.id == id) return pledge;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final account = widget.accounts.firstWhere((a) => a.id == _accountId);
    final campaign = _findCampaign(_campaignId);
    final pledge = _findPledge(_pledgeId);
    setState(() => _saving = true);
    try {
      await ref.read(operationalFinanceProvider.notifier).createMovement(
            churchUnitId: account.churchUnitId,
            financialAccountId: account.id,
            type: _movementType,
            montant: _parseMoney(_amountController.text)!,
            dateMouvement: _dateMouvement,
            libelle: _labelController.text,
            campagneId: campaign?.id,
            programmeId: campaign?.programmeId,
            promesseId: pledge?.id,
            membreId: _memberId ?? pledge?.membreId,
            contributeurNom: _contributorController.text,
            modePaiement: _paymentMode,
            referenceExterne: _referenceController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mouvement enregistre.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MovementValidationForm extends ConsumerStatefulWidget {
  const _MovementValidationForm({
    required this.movement,
    required this.accounts,
    required this.journals,
    required this.comptes,
    required this.centres,
    required this.tiers,
  });

  final FinancialMovement movement;
  final List<ChurchUnitFinancialAccount> accounts;
  final List<JournalComptable> journals;
  final List<CompteComptable> comptes;
  final List<CentreAnalytique> centres;
  final List<Tiers> tiers;

  @override
  ConsumerState<_MovementValidationForm> createState() =>
      _MovementValidationFormState();
}

class _MovementValidationFormState
    extends ConsumerState<_MovementValidationForm> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  late final TextEditingController _libelleController;
  String? _journalId;
  String? _treasuryAccountId;
  String? _counterpartAccountId;
  String? _centreId;
  String? _tiersId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _libelleController = TextEditingController(text: widget.movement.libelle);
    _referenceController.text =
        widget.movement.referenceExterne ??
        'MVT-${widget.movement.id.substring(0, 8)}';
    final account = _movementAccount;
    _journalId = _defaultJournalId(account);
    _treasuryAccountId =
        account?.comptableAccountId ?? _defaultTreasuryAccountId(account);
    _counterpartAccountId = _defaultCounterpartAccountId();
    _centreId = _defaultCentreId();
    _tiersId = widget.movement.tiersId;
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _libelleController.dispose();
    super.dispose();
  }

  ChurchUnitFinancialAccount? get _movementAccount {
    for (final account in widget.accounts) {
      if (account.id == widget.movement.financialAccountId) return account;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeJournals = widget.journals.where((j) => j.actif).toList();
    final activeComptes = widget.comptes.where((c) => c.actif).toList();
    final movement = widget.movement;
    final isOut = movement.type == 'decaissement';

    if (activeJournals.isEmpty || activeComptes.length < 2) {
      return const _InlineEmpty(
        message:
            'Le plan comptable ou les journaux ne sont pas encore disponibles. Configurez-les avant de valider les mouvements.',
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ValidationSummary(movement: movement, account: _movementAccount),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _journalId,
            decoration: const InputDecoration(labelText: 'Journal comptable'),
            items: [
              for (final journal in activeJournals)
                DropdownMenuItem(
                  value: journal.id,
                  child: Text('${journal.code} - ${journal.intitule}'),
                ),
            ],
            validator: (value) =>
                value == null ? 'Selectionnez un journal.' : null,
            onChanged: (value) => setState(() => _journalId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _treasuryAccountId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: isOut
                  ? 'Compte de tresorerie a crediter'
                  : 'Compte de tresorerie a debiter',
            ),
            items: [
              for (final compte in activeComptes)
                DropdownMenuItem(
                  value: compte.id,
                  child: Text('${compte.numero} - ${compte.intitule}'),
                ),
            ],
            validator: (value) =>
                value == null ? 'Selectionnez le compte de tresorerie.' : null,
            onChanged: (value) => setState(() => _treasuryAccountId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _counterpartAccountId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: isOut
                  ? 'Compte a debiter'
                  : 'Compte produit / contrepartie a crediter',
            ),
            items: [
              for (final compte in activeComptes)
                DropdownMenuItem(
                  value: compte.id,
                  child: Text('${compte.numero} - ${compte.intitule}'),
                ),
            ],
            validator: (value) {
              if (value == null) return 'Selectionnez le compte de contrepartie.';
              if (value == _treasuryAccountId) {
                return 'La contrepartie doit etre differente.';
              }
              return null;
            },
            onChanged: (value) => setState(() => _counterpartAccountId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _centreId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Centre analytique'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Aucun centre'),
              ),
              for (final centre in widget.centres)
                DropdownMenuItem<String?>(
                  value: centre.id,
                  child: Text('${centre.code} - ${centre.nom}'),
                ),
            ],
            onChanged: (value) => setState(() => _centreId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: _tiersId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tiers'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Aucun tiers'),
              ),
              for (final tiers in widget.tiers)
                DropdownMenuItem<String?>(
                  value: tiers.id,
                  child: Text(tiers.nom),
                ),
            ],
            onChanged: (value) => setState(() => _tiersId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference piece',
              hintText: 'Numero recu, reference MoMo ou piece interne.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _libelleController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Libelle comptable'),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Libelle requis.' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          EabButton(
            label: 'Valider et generer l ecriture',
            icon: Icons.fact_check_outlined,
            isLoading: _saving,
            fullWidth: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  String? _defaultJournalId(ChurchUnitFinancialAccount? account) {
    if (widget.journals.isEmpty) return null;
    TypeJournalComptable desired;
    if (account?.type == 'bank') {
      desired = TypeJournalComptable.banque;
    } else if (account?.type == 'mobile_money') {
      desired = TypeJournalComptable.banque;
    } else {
      desired = TypeJournalComptable.caisse;
    }
    for (final journal in widget.journals) {
      if (journal.actif && journal.type == desired) return journal.id;
    }
    for (final journal in widget.journals) {
      if (journal.actif) return journal.id;
    }
    return widget.journals.first.id;
  }

  String? _defaultTreasuryAccountId(ChurchUnitFinancialAccount? account) {
    final prefixes = account?.type == 'bank'
        ? const ['512']
        : account?.type == 'mobile_money'
        ? const ['52', '512', '531']
        : const ['531', '57', '512'];
    for (final prefix in prefixes) {
      for (final compte in widget.comptes) {
        if (compte.actif && compte.numero.startsWith(prefix)) return compte.id;
      }
    }
    return widget.comptes.where((c) => c.actif).isEmpty
        ? null
        : widget.comptes.firstWhere((c) => c.actif).id;
  }

  String? _defaultCounterpartAccountId() {
    final desiredNature = widget.movement.type == 'decaissement'
        ? NatureCompte.charge
        : NatureCompte.produit;
    for (final compte in widget.comptes) {
      if (compte.actif && compte.nature == desiredNature) return compte.id;
    }
    for (final compte in widget.comptes) {
      if (compte.actif && compte.id != _treasuryAccountId) return compte.id;
    }
    return null;
  }

  String? _defaultCentreId() {
    for (final centre in widget.centres) {
      if (centre.churchUnitId == widget.movement.churchUnitId) return centre.id;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(operationalFinanceProvider.notifier)
          .validateMovementAsAccountingEntry(
            movementId: widget.movement.id,
            movementType: widget.movement.type,
            churchUnitId: widget.movement.churchUnitId,
            journalId: _journalId!,
            treasuryAccountId: _treasuryAccountId!,
            counterpartAccountId: _counterpartAccountId!,
            date: widget.movement.dateMouvement,
            libelle: _libelleController.text,
            montant: widget.movement.montant,
            referencePiece: _referenceController.text,
            modePaiement: widget.movement.modePaiement,
            centreAnalytiqueId: _centreId,
            tiersId: _tiersId,
          );
      ref.invalidate(ecrituresComptablesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mouvement valide en comptabilite.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RejectMovementForm extends ConsumerStatefulWidget {
  const _RejectMovementForm({required this.movement});

  final FinancialMovement movement;

  @override
  ConsumerState<_RejectMovementForm> createState() =>
      _RejectMovementFormState();
}

class _RejectMovementFormState extends ConsumerState<_RejectMovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movement.libelle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currencyFormatter.format(widget.movement.montant),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motif du rejet',
              hintText: 'Piece manquante, montant incorrect, mauvais compte...',
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Motif requis.' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          EabButton(
            label: 'Rejeter le mouvement',
            icon: Icons.block_outlined,
            variant: EabButtonVariant.danger,
            fullWidth: true,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(operationalFinanceProvider.notifier).rejectMovement(
            movementId: widget.movement.id,
            reason: _reasonController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mouvement rejete.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.movement, required this.account});

  final FinancialMovement movement;
  final ChurchUnitFinancialAccount? account;

  @override
  Widget build(BuildContext context) {
    final isOut = movement.type == 'decaissement';
    final color = isOut ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            isOut ? Icons.north_east_outlined : Icons.south_west_outlined,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.libelle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  [
                    _statusLabel(movement.type),
                    dateFormatter.format(movement.dateMouvement),
                    account?.label ?? 'Compte financier',
                  ].join(' | '),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            currencyFormatter.format(movement.montant),
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _DatePickButton extends StatelessWidget {
  const _DatePickButton({
    required this.label,
    required this.value,
    required this.onPicked,
    this.allowClear = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text(
        value == null ? '$label : aucune' : '$label : ${dateFormatter.format(value!)}',
      ),
    );
  }
}

class _AmountMetric extends StatelessWidget {
  const _AmountMetric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(
          currencyFormatter.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }
}

class _KpiItem {
  const _KpiItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

const _campaignTypes = {
  'cotisation': 'Cotisation',
  'promesse_don': 'Promesse de don',
  'offrande_speciale': 'Offrande speciale',
  'projet': 'Projet',
  'activite': 'Activite',
  'autre': 'Autre',
};

String _campaignTypeLabel(String value) => _campaignTypes[value] ?? value;

String _statusLabel(String value) {
  return switch (value) {
    'brouillon' => 'Brouillon',
    'active' => 'Active',
    'cloturee' => 'Cloturee',
    'annulee' => 'Annulee',
    'ouverte' => 'Ouverte',
    'partielle' => 'Partielle',
    'reglee' => 'Reglee',
    'soumis' => 'Soumis',
    'valide' => 'Valide',
    'rejete' => 'Rejete',
    'annule' => 'Annule',
    _ => value,
  };
}

String _programLabel(Program program) {
  final type = typeProgrammeLabels[program.type] ?? 'Programme';
  return '$type - ${dateFormatter.format(program.date)}';
}

String _contributorLabel(
  FinancialPledge pledge,
  Map<String, Member> memberById,
) {
  final member = pledge.membreId == null ? null : memberById[pledge.membreId];
  if (member != null) return member.fullName;
  if (pledge.contributeurNom?.trim().isNotEmpty ?? false) {
    return pledge.contributeurNom!.trim();
  }
  return 'Contributeur non renseigne';
}

String _movementContributorLabel(
  FinancialMovement movement,
  Map<String, Member> memberById,
) {
  final member = movement.membreId == null ? null : memberById[movement.membreId];
  if (member != null) return member.fullName;
  if (movement.contributeurNom?.trim().isNotEmpty ?? false) {
    return movement.contributeurNom!.trim();
  }
  return 'Non rattache';
}

String _pledgeContributor(FinancialPledge pledge) {
  if (pledge.contributeurNom?.trim().isNotEmpty ?? false) {
    return pledge.contributeurNom!.trim();
  }
  return pledge.membreId == null ? 'Contributeur' : 'Fidele rattache';
}

double? _parseMoney(String? value) {
  final raw = value?.replaceAll(' ', '').replaceAll(',', '.').trim();
  if (raw == null || raw.isEmpty) return null;
  return double.tryParse(raw);
}

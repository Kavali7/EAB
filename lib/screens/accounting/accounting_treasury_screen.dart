import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../providers/accounting_providers.dart';
import '../../ui/ui.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';
import '../../widgets/error_retry_widget.dart';

class AccountingTreasuryScreen extends ConsumerStatefulWidget {
  const AccountingTreasuryScreen({super.key});

  @override
  ConsumerState<AccountingTreasuryScreen> createState() =>
      _AccountingTreasuryScreenState();
}

class _AccountingTreasuryScreenState
    extends ConsumerState<AccountingTreasuryScreen> {
  String? _compteSelectionneId;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  Widget build(BuildContext context) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return AppShell(
      title: 'Tresorerie (Caisses & Banques)',
      currentRoute: '/accounting-treasury',
      showBackButton: true,
      backRoute: '/accounting',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 620
              ? AppSpacing.lg
              : AppSpacing.pagePadding;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ContextHeader(showPorteeComptable: true),
                    const SizedBox(height: AppSpacing.cardGap),
                    _buildFiltersCard(),
                    const SizedBox(height: AppSpacing.cardGap),
                    Expanded(
                      child: comptesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, st) => ErrorRetryWidget(
                          message: 'Erreur chargement plan de comptes : $err',
                          onRetry: () =>
                              ref.invalidate(comptesComptablesProvider),
                        ),
                        data: (comptes) {
                          return _buildContent(
                            comptes: comptes,
                            ecritures: ecritures,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required List<CompteComptable> comptes,
    required List<EcritureComptable> ecritures,
  }) {
    final comptesCaisse = comptes
        .where((c) => c.numero.startsWith('531'))
        .toList();
    final comptesBanque = comptes
        .where((c) => c.numero.startsWith('512'))
        .toList();
    final comptesTresorerie = [...comptesCaisse, ...comptesBanque];
    final selectedCompte = _findCompte(comptesTresorerie, _compteSelectionneId);
    final totalCaisse = comptesCaisse.fold<double>(
      0,
      (sum, c) => sum + _calculerSoldeActif(c.id, ecritures),
    );
    final totalBanque = comptesBanque.fold<double>(
      0,
      (sum, c) => sum + _calculerSoldeActif(c.id, ecritures),
    );
    final totalTresorerie = totalCaisse + totalBanque;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryGrid(
              totalTresorerie: totalTresorerie,
              totalCaisse: totalCaisse,
              totalBanque: totalBanque,
              compact: compact,
            ),
            const SizedBox(height: AppSpacing.cardGap),
            if (compact) ...[
              _buildAccountsSection(
                title: 'Caisses',
                icon: Icons.point_of_sale_outlined,
                comptes: comptesCaisse,
                ecritures: ecritures,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.cardGap),
              _buildAccountsSection(
                title: 'Banques',
                icon: Icons.account_balance_outlined,
                comptes: comptesBanque,
                ecritures: ecritures,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.cardGap),
              _buildDetailsCompte(
                compte: selectedCompte,
                ecritures: ecritures,
                compact: true,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        _buildAccountsSection(
                          title: 'Caisses',
                          icon: Icons.point_of_sale_outlined,
                          comptes: comptesCaisse,
                          ecritures: ecritures,
                          compact: false,
                        ),
                        const SizedBox(height: AppSpacing.cardGap),
                        _buildAccountsSection(
                          title: 'Banques',
                          icon: Icons.account_balance_outlined,
                          comptes: comptesBanque,
                          ecritures: ecritures,
                          compact: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.cardGap),
                  Expanded(
                    flex: 5,
                    child: _buildDetailsCompte(
                      compte: selectedCompte,
                      ecritures: ecritures,
                      compact: false,
                    ),
                  ),
                ],
              ),
          ],
        );

        return SingleChildScrollView(child: content);
      },
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildDateChip(
              label: 'Du',
              value: _dateDebut != null
                  ? _formatDate(_dateDebut!)
                  : 'debut du mois',
              onPressed: () => _selectDate(isStart: true),
            ),
            _buildDateChip(
              label: 'Au',
              value: _dateFin != null ? _formatDate(_dateFin!) : 'fin du mois',
              onPressed: () => _selectDate(isStart: false),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _dateDebut = null;
                  _dateFin = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reinitialiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required String value,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text('$label : $value'),
    );
  }

  Widget _buildSummaryGrid({
    required double totalTresorerie,
    required double totalCaisse,
    required double totalBanque,
    required bool compact,
  }) {
    final cards = [
      _SummaryCard(
        title: 'Tresorerie nette',
        value: _formatMoney(totalTresorerie),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      _SummaryCard(
        title: 'Caisses',
        value: _formatMoney(totalCaisse),
        icon: Icons.point_of_sale_outlined,
        color: AppColors.teal,
      ),
      _SummaryCard(
        title: 'Banques',
        value: _formatMoney(totalBanque),
        icon: Icons.account_balance_outlined,
        color: AppColors.indigo,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact ? 1 : 3;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.cardGap) /
            columns;
        return Wrap(
          spacing: AppSpacing.cardGap,
          runSpacing: AppSpacing.cardGap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _buildAccountsSection({
    required String title,
    required IconData icon,
    required List<CompteComptable> comptes,
    required List<EcritureComptable> ecritures,
    required bool compact,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (comptes.isEmpty)
              _buildEmptyState('Aucun compte trouve.')
            else if (compact)
              Column(
                children: [
                  for (final compte in comptes)
                    _buildAccountCard(
                      compte: compte,
                      solde: _calculerSoldeActif(compte.id, ecritures),
                    ),
                ],
              )
            else
              _buildAccountsTable(comptes: comptes, ecritures: ecritures),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsTable({
    required List<CompteComptable> comptes,
    required List<EcritureComptable> ecritures,
  }) {
    return DataTable(
      columnSpacing: 24,
      headingTextStyle: AppTextStyles.label,
      dataTextStyle: AppTextStyles.body,
      columns: const [
        DataColumn(label: Text('Compte')),
        DataColumn(label: Text('Intitule')),
        DataColumn(label: Text('Solde')),
        DataColumn(label: Text('Actions')),
      ],
      rows: comptes.map((c) {
        final solde = _calculerSoldeActif(c.id, ecritures);
        return DataRow(
          selected: _compteSelectionneId == c.id,
          cells: [
            DataCell(Text(c.numero, style: AppTextStyles.mono)),
            DataCell(Text(c.intitule)),
            DataCell(Text(_formatMoney(solde))),
            DataCell(
              TextButton.icon(
                onPressed: () => setState(() => _compteSelectionneId = c.id),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Mouvements'),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAccountCard({
    required CompteComptable compte,
    required double solde,
  }) {
    final selected = _compteSelectionneId == compte.id;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.secondaryLight.withValues(alpha: 0.55)
            : null,
        border: Border.all(
          color: selected ? AppColors.secondary : AppColors.divider,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => setState(() => _compteSelectionneId = compte.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(compte.numero, style: AppTextStyles.mono),
                  const Spacer(),
                  Text(
                    _formatMoney(solde),
                    style: AppTextStyles.subtitle.copyWith(
                      color: solde < 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                compte.intitule,
                style: AppTextStyles.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _compteSelectionneId = compte.id),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Voir les mouvements'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCompte({
    required CompteComptable? compte,
    required List<EcritureComptable> ecritures,
    required bool compact,
  }) {
    if (compte == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: _buildEmptyState(
            'Selectionnez une caisse ou une banque pour consulter les mouvements.',
          ),
        ),
      );
    }

    final mouvements = _extraireMouvements(compte.id, ecritures);
    final solde = _calculerSoldeActif(compte.id, ecritures);

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
                      Text(compte.intitule, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(compte.numero, style: AppTextStyles.mono),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatMoney(solde),
                  style: AppTextStyles.heading3.copyWith(
                    color: solde < 0 ? AppColors.error : AppColors.success,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (mouvements.isEmpty)
              _buildEmptyState('Aucun mouvement sur la periode selectionnee.')
            else
              Column(
                children: [
                  for (final mouvement in mouvements)
                    _buildMovementTile(mouvement, compact: compact),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTile(
    _MouvementTresorerie mouvement, {
    required bool compact,
  }) {
    final net = mouvement.debit - mouvement.credit;
    final color = net >= 0 ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              net >= 0 ? Icons.south_west : Icons.north_east,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mouvement.libelle,
                  style: AppTextStyles.subtitle,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    _formatDate(mouvement.date),
                    if (mouvement.reference != null &&
                        mouvement.reference!.isNotEmpty)
                      'Ref: ${mouvement.reference}',
                  ].join(' - '),
                  style: AppTextStyles.bodySmall,
                ),
                if (compact) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Debit ${_formatMoney(mouvement.debit)} / Credit ${_formatMoney(mouvement.credit)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _formatMoney(net.abs()),
            style: AppTextStyles.subtitle.copyWith(color: color),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }

  double _calculerSoldeActif(
    String idCompte,
    List<EcritureComptable> ecritures,
  ) {
    double debit = 0;
    double credit = 0;
    for (final e in ecritures) {
      if (!_estDansPeriode(e.date)) continue;
      for (final l in e.lignes) {
        if (l.idCompteComptable == idCompte) {
          debit += l.debit ?? 0;
          credit += l.credit ?? 0;
        }
      }
    }
    return debit - credit;
  }

  CompteComptable? _findCompte(List<CompteComptable> comptes, String? id) {
    if (id == null) return null;
    for (final compte in comptes) {
      if (compte.id == id) return compte;
    }
    return null;
  }

  List<_MouvementTresorerie> _extraireMouvements(
    String idCompte,
    List<EcritureComptable> ecritures,
  ) {
    final result = <_MouvementTresorerie>[];
    for (final e in ecritures) {
      if (!_estDansPeriode(e.date)) continue;
      for (final l in e.lignes) {
        if (l.idCompteComptable == idCompte) {
          final debit = l.debit ?? 0;
          final credit = l.credit ?? 0;
          result.add(
            _MouvementTresorerie(
              date: e.date,
              libelle: (l.libelle?.isNotEmpty ?? false)
                  ? l.libelle!
                  : e.libelle,
              debit: debit,
              credit: credit,
              reference: e.referencePiece,
            ),
          );
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatMoney(double value) => currencyFormatter.format(value);

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_dateDebut ?? DateTime(now.year, now.month, 1))
          : (_dateFin ?? DateTime(now.year, now.month + 1, 0)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  bool _estDansPeriode(DateTime d) {
    if (_dateDebut != null && d.isBefore(_dateDebut!)) return false;
    if (_dateFin != null && d.isAfter(_dateFin!)) return false;
    return true;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _MouvementTresorerie {
  _MouvementTresorerie({
    required this.date,
    required this.libelle,
    required this.debit,
    required this.credit,
    required this.reference,
  });

  final DateTime date;
  final String libelle;
  final double debit;
  final double credit;
  final String? reference;
}

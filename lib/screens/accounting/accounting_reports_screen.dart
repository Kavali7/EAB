import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/compte_comptable.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/ecriture_comptable.dart';
import 'package:eab/models/tiers.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/error_retry_widget.dart';

import 'accounting_balance_print_screen.dart';
import 'accounting_ledger_print_screen.dart';

class AccountingReportsScreen extends ConsumerStatefulWidget {
  const AccountingReportsScreen({super.key});

  @override
  ConsumerState<AccountingReportsScreen> createState() =>
      _AccountingReportsScreenState();
}

class _AccountingReportsScreenState
    extends ConsumerState<AccountingReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _compteGrandLivreSelectionneId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ecritures = ref.watch(ecrituresFiltreesProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final tiersAsync = ref.watch(tiersProvider);

    return AppShell(
      title: 'Etats comptables',
      currentRoute: '/accounting-reports',
      showBackButton: true,
      backRoute: '/accounting',
      body: comptesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorRetryWidget(
          message: 'Erreur chargement plan de comptes : $err',
          onRetry: () => ref.invalidate(comptesComptablesProvider),
        ),
        data: (comptes) {
          final tiers = tiersAsync.asData?.value ?? [];
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.all(
                      compact ? AppSpacing.lg : AppSpacing.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ContextHeader(showPorteeComptable: true),
                        const SizedBox(height: AppSpacing.md),
                        _ReportsTabs(controller: _tabController),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildBalanceTab(comptes, ecritures, compact),
                              _buildGrandLivreTab(comptes, ecritures, compact),
                              _buildTiersTab(
                                comptes,
                                ecritures,
                                tiers,
                                compact,
                              ),
                              _buildExportsTab(
                                comptes,
                                ecritures,
                                tiers,
                                compact,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBalanceTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
    bool compact,
  ) {
    final lignes = _computeBalanceLines(comptes, ecritures);
    final totalDebits = lignes.fold<double>(0, (sum, l) => sum + l.debit);
    final totalCredits = lignes.fold<double>(0, (sum, l) => sum + l.credit);
    final ecart = totalDebits - totalCredits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionToolbar(
          title: 'Balance generale',
          subtitle: '${lignes.length} comptes mouvementes',
          action: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountingBalancePrintScreen(),
                ),
              );
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('Apercu'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TotalsStrip(
          items: [
            _TotalItem('Debits', _money(totalDebits), AppColors.primary),
            _TotalItem('Credits', _money(totalCredits), AppColors.teal),
            _TotalItem(
              'Ecart',
              _money(ecart),
              ecart == 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: lignes.isEmpty
              ? const _EmptyState(message: 'Aucun mouvement pour la balance.')
              : compact
              ? ListView.separated(
                  itemCount: lignes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _BalanceCard(line: lignes[index]),
                )
              : _BalanceTable(
                  lignes: lignes,
                  totalDebits: totalDebits,
                  totalCredits: totalCredits,
                ),
        ),
      ],
    );
  }

  Widget _buildGrandLivreTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
    bool compact,
  ) {
    final comptesTries = [...comptes]
      ..sort((a, b) => a.numero.compareTo(b.numero));
    final compteSelectionne = _compteGrandLivreSelectionneId == null
        ? null
        : comptesTries.firstWhere(
            (c) => c.id == _compteGrandLivreSelectionneId,
            orElse: () => comptesTries.first,
          );
    final mouvements = compteSelectionne == null
        ? <_MouvementCompte>[]
        : _computeMouvements(compteSelectionne, ecritures);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionToolbar(
          title: 'Grand livre',
          subtitle: compteSelectionne == null
              ? 'Selectionnez un compte'
              : '${mouvements.length} mouvements',
          action: compteSelectionne == null
              ? null
              : OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountingLedgerPrintScreen(
                          idCompteComptable: compteSelectionne.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Apercu'),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: compteSelectionne?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Compte',
            prefixIcon: Icon(Icons.account_tree_outlined),
          ),
          hint: const Text('Choisir un compte'),
          items: comptesTries
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.numero} - ${c.intitule}'),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _compteGrandLivreSelectionneId = v);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: compteSelectionne == null
              ? const _EmptyState(
                  message: 'Selectionnez un compte pour consulter le detail.',
                )
              : mouvements.isEmpty
              ? const _EmptyState(message: 'Aucun mouvement sur ce compte.')
              : compact
              ? _GrandLivreMobileList(mouvements: mouvements)
              : _GrandLivreTable(mouvements: mouvements),
        ),
      ],
    );
  }

  Widget _buildTiersTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
    List<Tiers> tiers,
    bool compact,
  ) {
    final lignes = _computeTiersLines(ecritures, tiers);
    final totalDebiteur = lignes
        .where((l) => l.solde > 0)
        .fold<double>(0, (sum, l) => sum + l.solde);
    final totalCrediteur = lignes
        .where((l) => l.solde < 0)
        .fold<double>(0, (sum, l) => sum + l.solde.abs());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionToolbar(
          title: 'Soldes tiers',
          subtitle: '${lignes.length} tiers suivis',
        ),
        const SizedBox(height: AppSpacing.md),
        _TotalsStrip(
          items: [
            _TotalItem('Debiteurs', _money(totalDebiteur), AppColors.primary),
            _TotalItem('Crediteurs', _money(totalCrediteur), AppColors.error),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: lignes.isEmpty
              ? const _EmptyState(message: 'Aucun tiers defini.')
              : compact
              ? ListView.separated(
                  itemCount: lignes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _TiersCard(line: lignes[index]),
                )
              : _TiersTable(lignes: lignes),
        ),
      ],
    );
  }

  Widget _buildExportsTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
    List<Tiers> tiers,
    bool compact,
  ) {
    final previewRows = _computeFecPreview(comptes, ecritures);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionToolbar(
          title: 'Exports et FEC',
          subtitle: '${previewRows.length} lignes dans l apercu',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ExportAction(
              icon: Icons.table_view_outlined,
              title: 'Balance',
              subtitle: 'CSV / Excel',
              onPressed: () => _showExportSnack(
                'Export Balance (CSV/Excel) sera implemente cote backend.',
              ),
            ),
            _ExportAction(
              icon: Icons.menu_book_outlined,
              title: 'Grand livre',
              subtitle: 'CSV / Excel',
              onPressed: () => _showExportSnack(
                'Export Grand livre (CSV/Excel) sera implemente cote backend.',
              ),
            ),
            _ExportAction(
              icon: Icons.upload_file_outlined,
              title: 'FEC',
              subtitle: 'Generation simulee',
              onPressed: () =>
                  _showExportSnack('Export FEC sera prepare cote backend.'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: previewRows.isEmpty
              ? const _EmptyState(message: 'Aucune ligne a exporter.')
              : compact
              ? ListView.separated(
                  itemCount: previewRows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _FecPreviewCard(row: previewRows[index]),
                )
              : _FecPreviewTable(rows: previewRows),
        ),
      ],
    );
  }

  List<_LigneBalance> _computeBalanceLines(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
  ) {
    final comptesParId = {for (final c in comptes) c.id: c};
    final Map<String, double> debitsParCompte = {};
    final Map<String, double> creditsParCompte = {};

    for (final e in ecritures) {
      for (final l in e.lignes) {
        final compte = comptesParId[l.idCompteComptable];
        if (compte == null) continue;
        debitsParCompte[compte.id] =
            (debitsParCompte[compte.id] ?? 0) + (l.debit ?? 0);
        creditsParCompte[compte.id] =
            (creditsParCompte[compte.id] ?? 0) + (l.credit ?? 0);
      }
    }

    final lignes = <_LigneBalance>[];
    for (final compte in comptes) {
      final totalD = debitsParCompte[compte.id] ?? 0;
      final totalC = creditsParCompte[compte.id] ?? 0;
      if (totalD == 0 && totalC == 0) continue;
      lignes.add(
        _LigneBalance(
          numero: compte.numero,
          intitule: compte.intitule,
          debit: totalD,
          credit: totalC,
          solde: totalD - totalC,
        ),
      );
    }
    lignes.sort((a, b) => a.numero.compareTo(b.numero));
    return lignes;
  }

  List<_MouvementCompte> _computeMouvements(
    CompteComptable compte,
    List<EcritureComptable> ecritures,
  ) {
    final mouvements = <_MouvementCompte>[];
    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable != compte.id) continue;
        mouvements.add(
          _MouvementCompte(
            date: e.date,
            libelle: (l.libelle?.isNotEmpty ?? false) ? l.libelle! : e.libelle,
            reference: e.referencePiece,
            debit: l.debit ?? 0,
            credit: l.credit ?? 0,
          ),
        );
      }
    }
    mouvements.sort((a, b) => a.date.compareTo(b.date));

    double solde = 0;
    return mouvements.map((m) {
      solde += m.debit - m.credit;
      return m.copyWith(solde: solde);
    }).toList();
  }

  List<_LigneTiers> _computeTiersLines(
    List<EcritureComptable> ecritures,
    List<Tiers> tiers,
  ) {
    final Map<String, double> soldesParTiers = {};
    for (final e in ecritures) {
      for (final l in e.lignes) {
        final idTiers = l.idTiers;
        if (idTiers == null) continue;
        soldesParTiers[idTiers] =
            (soldesParTiers[idTiers] ?? 0) + ((l.debit ?? 0) - (l.credit ?? 0));
      }
    }
    final lignes =
        tiers
            .map((t) => _LigneTiers(tiers: t, solde: soldesParTiers[t.id] ?? 0))
            .toList()
          ..sort((a, b) => b.solde.abs().compareTo(a.solde.abs()));
    return lignes;
  }

  List<_FecPreviewRow> _computeFecPreview(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
  ) {
    final comptesParId = {for (final c in comptes) c.id: c};
    return ecritures.take(20).expand((e) {
      return e.lignes.map((l) {
        final compte = comptesParId[l.idCompteComptable];
        return _FecPreviewRow(
          date: e.date,
          journal: e.idJournal,
          compte: compte == null
              ? l.idCompteComptable
              : '${compte.numero} - ${compte.intitule}',
          libelle: l.libelle ?? e.libelle,
          debit: l.debit ?? 0,
          credit: l.credit ?? 0,
        );
      });
    }).toList();
  }

  void _showExportSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(double value) => currencyFormatter.format(value);
}

class _ReportsTabs extends StatelessWidget {
  const _ReportsTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tabs: const [
          Tab(
            icon: Icon(Icons.account_balance_wallet_outlined),
            text: 'Balance',
          ),
          Tab(icon: Icon(Icons.menu_book_outlined), text: 'Grand livre'),
          Tab(icon: Icon(Icons.people_alt_outlined), text: 'Tiers'),
          Tab(icon: Icon(Icons.upload_file_outlined), text: 'Exports / FEC'),
        ],
      ),
    );
  }
}

class _SectionToolbar extends StatelessWidget {
  const _SectionToolbar({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              if (action != null) ...[
                const SizedBox(height: AppSpacing.sm),
                action!,
              ],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: titleBlock),
            if (action != null) action!,
          ],
        );
      },
    );
  }
}

class _TotalsStrip extends StatelessWidget {
  const _TotalsStrip({required this.items});

  final List<_TotalItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items.map((item) {
            final width = compact
                ? (constraints.maxWidth - AppSpacing.sm) / 2
                : (constraints.maxWidth - (items.length - 1) * AppSpacing.sm) /
                      items.length;
            return SizedBox(
              width: width.clamp(150, constraints.maxWidth).toDouble(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.value,
                      style: AppTextStyles.subtitle.copyWith(color: item.color),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({
    required this.lignes,
    required this.totalDebits,
    required this.totalCredits,
  });

  final List<_LigneBalance> lignes;
  final double totalDebits;
  final double totalCredits;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Compte')),
          DataColumn(label: Text('Intitule')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde')),
        ],
        rows: [
          ...lignes.map(
            (l) => DataRow(
              cells: [
                DataCell(Text(l.numero)),
                DataCell(Text(l.intitule)),
                DataCell(Text(currencyFormatter.format(l.debit))),
                DataCell(Text(currencyFormatter.format(l.credit))),
                DataCell(_AmountText(value: l.solde)),
              ],
            ),
          ),
          DataRow(
            selected: true,
            cells: [
              const DataCell(Text('TOTALS')),
              const DataCell(Text('')),
              DataCell(Text(currencyFormatter.format(totalDebits))),
              DataCell(Text(currencyFormatter.format(totalCredits))),
              DataCell(_AmountText(value: totalDebits - totalCredits)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrandLivreTable extends StatelessWidget {
  const _GrandLivreTable({required this.mouvements});

  final List<_MouvementCompte> mouvements;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Reference')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde')),
        ],
        rows: mouvements
            .map(
              (m) => DataRow(
                cells: [
                  DataCell(Text(dateFormatter.format(m.date))),
                  DataCell(Text(m.reference ?? '-')),
                  DataCell(Text(m.libelle)),
                  DataCell(Text(currencyFormatter.format(m.debit))),
                  DataCell(Text(currencyFormatter.format(m.credit))),
                  DataCell(_AmountText(value: m.solde)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TiersTable extends StatelessWidget {
  const _TiersTable({required this.lignes});

  final List<_LigneTiers> lignes;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nom')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Contact')),
          DataColumn(label: Text('Solde')),
        ],
        rows: lignes.map((l) {
          final t = l.tiers;
          return DataRow(
            cells: [
              DataCell(Text(t.nom)),
              DataCell(Text(_typeTiersLabel(t.type))),
              DataCell(Text(t.telephone ?? t.email ?? '-')),
              DataCell(_AmountText(value: l.solde)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FecPreviewTable extends StatelessWidget {
  const _FecPreviewTable({required this.rows});

  final List<_FecPreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Journal')),
          DataColumn(label: Text('Compte')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
        ],
        rows: rows
            .map(
              (row) => DataRow(
                cells: [
                  DataCell(Text(dateFormatter.format(row.date))),
                  DataCell(Text(row.journal)),
                  DataCell(Text(row.compte)),
                  DataCell(Text(row.libelle)),
                  DataCell(Text(currencyFormatter.format(row.debit))),
                  DataCell(Text(currencyFormatter.format(row.credit))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TableFrame extends StatelessWidget {
  const _TableFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.line});

  final _LigneBalance line;

  @override
  Widget build(BuildContext context) {
    return _MobileCard(
      title: '${line.numero} - ${line.intitule}',
      children: [
        _AmountRow(label: 'Debit', value: line.debit),
        _AmountRow(label: 'Credit', value: line.credit),
        _AmountRow(label: 'Solde', value: line.solde, strong: true),
      ],
    );
  }
}

class _GrandLivreMobileList extends StatelessWidget {
  const _GrandLivreMobileList({required this.mouvements});

  final List<_MouvementCompte> mouvements;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: mouvements.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final m = mouvements[index];
        return _MobileCard(
          title: m.libelle,
          subtitle: '${dateFormatter.format(m.date)} | ${m.reference ?? '-'}',
          children: [
            _AmountRow(label: 'Debit', value: m.debit),
            _AmountRow(label: 'Credit', value: m.credit),
            _AmountRow(label: 'Solde', value: m.solde, strong: true),
          ],
        );
      },
    );
  }
}

class _TiersCard extends StatelessWidget {
  const _TiersCard({required this.line});

  final _LigneTiers line;

  @override
  Widget build(BuildContext context) {
    final t = line.tiers;
    return _MobileCard(
      title: t.nom,
      subtitle: _typeTiersLabel(t.type),
      children: [
        if (t.telephone != null || t.email != null)
          _InfoLine(
            icon: Icons.contact_phone_outlined,
            text: t.telephone ?? t.email!,
          ),
        _AmountRow(label: 'Solde', value: line.solde, strong: true),
      ],
    );
  }
}

class _FecPreviewCard extends StatelessWidget {
  const _FecPreviewCard({required this.row});

  final _FecPreviewRow row;

  @override
  Widget build(BuildContext context) {
    return _MobileCard(
      title: row.libelle,
      subtitle: '${dateFormatter.format(row.date)} | Journal ${row.journal}',
      children: [
        _InfoLine(icon: Icons.tag_outlined, text: row.compte),
        _AmountRow(label: 'Debit', value: row.debit),
        _AmountRow(label: 'Credit', value: row.credit),
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _ExportAction extends StatelessWidget {
  const _ExportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(AppSpacing.md),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          _AmountText(value: value, strong: strong),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({required this.value, this.strong = false});

  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = value == 0
        ? AppColors.textSecondary
        : value > 0
        ? AppColors.success
        : AppColors.error;
    return Text(
      currencyFormatter.format(value),
      textAlign: TextAlign.right,
      style: AppTextStyles.body.copyWith(
        color: color,
        fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TotalItem {
  const _TotalItem(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _LigneBalance {
  const _LigneBalance({
    required this.numero,
    required this.intitule,
    required this.debit,
    required this.credit,
    required this.solde,
  });

  final String numero;
  final String intitule;
  final double debit;
  final double credit;
  final double solde;
}

class _MouvementCompte {
  const _MouvementCompte({
    required this.date,
    required this.libelle,
    required this.reference,
    required this.debit,
    required this.credit,
    this.solde = 0,
  });

  final DateTime date;
  final String libelle;
  final String? reference;
  final double debit;
  final double credit;
  final double solde;

  _MouvementCompte copyWith({double? solde}) {
    return _MouvementCompte(
      date: date,
      libelle: libelle,
      reference: reference,
      debit: debit,
      credit: credit,
      solde: solde ?? this.solde,
    );
  }
}

class _LigneTiers {
  const _LigneTiers({required this.tiers, required this.solde});

  final Tiers tiers;
  final double solde;
}

class _FecPreviewRow {
  const _FecPreviewRow({
    required this.date,
    required this.journal,
    required this.compte,
    required this.libelle,
    required this.debit,
    required this.credit,
  });

  final DateTime date;
  final String journal;
  final String compte;
  final String libelle;
  final double debit;
  final double credit;
}

String _typeTiersLabel(TypeTiers type) {
  return switch (type) {
    TypeTiers.membre => 'Membre',
    TypeTiers.fournisseur => 'Fournisseur',
    TypeTiers.bailleur => 'Bailleur',
    TypeTiers.employe => 'Employe',
    TypeTiers.partenaire => 'Partenaire',
    TypeTiers.autre => 'Autre',
  };
}

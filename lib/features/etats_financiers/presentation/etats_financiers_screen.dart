/// Ecran des etats financiers SYCEBNL.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:eab/core/errors/error_handler.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';

import '../application/reports_providers.dart';
import '../data/reports_repository.dart';
import '../services/export_service.dart';

final _currencyFmt = NumberFormat('#,##0', 'fr_FR');
final _dateFmt = DateFormat('dd/MM/yyyy');

class EtatsFinanciersScreen extends ConsumerStatefulWidget {
  const EtatsFinanciersScreen({super.key});

  @override
  ConsumerState<EtatsFinanciersScreen> createState() =>
      _EtatsFinanciersScreenState();
}

class _EtatsFinanciersScreenState extends ConsumerState<EtatsFinanciersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;
  String? _loadedOrgId;

  List<LigneBalance> _balance = [];
  List<LigneResultat> _resultat = [];
  List<LigneBilan> _bilan = [];
  List<LigneGrandLivre> _grandLivre = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _dateDebut = DateTime(now.year, 1, 1);
    _dateFin = DateTime(now.year, 12, 31);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final org = ref.read(currentOrganizationProvider).value;
    if (org == null) return;

    setState(() {
      _isLoading = true;
      _loadedOrgId = org.id;
    });
    final repo = ref.read(reportsRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.fetchBalanceGenerale(
          org.id,
          dateDebut: _dateDebut,
          dateFin: _dateFin,
        ),
        repo.fetchCompteResultat(
          org.id,
          dateDebut: _dateDebut,
          dateFin: _dateFin,
        ),
        repo.fetchBilan(org.id, dateFin: _dateFin),
        repo.fetchGrandLivre(org.id, dateDebut: _dateDebut, dateFin: _dateFin),
      ]);
      setState(() {
        _balance = results[0] as List<LigneBalance>;
        _resultat = results[1] as List<LigneResultat>;
        _bilan = results[2] as List<LigneBilan>;
        _grandLivre = results[3] as List<LigneGrandLivre>;
      });
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onExport(String format) {
    final org = ref.read(currentOrganizationProvider).value;
    final orgName = org?.nom ?? 'Organisation';
    final periode =
        '${_dateFmt.format(_dateDebut!)} - ${_dateFmt.format(_dateFin!)}';

    if (format == 'pdf') {
      _exportPdf(orgName, periode);
    } else {
      _exportCsv();
    }
  }

  void _exportPdf(String orgName, String periode) {
    final tabNames = ['Balance', 'Resultat', 'Bilan', 'Grand livre'];
    final tab = _tabCtrl.index;
    final doc = switch (tab) {
      0 => PdfExportService.buildBalancePdf(
        orgName: orgName,
        periode: periode,
        lignes: _balance,
      ),
      1 => PdfExportService.buildResultatPdf(
        orgName: orgName,
        periode: periode,
        lignes: _resultat,
      ),
      2 => PdfExportService.buildBilanPdf(
        orgName: orgName,
        dateFin: _dateFmt.format(_dateFin!),
        lignes: _bilan,
      ),
      3 => PdfExportService.buildGrandLivrePdf(
        orgName: orgName,
        periode: periode,
        lignes: _grandLivre,
      ),
      _ => null,
    };

    if (doc != null) {
      PdfExportService.preview(context, doc, '${tabNames[tab]} - $orgName');
    }
  }

  void _exportCsv() {
    final csv = switch (_tabCtrl.index) {
      0 => CsvExportService.balanceToCsv(_balance),
      1 => CsvExportService.resultatToCsv(_resultat),
      3 => CsvExportService.grandLivreToCsv(_grandLivre),
      _ => null,
    };

    if (csv != null) {
      Printing.sharePdf(
        bytes: Uint8List.fromList(csv.codeUnits),
        filename: 'export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } else {
      context.showSuccess('Export CSV non disponible pour cet onglet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(currentOrganizationProvider).value;
    if (org != null && _loadedOrgId != org.id && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAll();
      });
    }

    return AppShell(
      title: 'Etats financiers',
      currentRoute: '/etats-financiers',
      showBackButton: true,
      backRoute: '/accounting',
      body: LayoutBuilder(
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
                    const ContextHeader(showPorteeComptable: false),
                    const SizedBox(height: AppSpacing.md),
                    _FiltersBar(
                      compact: compact,
                      dateDebut: _dateDebut,
                      dateFin: _dateFin,
                      isLoading: _isLoading,
                      onDateDebutChanged: (d) => setState(() => _dateDebut = d),
                      onDateFinChanged: (d) => setState(() => _dateFin = d),
                      onRefresh: _loadAll,
                      onExport: _onExport,
                    ),
                    SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                    _ReportsTabs(controller: _tabCtrl),
                    SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: SkeletonLoader())
                          : TabBarView(
                              controller: _tabCtrl,
                              children: [
                                _buildBalance(compact),
                                _buildResultat(compact),
                                _buildBilan(compact),
                                _buildGrandLivre(compact),
                              ],
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

  Widget _buildBalance(bool compact) {
    if (_balance.isEmpty) {
      return const _EmptyState(
        message: 'Aucune ecriture validee pour cette periode.',
      );
    }

    final totalD = _balance.fold(0.0, (s, l) => s + l.totalDebit);
    final totalC = _balance.fold(0.0, (s, l) => s + l.totalCredit);
    final totalSD = _balance.fold(0.0, (s, l) => s + l.soldeDebiteur);
    final totalSC = _balance.fold(0.0, (s, l) => s + l.soldeCrediteur);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Balance generale',
          subtitle: '${_balance.length} comptes',
        ),
        const SizedBox(height: AppSpacing.md),
        _TotalsStrip(
          items: [
            _TotalItem('Debit', totalD, AppColors.primary),
            _TotalItem('Credit', totalC, AppColors.teal),
            _TotalItem('Solde D', totalSD, AppColors.success),
            _TotalItem('Solde C', totalSC, AppColors.error),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: compact
              ? ListView.separated(
                  itemCount: _balance.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _BalanceCard(line: _balance[index]),
                )
              : _BalanceTable(lignes: _balance),
        ),
      ],
    );
  }

  Widget _buildResultat(bool compact) {
    if (_resultat.isEmpty) {
      return const _EmptyState(
        message: 'Aucune ecriture de charges ou produits pour cette periode.',
      );
    }

    final produits = _resultat.where((l) => l.section == 'produits').toList();
    final charges = _resultat.where((l) => l.section == 'charges').toList();
    final totalProduits = produits.fold(0.0, (s, l) => s + l.montant);
    final totalCharges = charges.fold(0.0, (s, l) => s + l.montant);
    final resultat = totalProduits - totalCharges;

    return ListView(
      children: [
        _ResultatNetCard(resultat: resultat),
        const SizedBox(height: AppSpacing.md),
        _ResultatSection(
          title: 'Produits',
          total: totalProduits,
          lignes: produits,
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.md),
        _ResultatSection(
          title: 'Charges',
          total: totalCharges,
          lignes: charges,
          compact: compact,
        ),
      ],
    );
  }

  Widget _buildBilan(bool compact) {
    if (_bilan.isEmpty) {
      return const _EmptyState(
        message: 'Aucun solde de bilan pour cette periode.',
      );
    }

    final actif = _bilan.where((l) => l.section == 'actif').toList();
    final passif = _bilan.where((l) => l.section == 'passif').toList();
    final totalActif = actif.fold(0.0, (s, l) => s + l.solde);
    final totalPassif = passif.fold(0.0, (s, l) => s + l.solde);

    final sections = [
      _BilanSection(title: 'Actif', total: totalActif, lignes: actif),
      _BilanSection(title: 'Passif', total: totalPassif, lignes: passif),
    ];

    if (compact) {
      return ListView.separated(
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => sections[index],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: sections[0]),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: sections[1]),
      ],
    );
  }

  Widget _buildGrandLivre(bool compact) {
    if (_grandLivre.isEmpty) {
      return const _EmptyState(message: 'Aucun mouvement pour cette periode.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Grand livre',
          subtitle: '${_grandLivre.length} mouvements',
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: compact
              ? ListView.separated(
                  itemCount: _grandLivre.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _GrandLivreCard(line: _grandLivre[index]),
                )
              : _GrandLivreTable(lignes: _grandLivre),
        ),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.compact,
    required this.dateDebut,
    required this.dateFin,
    required this.isLoading,
    required this.onDateDebutChanged,
    required this.onDateFinChanged,
    required this.onRefresh,
    required this.onExport,
  });

  final bool compact;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool isLoading;
  final ValueChanged<DateTime?> onDateDebutChanged;
  final ValueChanged<DateTime?> onDateFinChanged;
  final VoidCallback onRefresh;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    final dateFields = [
      EabDateField(
        label: 'Du',
        value: dateDebut,
        onChanged: onDateDebutChanged,
      ),
      EabDateField(label: 'Au', value: dateFin, onChanged: onDateFinChanged),
    ];
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact)
          IconButton.filled(
            tooltip: 'Actualiser',
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_outlined),
          )
        else
          EabButton(
            label: 'Actualiser',
            variant: EabButtonVariant.primary,
            size: EabButtonSize.small,
            isLoading: isLoading,
            onPressed: onRefresh,
          ),
        const SizedBox(width: AppSpacing.sm),
        PopupMenuButton<String>(
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Exporter',
          onSelected: onExport,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            PopupMenuItem(value: 'csv', child: Text('Export CSV')),
          ],
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: dateFields[0]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: dateFields[1]),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              children: [
                Expanded(child: dateFields[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: dateFields[1]),
                const SizedBox(width: AppSpacing.md),
                actions,
              ],
            ),
    );
  }
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
          Tab(icon: Icon(Icons.account_balance_outlined), text: 'Balance'),
          Tab(icon: Icon(Icons.trending_up_outlined), text: 'Resultat'),
          Tab(icon: Icon(Icons.balance_outlined), text: 'Bilan'),
          Tab(icon: Icon(Icons.menu_book_outlined), text: 'Grand livre'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.bodySmall),
      ],
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
        final compact = constraints.maxWidth < 720;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items.map((item) {
            final columns = compact ? 2 : items.length;
            final width =
                (constraints.maxWidth - ((columns - 1) * AppSpacing.sm)) /
                columns;
            return SizedBox(
              width: width.clamp(150, constraints.maxWidth).toDouble(),
              child: _MetricTile(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final _TotalItem item;

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
          Text(item.label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _money(item.value),
            style: AppTextStyles.subtitle.copyWith(color: item.color),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.line});

  final LigneBalance line;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: '${line.numero} - ${line.intitule}',
      subtitle: line.nature,
      children: [
        _AmountRow(label: 'Debit', value: line.totalDebit),
        _AmountRow(label: 'Credit', value: line.totalCredit),
        _AmountRow(label: 'Solde debiteur', value: line.soldeDebiteur),
        _AmountRow(label: 'Solde crediteur', value: line.soldeCrediteur),
      ],
    );
  }
}

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({required this.lignes});

  final List<LigneBalance> lignes;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('N')),
          DataColumn(label: Text('Intitule')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde D')),
          DataColumn(label: Text('Solde C')),
        ],
        rows: lignes
            .map(
              (l) => DataRow(
                cells: [
                  DataCell(Text(l.numero)),
                  DataCell(SizedBox(width: 260, child: Text(l.intitule))),
                  DataCell(Text(_money(l.totalDebit))),
                  DataCell(Text(_money(l.totalCredit))),
                  DataCell(
                    Text(l.soldeDebiteur > 0 ? _money(l.soldeDebiteur) : '-'),
                  ),
                  DataCell(
                    Text(l.soldeCrediteur > 0 ? _money(l.soldeCrediteur) : '-'),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ResultatNetCard extends StatelessWidget {
  const _ResultatNetCard({required this.resultat});

  final double resultat;

  @override
  Widget build(BuildContext context) {
    final positive = resultat >= 0;
    final color = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.trending_up_outlined
                : Icons.trending_down_outlined,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              positive ? 'Benefice net' : 'Perte nette',
              style: AppTextStyles.subtitle.copyWith(color: color),
            ),
          ),
          Text(
            _money(resultat.abs()),
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ResultatSection extends StatelessWidget {
  const _ResultatSection({
    required this.title,
    required this.total,
    required this.lignes,
    required this.compact,
  });

  final String title;
  final double total;
  final List<LigneResultat> lignes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '$title - ${_money(total)}',
      child: lignes.isEmpty
          ? const Text(
              'Aucune ligne',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : compact
          ? Column(
              children: lignes
                  .map(
                    (l) => _ReportCard(
                      title: '${l.numero} - ${l.intitule}',
                      children: [
                        _AmountRow(label: 'Montant', value: l.montant),
                      ],
                    ),
                  )
                  .toList(),
            )
          : _ResultatTable(lignes: lignes),
    );
  }
}

class _ResultatTable extends StatelessWidget {
  const _ResultatTable({required this.lignes});

  final List<LigneResultat> lignes;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('N')),
          DataColumn(label: Text('Intitule')),
          DataColumn(label: Text('Montant')),
        ],
        rows: lignes
            .map(
              (l) => DataRow(
                cells: [
                  DataCell(Text(l.numero)),
                  DataCell(SizedBox(width: 300, child: Text(l.intitule))),
                  DataCell(Text(_money(l.montant))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BilanSection extends StatelessWidget {
  const _BilanSection({
    required this.title,
    required this.total,
    required this.lignes,
  });

  final String title;
  final double total;
  final List<LigneBilan> lignes;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '$title - ${_money(total)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _bilanRows(lignes),
      ),
    );
  }

  List<Widget> _bilanRows(List<LigneBilan> lignes) {
    final labels = {
      'immobilisations': 'Immobilisations',
      'circulant': 'Actif circulant',
      'fonds_propres': 'Fonds propres',
      'dettes': 'Dettes',
    };
    final widgets = <Widget>[];
    String? current;
    for (final line in lignes) {
      if (line.sousSection != current) {
        current = line.sousSection;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              labels[current] ?? current,
              style: AppTextStyles.subtitle,
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Text(line.numero, style: AppTextStyles.caption),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(line.intitule, style: AppTextStyles.bodySmall),
              ),
              Text(_money(line.solde), style: AppTextStyles.subtitle),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

class _GrandLivreCard extends StatelessWidget {
  const _GrandLivreCard({required this.line});

  final LigneGrandLivre line;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: '${line.compteNumero} - ${line.compteIntitule}',
      subtitle: '${_dateFmt.format(line.ecritureDate)} | ${line.journalCode}',
      children: [
        Text(
          line.ligneLibelle ?? line.ecritureLibelle,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AmountRow(label: 'Debit', value: line.debit),
        _AmountRow(label: 'Credit', value: line.credit),
        _AmountRow(label: 'Solde', value: line.soldeCumule),
      ],
    );
  }
}

class _GrandLivreTable extends StatelessWidget {
  const _GrandLivreTable({required this.lignes});

  final List<LigneGrandLivre> lignes;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Compte')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Journal')),
          DataColumn(label: Text('Ref')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde')),
        ],
        rows: lignes
            .map(
              (l) => DataRow(
                cells: [
                  DataCell(Text(l.compteNumero)),
                  DataCell(Text(_dateFmt.format(l.ecritureDate))),
                  DataCell(Text(l.journalCode)),
                  DataCell(Text(l.referencePiece ?? '-')),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(l.ligneLibelle ?? l.ecritureLibelle),
                    ),
                  ),
                  DataCell(Text(l.debit > 0 ? _money(l.debit) : '-')),
                  DataCell(Text(l.credit > 0 ? _money(l.credit) : '-')),
                  DataCell(Text(_money(l.soldeCumule))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
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
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(
            _money(value),
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

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
          const SizedBox(height: AppSpacing.md),
          child,
        ],
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
        child: Text(
          message,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TotalItem {
  const _TotalItem(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

String _money(double value) => '${_currencyFmt.format(value)} FCFA';

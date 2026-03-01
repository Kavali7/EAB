/// Écran des états financiers SYCEBNL.
///
/// 4 onglets : Balance générale, Compte de résultat, Bilan, Grand livre.
/// Filtres par période (exercice ou dates custom).
/// Boutons export PDF / Excel (préparés, à implémenter).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/errors/error_handler.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/providers/user_profile_providers.dart';
import '../application/reports_providers.dart';
import '../data/reports_repository.dart';
import '../services/export_service.dart';

final _currencyFmt = NumberFormat('#,##0', 'fr_FR');

class EtatsFinanciersScreen extends ConsumerStatefulWidget {
  const EtatsFinanciersScreen({super.key});

  @override
  ConsumerState<EtatsFinanciersScreen> createState() =>
      _EtatsFinanciersScreenState();
}

class _EtatsFinanciersScreenState
    extends ConsumerState<EtatsFinanciersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;

  // Data
  List<LigneBalance> _balance = [];
  List<LigneResultat> _resultat = [];
  List<LigneBilan> _bilan = [];
  List<LigneGrandLivre> _grandLivre = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    // Default: full year
    final now = DateTime.now();
    _dateDebut = DateTime(now.year, 1, 1);
    _dateFin = DateTime(now.year, 12, 31);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final profile = ref.read(profilUtilisateurCourantProvider);
    if (profile == null) return;
    final orgId = profile.id;

    setState(() => _isLoading = true);
    final repo = ref.read(reportsRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.fetchBalanceGenerale(orgId,
            dateDebut: _dateDebut, dateFin: _dateFin),
        repo.fetchCompteResultat(orgId,
            dateDebut: _dateDebut, dateFin: _dateFin),
        repo.fetchBilan(orgId, dateFin: _dateFin),
        repo.fetchGrandLivre(orgId,
            dateDebut: _dateDebut, dateFin: _dateFin),
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
    final profile = ref.read(profilUtilisateurCourantProvider);
    final orgName = profile?.nom ?? 'Organisation';
    final dateFmt = DateFormat('dd/MM/yyyy');
    final periode =
        '${dateFmt.format(_dateDebut!)} — ${dateFmt.format(_dateFin!)}';

    if (format == 'pdf') {
      _exportPdf(orgName, periode);
    } else {
      _exportCsv();
    }
  }

  void _exportPdf(String orgName, String periode) {
    final tabNames = ['Balance', 'Résultat', 'Bilan', 'Grand Livre'];
    final tab = _tabCtrl.index;

    final doc = switch (tab) {
      0 => PdfExportService.buildBalancePdf(
          orgName: orgName, periode: periode, lignes: _balance),
      1 => PdfExportService.buildResultatPdf(
          orgName: orgName, periode: periode, lignes: _resultat),
      2 => PdfExportService.buildBilanPdf(
          orgName: orgName,
          dateFin: DateFormat('dd/MM/yyyy').format(_dateFin!),
          lignes: _bilan),
      3 => PdfExportService.buildGrandLivrePdf(
          orgName: orgName, periode: periode, lignes: _grandLivre),
      _ => null,
    };

    if (doc != null) {
      PdfExportService.preview(context, doc, '${tabNames[tab]} — $orgName');
    }
  }

  void _exportCsv() {
    final tab = _tabCtrl.index;
    final csv = switch (tab) {
      0 => CsvExportService.balanceToCsv(_balance),
      1 => CsvExportService.resultatToCsv(_resultat),
      3 => CsvExportService.grandLivreToCsv(_grandLivre),
      _ => null,
    };

    if (csv != null) {
      // Share via printing (save as file)
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
    return AppShell(
      title: 'États financiers',
      currentRoute: '/etats-financiers',
      body: Column(
        children: [
          // Header + filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, AppSpacing.pagePadding,
                AppSpacing.pagePadding, 0),
            child: Column(
              children: [
                const ContextHeader(showPorteeComptable: false),
                const SizedBox(height: AppSpacing.md),
                // Filtres dates
                Row(
                  children: [
                    Expanded(
                      child: EabDateField(
                        label: 'Du',
                        value: _dateDebut,
                        onChanged: (d) => setState(() => _dateDebut = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.cardGap),
                    Expanded(
                      child: EabDateField(
                        label: 'Au',
                        value: _dateFin,
                        onChanged: (d) => setState(() => _dateFin = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.cardGap),
                    EabButton(
                      label: 'Actualiser',
                      variant: EabButtonVariant.primary,
                      size: EabButtonSize.small,
                      isLoading: _isLoading,
                      onPressed: _loadAll,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.download),
                      tooltip: 'Exporter',
                      onSelected: _onExport,
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'pdf', child: Text('📄 Export PDF')),
                        const PopupMenuItem(value: 'csv', child: Text('📊 Export CSV (Excel)')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Balance'),
              Tab(text: 'Résultat'),
              Tab(text: 'Bilan'),
              Tab(text: 'Grand livre'),
            ],
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: SkeletonLoader())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildBalance(),
                      _buildResultat(),
                      _buildBilan(),
                      _buildGrandLivre(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 1 : BALANCE GÉNÉRALE
  // ══════════════════════════════════════════
  Widget _buildBalance() {
    if (_balance.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance,
        message: 'Aucune écriture validée pour cette période.',
      );
    }

    final totalD = _balance.fold(0.0, (s, l) => s + l.totalDebit);
    final totalC = _balance.fold(0.0, (s, l) => s + l.totalCredit);
    final totalSD = _balance.fold(0.0, (s, l) => s + l.soldeDebiteur);
    final totalSC = _balance.fold(0.0, (s, l) => s + l.soldeCrediteur);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: SectionCard(
        title: 'Balance générale (${_balance.length} comptes)',
        child: Column(
          children: [
            // Totaux
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _total('Total Débit', totalD),
                  _total('Total Crédit', totalC),
                  _total('Solde Débiteur', totalSD),
                  _total('Solde Créditeur', totalSC),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.grey.shade100),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('N°', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Intitulé', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Solde D', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Solde C', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: _balance.map((l) => DataRow(cells: [
                  DataCell(Text(l.numero, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(SizedBox(width: 250, child: Text(l.intitule))),
                  DataCell(Text(_currencyFmt.format(l.totalDebit))),
                  DataCell(Text(_currencyFmt.format(l.totalCredit))),
                  DataCell(Text(l.soldeDebiteur > 0 ? _currencyFmt.format(l.soldeDebiteur) : '')),
                  DataCell(Text(l.soldeCrediteur > 0 ? _currencyFmt.format(l.soldeCrediteur) : '')),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 2 : COMPTE DE RÉSULTAT
  // ══════════════════════════════════════════
  Widget _buildResultat() {
    if (_resultat.isEmpty) {
      return const EmptyState(
        icon: Icons.trending_up,
        message: 'Aucune écriture de charges ou produits pour cette période.',
      );
    }

    final produits = _resultat.where((l) => l.section == 'produits').toList();
    final charges = _resultat.where((l) => l.section == 'charges').toList();
    final totalProduits = produits.fold(0.0, (s, l) => s + l.montant);
    final totalCharges = charges.fold(0.0, (s, l) => s + l.montant);
    final resultat = totalProduits - totalCharges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          // Résultat net
          Card(
            color: resultat >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: BorderSide(
                color: resultat >= 0
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    resultat >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: resultat >= 0 ? Colors.green[700] : Colors.red[700],
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    children: [
                      Text(
                        resultat >= 0 ? 'BÉNÉFICE NET' : 'PERTE NETTE',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '${_currencyFmt.format(resultat.abs())} FCFA',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: resultat >= 0
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Produits
          SectionCard(
            title: 'Produits — ${_currencyFmt.format(totalProduits)} FCFA',
            child: _reportTable(produits),
          ),
          const SizedBox(height: AppSpacing.cardGap),

          // Charges
          SectionCard(
            title: 'Charges — ${_currencyFmt.format(totalCharges)} FCFA',
            child: _reportTable(charges),
          ),
        ],
      ),
    );
  }

  Widget _reportTable(List<LigneResultat> lignes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
        columns: const [
          DataColumn(label: Text('N°', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Intitulé', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: lignes.map((l) => DataRow(cells: [
          DataCell(Text(l.numero)),
          DataCell(SizedBox(width: 300, child: Text(l.intitule))),
          DataCell(Text('${_currencyFmt.format(l.montant)} FCFA')),
        ])).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 3 : BILAN
  // ══════════════════════════════════════════
  Widget _buildBilan() {
    if (_bilan.isEmpty) {
      return const EmptyState(
        icon: Icons.balance,
        message: 'Aucun solde de bilan pour cette période.',
      );
    }

    final actif = _bilan.where((l) => l.section == 'actif').toList();
    final passif = _bilan.where((l) => l.section == 'passif').toList();
    final totalActif = actif.fold(0.0, (s, l) => s + l.solde);
    final totalPassif = passif.fold(0.0, (s, l) => s + l.solde);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actif
          Expanded(
            child: SectionCard(
              title: 'ACTIF — ${_currencyFmt.format(totalActif)} FCFA',
              child: _bilanTable(actif),
            ),
          ),
          const SizedBox(width: AppSpacing.cardGap),
          // Passif
          Expanded(
            child: SectionCard(
              title: 'PASSIF — ${_currencyFmt.format(totalPassif)} FCFA',
              child: _bilanTable(passif),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilanTable(List<LigneBilan> lignes) {
    // Grouper par sous-section
    final sousLabels = {
      'immobilisations': 'Immobilisations',
      'circulant': 'Actif circulant',
      'fonds_propres': 'Fonds propres',
      'dettes': 'Dettes',
    };

    final children = <Widget>[];
    String? currentSous;
    for (final l in lignes) {
      if (l.sousSection != currentSous) {
        currentSous = l.sousSection;
        children.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(
            sousLabels[l.sousSection] ?? l.sousSection,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ));
      }
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(l.numero, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l.intitule, style: const TextStyle(fontSize: 13))),
            Text(
              '${_currencyFmt.format(l.solde)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // ══════════════════════════════════════════
  // TAB 4 : GRAND LIVRE
  // ══════════════════════════════════════════
  Widget _buildGrandLivre() {
    if (_grandLivre.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book,
        message: 'Aucun mouvement pour cette période.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: SectionCard(
        title: 'Grand livre (${_grandLivre.length} mouvements)',
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columnSpacing: 16,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            columns: const [
              DataColumn(label: Text('Compte', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Journal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Réf', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            ],
            rows: _grandLivre.map((l) => DataRow(cells: [
              DataCell(Text(l.compteNumero, style: const TextStyle(fontSize: 12))),
              DataCell(Text(dateFormatter.format(l.ecritureDate), style: const TextStyle(fontSize: 12))),
              DataCell(Text(l.journalCode, style: const TextStyle(fontSize: 12))),
              DataCell(Text(l.referencePiece ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(SizedBox(
                width: 250,
                child: Text(
                  l.ligneLibelle ?? l.ecritureLibelle,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
              DataCell(Text(
                l.debit > 0 ? _currencyFmt.format(l.debit) : '',
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(Text(
                l.credit > 0 ? _currencyFmt.format(l.credit) : '',
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(Text(
                _currencyFmt.format(l.soldeCumule),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: l.soldeCumule >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              )),
            ])).toList(),
          ),
        ),
      ),
    );
  }

  Widget _total(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '${_currencyFmt.format(value)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

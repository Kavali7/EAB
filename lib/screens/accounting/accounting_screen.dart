import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/accounting_entry.dart';
import '../../models/centre_analytique.dart';
import '../../models/compte_comptable.dart';
import '../../models/compta_enums.dart';
import '../../models/assemblee_locale.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/journal_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/district_eglise.dart';
import '../../models/tiers.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';
import 'widgets/ecriture_comptable_form.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  AccountingType? _typeFilter;
  String? _categoryFilter;
  final String _query = '';
  DateTimeRange? _dateRange;
  String? _journalIdFilter;
  DateTime? _journalDateDebut;
  DateTime? _journalDateFin;
  String _journalRecherche = '';

  @override
  Widget build(BuildContext context) {
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider);
    final ecrituresBase = ref.watch(ecrituresFiltreesProvider);
    final journauxAsync = ref.watch(journauxComptablesProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final centresAsync = ref.watch(centresAnalytiquesProvider);
    final tiersAsync = ref.watch(tiersProvider);
    final profilCourant = ref.watch(profilUtilisateurCourantProvider);
    final entriesAsync = ref.watch(accountingEntriesProvider);
    final entries = entriesAsync.value ?? [];
    final entriesInRange = entries.where((e) {
      if (_dateRange == null) return true;
      return !e.date.isBefore(_dateRange!.start) &&
          !e.date.isAfter(_dateRange!.end);
    }).toList();
    final filtered = entriesInRange.where((e) {
      final matchesType = _typeFilter == null || e.type == _typeFilter;
      final matchesCategory =
          _categoryFilter == null || e.category == _categoryFilter;
      final matchesQuery =
          _query.isEmpty ||
          (e.description ?? '').toLowerCase().contains(_query.toLowerCase()) ||
          e.category.toLowerCase().contains(_query.toLowerCase());
      return matchesType && matchesCategory && matchesQuery;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final journaux = journauxAsync.value ?? [];
    final comptes = comptesAsync.value ?? [];
    final centres = centresAsync.value ?? [];
    final tiers = tiersAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final districts = districtsAsync.value ?? [];
    final journalById = {for (final j in journaux) j.id: j};
    final compteById = {for (final c in comptes) c.id: c};
    final centreById = {for (final c in centres) c.id: c};
    final tiersById = {for (final t in tiers) t.id: t};
    final assembleeById = {for (final a in assemblees) a.id: a};
    final assembleeContextLabel = assembleeActiveId == null
        ? 'Toutes les assemblees'
        : 'Assemblee active : ${assembleeById[assembleeActiveId]?.nom ?? assembleeActiveId}';
    final ecrituresJournal = _filtrerEcrituresJournal(ecrituresBase);
    final assembleesAutorisees =
        _assembleesAutorisees(profilCourant, assemblees, districts);
    final peutCreerEcriture = assembleeActiveId != null &&
        assembleesAutorisees.any((a) => a.id == assembleeActiveId);
    final isJournalLoading = ecrituresAsync.isLoading ||
        journauxAsync.isLoading ||
        comptesAsync.isLoading ||
        centresAsync.isLoading ||
        tiersAsync.isLoading ||
        assembleesAsync.isLoading ||
        districtsAsync.isLoading;
    final hasJournalError = ecrituresAsync.hasError ||
        journauxAsync.hasError ||
        comptesAsync.hasError ||
        centresAsync.hasError ||
        tiersAsync.hasError ||
        assembleesAsync.hasError ||
        districtsAsync.hasError;

    final totalIncome = filtered
        .where((e) => e.type == AccountingType.income)
        .fold<double>(0, (p, e) => p + e.amount);
    final totalExpense = filtered
        .where((e) => e.type == AccountingType.expense)
        .fold<double>(0, (p, e) => p + e.amount);

    return DefaultTabController(
      length: 2,
      child: AppShell(
        title: 'Comptabilite',
        currentRoute: '/accounting',
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Journal'),
            Tab(text: 'Synthese'),
          ],
        ),
        floatingActionButton: peutCreerEcriture
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) =>
                        const EcritureComptableFormDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle ecriture'),
              )
            : null,
        body: TabBarView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: peutCreerEcriture
                          ? () async {
                              await showDialog(
                                context: context,
                                builder: (context) =>
                                    const EcritureComptableFormDialog(),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle ecriture'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Journal'),
                        initialValue: _journalIdFilter,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tous les journaux'),
                          ),
                          ...journaux.map(
                            (j) => DropdownMenuItem<String?>(
                              value: j.id,
                              child: Text('${j.code} - ${j.intitule}'),
                            ),
                          ),
                        ],
                        onChanged: journauxAsync.isLoading
                            ? null
                            : (value) =>
                                setState(() => _journalIdFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _JournalDateFilterField(
                        label: 'Du',
                        value: _journalDateDebut,
                        onSelected: (d) => setState(() {
                          _journalDateDebut = d;
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _JournalDateFilterField(
                        label: 'Au',
                        value: _journalDateFin,
                        onSelected: (d) => setState(() {
                          _journalDateFin = d;
                        }),
                        allowClear: true,
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Recherche (libelle ou reference)',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            setState(() => _journalRecherche = value),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    assembleeContextLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 12),
                Expanded(
                  child: isJournalLoading
                      ? const Center(child: CircularProgressIndicator())
                      : hasJournalError
                          ? Center(
                              child: Text(
                                'Erreur lors du chargement des donnees comptables.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : Card(
                              child: ecrituresJournal.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Aucune ecriture.'),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Journal')),
                                          DataColumn(label: Text('Reference')),
                                          DataColumn(label: Text('Libelle')),
                                          DataColumn(label: Text('Debit')),
                                          DataColumn(label: Text('Credit')),
                                          DataColumn(label: Text('Solde')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: ecrituresJournal
                                            .map(
                                              (e) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      dateFormatter.format(
                                                        e.date,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _journalLabel(
                                                        e.idJournal,
                                                        journalById,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      e.referencePiece ??
                                                          '--',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 220,
                                                      child: Text(
                                                        e.libelle,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      currencyFormatter.format(
                                                        _totalDebit(e),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      currencyFormatter.format(
                                                        _totalCredit(e),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      currencyFormatter.format(
                                                        _totalDebit(e) -
                                                            _totalCredit(e),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.visibility_outlined,
                                                          ),
                                                          tooltip:
                                                              'Voir le detail',
                                                          onPressed: () =>
                                                              _showEcritureDetails(
                                                            context,
                                                            e,
                                                            journalById,
                                                            compteById,
                                                            centreById,
                                                            tiersById,
                                                            assembleeById,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit_outlined,
                                                          ),
                                                          tooltip:
                                                              'Modifier cette ecriture',
                                                          onPressed: _peutGererEcriture(
                                                                  profilCourant,
                                                                  assembleesAutorisees,
                                                                  e)
                                                              ? () async {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            EcritureComptableFormDialog(
                                                                      ecritureExistante:
                                                                          e,
                                                                    ),
                                                                  );
                                                                }
                                                              : null,
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete_outline,
                                                          ),
                                                          tooltip:
                                                              'Supprimer cette ecriture',
                                                          onPressed: _peutGererEcriture(
                                                                  profilCourant,
                                                                  assembleesAutorisees,
                                                                  e)
                                                              ? () async {
                                                                  final confirm =
                                                                      await showDialog<
                                                                          bool>(
                                                                    context:
                                                                        context,
                                                                    builder: (ctx) =>
                                                                        AlertDialog(
                                                                      title: const Text(
                                                                          'Supprimer l\'ecriture'),
                                                                      content:
                                                                          const Text(
                                                                              'Voulez-vous vraiment supprimer cette ecriture ?'),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.of(ctx)
                                                                              .pop(false),
                                                                          child:
                                                                              const Text('Annuler'),
                                                                        ),
                                                                        ElevatedButton(
                                                                          onPressed: () => Navigator.of(ctx)
                                                                              .pop(true),
                                                                          style:
                                                                              ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                                          child:
                                                                              const Text('Supprimer'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (confirm ==
                                                                      true) {
                                                                    await ref
                                                                        .read(ecrituresComptablesProvider.notifier)
                                                                        .supprimerEcriture(e.id);
                                                                  }
                                                                }
                                                              : null,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                            ),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Total recettes',
                          value: currencyFormatter.format(totalIncome),
                          icon: Icons.trending_up,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Total depenses',
                          value: currencyFormatter.format(totalExpense),
                          icon: Icons.trending_down,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Balance',
                          value: currencyFormatter.format(
                            totalIncome - totalExpense,
                          ),
                          icon: Icons.account_balance_wallet_outlined,
                          color: ChurchTheme.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Exporter CSV (stub)'),
                        onPressed: () => _showExportStub(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flux sur 6 mois',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: LineChart(_sixMonthsLine(filtered)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top categories',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._topCategories(filtered).map(
                            (item) => ListTile(
                              dense: true,
                              title: Text(item.category),
                              subtitle: Text(accountingTypeLabels[item.type]!),
                              trailing: Text(
                                currencyFormatter.format(item.total),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tableau croise categories',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Categorie')),
                                DataColumn(label: Text('Montant')),
                              ],
                              rows: _aggregateByCategory(filtered)
                                  .map(
                                    (item) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            accountingTypeLabels[item.type]!,
                                          ),
                                        ),
                                        DataCell(Text(item.category)),
                                        DataCell(
                                          Text(
                                            currencyFormatter.format(
                                              item.total,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EcritureComptable> _filtrerEcrituresJournal(
    List<EcritureComptable> source,
  ) {
    Iterable<EcritureComptable> res = source;
    if (_journalIdFilter != null && _journalIdFilter!.isNotEmpty) {
      res = res.where((e) => e.idJournal == _journalIdFilter);
    }
    if (_journalDateDebut != null) {
      res = res.where((e) => !e.date.isBefore(_journalDateDebut!));
    }
    if (_journalDateFin != null) {
      res = res.where((e) => !e.date.isAfter(_journalDateFin!));
    }
    final q = _journalRecherche.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((e) {
        final lib = e.libelle.toLowerCase();
        final ref = (e.referencePiece ?? '').toLowerCase();
        return lib.contains(q) || ref.contains(q);
      });
    }
    return res.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double _totalDebit(EcritureComptable e) =>
      e.lignes.fold(0.0, (sum, l) => sum + (l.debit ?? 0));

  double _totalCredit(EcritureComptable e) =>
      e.lignes.fold(0.0, (sum, l) => sum + (l.credit ?? 0));

  String _journalLabel(
    String idJournal,
    Map<String, JournalComptable> journalById,
  ) {
    final journal = journalById[idJournal];
    if (journal == null) return idJournal;
    return '${journal.code} - ${journal.intitule}';
  }

  String _compteLabel(
    String idCompte,
    Map<String, CompteComptable> compteById,
  ) {
    final compte = compteById[idCompte];
    if (compte == null) return idCompte;
    return '${compte.numero} - ${compte.intitule}';
  }

  String _centreLabel(
    String? idCentre,
    Map<String, CentreAnalytique> centreById,
  ) {
    if (idCentre == null) return '--';
    final centre = centreById[idCentre];
    if (centre == null) return idCentre;
    return '${centre.code} - ${centre.nom}';
  }

  String _tiersLabel(String? idTiers, Map<String, Tiers> tiersById) {
    if (idTiers == null) return '--';
    final t = tiersById[idTiers];
    if (t == null) return idTiers;
    return t.nom;
  }

  String _assembleeLabel(
    String? idAssemblee,
    Map<String, AssembleeLocale> assembleeById,
  ) {
    if (idAssemblee == null) return 'Non renseignee';
    final a = assembleeById[idAssemblee];
    return a?.nom ?? idAssemblee;
  }

  String _modePaiementLabel(ModePaiement? mode) {
    switch (mode) {
      case ModePaiement.especes:
        return 'Especes';
      case ModePaiement.cheque:
        return 'Cheque';
      case ModePaiement.virementBancaire:
        return 'Virement bancaire';
      case ModePaiement.mobileMoney:
        return 'Mobile money';
      case ModePaiement.microfinance:
        return 'Microfinance';
      case ModePaiement.autre:
        return 'Autre';
      case null:
        return '--';
    }
  }

  List<AssembleeLocale> _assembleesAutorisees(
    ProfilUtilisateur? profil,
    List<AssembleeLocale> assemblees,
    List<DistrictEglise> districts,
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

  bool _peutGererEcriture(
    ProfilUtilisateur? profil,
    List<AssembleeLocale> assembleesAutorisees,
    EcritureComptable ecriture,
  ) {
    if (profil == null) return false;
    if (profil.role == RoleUtilisateur.adminNational) return true;
    if (ecriture.idAssembleeLocale == null) return false;
    return assembleesAutorisees.any((a) => a.id == ecriture.idAssembleeLocale);
  }

  Future<void> _showEcritureDetails(
    BuildContext context,
    EcritureComptable ecriture,
    Map<String, JournalComptable> journalById,
    Map<String, CompteComptable> compteById,
    Map<String, CentreAnalytique> centreById,
    Map<String, Tiers> tiersById,
    Map<String, AssembleeLocale> assembleeById,
  ) async {
    final journal = journalById[ecriture.idJournal];
    final centrePrincipal = ecriture.idCentreAnalytiquePrincipal != null
        ? centreById[ecriture.idCentreAnalytiquePrincipal!]
        : null;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ecriture du ${dateFormatter.format(ecriture.date)}'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journal : ${journal != null ? '${journal.code} - ${journal.intitule}' : ecriture.idJournal}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (ecriture.referencePiece != null &&
                    ecriture.referencePiece!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Reference : ${ecriture.referencePiece}'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Libelle : ${ecriture.libelle}'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Assemblee : ${_assembleeLabel(ecriture.idAssembleeLocale, assembleeById)}',
                  ),
                ),
                if (centrePrincipal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Centre principal : ${centrePrincipal.code} - ${centrePrincipal.nom}',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Lignes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Compte')),
                      DataColumn(label: Text('Libelle')),
                      DataColumn(label: Text('Debit')),
                      DataColumn(label: Text('Credit')),
                      DataColumn(label: Text('Centre')),
                      DataColumn(label: Text('Tiers')),
                      DataColumn(label: Text('Mode')),
                    ],
                    rows: ecriture.lignes
                        .map(
                          (l) => DataRow(
                            cells: [
                              DataCell(Text(_compteLabel(l.idCompteComptable, compteById))),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    l.libelle ?? '--',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(currencyFormatter
                                    .format((l.debit ?? 0).toDouble())),
                              ),
                              DataCell(
                                Text(currencyFormatter
                                    .format((l.credit ?? 0).toDouble())),
                              ),
                              DataCell(Text(_centreLabel(l.idCentreAnalytique, centreById))),
                              DataCell(Text(_tiersLabel(l.idTiers, tiersById))),
                              DataCell(Text(_modePaiementLabel(l.modePaiement))),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showExportStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export CSV/Excel sera branche cote backend'),
      ),
    );
  }

  LineChartData _sixMonthsLine(List<AccountingEntry> entries) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i)),
    );
    final income = <FlSpot>[];
    final expense = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final incomeSum = entries
          .where(
            (e) =>
                e.type == AccountingType.income &&
                e.date.year == month.year &&
                e.date.month == month.month,
          )
          .fold<double>(0, (p, e) => p + e.amount);
      final expenseSum = entries
          .where(
            (e) =>
                e.type == AccountingType.expense &&
                e.date.year == month.year &&
                e.date.month == month.month,
          )
          .fold<double>(0, (p, e) => p + e.amount);
      income.add(FlSpot(i.toDouble(), incomeSum / 1000));
      expense.add(FlSpot(i.toDouble(), expenseSum / 1000));
    }
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= months.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  monthFormatter.format(months[index]),
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}k'),
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: income,
          isCurved: true,
          color: Colors.green[700],
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: expense,
          isCurved: true,
          color: Colors.red[600],
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  List<_CategoryTotal> _topCategories(List<AccountingEntry> entries) {
    final map = <String, _CategoryTotal>{};
    for (final e in entries) {
      final key = '${e.type.name}-${e.category}';
      final current =
          map[key] ??
          _CategoryTotal(category: e.category, total: 0, type: e.type);
      map[key] = current.copyWith(total: current.total + e.amount);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(6).toList();
  }

  List<_CategoryTotal> _aggregateByCategory(List<AccountingEntry> entries) {
    final map = <String, _CategoryTotal>{};
    for (final e in entries) {
      final key = '${e.type.name}-${e.category}';
      final current =
          map[key] ??
          _CategoryTotal(category: e.category, total: 0, type: e.type);
      map[key] = current.copyWith(total: current.total + e.amount);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(12).toList();
  }
}

class AccountingEntryForm extends ConsumerStatefulWidget {
  const AccountingEntryForm({super.key, this.entry});

  final AccountingEntry? entry;

  @override
  ConsumerState<AccountingEntryForm> createState() =>
      _AccountingEntryFormState();
}

class _AccountingEntryFormState extends ConsumerState<AccountingEntryForm> {
  final _formKey = GlobalKey<FormState>();
  AccountingType? _type = AccountingType.income;
  String? _category;
  String? _paymentMethod;
  DateTime _date = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _type = e.type;
      _category = e.category;
      _paymentMethod = e.paymentMethod;
      _date = e.date;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _descriptionCtrl.text = e.description ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    final categories = _type == AccountingType.expense
        ? expenseCategories
        : incomeCategories;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'ecriture' : 'Nouvelle ecriture'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AccountingType>(
                  isExpanded: true,
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: AccountingType.income,
                      child: Text('Recette'),
                    ),
                    DropdownMenuItem(
                      value: AccountingType.expense,
                      child: Text('Depense'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _category = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categorie'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                  validator: (v) => v == null ? 'Categorie requise' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Montant'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Montant requis';
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null) return 'Montant invalide';
                    if (parsed < 0) return 'Montant negatif non autorise';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                  ),
                  items: paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date',
                  value: _date,
                  onSelected: (d) =>
                      setState(() => _date = d ?? DateTime.now()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Mettre a jour' : 'Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    final notifier = ref.read(accountingEntriesProvider.notifier);
    final entry = AccountingEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      date: _date,
      amount: amount,
      type: _type ?? AccountingType.income,
      category: _category ?? '',
      paymentMethod: _paymentMethod,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
    );
    if (widget.entry == null) {
      await notifier.addEntry(entry);
    } else {
      await notifier.updateEntry(entry);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _CategoryTotal {
  const _CategoryTotal({
    required this.category,
    required this.total,
    required this.type,
  });

  final String category;
  final double total;
  final AccountingType type;

  _CategoryTotal copyWith({
    String? category,
    double? total,
    AccountingType? type,
  }) {
    return _CategoryTotal(
      category: category ?? this.category,
      total: total ?? this.total,
      type: type ?? this.type,
    );
  }
}

class _JournalDateFilterField extends StatelessWidget {
  const _JournalDateFilterField({
    required this.label,
    required this.value,
    required this.onSelected,
    this.allowClear = false,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime?) onSelected;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null || allowClear) {
          onSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.event)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allowClear)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => onSelected(null),
                      ),
                    const Icon(Icons.event),
                  ],
                ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 72, minHeight: 48),
        ),
        child: Text(
          value != null ? dateFormatter.format(value!) : 'Aucune date',
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime?) onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.date_range),
        ),
        child: Text(value != null ? dateFormatter.format(value!) : 'Choisir'),
      ),
    );
  }
}

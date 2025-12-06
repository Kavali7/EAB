import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/centre_analytique.dart';
import '../../models/compte_comptable.dart';
import '../../models/compta_enums.dart';
import '../../models/assemblee_locale.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/journal_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/district_eglise.dart';
import '../../models/tiers.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';
import '../../widgets/context_header.dart';
import 'widgets/ecriture_comptable_form.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  String? _journalIdFilter;
  DateTime? _journalDateDebut;
  DateTime? _journalDateFin;
  String _journalRecherche = '';
  DateTime? _dateDebutSynthese;
  DateTime? _dateFinSynthese;

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
    final portee = ref.watch(porteeComptableProvider);
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
                const ContextHeader(showPorteeComptable: true),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildSelecteurPortee(portee, profilCourant),
                ),
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
            _buildSyntheseTab(
              context,
              assembleeContextLabel,
              comptesAsync,
              ecrituresBase,
              portee,
              profilCourant,
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

  Widget _buildSelecteurPortee(
    PorteeComptable portee,
    ProfilUtilisateur? profil,
  ) {
    final options = _porteesDisponiblesPourProfil(profil);
    final current =
        options.contains(portee) ? portee : options.isNotEmpty ? options.first : PorteeComptable.assemblee;
    return Row(
      children: [
        const Text('Portee comptable :'),
        const SizedBox(width: 8),
        DropdownButton<PorteeComptable>(
          value: current,
          items: options
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(_labelPortee(p)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            ref.read(porteeComptableProvider.notifier).setPortee(value);
          },
        ),
      ],
    );
  }

  List<PorteeComptable> _porteesDisponiblesPourProfil(ProfilUtilisateur? profil) {
    if (profil == null) return const [PorteeComptable.assemblee];
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return const [
          PorteeComptable.assemblee,
          PorteeComptable.district,
          PorteeComptable.region,
          PorteeComptable.national,
        ];
      case RoleUtilisateur.responsableRegion:
        return const [
          PorteeComptable.assemblee,
          PorteeComptable.district,
          PorteeComptable.region,
        ];
      case RoleUtilisateur.surintendantDistrict:
        return const [
          PorteeComptable.assemblee,
          PorteeComptable.district,
        ];
      case RoleUtilisateur.tresorierAssemblee:
        return const [PorteeComptable.assemblee];
    }
  }

  String _labelPortee(PorteeComptable p) {
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

  Widget _buildSyntheseTab(
    BuildContext context,
    String assembleeContextLabel,
    AsyncValue<List<CompteComptable>> comptesAsync,
    List<EcritureComptable> ecrituresBase,
    PorteeComptable portee,
    ProfilUtilisateur? profil,
  ) {
    return comptesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('Impossible de charger le plan de comptes.'),
      ),
      data: (comptes) {
        final comptesParId = {for (final c in comptes) c.id: c};
        final ecritures = _filtrerEcrituresSynthese(ecrituresBase);
        final synthese = _calculerSynthese(ecritures, comptesParId);
        final topCharges = _topComptes(synthese.chargesParCompte, comptesParId);
        final topProduits =
            _topComptes(synthese.produitsParCompte, comptesParId);
        final resultatParMois = _resultatParMoisLimite(synthese.resultatParMois);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ContextHeader(showPorteeComptable: true),
              const SizedBox(height: 8),
              _buildSelecteurPortee(portee, profil),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 180,
                    child: _JournalDateFilterField(
                      label: 'Du',
                      value: _dateDebutSynthese,
                      onSelected: (d) => setState(() => _dateDebutSynthese = d),
                      allowClear: true,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _JournalDateFilterField(
                      label: 'Au',
                      value: _dateFinSynthese,
                      onSelected: (d) => setState(() => _dateFinSynthese = d),
                      allowClear: true,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _dateDebutSynthese = null;
                      _dateFinSynthese = null;
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                assembleeContextLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: InfoCard(
                      title: 'Produits (periode)',
                      value: currencyFormatter.format(synthese.totalProduits),
                      icon: Icons.trending_up,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: InfoCard(
                      title: 'Charges (periode)',
                      value: currencyFormatter.format(synthese.totalCharges),
                      icon: Icons.trending_down,
                      color: Colors.red[600],
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: InfoCard(
                      title: 'Resultat (periode)',
                      value: currencyFormatter.format(synthese.resultat),
                      icon: Icons.account_balance_wallet_outlined,
                      color: synthese.resultat >= 0
                          ? Colors.green[800]
                          : Colors.red[700],
                    ),
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
                        'Resultat par mois',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: resultatParMois.isEmpty
                            ? const Center(child: Text('Aucune donnee.'))
                            : LineChart(
                                _resultatLineChart(resultatParMois),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: isWide ? (constraints.maxWidth / 2) - 12 : constraints.maxWidth,
                        child: _buildTopTable(
                          'Top comptes de charges',
                          topCharges,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth / 2) - 12 : constraints.maxWidth,
                        child: _buildTopTable(
                          'Top comptes de produits',
                          topProduits,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTable(
    String title,
    List<_CompteMontant> donnees,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (donnees.isEmpty)
              const Text('Aucune donnee.')
            else
              DataTable(
                columns: const [
                  DataColumn(label: Text('Compte')),
                  DataColumn(label: Text('Montant')),
                ],
                rows: donnees
                    .map(
                      (d) => DataRow(
                        cells: [
                          DataCell(Text('${d.numero} - ${d.intitule}')),
                          DataCell(Text(currencyFormatter.format(d.montant))),
                        ],
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<_CompteMontant> _topComptes(
    Map<String, double> montantsParCompte,
    Map<String, CompteComptable> comptesParId,
  ) {
    final list = montantsParCompte.entries
        .map(
          (e) => _CompteMontant(
            id: e.key,
            numero: comptesParId[e.key]?.numero ?? e.key,
            intitule: comptesParId[e.key]?.intitule ?? '',
            montant: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.montant.compareTo(a.montant));
    return list.take(5).toList();
  }

  Map<DateTime, double> _resultatParMoisLimite(Map<DateTime, double> data) {
    final keys = data.keys.toList()..sort();
    if (keys.length <= 6) return data;
    final last = keys.sublist(keys.length - 6);
    return {for (final k in last) k: data[k] ?? 0};
  }

  LineChartData _resultatLineChart(Map<DateTime, double> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value / 1000));
    }
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= entries.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  monthFormatter.format(entries[index].key),
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
          spots: spots,
          isCurved: true,
          color: ChurchTheme.navy,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  SyntheseResultat _calculerSynthese(
    List<EcritureComptable> ecritures,
    Map<String, CompteComptable> comptesParId,
  ) {
    double totalCharges = 0;
    double totalProduits = 0;
    final chargesParCompte = <String, double>{};
    final produitsParCompte = <String, double>{};
    final resultatParMois = <DateTime, double>{};

    for (final e in ecritures) {
      double chargesMois = 0;
      double produitsMois = 0;
      for (final l in e.lignes) {
        final compte = comptesParId[l.idCompteComptable];
        if (compte == null) continue;
        final debit = l.debit ?? 0;
        final credit = l.credit ?? 0;
        if (compte.nature == NatureCompte.charge) {
          final montant = debit - credit;
          if (montant != 0) {
            totalCharges += montant;
            chargesParCompte[compte.id] =
                (chargesParCompte[compte.id] ?? 0) + montant;
            chargesMois += montant;
          }
        } else if (compte.nature == NatureCompte.produit) {
          final montant = credit - debit;
          if (montant != 0) {
            totalProduits += montant;
            produitsParCompte[compte.id] =
                (produitsParCompte[compte.id] ?? 0) + montant;
            produitsMois += montant;
          }
        }
      }
      final moisCle = DateTime(e.date.year, e.date.month);
      final resMois = produitsMois - chargesMois;
      resultatParMois[moisCle] = (resultatParMois[moisCle] ?? 0) + resMois;
    }

    return SyntheseResultat(
      totalCharges: totalCharges,
      totalProduits: totalProduits,
      resultat: totalProduits - totalCharges,
      chargesParCompte: chargesParCompte,
      produitsParCompte: produitsParCompte,
      resultatParMois: resultatParMois,
    );
  }

  List<EcritureComptable> _filtrerEcrituresSynthese(
    List<EcritureComptable> ecritures,
  ) {
    Iterable<EcritureComptable> res = ecritures;
    if (_dateDebutSynthese != null) {
      res = res.where((e) => !e.date.isBefore(_dateDebutSynthese!));
    }
    if (_dateFinSynthese != null) {
      res = res.where((e) => !e.date.isAfter(_dateFinSynthese!));
    }
    return res.toList()..sort((a, b) => a.date.compareTo(b.date));
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

}

class SyntheseResultat {
  const SyntheseResultat({
    required this.totalCharges,
    required this.totalProduits,
    required this.resultat,
    required this.chargesParCompte,
    required this.produitsParCompte,
    required this.resultatParMois,
  });

  final double totalCharges;
  final double totalProduits;
  final double resultat;
  final Map<String, double> chargesParCompte;
  final Map<String, double> produitsParCompte;
  final Map<DateTime, double> resultatParMois;
}

class _CompteMontant {
  const _CompteMontant({
    required this.id,
    required this.numero,
    required this.intitule,
    required this.montant,
  });

  final String id;
  final String numero;
  final String intitule;
  final double montant;
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

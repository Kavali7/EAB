import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assemblee_locale.dart';
import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/tiers.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/compta_enums.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../providers/church_structure_providers.dart';

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
    final profil = ref.watch(profilUtilisateurCourantProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final portee = ref.watch(porteeComptableProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final tiersAsync = ref.watch(tiersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etats comptables'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Balance'),
            Tab(text: 'Grand livre'),
            Tab(text: 'Tiers'),
            Tab(text: 'Exports / FEC'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: comptesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) =>
              const Center(child: Text('Erreur chargement plan de comptes')),
          data: (comptes) {
            final tiers = tiersAsync.asData?.value ?? [];
            final assemblees = assembleesAsync.asData?.value ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContexteHeader(
                  profil,
                  assemblees,
                  assembleeActiveId,
                  portee,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBalanceTab(comptes, ecritures),
                      _buildGrandLivreTab(comptes, ecritures),
                      _buildTiersTab(comptes, ecritures, tiers),
                      _buildExportsTab(comptes, ecritures, tiers),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContexteHeader(
    ProfilUtilisateur? profil,
    List<AssembleeLocale> assemblees,
    String? assembleeActiveId,
    PorteeComptable portee,
  ) {
    AssembleeLocale? assembleeActive;
    if (assembleeActiveId != null) {
      assembleeActive = assemblees.firstWhere(
        (a) => a.id == assembleeActiveId,
        orElse: () => AssembleeLocale(
          id: 'inconnu',
          nom: 'Aucune assemblee active',
          idDistrict: '',
        ),
      );
    }
    final porteeLabel = switch (portee) {
      PorteeComptable.assemblee => 'Assemblee',
      PorteeComptable.district => 'District',
      PorteeComptable.region => 'Region',
      PorteeComptable.national => 'National',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil : ${profil?.nom ?? '—'}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text('Assemblee active : ${assembleeActive?.nom ?? '—'}'),
        Text('Portee comptable : $porteeLabel'),
      ],
    );
  }

  Widget _buildBalanceTab(
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
        final d = l.debit ?? 0;
        final c = l.credit ?? 0;
        debitsParCompte[compte.id] = (debitsParCompte[compte.id] ?? 0) + d;
        creditsParCompte[compte.id] = (creditsParCompte[compte.id] ?? 0) + c;
      }
    }

    final lignes = <_LigneBalance>[];

    for (final compte in comptes) {
      final totalD = debitsParCompte[compte.id] ?? 0;
      final totalC = creditsParCompte[compte.id] ?? 0;
      if (totalD == 0 && totalC == 0) continue;
      final solde = totalD - totalC;
      lignes.add(
        _LigneBalance(
          numero: compte.numero,
          intitule: compte.intitule,
          debit: totalD,
          credit: totalC,
          solde: solde,
        ),
      );
    }

    lignes.sort((a, b) => a.numero.compareTo(b.numero));

    double totalDebits = 0;
    double totalCredits = 0;
    for (final l in lignes) {
      totalDebits += l.debit;
      totalCredits += l.credit;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balance generale (${lignes.length} comptes)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
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
                      DataCell(Text(l.debit.toStringAsFixed(0))),
                      DataCell(Text(l.credit.toStringAsFixed(0))),
                      DataCell(
                        Text(
                          l.solde.toStringAsFixed(0),
                          style: TextStyle(
                            color: l.solde >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DataRow(
                  selected: true,
                  cells: [
                    const DataCell(Text('TOTALS')),
                    const DataCell(Text('')),
                    DataCell(Text(totalDebits.toStringAsFixed(0))),
                    DataCell(Text(totalCredits.toStringAsFixed(0))),
                    DataCell(
                      Text(
                        (totalDebits - totalCredits).toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (totalDebits - totalCredits) == 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrandLivreTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
  ) {
    comptes.sort((a, b) => a.numero.compareTo(b.numero));
    final compteSelectionne = _compteGrandLivreSelectionneId == null
        ? null
        : comptes.firstWhere(
            (c) => c.id == _compteGrandLivreSelectionneId,
            orElse: () => comptes.first,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Compte : ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: compteSelectionne?.id,
              hint: const Text('Choisir un compte'),
              items: comptes
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.numero} - ${c.intitule}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _compteGrandLivreSelectionneId = v;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (compteSelectionne == null)
          const Text('Selectionnez un compte pour voir le grand livre.')
        else
          Expanded(
            child: _buildGrandLivreTable(compteSelectionne, ecritures),
          ),
      ],
    );
  }

  Widget _buildGrandLivreTable(
    CompteComptable compte,
    List<EcritureComptable> ecritures,
  ) {
    final mouvements = <_MouvementCompte>[];

    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable == compte.id) {
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
    }

    mouvements.sort((a, b) => a.date.compareTo(b.date));

    double solde = 0;
    final lignes = <DataRow>[];

    for (final m in mouvements) {
      solde += (m.debit - m.credit);
      lignes.add(
        DataRow(
          cells: [
            DataCell(Text(_formatDate(m.date))),
            DataCell(Text(m.reference ?? '')),
            DataCell(Text(m.libelle)),
            DataCell(Text(m.debit.toStringAsFixed(0))),
            DataCell(Text(m.credit.toStringAsFixed(0))),
            DataCell(
              Text(
                solde.toStringAsFixed(0),
                style: TextStyle(
                  color: solde >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Reference')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde')),
        ],
        rows: lignes,
      ),
    );
  }

  Widget _buildTiersTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
    List<Tiers> tiers,
  ) {
    if (tiers.isEmpty) {
      return const Center(child: Text('Aucun tiers defini.'));
    }

    final Map<String, double> soldesParTiers = {};

    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idTiers == null) continue;
        final idT = l.idTiers!;
        final debit = l.debit ?? 0;
        final credit = l.credit ?? 0;
        soldesParTiers[idT] = (soldesParTiers[idT] ?? 0) + (debit - credit);
      }
    }

    final lignes = <_LigneTiers>[];
    for (final t in tiers) {
      final solde = soldesParTiers[t.id] ?? 0;
      lignes.add(_LigneTiers(tiers: t, solde: solde));
    }

    lignes.sort((a, b) => b.solde.abs().compareTo(a.solde.abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soldes tiers (${lignes.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Solde')),
              ],
              rows: lignes.map((l) {
                final t = l.tiers;
                final typeLabel = switch (t.type) {
                  TypeTiers.membre => 'Membre',
                  TypeTiers.fournisseur => 'Fournisseur',
                  TypeTiers.bailleur => 'Bailleur',
                  TypeTiers.employe => 'Employe',
                  TypeTiers.partenaire => 'Partenaire',
                  TypeTiers.autre => 'Autre',
                };
                return DataRow(
                  cells: [
                    DataCell(Text(t.nom)),
                    DataCell(Text(typeLabel)),
                    DataCell(
                      Text(
                        l.solde.toStringAsFixed(0),
                        style: TextStyle(
                          color: l.solde >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportsTab(
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
    List<Tiers> tiers,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exports & FEC (preparation)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ces exports seront branches au backend plus tard. '
            'Pour l instant, ils simulent simplement l action.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Export Balance (CSV/Excel) sera implemente cote backend.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.table_view),
                label: const Text('Exporter la balance'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Export Grand livre (CSV/Excel) sera implemente cote backend.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Exporter le grand livre'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Export FEC sera prepare cote backend.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Generer FEC (simulation)'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Apercu FEC (simplifie) :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Journal')),
                  DataColumn(label: Text('Compte')),
                  DataColumn(label: Text('Libelle')),
                  DataColumn(label: Text('Debit')),
                  DataColumn(label: Text('Credit')),
                ],
                rows: ecritures.take(20).expand((e) {
                  return e.lignes.map((l) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatDate(e.date))),
                        DataCell(Text(e.idJournal)),
                        DataCell(Text(l.idCompteComptable)),
                        DataCell(Text(l.libelle ?? e.libelle)),
                        DataCell(Text((l.debit ?? 0).toStringAsFixed(0))),
                        DataCell(Text((l.credit ?? 0).toStringAsFixed(0))),
                      ],
                    );
                  });
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _LigneBalance {
  _LigneBalance({
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
  _MouvementCompte({
    required this.date,
    required this.libelle,
    required this.reference,
    required this.debit,
    required this.credit,
  });

  final DateTime date;
  final String libelle;
  final String? reference;
  final double debit;
  final double credit;
}

class _LigneTiers {
  _LigneTiers({
    required this.tiers,
    required this.solde,
  });

  final Tiers tiers;
  final double solde;
}

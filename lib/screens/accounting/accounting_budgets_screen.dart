import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/assemblee_locale.dart';
import '../../models/budget_comptable.dart';
import '../../models/centre_analytique.dart';
import '../../models/compte_comptable.dart';
import '../../models/compta_enums.dart';
import '../../models/district_eglise.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/context_header.dart';

class AccountingBudgetsScreen extends ConsumerStatefulWidget {
  const AccountingBudgetsScreen({super.key});

  @override
  ConsumerState<AccountingBudgetsScreen> createState() =>
      _AccountingBudgetsScreenState();
}

class _AccountingBudgetsScreenState
    extends ConsumerState<AccountingBudgetsScreen> {
  int _exerciceSelectionne = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilUtilisateurCourantProvider);
    final budgetsAsync = ref.watch(budgetsComptablesProvider);
    final lignesBudgetsAsync = ref.watch(lignesBudgetsProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final centresAsync = ref.watch(centresAnalytiquesProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ContextHeader(showPorteeComptable: true),
            const SizedBox(height: 8),
            Expanded(
              child: _buildContent(
                profil: profil,
                budgetsAsync: budgetsAsync,
                lignesBudgetsAsync: lignesBudgetsAsync,
                comptesAsync: comptesAsync,
                centresAsync: centresAsync,
                assembleesAsync: assembleesAsync,
                districtsAsync: districtsAsync,
                ecritures: ecritures,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFabAjoutBudget(profil),
    );
  }

  Widget _buildContent({
    required ProfilUtilisateur? profil,
    required AsyncValue<List<BudgetComptable>> budgetsAsync,
    required AsyncValue<List<LigneBudgetComptable>> lignesBudgetsAsync,
    required AsyncValue<List<CompteComptable>> comptesAsync,
    required AsyncValue<List<CentreAnalytique>> centresAsync,
    required AsyncValue<List<AssembleeLocale>> assembleesAsync,
    required AsyncValue<List<DistrictEglise>> districtsAsync,
    required List<EcritureComptable> ecritures,
  }) {
    if (budgetsAsync.isLoading ||
        lignesBudgetsAsync.isLoading ||
        comptesAsync.isLoading ||
        centresAsync.isLoading ||
        assembleesAsync.isLoading ||
        districtsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (budgetsAsync.hasError ||
        lignesBudgetsAsync.hasError ||
        comptesAsync.hasError ||
        centresAsync.hasError ||
        assembleesAsync.hasError ||
        districtsAsync.hasError) {
      return const Center(
        child: Text('Erreur lors du chargement des donnees budgets'),
      );
    }

    final budgets = budgetsAsync.value ?? [];
    final lignesBudgets = lignesBudgetsAsync.value ?? [];
    final comptes = comptesAsync.value ?? [];
    final centres = centresAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final districts = districtsAsync.value ?? [];
    final comptesParId = {for (final c in comptes) c.id: c};
    final centresParId = {for (final c in centres) c.id: c};
    final assembleesParId = {for (final a in assemblees) a.id: a};
    final idsAutorises = _assembleesAutorisees(profil, assemblees, districts);

    final budgetsFiltres = budgets.where((b) {
      if (b.exercice != _exerciceSelectionne) return false;
      if (profil?.role == RoleUtilisateur.adminNational) return true;
      // Controle simple : budget rattaché à une assemblee ou centre autorise
      if (b.idAssembleeLocale != null) {
        return idsAutorises.contains(b.idAssembleeLocale);
      }
      if (b.idCentreAnalytique != null) {
        final centre = centresParId[b.idCentreAnalytique!];
        if (centre?.idAssembleeLocale != null) {
          return idsAutorises.contains(centre!.idAssembleeLocale);
        }
      }
      return false;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Exercice',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _exerciceSelectionne,
              items: () {
                final years = <int>{
                  DateTime.now().year - 1,
                  DateTime.now().year,
                  DateTime.now().year + 1,
                  2025,
                }.toList()
                  ..sort();
                return years
                    .map(
                      (an) =>
                          DropdownMenuItem(value: an, child: Text('$an')),
                    )
                    .toList();
              }(),
              onChanged: (v) {
                if (v != null) setState(() => _exerciceSelectionne = v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: budgetsFiltres.isEmpty
              ? const Center(child: Text('Aucun budget pour cet exercice.'))
              : ListView.builder(
                  itemCount: budgetsFiltres.length,
                  itemBuilder: (context, index) {
                    final budget = budgetsFiltres[index];
                    final lignes = lignesBudgets
                        .where((l) => l.idBudget == budget.id)
                        .toList();
                    final resume = _calculerResumeBudget(
                      budget,
                      lignes,
                      ecritures,
                      comptesParId,
                    );
                    final assemblee =
                        budget.idAssembleeLocale != null ? assembleesParId[budget.idAssembleeLocale] : null;
                    final centre =
                        budget.idCentreAnalytique != null ? centresParId[budget.idCentreAnalytique!] : null;
                    return Card(
                      child: ExpansionTile(
                        title: Text(budget.libelle ?? 'Budget ${budget.exercice}'),
                        subtitle: Text([
                          if (assemblee != null) 'Assemblee: ${assemblee.nom}',
                          if (centre != null) 'Centre: ${centre.code}'
                        ].join(' • ')),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _smallInfo(
                                      'Budget prevu',
                                      currencyFormatter.format(resume.budgetTotal),
                                    ),
                                    _smallInfo(
                                      'Realise',
                                      currencyFormatter.format(resume.realiseTotal),
                                    ),
                                    _smallInfo(
                                      'Ecart',
                                      currencyFormatter.format(
                                        resume.realiseTotal - resume.budgetTotal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Compte')),
                                      DataColumn(label: Text('Budget')),
                                      DataColumn(label: Text('Realise')),
                                      DataColumn(label: Text('Ecart')),
                                      DataColumn(label: Text('Taux')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: lignes.map((l) {
                                      final compte = comptesParId[l.idCompteComptable];
                                      final realise = resume.realisesParLigne[l.id] ?? 0;
                                      final ecart = realise - l.montantPrevu;
                                      final taux = l.montantPrevu == 0
                                          ? null
                                          : (realise / l.montantPrevu);
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              compte != null
                                                  ? '${compte.numero} - ${compte.intitule}'
                                                  : l.idCompteComptable,
                                            ),
                                          ),
                                          DataCell(
                                            Text(currencyFormatter
                                                .format(l.montantPrevu)),
                                          ),
                                          DataCell(
                                            Text(currencyFormatter
                                                .format(realise)),
                                          ),
                                          DataCell(
                                            Text(currencyFormatter.format(ecart)),
                                          ),
                                          DataCell(Text(
                                            taux == null
                                                ? '--'
                                                : '${(taux * 100).toStringAsFixed(1)}%',
                                          )),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () => _ouvrirDialogLigneBudget(
                                                budget,
                                                l,
                                                comptes,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList()
                                      ..add(
                                        DataRow(
                                          cells: [
                                            const DataCell(Text('')),
                                            const DataCell(Text('')),
                                            const DataCell(Text('')),
                                            const DataCell(Text('')),
                                            const DataCell(Text('')),
                                            DataCell(
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _ouvrirDialogLigneBudget(
                                                  budget,
                                                  null,
                                                  comptes,
                                                ),
                                                icon: const Icon(Icons.add),
                                                label: const Text('Ajouter une ligne'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _smallInfo(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget? _buildFabAjoutBudget(ProfilUtilisateur? profil) {
    final peutCreer = profil != null;
    if (!peutCreer) return null;
    return FloatingActionButton.extended(
      onPressed: () => _ouvrirDialogBudget(null),
      icon: const Icon(Icons.add),
      label: const Text('Nouveau budget'),
    );
  }

  Future<void> _ouvrirDialogBudget(BudgetComptable? budget) async {
    final assembleesAsync = ref.read(assembleesLocalesProvider);
    final centresAsync = ref.read(centresAnalytiquesProvider);
    final tiersAsync = ref.read(tiersProvider);
    final assemblees = assembleesAsync.value ?? [];
    final centres = centresAsync.value ?? [];
    final bailleurs = (tiersAsync.value ?? [])
        .where((t) => t.type == TypeTiers.bailleur)
        .toList();

    final formKey = GlobalKey<FormState>();
    int exercice = budget?.exercice ?? _exerciceSelectionne;
    String? idAssemblee = budget?.idAssembleeLocale;
    String? idCentre = budget?.idCentreAnalytique;
    String? idBailleur = budget?.idTiersBailleur;
    String libelle = budget?.libelle ?? '';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget == null ? 'Nouveau budget' : 'Modifier le budget'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: exercice.toString(),
                  decoration: const InputDecoration(labelText: 'Exercice'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || int.tryParse(v) == null ? 'Exercice requis' : null,
                  onSaved: (v) => exercice = int.tryParse(v ?? '') ?? exercice,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: libelle,
                  decoration: const InputDecoration(labelText: 'Libelle'),
                  onSaved: (v) => libelle = v?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: idAssemblee,
                  decoration: const InputDecoration(labelText: 'Assemblee'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aucune'),
                    ),
                    ...assemblees.map(
                      (a) => DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text(a.nom),
                      ),
                    ),
                  ],
                  onChanged: (v) => idAssemblee = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: idCentre,
                  decoration: const InputDecoration(labelText: 'Centre analytique'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...centres.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text('${c.code} - ${c.nom}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => idCentre = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: idBailleur,
                  decoration:
                      const InputDecoration(labelText: 'Bailleur (optionnel)'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...bailleurs.map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.nom),
                      ),
                    ),
                  ],
                  onChanged: (v) => idBailleur = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              final notifier = ref.read(budgetsComptablesProvider.notifier);
              final nouveau = BudgetComptable(
                id: budget?.id ?? 'budget_${DateTime.now().millisecondsSinceEpoch}',
                exercice: exercice,
                idAssembleeLocale: idAssemblee,
                idCentreAnalytique: idCentre,
                idTiersBailleur: idBailleur,
                libelle: libelle.isEmpty
                    ? 'Budget $exercice'
                    : libelle,
                estVerrouille: budget?.estVerrouille ?? false,
              );
              if (budget == null) {
                notifier.ajouterBudget(nouveau);
              } else {
                notifier.mettreAJourBudget(nouveau);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirDialogLigneBudget(
    BudgetComptable budget,
    LigneBudgetComptable? ligne,
    List<CompteComptable> comptes,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? idCompte = ligne?.idCompteComptable;
    double montant = ligne?.montantPrevu ?? 0;
    double? montantRevu = ligne?.montantRevu;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ligne == null ? 'Ajouter une ligne' : 'Modifier la ligne'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: idCompte,
                  decoration: const InputDecoration(labelText: 'Compte'),
                  items: comptes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.numero} - ${c.intitule}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => idCompte = v,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Compte requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: montant.toStringAsFixed(0),
                  decoration:
                      const InputDecoration(labelText: 'Montant prevu'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final parsed =
                        v != null ? double.tryParse(v.replaceAll(',', '.')) : null;
                    if (parsed == null) return 'Montant requis';
                    return null;
                  },
                  onSaved: (v) =>
                      montant = double.parse(v!.replaceAll(',', '.')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: montantRevu?.toStringAsFixed(0),
                  decoration:
                      const InputDecoration(labelText: 'Montant revu (optionnel)'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => montantRevu =
                      v != null && v.trim().isNotEmpty
                          ? double.tryParse(v.replaceAll(',', '.'))
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              final notifier = ref.read(lignesBudgetsProvider.notifier);
              final nouvelleLigne = LigneBudgetComptable(
                id: ligne?.id ??
                    'ligbud_${DateTime.now().millisecondsSinceEpoch}',
                idBudget: budget.id,
                idCompteComptable: idCompte!,
                montantPrevu: montant,
                montantRevu: montantRevu,
              );
              if (ligne == null) {
                notifier.ajouterLigne(nouvelleLigne);
              } else {
                notifier.mettreAJourLigne(nouvelleLigne);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  _ResumeBudget _calculerResumeBudget(
    BudgetComptable budget,
    List<LigneBudgetComptable> lignes,
    List<EcritureComptable> ecritures,
    Map<String, CompteComptable> comptesParId,
  ) {
    double budgetTotal = 0;
    double realiseTotal = 0;
    final realisesParLigne = <String, double>{};
    for (final ligne in lignes) {
      budgetTotal += ligne.montantPrevu;
      final compte = comptesParId[ligne.idCompteComptable];
      if (compte == null) continue;
      double realise = 0;
      for (final e in ecritures) {
        if (e.date.year != budget.exercice) continue;
        for (final lec in e.lignes) {
          if (lec.idCompteComptable != ligne.idCompteComptable) continue;
          final debit = lec.debit ?? 0;
          final credit = lec.credit ?? 0;
          if (compte.nature == NatureCompte.charge) {
            realise += debit - credit;
          } else if (compte.nature == NatureCompte.produit) {
            realise += credit - debit;
          }
        }
      }
      realisesParLigne[ligne.id] = realise;
      realiseTotal += realise;
    }
    return _ResumeBudget(
      budgetTotal: budgetTotal,
      realiseTotal: realiseTotal,
      realisesParLigne: realisesParLigne,
    );
  }

  Set<String> _assembleesAutorisees(
    ProfilUtilisateur? profil,
    List<AssembleeLocale> assemblees,
    List<DistrictEglise> districts,
  ) {
    if (profil == null) return {};
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return assemblees.map((e) => e.id).toSet();
      case RoleUtilisateur.responsableRegion:
        final idRegion = profil.idRegion;
        if (idRegion == null) return {};
        final districtIds =
            districts.where((d) => d.idRegion == idRegion).map((d) => d.id).toSet();
        return assemblees
            .where((a) => districtIds.contains(a.idDistrict))
            .map((a) => a.id)
            .toSet();
      case RoleUtilisateur.surintendantDistrict:
        final idDistrict = profil.idDistrict;
        if (idDistrict == null) return {};
        return assemblees
            .where((a) => a.idDistrict == idDistrict)
            .map((a) => a.id)
            .toSet();
      case RoleUtilisateur.tresorierAssemblee:
        final idAss = profil.idAssembleeLocale;
        if (idAss == null) return {};
        return {idAss};
    }
  }
}

class _ResumeBudget {
  const _ResumeBudget({
    required this.budgetTotal,
    required this.realiseTotal,
    required this.realisesParLigne,
  });

  final double budgetTotal;
  final double realiseTotal;
  final Map<String, double> realisesParLigne;
}

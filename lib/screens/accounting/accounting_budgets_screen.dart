import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
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
import '../../ui/ui.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';
import '../../widgets/error_retry_widget.dart';

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

    return AppShell(
      title: 'Budgets',
      currentRoute: '/accounting-budgets',
      showBackButton: true,
      backRoute: '/accounting',
      floatingActionButton: _buildFabAjoutBudget(profil),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Padding(
            padding: EdgeInsets.all(
              compact ? AppSpacing.lg : AppSpacing.pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ContextHeader(showPorteeComptable: true),
                const SizedBox(height: AppSpacing.cardGap),
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
          );
        },
      ),
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
      final err =
          budgetsAsync.error ??
          lignesBudgetsAsync.error ??
          comptesAsync.error ??
          centresAsync.error ??
          assembleesAsync.error ??
          districtsAsync.error;
      return ErrorRetryWidget(
        message: 'Erreur lors du chargement des donnees budgets : $err',
        onRetry: () {
          ref.invalidate(budgetsComptablesProvider);
          ref.invalidate(lignesBudgetsProvider);
          ref.invalidate(comptesComptablesProvider);
          ref.invalidate(centresAnalytiquesProvider);
          ref.invalidate(assembleesLocalesProvider);
          ref.invalidate(districtsProvider);
        },
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

    final cards = budgetsFiltres.map((budget) {
      final lignes = lignesBudgets
          .where((l) => l.idBudget == budget.id)
          .toList();
      final resume = _calculerResumeBudget(
        budget,
        lignes,
        ecritures,
        comptesParId,
      );
      return _BudgetCardData(
        budget: budget,
        lignes: lignes,
        resume: resume,
        assemblee: budget.idAssembleeLocale != null
            ? assembleesParId[budget.idAssembleeLocale]
            : null,
        centre: budget.idCentreAnalytique != null
            ? centresParId[budget.idCentreAnalytique!]
            : null,
      );
    }).toList();

    final totalBudget = cards.fold<double>(
      0,
      (sum, card) => sum + card.resume.budgetTotal,
    );
    final totalRealise = cards.fold<double>(
      0,
      (sum, card) => sum + card.resume.realiseTotal,
    );
    final ecartGlobal = totalRealise - totalBudget;
    final tauxGlobal = totalBudget == 0 ? null : totalRealise / totalBudget;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(compact: compact),
                  const SizedBox(height: AppSpacing.cardGap),
                  _buildSummaryGrid(
                    compact: compact,
                    totalBudget: totalBudget,
                    totalRealise: totalRealise,
                    ecartGlobal: ecartGlobal,
                    tauxGlobal: tauxGlobal,
                  ),
                  const SizedBox(height: AppSpacing.cardGap),
                  if (cards.isEmpty)
                    _emptyCard('Aucun budget pour cet exercice.')
                  else
                    for (final card in cards)
                      _buildBudgetCard(
                        data: card,
                        comptesParId: comptesParId,
                        comptes: comptes,
                        compact: compact,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar({required bool compact}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_yearSelector()],
              )
            : Row(children: [SizedBox(width: 220, child: _yearSelector())]),
      ),
    );
  }

  Widget _yearSelector() {
    final years = <int>{
      DateTime.now().year - 1,
      DateTime.now().year,
      DateTime.now().year + 1,
      2025,
    }.toList()..sort();
    return DropdownButtonFormField<int>(
      initialValue: _exerciceSelectionne,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Exercice',
        border: OutlineInputBorder(),
      ),
      items: years
          .map((an) => DropdownMenuItem(value: an, child: Text('$an')))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _exerciceSelectionne = v);
      },
    );
  }

  Widget _buildSummaryGrid({
    required bool compact,
    required double totalBudget,
    required double totalRealise,
    required double ecartGlobal,
    required double? tauxGlobal,
  }) {
    final items = [
      _SummaryTile(
        label: 'Budget prevu',
        value: currencyFormatter.format(totalBudget),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      _SummaryTile(
        label: 'Realise',
        value: currencyFormatter.format(totalRealise),
        icon: Icons.trending_up,
        color: AppColors.indigo,
      ),
      _SummaryTile(
        label: 'Ecart',
        value: currencyFormatter.format(ecartGlobal),
        icon: ecartGlobal >= 0
            ? Icons.add_circle_outline
            : Icons.remove_circle_outline,
        color: ecartGlobal >= 0 ? AppColors.success : AppColors.error,
      ),
      _SummaryTile(
        label: 'Taux global',
        value: _texteTaux(tauxGlobal),
        icon: Icons.percent,
        color: _couleurTaux(tauxGlobal),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 1
            : constraints.maxWidth >= 1040
            ? 4
            : 2;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.cardGap) /
            columns;
        return Wrap(
          spacing: AppSpacing.cardGap,
          runSpacing: AppSpacing.cardGap,
          children: [
            for (final item in items) SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }

  Widget _buildBudgetCard({
    required _BudgetCardData data,
    required Map<String, CompteComptable> comptesParId,
    required List<CompteComptable> comptes,
    required bool compact,
  }) {
    final budget = data.budget;
    final resume = data.resume;
    final ecartGlobal = resume.realiseTotal - resume.budgetTotal;
    final tauxGlobal = resume.budgetTotal == 0
        ? null
        : resume.realiseTotal / resume.budgetTotal;
    final subtitle = [
      if (data.assemblee != null) 'Assemblee: ${data.assemblee!.nom}',
      if (data.centre != null) 'Centre: ${data.centre!.code}',
    ].join(' - ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          0,
          AppSpacing.cardPadding,
          AppSpacing.cardPadding,
        ),
        title: Text(
          budget.libelle ?? 'Budget ${budget.exercice}',
          style: AppTextStyles.sectionTitle,
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
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
                currencyFormatter.format(ecartGlobal),
                valueColor: ecartGlobal >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              _smallInfo(
                'Taux',
                _texteTaux(tauxGlobal),
                valueColor: _couleurTaux(tauxGlobal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.lignes.isEmpty)
            _emptyBox('Aucune ligne budgetaire.')
          else
            for (final ligne in data.lignes)
              _buildBudgetLineCard(
                budget: budget,
                ligne: ligne,
                compte: comptesParId[ligne.idCompteComptable],
                realise: resume.realisesParLigne[ligne.id] ?? 0,
                comptes: comptes,
              ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: compact ? double.infinity : null,
            child: OutlinedButton.icon(
              onPressed: () => _ouvrirDialogLigneBudget(budget, null, comptes),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une ligne'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetLineCard({
    required BudgetComptable budget,
    required LigneBudgetComptable ligne,
    required CompteComptable? compte,
    required double realise,
    required List<CompteComptable> comptes,
  }) {
    final ecart = realise - ligne.montantPrevu;
    final taux = ligne.montantPrevu == 0 ? null : realise / ligne.montantPrevu;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  compte != null
                      ? '${compte.numero} - ${compte.intitule}'
                      : ligne.idCompteComptable,
                  style: AppTextStyles.subtitle,
                ),
              ),
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    _ouvrirDialogLigneBudget(budget, ligne, comptes),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _metricChip(
                'Budget',
                currencyFormatter.format(ligne.montantPrevu),
              ),
              _metricChip('Realise', currencyFormatter.format(realise)),
              _metricChip(
                'Ecart',
                currencyFormatter.format(ecart),
                color: ecart >= 0 ? AppColors.success : AppColors.error,
              ),
              _metricChip('Taux', _texteTaux(taux), color: _couleurTaux(taux)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, {Color? color}) {
    return Chip(
      label: Text('$label : $value'),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _smallInfo(String label, String value, {Color? valueColor}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: _emptyBox(message),
      ),
    );
  }

  Widget _emptyBox(String message) {
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

  Widget? _buildFabAjoutBudget(ProfilUtilisateur? profil) {
    if (profil == null) return null;
    return FloatingActionButton.extended(
      onPressed: () => _ouvrirDialogBudget(null),
      icon: const Icon(Icons.add),
      label: const Text('Nouveau budget'),
    );
  }

  Future<void> _ouvrirDialogBudget(BudgetComptable? budget) async {
    final assemblees = ref.read(assembleesLocalesProvider).value ?? [];
    final centres = ref.read(centresAnalytiquesProvider).value ?? [];
    final bailleurs = (ref.read(tiersProvider).value ?? [])
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
      builder: (context) => EabDialog(
        title: budget == null ? 'Nouveau budget' : 'Modifier le budget',
        width: 560,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: exercice.toString(),
                decoration: const InputDecoration(labelText: 'Exercice'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null
                    ? 'Exercice requis'
                    : null,
                onSaved: (v) => exercice = int.tryParse(v ?? '') ?? exercice,
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              TextFormField(
                initialValue: libelle,
                decoration: const InputDecoration(labelText: 'Libelle'),
                onSaved: (v) => libelle = v?.trim() ?? '',
              ),
              const SizedBox(height: AppSpacing.fieldGap),
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
              const SizedBox(height: AppSpacing.fieldGap),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: idCentre,
                decoration: const InputDecoration(
                  labelText: 'Centre analytique',
                ),
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
              const SizedBox(height: AppSpacing.fieldGap),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: idBailleur,
                decoration: const InputDecoration(
                  labelText: 'Bailleur (optionnel)',
                ),
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
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          EabButton(
            label: 'Enregistrer',
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              final notifier = ref.read(budgetsComptablesProvider.notifier);
              final nouveau = BudgetComptable(
                id:
                    budget?.id ??
                    'budget_${DateTime.now().millisecondsSinceEpoch}',
                exercice: exercice,
                idAssembleeLocale: idAssemblee,
                idCentreAnalytique: idCentre,
                idTiersBailleur: idBailleur,
                libelle: libelle.isEmpty ? 'Budget $exercice' : libelle,
                estVerrouille: budget?.estVerrouille ?? false,
              );
              if (budget == null) {
                notifier.ajouterBudget(nouveau);
              } else {
                notifier.mettreAJourBudget(nouveau);
              }
              Navigator.of(context).pop();
            },
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
      builder: (context) => EabDialog(
        title: ligne == null ? 'Ajouter une ligne' : 'Modifier la ligne',
        width: 520,
        content: Form(
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
              const SizedBox(height: AppSpacing.fieldGap),
              TextFormField(
                initialValue: montant.toStringAsFixed(0),
                decoration: const InputDecoration(labelText: 'Montant prevu'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final parsed = v != null
                      ? double.tryParse(v.replaceAll(',', '.'))
                      : null;
                  return parsed == null ? 'Montant requis' : null;
                },
                onSaved: (v) => montant = double.parse(v!.replaceAll(',', '.')),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              TextFormField(
                initialValue: montantRevu?.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Montant revu (optionnel)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (v) => montantRevu = v != null && v.trim().isNotEmpty
                    ? double.tryParse(v.replaceAll(',', '.'))
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          EabButton(
            label: 'Enregistrer',
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              final notifier = ref.read(lignesBudgetsProvider.notifier);
              final nouvelleLigne = LigneBudgetComptable(
                id:
                    ligne?.id ??
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
        final districtIds = districts
            .where((d) => d.idRegion == idRegion)
            .map((d) => d.id)
            .toSet();
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

  Color _couleurTaux(double? taux) {
    if (taux == null || taux.isNaN || taux.isInfinite) {
      return AppColors.textSecondary;
    }
    if (taux < 0.8) return AppColors.error;
    if (taux <= 1.1) return AppColors.success;
    return AppColors.warning;
  }

  String _texteTaux(double? taux) {
    if (taux == null || taux.isNaN || taux.isInfinite) return '-';
    return '${(taux * 100).toStringAsFixed(0)} %';
  }
}

class _BudgetCardData {
  const _BudgetCardData({
    required this.budget,
    required this.lignes,
    required this.resume,
    required this.assemblee,
    required this.centre,
  });

  final BudgetComptable budget;
  final List<LigneBudgetComptable> lignes;
  final _ResumeBudget resume;
  final AssembleeLocale? assemblee;
  final CentreAnalytique? centre;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
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
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTextStyles.heading3,
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

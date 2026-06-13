import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../features/church_units/application/church_unit_scope_utils.dart';
import '../../features/church_units/application/church_units_provider.dart';
import '../../models/assemblee_locale.dart';
import '../../models/centre_analytique.dart';
import '../../models/compte_comptable.dart';
import '../../models/immobilisation_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../ui/ui.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';
import '../../widgets/error_retry_widget.dart';

class AccountingImmobilisationsScreen extends ConsumerStatefulWidget {
  const AccountingImmobilisationsScreen({super.key});

  @override
  ConsumerState<AccountingImmobilisationsScreen> createState() =>
      _AccountingImmobilisationsScreenState();
}

class _AccountingImmobilisationsScreenState
    extends ConsumerState<AccountingImmobilisationsScreen> {
  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilUtilisateurCourantProvider);
    final immobilisationsAsync = ref.watch(immobilisationsComptablesProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final centresAsync = ref.watch(centresAnalytiquesProvider);

    return AppShell(
      title: 'Immobilisations',
      currentRoute: '/accounting-immobilisations',
      showBackButton: true,
      backRoute: '/accounting',
      floatingActionButton: _buildFabAjoutImmo(profil),
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
                  child: immobilisationsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => ErrorRetryWidget(
                      message:
                          'Erreur lors du chargement des immobilisations : $err',
                      onRetry: () =>
                          ref.invalidate(immobilisationsComptablesProvider),
                    ),
                    data: (immobilisations) {
                      final assemblees = assembleesAsync.asData?.value ?? [];
                      final centres = centresAsync.asData?.value ?? [];
                      final assembleesParId = {
                        for (final a in assemblees) a.id: a,
                      };
                      final centresParId = {for (final c in centres) c.id: c};

                      return _buildListeImmobilisations(
                        immobilisations: immobilisations,
                        assembleesParId: assembleesParId,
                        centresParId: centresParId,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _buildFabAjoutImmo(ProfilUtilisateur? profil) {
    if (profil == null) return null;
    return FloatingActionButton.extended(
      onPressed: () => _ouvrirDialogImmobilisation(context, null),
      icon: const Icon(Icons.add),
      label: const Text('Ajouter une immobilisation'),
    );
  }

  Widget _buildListeImmobilisations({
    required List<ImmobilisationComptable> immobilisations,
    required Map<String, AssembleeLocale> assembleesParId,
    required Map<String, CentreAnalytique> centresParId,
  }) {
    immobilisations.sort(
      (a, b) => a.dateAcquisition.compareTo(b.dateAcquisition),
    );

    if (immobilisations.isEmpty) {
      return _emptyCard('Aucune immobilisation enregistree.');
    }

    final totalOrigine = immobilisations.fold<double>(
      0,
      (sum, immo) => sum + immo.valeurAcquisition,
    );
    final totalValeurNette = immobilisations.fold<double>(
      0,
      (sum, immo) => sum + _calculAmortissement(immo).valeurNette,
    );
    final sorties = immobilisations.where((immo) => immo.estSortie).length;

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
                  _buildSummaryGrid(
                    compact: compact,
                    totalOrigine: totalOrigine,
                    totalValeurNette: totalValeurNette,
                    sorties: sorties,
                  ),
                  const SizedBox(height: AppSpacing.cardGap),
                  for (final immo in immobilisations)
                    _buildImmobilisationCard(
                      immo: immo,
                      assemblee: immo.idAssembleeLocale != null
                          ? assembleesParId[immo.idAssembleeLocale]
                          : null,
                      centre: immo.idCentreAnalytique != null
                          ? centresParId[immo.idCentreAnalytique]
                          : null,
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

  Widget _buildSummaryGrid({
    required bool compact,
    required double totalOrigine,
    required double totalValeurNette,
    required int sorties,
  }) {
    final items = [
      _SummaryTile(
        label: 'Valeur origine',
        value: currencyFormatter.format(totalOrigine),
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _SummaryTile(
        label: 'Valeur nette',
        value: currencyFormatter.format(totalValeurNette),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
      ),
      _SummaryTile(
        label: 'Sorties',
        value: sorties.toString(),
        icon: Icons.logout_outlined,
        color: sorties > 0 ? AppColors.warning : AppColors.textSecondary,
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
            for (final item in items) SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }

  Widget _buildImmobilisationCard({
    required ImmobilisationComptable immo,
    required AssembleeLocale? assemblee,
    required CentreAnalytique? centre,
    required bool compact,
  }) {
    final calcul = _calculAmortissement(immo);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(immo.libelle, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_libelleTypeImmobilisation(immo.type)} - Acquis le ${_formatDate(immo.dateAcquisition)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _ouvrirDialogImmobilisation(context, immo),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _metricChip(
                  'Origine',
                  currencyFormatter.format(immo.valeurAcquisition),
                ),
                _metricChip(
                  'Amortissement',
                  currencyFormatter.format(calcul.amortissementCumule),
                ),
                _metricChip(
                  'Valeur nette',
                  currencyFormatter.format(calcul.valeurNette),
                  color: AppColors.success,
                ),
                if (calcul.duree != null)
                  _metricChip(
                    'Duree',
                    '${calcul.duree} ans',
                    color: AppColors.indigo,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (assemblee != null || centre != null)
              Text(
                [
                  if (assemblee != null) 'Assemblee : ${assemblee.nom}',
                  if (centre != null) 'Centre : ${centre.nom}',
                ].join(' - '),
                style: AppTextStyles.bodySmall,
              ),
            if (immo.estSortie) ...[
              const SizedBox(height: AppSpacing.sm),
              Chip(
                avatar: const Icon(Icons.logout_outlined, size: 16),
                label: Text(
                  'Sortie ${immo.dateSortie != null ? _formatDate(immo.dateSortie!) : ''}',
                ),
                labelStyle: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
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

  _Amortissement _calculAmortissement(ImmobilisationComptable immo) {
    final base = (immo.valeurAcquisition - (immo.valeurResiduelle ?? 0))
        .clamp(0, 1e14)
        .toDouble();
    final duree = immo.dureeUtiliteEnAnnees <= 0
        ? null
        : immo.dureeUtiliteEnAnnees;
    final dotationAnnuelle = (duree == null || duree == 0)
        ? 0.0
        : base / duree.toDouble();
    var annees = DateTime.now().year - immo.dateAcquisition.year;
    if (annees < 0) annees = 0;
    if (duree != null && annees > duree) annees = duree;
    var amortCumul = dotationAnnuelle * annees;
    if (amortCumul > base) amortCumul = base;
    final valeurNette = immo.valeurAcquisition - amortCumul;
    return _Amortissement(
      duree: duree,
      dotationAnnuelle: dotationAnnuelle,
      amortissementCumule: amortCumul,
      valeurNette: valeurNette,
    );
  }

  Future<void> _ouvrirDialogImmobilisation(
    BuildContext context,
    ImmobilisationComptable? immo,
  ) async {
    final formKey = GlobalKey<FormState>();
    final comptesAsync = ref.read(comptesComptablesProvider);
    final centresAsync = ref.read(centresAnalytiquesProvider);
    final churchUnits = accountingScopeUnits(
      ref.read(churchUnitsProvider).value ?? [],
    );
    final assembleeActiveId = ref.read(assembleeActiveIdProvider);

    final comptes = comptesAsync.asData?.value ?? <CompteComptable>[];
    final centres = centresAsync.asData?.value ?? <CentreAnalytique>[];

    String libelle = immo?.libelle ?? '';
    var type = immo?.type ?? TypeImmobilisation.autre;
    var dateAcquisition = immo?.dateAcquisition ?? DateTime.now();
    var valeurAcquisitionStr = immo?.valeurAcquisition.toString() ?? '';
    var valeurResiduelleStr = immo?.valeurResiduelle?.toString() ?? '';
    var dureeStr = immo?.dureeUtiliteEnAnnees.toString() ?? '5';

    String? idCompteImmobilisation =
        immo?.idCompteImmobilisation ??
        (comptes.isNotEmpty ? comptes.first.id : null);
    String? idCompteAmortissement = immo?.idCompteAmortissement;
    String? idCompteDotation = immo?.idCompteDotation;
    String? idAssembleeLocale = immo?.idAssembleeLocale ?? assembleeActiveId;
    String? churchUnitId =
        immo?.churchUnitId ??
        churchUnitIdForLegacyAssemblee(churchUnits, idAssembleeLocale);
    if (churchUnitId != null &&
        !churchUnits.any((unit) => unit.id == churchUnitId)) {
      churchUnitId = null;
    }
    String? idCentreAnalytique = immo?.idCentreAnalytique;

    var estSortie = immo?.estSortie ?? false;
    DateTime? dateSortie = immo?.dateSortie;
    var valeurCessionStr = immo?.valeurCession?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final dateAcqController = TextEditingController(
              text: _formatDate(dateAcquisition),
            );
            final dateSortieController = TextEditingController(
              text: dateSortie != null ? _formatDate(dateSortie!) : '',
            );
            return EabDialog(
              title: immo == null
                  ? 'Nouvelle immobilisation'
                  : 'Modifier une immobilisation',
              width: 600,
              content: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: libelle,
                      decoration: const InputDecoration(labelText: 'Libelle'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Libelle obligatoire'
                          : null,
                      onSaved: (v) => libelle = v!.trim(),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TypeImmobilisation>(
                      isExpanded: true,
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: TypeImmobilisation.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_libelleTypeImmobilisation(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setStateDialog(() => type = v);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      readOnly: true,
                      controller: dateAcqController,
                      decoration: const InputDecoration(
                        labelText: 'Date d\'acquisition',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dateAcquisition,
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dateAcquisition = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: valeurAcquisitionStr,
                      decoration: const InputDecoration(
                        labelText: 'Valeur d\'acquisition',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) =>
                          (v == null ||
                              double.tryParse(v.replaceAll(',', '.')) == null)
                          ? 'Montant valide requis'
                          : null,
                      onSaved: (v) => valeurAcquisitionStr = v!.trim(),
                    ),
                    TextFormField(
                      initialValue: valeurResiduelleStr,
                      decoration: const InputDecoration(
                        labelText: 'Valeur residuelle (facultatif)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onSaved: (v) => valeurResiduelleStr = v?.trim() ?? '',
                    ),
                    TextFormField(
                      initialValue: dureeStr,
                      decoration: const InputDecoration(
                        labelText: 'Duree d\'utilite (annees)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || int.tryParse(v) == null)
                          ? 'Duree invalide'
                          : null,
                      onSaved: (v) => dureeStr = v!.trim(),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: idCompteImmobilisation,
                      decoration: const InputDecoration(
                        labelText: 'Compte d\'immobilisation',
                      ),
                      items: comptes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.numero} - ${c.intitule}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setStateDialog(() => idCompteImmobilisation = v),
                    ),
                    TextFormField(
                      initialValue: idCompteAmortissement ?? '',
                      decoration: const InputDecoration(
                        labelText:
                            'Compte d\'amortissement (id texte, facultatif)',
                      ),
                      onSaved: (v) => idCompteAmortissement =
                          (v?.trim().isEmpty ?? true) ? null : v!.trim(),
                    ),
                    TextFormField(
                      initialValue: idCompteDotation ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Compte de dotation (id texte, facultatif)',
                      ),
                      onSaved: (v) => idCompteDotation =
                          (v?.trim().isEmpty ?? true) ? null : v!.trim(),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: churchUnitId,
                      decoration: const InputDecoration(
                        labelText: 'Unite / perimetre (facultatif)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Aucune'),
                        ),
                        ...churchUnits.map(
                          (unit) => DropdownMenuItem<String?>(
                            value: unit.id,
                            child: Text(churchUnitLabel(unit)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setStateDialog(() {
                        churchUnitId = v;
                        idAssembleeLocale = legacyAssembleeIdForChurchUnit(
                          churchUnits,
                          v,
                        );
                      }),
                    ),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: idCentreAnalytique,
                      decoration: const InputDecoration(
                        labelText: 'Centre analytique (facultatif)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Aucun'),
                        ),
                        ...centres.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.nom),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setStateDialog(() => idCentreAnalytique = v),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: estSortie,
                      title: const Text('Immobilisation sortie / cede'),
                      onChanged: (v) => setStateDialog(() => estSortie = v),
                    ),
                    if (estSortie) ...[
                      TextFormField(
                        readOnly: true,
                        controller: dateSortieController,
                        decoration: const InputDecoration(
                          labelText: 'Date de sortie (facultatif)',
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dateSortie ?? DateTime.now(),
                            firstDate: DateTime(1990),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              dateSortie = picked;
                            });
                          }
                        },
                      ),
                      TextFormField(
                        initialValue: valeurCessionStr,
                        decoration: const InputDecoration(
                          labelText: 'Valeur de cession (facultatif)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onSaved: (v) => valeurCessionStr = v?.trim() ?? '',
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                EabButton(
                  label: 'Annuler',
                  variant: EabButtonVariant.ghost,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                EabButton(
                  label: 'Enregistrer',
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();

                    final valAcq = double.parse(
                      valeurAcquisitionStr.replaceAll(',', '.'),
                    );
                    final valRes = valeurResiduelleStr.isEmpty
                        ? null
                        : double.parse(
                            valeurResiduelleStr.replaceAll(',', '.'),
                          );
                    final duree = int.parse(dureeStr);
                    final valCession = valeurCessionStr.isEmpty
                        ? null
                        : double.parse(valeurCessionStr.replaceAll(',', '.'));

                    final notifier = ref.read(
                      immobilisationsComptablesProvider.notifier,
                    );

                    if (immo == null) {
                      final nouvelle = ImmobilisationComptable(
                        id: 'immo_${DateTime.now().millisecondsSinceEpoch}',
                        libelle: libelle,
                        type: type,
                        dateAcquisition: dateAcquisition,
                        valeurAcquisition: valAcq,
                        valeurResiduelle: valRes,
                        dureeUtiliteEnAnnees: duree,
                        idCompteImmobilisation:
                            idCompteImmobilisation ?? 'compte_immo_inconnu',
                        idCompteAmortissement: idCompteAmortissement,
                        idCompteDotation: idCompteDotation,
                        idAssembleeLocale: idAssembleeLocale,
                        churchUnitId: churchUnitId,
                        idCentreAnalytique: idCentreAnalytique,
                        estSortie: estSortie,
                        dateSortie: dateSortie,
                        valeurCession: valCession,
                      );
                      notifier.ajouterImmobilisation(nouvelle);
                    } else {
                      final maj = immo.copyWith(
                        libelle: libelle,
                        type: type,
                        dateAcquisition: dateAcquisition,
                        valeurAcquisition: valAcq,
                        valeurResiduelle: valRes,
                        dureeUtiliteEnAnnees: duree,
                        idCompteImmobilisation:
                            idCompteImmobilisation ??
                            immo.idCompteImmobilisation,
                        idCompteAmortissement: idCompteAmortissement,
                        idCompteDotation: idCompteDotation,
                        idAssembleeLocale: idAssembleeLocale,
                        churchUnitId: churchUnitId,
                        idCentreAnalytique: idCentreAnalytique,
                        estSortie: estSortie,
                        dateSortie: dateSortie,
                        valeurCession: valCession,
                      );
                      notifier.mettreAJourImmobilisation(maj);
                    }

                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _libelleTypeImmobilisation(TypeImmobilisation t) {
    switch (t) {
      case TypeImmobilisation.terrain:
        return 'Terrain';
      case TypeImmobilisation.batiment:
        return 'Batiment';
      case TypeImmobilisation.mobilier:
        return 'Mobilier';
      case TypeImmobilisation.materielInformatique:
        return 'Materiel informatique';
      case TypeImmobilisation.materielSono:
        return 'Materiel de sonorisation';
      case TypeImmobilisation.vehicule:
        return 'Vehicule';
      case TypeImmobilisation.autre:
        return 'Autre';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _emptyCard(String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(message, style: AppTextStyles.bodySmall),
            ),
          ),
        ),
      ),
    );
  }
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

class _Amortissement {
  _Amortissement({
    required this.duree,
    required this.dotationAnnuelle,
    required this.amortissementCumule,
    required this.valeurNette,
  });

  final int? duree;
  final double dotationAnnuelle;
  final double amortissementCumule;
  final double valeurNette;
}

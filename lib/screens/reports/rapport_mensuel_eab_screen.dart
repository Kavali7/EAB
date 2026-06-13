import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../features/church_units/application/church_units_provider.dart';
import '../../features/church_units/data/church_unit_model.dart';
import '../../models/rapport_mensuel_eab.dart';
import '../../providers/rapport_mensuel_eab_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../ui/ui.dart';
import '../../widgets/app_shell.dart';
import 'rapport_mensuel_eab_print_screen.dart';

class RapportMensuelEabScreen extends ConsumerStatefulWidget {
  const RapportMensuelEabScreen({super.key});

  @override
  ConsumerState<RapportMensuelEabScreen> createState() =>
      _RapportMensuelEabScreenState();
}

class _RapportMensuelEabScreenState
    extends ConsumerState<RapportMensuelEabScreen> {
  int _annee = DateTime.now().year;
  int _mois = DateTime.now().month;
  String? _selectedChurchUnitId;

  final TextEditingController _resumeActivitesCtrl = TextEditingController();
  final TextEditingController _projetsRealisationsCtrl =
      TextEditingController();
  final TextEditingController _projetsMoisSuivantCtrl = TextEditingController();
  final TextEditingController _observationsCtrl = TextEditingController();

  @override
  void dispose() {
    _resumeActivitesCtrl.dispose();
    _projetsRealisationsCtrl.dispose();
    _projetsMoisSuivantCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);

    return churchUnitsAsync.when(
      loading: () => const AppShell(
        title: 'Rapport mensuel',
        currentRoute: '/reports-rapport-mensuel',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => AppShell(
        title: 'Rapport mensuel',
        currentRoute: '/reports-rapport-mensuel',
        body: Center(child: Text('Erreur chargement des unites : $err')),
      ),
      data: (units) {
        final reportUnits = _reportUnits(units);
        if (_selectedChurchUnitId == null && reportUnits.isNotEmpty) {
          _selectedChurchUnitId = _initialChurchUnitId(
            reportUnits,
            assembleeActiveId,
          );
        }
        if (_selectedChurchUnitId != null &&
            !reportUnits.any((unit) => unit.id == _selectedChurchUnitId)) {
          _selectedChurchUnitId = _initialChurchUnitId(
            reportUnits,
            assembleeActiveId,
          );
        }
        if (_selectedChurchUnitId == null) {
          return const AppShell(
            title: 'Rapport mensuel',
            currentRoute: '/reports-rapport-mensuel',
            body: Center(child: Text('Aucune unite disponible.')),
          );
        }

        final selectedUnit = reportUnits.firstWhere(
          (unit) => unit.id == _selectedChurchUnitId,
          orElse: () => reportUnits.first,
        );
        final params = RapportMensuelParams(
          annee: _annee,
          mois: _mois,
          churchUnitId: selectedUnit.id,
        );
        final rapportAsync = ref.watch(rapportMensuelEabProvider(params));

        return AppShell(
          title: 'Rapport mensuel',
          currentRoute: '/reports-rapport-mensuel',
          showBackButton: true,
          backRoute: '/',
          actions: [
            IconButton(
              tooltip: 'Apercu imprimable',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _openPrintPreview(),
            ),
          ],
          body: rapportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) =>
                Center(child: Text('Erreur lors du calcul du rapport : $err')),
            data: (rapport) {
              _initialiserChampsTexteSiVides(rapport);
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: ListView(
                        padding: EdgeInsets.all(
                          compact ? AppSpacing.lg : AppSpacing.pagePadding,
                        ),
                        children: [
                          _FiltersPanel(
                            compact: compact,
                            annee: _annee,
                            mois: _mois,
                            units: reportUnits,
                            selectedChurchUnitId: _selectedChurchUnitId,
                            onAnneeChanged: (value) {
                              if (value == null) return;
                              setState(() => _annee = value);
                              _viderChampsTexte();
                            },
                            onMoisChanged: (value) {
                              if (value == null) return;
                              setState(() => _mois = value);
                              _viderChampsTexte();
                            },
                            onChurchUnitChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedChurchUnitId = value);
                              _viderChampsTexte();
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ReportIdentity(unit: selectedUnit, rapport: rapport),
                          const SizedBox(height: AppSpacing.md),
                          _buildRapportContent(compact, rapport),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openPrintPreview() {
    if (_selectedChurchUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez selectionner une unite.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RapportMensuelEabPrintScreen(
          annee: _annee,
          mois: _mois,
          churchUnitId: _selectedChurchUnitId!,
        ),
      ),
    );
  }

  void _initialiserChampsTexteSiVides(RapportMensuelEab rapport) {
    if (_resumeActivitesCtrl.text.isEmpty && rapport.resumeActivites != null) {
      _resumeActivitesCtrl.text = rapport.resumeActivites!;
    }
    if (_projetsRealisationsCtrl.text.isEmpty &&
        rapport.projetsRealisations != null) {
      _projetsRealisationsCtrl.text = rapport.projetsRealisations!;
    }
    if (_projetsMoisSuivantCtrl.text.isEmpty &&
        rapport.projetsMoisSuivant != null) {
      _projetsMoisSuivantCtrl.text = rapport.projetsMoisSuivant!;
    }
    if (_observationsCtrl.text.isEmpty && rapport.observations != null) {
      _observationsCtrl.text = rapport.observations!;
    }
  }

  void _viderChampsTexte() {
    _resumeActivitesCtrl.clear();
    _projetsRealisationsCtrl.clear();
    _projetsMoisSuivantCtrl.clear();
    _observationsCtrl.clear();
  }

  Widget _buildRapportContent(bool compact, RapportMensuelEab rapport) {
    return Column(
      children: [
        _buildSectionMembres(rapport.statsMembres, compact),
        const SizedBox(height: AppSpacing.md),
        _buildSectionActivites(rapport.statsActivites, compact),
        const SizedBox(height: AppSpacing.md),
        _buildSectionFinances(rapport.statsFinances, compact),
        const SizedBox(height: AppSpacing.md),
        _buildSectionTextesLibre(),
      ],
    );
  }

  Widget _buildSectionMembres(StatsMembresMensuelles stats, bool compact) {
    return _ReportSection(
      title: 'Membres',
      icon: Icons.groups_outlined,
      children: [
        _MetricGrid(
          compact: compact,
          items: [
            _Metric('Membres actifs', stats.totalMembresActifs),
            _Metric('Hommes', stats.totalHommesActifs),
            _Metric('Femmes', stats.totalFemmesActives),
            _Metric('Enfants', stats.totalEnfants),
            _Metric('Officiers', stats.totalOfficiers),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Personnes vulnerables',
          compact: compact,
          items: [
            _Metric('Orphelins', stats.totalOrphelins),
            _Metric('Veufs / veuves', stats.totalVeufsVeuves),
            _Metric('Handicapes', stats.totalHandicapes),
            _Metric('3e age', stats.totalTroisiemeAge),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Mouvements du mois',
          compact: compact,
          items: [
            _Metric('Convertis', stats.nouveauxConvertis),
            _Metric('Baptises', stats.nouveauxBaptises),
            _Metric('Mains association', stats.nouvellesMainsAssociation),
            _Metric('Mariages', stats.mariagesCheres),
            _Metric('Departs', stats.departAssemblage),
            _Metric('Deces', stats.deces),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionActivites(StatsActivitesMensuelles stats, bool compact) {
    return _ReportSection(
      title: 'Activites',
      icon: Icons.event_available_outlined,
      children: [
        _SubSection(
          title: 'Evangelisations',
          compact: compact,
          items: [
            _Metric('Masse', stats.nbEvangelisationsMasse),
            _Metric('Porte a porte', stats.nbEvangelisationsPorteAPorte),
            _Metric('Conv. hommes', stats.totalConversionsHommes),
            _Metric('Conv. femmes', stats.totalConversionsFemmes),
            _Metric('Conv. garcons', stats.totalConversionsGarcons),
            _Metric('Conv. filles', stats.totalConversionsFilles),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Cultes et actes',
          compact: compact,
          items: [
            _Metric('Baptemes', stats.nbBaptemes),
            _Metric('Mains association', stats.nbMainsAssociation),
            _Metric('Saintes cenes', stats.nbSaintesCenes),
            _Metric('Prieres', stats.nbReunionsPriere),
            _Metric('Mariages', stats.nbMariages),
            _Metric('Disciplines', stats.nbDisciplines),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Visites',
          compact: compact,
          items: [
            _Metric('Fideles', stats.nbVisitesFideles),
            _Metric('Autorites', stats.nbVisitesAutorites),
            _Metric('Partenaires', stats.nbVisitesPartenaires),
            _Metric('Autres assemblees', stats.nbVisitesAutresAssemblees),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Ecole du dimanche',
          compact: compact,
          items: [
            _Metric('Seances', stats.nbSeancesEcoleDimanche),
            _Metric('Apprenants H', stats.totalApprenantsHommes),
            _Metric('Apprenants F', stats.totalApprenantsFemmes),
            _Metric('Apprenants G', stats.totalApprenantsGarcons),
            _Metric('Apprenants filles', stats.totalApprenantsFilles),
            _Metric('Classes', stats.totalClassesEcoleDimanche),
            _Metric('Moniteurs', stats.totalMoniteursHommes),
            _Metric('Monitrices', stats.totalMonitricesFemmes),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionFinances(StatsFinancieresMensuelles stats, bool compact) {
    final resultat = stats.totalProduits - stats.totalCharges;
    return _ReportSection(
      title: 'Finances',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _MetricGrid(
          compact: compact,
          items: [
            _Metric.money('Produits', stats.totalProduits),
            _Metric.money('Charges', stats.totalCharges),
            _Metric.money('Resultat', resultat),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Detail produits',
          compact: compact,
          items: [
            _Metric.money('Offrandes', stats.totalOffrandesCultes),
            _Metric.money('Dons', stats.totalDonsLiberaites),
            _Metric.money('Autres recettes', stats.totalRecettesAutres),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SubSection(
          title: 'Detail charges',
          compact: compact,
          items: [
            _Metric.money('Fonctionnement', stats.totalChargesFonctionnement),
            _Metric.money('Charges sociales', stats.totalChargesSociales),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTextesLibre() {
    return _ReportSection(
      title: 'Synthese et projets',
      icon: Icons.notes_outlined,
      children: [
        _TextArea(
          controller: _resumeActivitesCtrl,
          label: 'Resume des principales activites du mois',
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        _TextArea(
          controller: _projetsRealisationsCtrl,
          label: 'Projets / realisations',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        _TextArea(
          controller: _projetsMoisSuivantCtrl,
          label: 'Projets prevus pour le mois suivant',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        _TextArea(
          controller: _observationsCtrl,
          label: 'Observations / suggestions',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Les champs texte sont stockes uniquement dans l interface pour le moment.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Simuler la sauvegarde'),
          ),
        ),
      ],
    );
  }

  List<ChurchUnit> _reportUnits(List<ChurchUnit> units) {
    final scopedUnits =
        units
            .where(
              (unit) =>
                  unit.active &&
                  (unit.canHaveMembers ||
                      unit.isFinancialScope ||
                      unit.isLocal),
            )
            .toList()
          ..sort((a, b) {
            final level = a.levelOrder.compareTo(b.levelOrder);
            if (level != 0) return level;
            return a.nom.compareTo(b.nom);
          });
    return scopedUnits.isEmpty
        ? units.where((unit) => unit.active).toList()
        : scopedUnits;
  }

  String? _initialChurchUnitId(
    List<ChurchUnit> units,
    String? activeAssembleeId,
  ) {
    if (units.isEmpty) return null;
    if (activeAssembleeId != null) {
      for (final unit in units) {
        if (unit.legacyAssembleeId == activeAssembleeId) return unit.id;
      }
    }
    for (final unit in units) {
      if (unit.isLocal || unit.canHaveMembers) return unit.id;
    }
    for (final unit in units) {
      if (unit.isFinancialScope) return unit.id;
    }
    return units.first.id;
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.compact,
    required this.annee,
    required this.mois,
    required this.units,
    required this.selectedChurchUnitId,
    required this.onAnneeChanged,
    required this.onMoisChanged,
    required this.onChurchUnitChanged,
  });

  final bool compact;
  final int annee;
  final int mois;
  final List<ChurchUnit> units;
  final String? selectedChurchUnitId;
  final ValueChanged<int?> onAnneeChanged;
  final ValueChanged<int?> onMoisChanged;
  final ValueChanged<String?> onChurchUnitChanged;

  @override
  Widget build(BuildContext context) {
    final years = [
      DateTime.now().year - 1,
      DateTime.now().year,
      DateTime.now().year + 1,
    ];
    final children = [
      DropdownButtonFormField<int>(
        initialValue: annee,
        decoration: const InputDecoration(labelText: 'Annee'),
        items: years
            .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
            .toList(),
        onChanged: onAnneeChanged,
      ),
      DropdownButtonFormField<int>(
        initialValue: mois,
        decoration: const InputDecoration(labelText: 'Mois'),
        items: [
          for (int m = 1; m <= 12; m++)
            DropdownMenuItem(value: m, child: Text('$m')),
        ],
        onChanged: onMoisChanged,
      ),
      DropdownButtonFormField<String>(
        initialValue: selectedChurchUnitId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Unite / perimetre'),
        items: units
            .map(
              (unit) => DropdownMenuItem(
                value: unit.id,
                child: Text(_unitLabel(unit), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChurchUnitChanged,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: compact
          ? Column(
              children:
                  children
                      .expand(
                        (child) => [
                          child,
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      )
                      .toList()
                    ..removeLast(),
            )
          : Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: children[1]),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 2, child: children[2]),
              ],
            ),
    );
  }

  String _unitLabel(ChurchUnit unit) {
    final code = unit.code == null || unit.code!.trim().isEmpty
        ? ''
        : ' - ${unit.code}';
    return '${unit.nom}$code';
  }
}

class _ReportIdentity extends StatelessWidget {
  const _ReportIdentity({required this.unit, required this.rapport});

  final ChurchUnit unit;
  final RapportMensuelEab rapport;

  @override
  Widget build(BuildContext context) {
    final details = [
      'Mois ${rapport.mois} / ${rapport.annee}',
      unit.typeLabel,
      if (unit.code != null) 'Code ${unit.code}',
      if (unit.ville != null) unit.ville!,
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.nom, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                Text(details.join(' | '), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _SubSection extends StatelessWidget {
  const _SubSection({
    required this.title,
    required this.items,
    required this.compact,
  });

  final String title;
  final List<_Metric> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.sm),
        _MetricGrid(compact: compact, items: items),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.compact, required this.items});

  final bool compact;
  final List<_Metric> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 2
            : constraints.maxWidth > 980
            ? 5
            : 3;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.sm)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: width.clamp(132, constraints.maxWidth).toDouble(),
                  child: _MetricTile(metric: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.isMoney
                ? currencyFormatter.format(metric.value)
                : metric.value.toStringAsFixed(0),
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({
    required this.controller,
    required this.label,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _Metric {
  _Metric(this.label, num value) : value = value.toDouble(), isMoney = false;

  const _Metric.money(this.label, this.value) : isMoney = true;

  final String label;
  final double value;
  final bool isMoney;
}

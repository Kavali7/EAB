import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../features/church_units/application/church_units_provider.dart';
import '../../features/church_units/data/church_unit_model.dart';
import '../../features/organization/application/organization_providers.dart';
import '../../features/organization/data/organization_model.dart';
import '../../models/rapport_mensuel_eab.dart';
import '../../providers/rapport_mensuel_eab_providers.dart';
import '../../widgets/print_preview_shell.dart';

class RapportMensuelEabPrintScreen extends ConsumerWidget {
  const RapportMensuelEabPrintScreen({
    super.key,
    required this.annee,
    required this.mois,
    required this.churchUnitId,
  });

  final int annee;
  final int mois;
  final String churchUnitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(churchUnitsProvider);
    final organization = ref.watch(currentOrganizationProvider).value;

    return unitsAsync.when(
      loading: () => const _ReportStateScreen(
        title: 'Rapport mensuel',
        subtitle: 'Chargement des unites',
        message: 'Preparation de l apercu...',
        loading: true,
      ),
      error: (err, st) => const _ReportStateScreen(
        title: 'Rapport mensuel',
        subtitle: 'Apercu indisponible',
        message: 'Erreur chargement des unites',
      ),
      data: (units) {
        final unit = units.firstWhere(
          (item) => item.id == churchUnitId,
          orElse: () => units.isNotEmpty
              ? units.first
              : ChurchUnit.legacy(
                  id: churchUnitId,
                  organizationId: '',
                  nom: 'Unite inconnue',
                  typeCode: 'unit',
                  typeLabel: 'Unite',
                  levelOrder: 0,
                ),
        );

        final params = RapportMensuelParams(
          annee: annee,
          mois: mois,
          churchUnitId: churchUnitId,
        );
        final rapportAsync = ref.watch(rapportMensuelEabProvider(params));

        return rapportAsync.when(
          loading: () => _ReportStateScreen(
            title: 'Rapport mensuel',
            subtitle: unit.nom,
            message: 'Calcul du rapport en cours...',
            loading: true,
          ),
          error: (err, st) => _ReportStateScreen(
            title: 'Rapport mensuel',
            subtitle: unit.nom,
            message: 'Erreur calcul rapport : $err',
          ),
          data: (rapport) => _ReportPreview(
            unit: unit,
            organization: organization,
            rapport: rapport,
          ),
        );
      },
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({
    required this.unit,
    required this.organization,
    required this.rapport,
  });

  final ChurchUnit unit;
  final Organization? organization;
  final RapportMensuelEab rapport;

  @override
  Widget build(BuildContext context) {
    final resultat =
        rapport.statsFinances.totalProduits -
        rapport.statsFinances.totalCharges;

    return PrintPreviewShell(
      title: 'Rapport mensuel',
      subtitle: '${unit.nom} - ${rapport.mois}/${rapport.annee}',
      icon: Icons.description_outlined,
      children: [
        PrintMetricGrid(
          metrics: [
            PrintMetric(
              label: 'Unite',
              value: unit.nom,
              icon: Icons.church_outlined,
            ),
            PrintMetric(
              label: 'Periode',
              value: '${rapport.mois}/${rapport.annee}',
              icon: Icons.calendar_month_outlined,
              color: AppColors.info,
            ),
            PrintMetric(
              label: 'Membres actifs',
              value: rapport.statsMembres.totalMembresActifs.toString(),
              icon: Icons.groups_outlined,
              color: AppColors.teal,
            ),
            PrintMetric(
              label: 'Resultat',
              value: _formatAmount(resultat),
              icon: Icons.account_balance_wallet_outlined,
              color: resultat >= 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        PrintSection(
          title: 'Identification',
          subtitle: 'Informations de contexte du rapport',
          icon: Icons.badge_outlined,
          child: _FactsGrid(
            items: [
              _FactItem('Eglise', _safeText(organization?.nom)),
              _FactItem('Sigle', _safeText(organization?.sigle)),
              _FactItem('Unite', unit.nom),
              _FactItem('Type', unit.typeLabel),
              _FactItem('Ville', _safeText(unit.ville)),
              _FactItem('Mois', '${rapport.mois}/${rapport.annee}'),
            ],
          ),
        ),
        _membersSection(rapport.statsMembres),
        _activitiesSection(rapport.statsActivites),
        _financesSection(rapport.statsFinances),
        _commentsSection(rapport),
      ],
    );
  }

  Widget _membersSection(StatsMembresMensuelles stats) {
    return PrintSection(
      title: 'Statistiques membres',
      icon: Icons.groups_outlined,
      child: _FactsGrid(
        items: [
          _FactItem('Total membres actifs', '${stats.totalMembresActifs}'),
          _FactItem(
            'Hommes / Femmes',
            '${stats.totalHommesActifs} / ${stats.totalFemmesActives}',
          ),
          _FactItem('Enfants (0-14 ans)', '${stats.totalEnfants}'),
          _FactItem('Officiers', '${stats.totalOfficiers}'),
          _FactItem(
            'Orphelins / Veufs / Handicapes / 3e age',
            '${stats.totalOrphelins} / ${stats.totalVeufsVeuves} / ${stats.totalHandicapes} / ${stats.totalTroisiemeAge}',
          ),
          _FactItem('Nouveaux convertis', '${stats.nouveauxConvertis}'),
          _FactItem('Nouveaux baptises', '${stats.nouveauxBaptises}'),
          _FactItem(
            'Nouvelles mains association',
            '${stats.nouvellesMainsAssociation}',
          ),
          _FactItem('Mariages cheres', '${stats.mariagesCheres}'),
          _FactItem(
            'Departs / deces',
            '${stats.departAssemblage} / ${stats.deces}',
          ),
        ],
      ),
    );
  }

  Widget _activitiesSection(StatsActivitesMensuelles stats) {
    return PrintSection(
      title: 'Activites et visites',
      icon: Icons.event_available_outlined,
      child: _FactsGrid(
        items: [
          _FactItem(
            'Evangelisation masse / porte a porte',
            '${stats.nbEvangelisationsMasse} / ${stats.nbEvangelisationsPorteAPorte}',
          ),
          _FactItem(
            'Conversions H/F/G/Fi',
            '${stats.totalConversionsHommes}/${stats.totalConversionsFemmes}/${stats.totalConversionsGarcons}/${stats.totalConversionsFilles}',
          ),
          _FactItem('Baptemes', '${stats.nbBaptemes}'),
          _FactItem('Mains association', '${stats.nbMainsAssociation}'),
          _FactItem('Saintes cenes', '${stats.nbSaintesCenes}'),
          _FactItem('Reunions de priere', '${stats.nbReunionsPriere}'),
          _FactItem('Mariages', '${stats.nbMariages}'),
          _FactItem('Disciplines', '${stats.nbDisciplines}'),
          _FactItem(
            'Visites fideles / autorites / partenaires / autres assemblees',
            '${stats.nbVisitesFideles} / ${stats.nbVisitesAutorites} / ${stats.nbVisitesPartenaires} / ${stats.nbVisitesAutresAssemblees}',
          ),
          _FactItem(
            'Ecole du dimanche',
            '${stats.nbSeancesEcoleDimanche} seances, ${stats.totalClassesEcoleDimanche} classes',
          ),
          _FactItem(
            'Apprenants H/F/G/Fi',
            '${stats.totalApprenantsHommes}/${stats.totalApprenantsFemmes}/${stats.totalApprenantsGarcons}/${stats.totalApprenantsFilles}',
          ),
          _FactItem(
            'Moniteurs H/F',
            '${stats.totalMoniteursHommes}/${stats.totalMonitricesFemmes}',
          ),
        ],
      ),
    );
  }

  Widget _financesSection(StatsFinancieresMensuelles stats) {
    final resultat = stats.totalProduits - stats.totalCharges;

    return PrintSection(
      title: 'Finances (FCFA)',
      icon: Icons.payments_outlined,
      child: _FactsGrid(
        items: [
          _FactItem('Total produits', _formatAmount(stats.totalProduits)),
          _FactItem('Total charges', _formatAmount(stats.totalCharges)),
          _FactItem('Resultat', _formatAmount(resultat)),
          _FactItem(
            'Offrandes de culte',
            _formatAmount(stats.totalOffrandesCultes),
          ),
          _FactItem(
            'Dons et liberalites',
            _formatAmount(stats.totalDonsLiberaites),
          ),
          _FactItem(
            'Autres recettes',
            _formatAmount(stats.totalRecettesAutres),
          ),
          _FactItem(
            'Charges fonctionnement',
            _formatAmount(stats.totalChargesFonctionnement),
          ),
          _FactItem(
            'Charges sociales',
            _formatAmount(stats.totalChargesSociales),
          ),
        ],
      ),
    );
  }

  Widget _commentsSection(RapportMensuelEab rapport) {
    return PrintSection(
      title: 'Commentaires',
      icon: Icons.notes_outlined,
      child: Column(
        children: [
          _ParagraphBlock('Resume des activites', rapport.resumeActivites),
          _ParagraphBlock('Projets realises', rapport.projetsRealisations),
          _ParagraphBlock(
            'Projets du mois suivant',
            rapport.projetsMoisSuivant,
          ),
          _ParagraphBlock('Observations', rapport.observations),
        ],
      ),
    );
  }
}

class _FactsGrid extends StatelessWidget {
  const _FactsGrid({required this.items});

  final List<_FactItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final columns = compact ? 1 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width
                    .clamp(
                      constraints.maxWidth < 180 ? constraints.maxWidth : 180.0,
                      constraints.maxWidth,
                    )
                    .toDouble(),
                child: _FactTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.item});

  final _FactItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(item.value, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = (value ?? '').trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.subtitle),
          const SizedBox(height: 6),
          Text(
            text.isNotEmpty ? text : 'Non renseigne',
            style: AppTextStyles.bodySmall.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _FactItem {
  const _FactItem(this.label, this.value);

  final String label;
  final String value;
}

class _ReportStateScreen extends StatelessWidget {
  const _ReportStateScreen({
    required this.title,
    required this.subtitle,
    required this.message,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PrintPreviewShell(
      title: title,
      subtitle: subtitle,
      icon: loading ? Icons.description_outlined : Icons.error_outline,
      children: [
        PrintSection(
          title: loading ? 'Chargement' : 'Apercu indisponible',
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : PrintEmptyState(message: message, icon: Icons.info_outline),
        ),
      ],
    );
  }
}

String _safeText(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? 'Non renseigne' : text;
}

String _formatAmount(double value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(' ');
  }
  return '$sign$buffer';
}

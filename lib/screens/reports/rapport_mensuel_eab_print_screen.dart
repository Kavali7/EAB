import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assemblee_locale.dart';
import '../../models/rapport_mensuel_eab.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/rapport_mensuel_eab_providers.dart';

class RapportMensuelEabPrintScreen extends ConsumerWidget {
  final int annee;
  final int mois;
  final String idAssembleeLocale;

  const RapportMensuelEabPrintScreen({
    super.key,
    required this.annee,
    required this.mois,
    required this.idAssembleeLocale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assembleesAsync = ref.watch(assembleesLocalesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apercu imprimable - Rapport mensuel EAB'),
      ),
      body: assembleesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            const Center(child: Text('Erreur chargement assemblees')),
        data: (assemblees) {
          final assemblee = assemblees.firstWhere(
            (a) => a.id == idAssembleeLocale,
            orElse: () => assemblees.isNotEmpty
                ? assemblees.first
                : AssembleeLocale(
                    id: idAssembleeLocale,
                    nom: 'Assemblee inconnue',
                    idDistrict: '',
                  ),
          );

          final params = RapportMensuelParams(
            annee: annee,
            mois: mois,
            idAssembleeLocale: idAssembleeLocale,
          );

          final rapportAsync = ref.watch(rapportMensuelEabProvider(params));

          return rapportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(
              child: Text('Erreur calcul rapport : $err'),
            ),
            data: (rapport) {
              return _buildPrintLayout(context, assemblee, rapport);
            },
          );
        },
      ),
    );
  }

  Widget _buildPrintLayout(
    BuildContext context,
    AssembleeLocale assemblee,
    RapportMensuelEab rapport,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(assemblee, rapport),
            const SizedBox(height: 24),
            _buildSectionMembres(rapport.statsMembres),
            const SizedBox(height: 16),
            _buildSectionActivites(rapport.statsActivites),
            const SizedBox(height: 16),
            _buildSectionFinances(rapport.statsFinances),
            const SizedBox(height: 16),
            _buildSectionTextes(rapport),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AssembleeLocale a, RapportMensuelEab r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'EGLISE APOSTOLIQUE DU BENIN',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Rapport mensuel d\'activites',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Assemblee : ${a.nom}',
          textAlign: TextAlign.center,
        ),
        Text(
          'Mois : ${r.mois} / ${r.annee}',
          textAlign: TextAlign.center,
        ),
        if (a.ville != null && a.ville!.isNotEmpty)
          Text('Ville : ${a.ville}', textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSectionMembres(StatsMembresMensuelles stats) {
    return _section(
      'Statistiques membres',
      [
        _line('Total membres actifs', '${stats.totalMembresActifs}'),
        _line('Hommes / Femmes', '${stats.totalHommesActifs} / ${stats.totalFemmesActives}'),
        _line('Enfants (0-14 ans)', '${stats.totalEnfants}'),
        _line('Officiers', '${stats.totalOfficiers}'),
        _line('Orphelins / Veufs/Veuves / Handicapes / 3e age',
            '${stats.totalOrphelins} / ${stats.totalVeufsVeuves} / ${stats.totalHandicapes} / ${stats.totalTroisiemeAge}'),
        _line('Nouveaux convertis', '${stats.nouveauxConvertis}'),
        _line('Nouveaux baptises', '${stats.nouveauxBaptises}'),
        _line('Nouvelles mains d\'association', '${stats.nouvellesMainsAssociation}'),
        _line('Mariages cheres', '${stats.mariagesCheres}'),
        _line('Departs / deces', '${stats.departAssemblage} / ${stats.deces}'),
      ],
    );
  }

  Widget _buildSectionActivites(StatsActivitesMensuelles stats) {
    return _section(
      'Activites et visites',
      [
        _line('Evangelisation masse / porte a porte',
            '${stats.nbEvangelisationsMasse} / ${stats.nbEvangelisationsPorteAPorte}'),
        _line(
          'Conversions H/F/G/Fi',
          '${stats.totalConversionsHommes}/${stats.totalConversionsFemmes}/${stats.totalConversionsGarcons}/${stats.totalConversionsFilles}',
        ),
        _line('Baptemes', '${stats.nbBaptemes}'),
        _line('Mains d\'association', '${stats.nbMainsAssociation}'),
        _line('Saintes cenes', '${stats.nbSaintesCenes}'),
        _line('Reunions de priere', '${stats.nbReunionsPriere}'),
        _line('Mariages', '${stats.nbMariages}'),
        _line('Disciplines', '${stats.nbDisciplines}'),
        _line(
          'Visites fideles / autorites / partenaires / autres assemblees',
          '${stats.nbVisitesFideles} / ${stats.nbVisitesAutorites} / ${stats.nbVisitesPartenaires} / ${stats.nbVisitesAutresAssemblees}',
        ),
        _line(
          'Ecole du dimanche : seances / apprenants H/F/G/Fi / classes / moniteurs H/F',
          '${stats.nbSeancesEcoleDimanche} / ${stats.totalApprenantsHommes}/${stats.totalApprenantsFemmes}/${stats.totalApprenantsGarcons}/${stats.totalApprenantsFilles} / ${stats.totalClassesEcoleDimanche} / ${stats.totalMoniteursHommes}/${stats.totalMonitricesFemmes}',
        ),
      ],
    );
  }

  Widget _buildSectionFinances(StatsFinancieresMensuelles stats) {
    return _section(
      'Finances (FCFA)',
      [
        _line('Total produits', stats.totalProduits.toStringAsFixed(0)),
        _line('Total charges', stats.totalCharges.toStringAsFixed(0)),
        _line(
          'Resultat',
          (stats.totalProduits - stats.totalCharges).toStringAsFixed(0),
        ),
        _line('Offrandes de culte', stats.totalOffrandesCultes.toStringAsFixed(0)),
        _line('Dons & liberalites', stats.totalDonsLiberaites.toStringAsFixed(0)),
        _line('Autres recettes', stats.totalRecettesAutres.toStringAsFixed(0)),
        _line('Charges fonctionnement', stats.totalChargesFonctionnement.toStringAsFixed(0)),
        _line('Charges sociales', stats.totalChargesSociales.toStringAsFixed(0)),
      ],
    );
  }

  Widget _buildSectionTextes(RapportMensuelEab r) {
    return _section(
      'Commentaires',
      [
        _paragraph('Resume des activites', r.resumeActivites),
        _paragraph('Projets realises', r.projetsRealisations),
        _paragraph('Projets du mois suivant', r.projetsMoisSuivant),
        _paragraph('Observations', r.observations),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            (value ?? '').isNotEmpty ? value! : 'Non renseigne',
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assemblee_locale.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/rapport_mensuel_eab.dart';
import '../../core/theme.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/rapport_mensuel_eab_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';

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
  String? _idAssembleeSelectionnee;

  // Champs texte locaux (non persistés pour l'instant)
  final TextEditingController _resumeActivitesCtrl = TextEditingController();
  final TextEditingController _projetsRealisationsCtrl =
      TextEditingController();
  final TextEditingController _projetsMoisSuivantCtrl =
      TextEditingController();
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
    final profil = ref.watch(profilUtilisateurCourantProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);

    return assembleesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        body: Center(child: Text('Erreur chargement assemblees : $err')),
      ),
      data: (assemblees) {
        if (_idAssembleeSelectionnee == null && assemblees.isNotEmpty) {
          _idAssembleeSelectionnee =
              assembleeActiveId ?? assemblees.first.id;
        }
        if (_idAssembleeSelectionnee == null) {
          return const Scaffold(
            body: Center(child: Text('Aucune assemblee disponible.')),
          );
        }
        final assemblee = assemblees
            .firstWhere((a) => a.id == _idAssembleeSelectionnee,
                orElse: () => assemblees.isNotEmpty
                    ? assemblees.first
                    : AssembleeLocale(
                        id: 'inconnu',
                        nom: 'Aucune assemblee',
                        idDistrict: '',
                      ));

        final params = RapportMensuelParams(
          annee: _annee,
          mois: _mois,
          idAssembleeLocale: assemblee.id,
        );

        final rapportAsync = ref.watch(rapportMensuelEabProvider(params));

        return AppShell(
          title: 'Rapport mensuel EAB',
          currentRoute: '/reports-rapport-mensuel',
          body: rapportAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(
              child: Text('Erreur lors du calcul du rapport : $err'),
            ),
            data: (rapport) {
              _initialiserChampsTexteSiVides(rapport);
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ContextHeader(showPorteeComptable: false),
                      const SizedBox(height: 8),
                      _buildHeaderFilters(assemblees),
                      _buildRapportContent(
                        context,
                        profil,
                        assemblee,
                        rapport,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _initialiserChampsTexteSiVides(RapportMensuelEab rapport) {
    if (_resumeActivitesCtrl.text.isEmpty &&
        rapport.resumeActivites != null) {
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

  Widget _buildHeaderFilters(List<AssembleeLocale> assemblees) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Annee : '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _annee,
                  items: [
                    for (final an in [
                      DateTime.now().year - 1,
                      DateTime.now().year,
                      DateTime.now().year + 1,
                    ])
                      DropdownMenuItem(
                        value: an,
                        child: Text('$an'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _annee = v);
                      _viderChampsTexte();
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mois : '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _mois,
                  items: [
                    for (int m = 1; m <= 12; m++)
                      DropdownMenuItem(
                        value: m,
                        child: Text('$m'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _mois = v);
                      _viderChampsTexte();
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Assemblee : '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _idAssembleeSelectionnee,
                  items: assemblees
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.nom),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _idAssembleeSelectionnee = v);
                      _viderChampsTexte();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viderChampsTexte() {
    _resumeActivitesCtrl.clear();
    _projetsRealisationsCtrl.clear();
    _projetsMoisSuivantCtrl.clear();
    _observationsCtrl.clear();
  }

  Widget _buildRapportContent(
    BuildContext context,
    ProfilUtilisateur? profil,
    AssembleeLocale assemblee,
    RapportMensuelEab rapport,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionInfos(assemblee, rapport),
        const SizedBox(height: 16),
        _buildSectionMembres(rapport.statsMembres),
        const SizedBox(height: 16),
        _buildSectionActivites(rapport.statsActivites),
        const SizedBox(height: 16),
        _buildSectionFinances(rapport.statsFinances),
        const SizedBox(height: 16),
        _buildSectionTextesLibre(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionInfos(
    AssembleeLocale assemblee,
    RapportMensuelEab rapport,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations generales',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text('Assemblee : ${assemblee.nom} (${assemblee.code ?? '-'})'),
            Text('Mois : ${rapport.mois} / ${rapport.annee}'),
            if (assemblee.ville != null) Text('Ville : ${assemblee.ville}'),
            if (assemblee.quartier != null)
              Text('Quartier : ${assemblee.quartier}'),
            if (assemblee.telephone != null)
              Text('Telephone : ${assemblee.telephone}'),
            if (assemblee.email != null) Text('Email : ${assemblee.email}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionMembres(StatsMembresMensuelles s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques des membres',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Membres actifs', s.totalMembresActifs),
                _statLine('Hommes actifs', s.totalHommesActifs),
                _statLine('Femmes actives', s.totalFemmesActives),
                _statLine('Enfants (0-14 ans)', s.totalEnfants),
                _statLine('Officiers', s.totalOfficiers),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Personnes vulnerables',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Orphelins', s.totalOrphelins),
                _statLine('Veufs/veuves', s.totalVeufsVeuves),
                _statLine('Handicapes', s.totalHandicapes),
                _statLine('3e age', s.totalTroisiemeAge),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Mouvements du mois',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Nouveaux convertis', s.nouveauxConvertis),
                _statLine('Nouveaux baptises', s.nouveauxBaptises),
                _statLine(
                    'Nouvelles mains d association', s.nouvellesMainsAssociation),
                _statLine('Mariages celebres', s.mariagesCheres),
                _statLine('Departs', s.departAssemblage),
                _statLine('Deces', s.deces),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionActivites(StatsActivitesMensuelles a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activites',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            const Text(
              'Evangelisations',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Ev. de masse', a.nbEvangelisationsMasse),
                _statLine('Ev. porte a porte', a.nbEvangelisationsPorteAPorte),
                _statLine('Conversions H', a.totalConversionsHommes),
                _statLine('Conversions F', a.totalConversionsFemmes),
                _statLine('Conversions G', a.totalConversionsGarcons),
                _statLine('Conversions filles', a.totalConversionsFilles),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cultes & actes',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Baptemes', a.nbBaptemes),
                _statLine('Mains d association', a.nbMainsAssociation),
                _statLine('Saintes cenes', a.nbSaintesCenes),
                _statLine('Reunions de priere', a.nbReunionsPriere),
                _statLine('Mariages', a.nbMariages),
                _statLine('Disciplines', a.nbDisciplines),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Visites',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Visites aux fideles', a.nbVisitesFideles),
                _statLine('Visites aux autorites', a.nbVisitesAutorites),
                _statLine('Visites aux partenaires', a.nbVisitesPartenaires),
                _statLine('Visites aux autres assemblees',
                    a.nbVisitesAutresAssemblees),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Ecole du dimanche',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLine('Seances EDD', a.nbSeancesEcoleDimanche),
                _statLine('Apprenants H', a.totalApprenantsHommes),
                _statLine('Apprenants F', a.totalApprenantsFemmes),
                _statLine('Apprenants G', a.totalApprenantsGarcons),
                _statLine('Apprenants filles', a.totalApprenantsFilles),
                _statLine('Classes', a.totalClassesEcoleDimanche),
                _statLine('Moniteurs H', a.totalMoniteursHommes),
                _statLine('Monitrices F', a.totalMonitricesFemmes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionFinances(StatsFinancieresMensuelles f) {
    final resultat = f.totalProduits - f.totalCharges;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finances (periode du mois)',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLineMontant('Total produits', f.totalProduits),
                _statLineMontant('Total charges', f.totalCharges),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Resultat : ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      resultat.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: resultat >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Detail produits',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLineMontant('Offrandes de culte', f.totalOffrandesCultes),
                _statLineMontant('Dons & liberalites', f.totalDonsLiberaites),
                _statLineMontant('Autres recettes', f.totalRecettesAutres),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Detail charges',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 32,
              runSpacing: 8,
              children: [
                _statLineMontant(
                    'Charges de fonctionnement', f.totalChargesFonctionnement),
                _statLineMontant('Charges sociales', f.totalChargesSociales),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTextesLibre() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synthese & Projets (saisie manuelle)',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resumeActivitesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Resume des principales activites du mois',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projetsRealisationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Projets / realisations (travaux, amenagements, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projetsMoisSuivantCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Projets prevus pour le mois suivant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observations / suggestions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                icon: const Icon(Icons.save),
                label: const Text('Simuler la sauvegarde'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statLine(String label, num value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text('$value'),
      ],
    );
  }

  Widget _statLineMontant(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(value.toStringAsFixed(0)),
      ],
    );
  }
}

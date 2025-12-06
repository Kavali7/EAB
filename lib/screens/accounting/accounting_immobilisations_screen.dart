import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assemblee_locale.dart';
import '../../models/centre_analytique.dart';
import '../../models/compte_comptable.dart';
import '../../models/immobilisation_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/context_header.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Immobilisations'),
      ),
      floatingActionButton: _buildFabAjoutImmo(profil),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ContextHeader(showPorteeComptable: true),
            const SizedBox(height: 8),
            Expanded(
              child: immobilisationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => const Center(
                  child: Text('Erreur lors du chargement des immobilisations'),
                ),
                data: (immobilisations) {
                  final assemblees = assembleesAsync.asData?.value ?? [];
                  final centres = centresAsync.asData?.value ?? [];
                  final assembleesParId = {for (final a in assemblees) a.id: a};
                  final centresParId = {for (final c in centres) c.id: c};

                  return _buildListeImmobilisations(
                    context: context,
                    immobilisations: immobilisations,
                    assembleesParId: assembleesParId,
                    centresParId: centresParId,
                  );
                },
              ),
            ),
          ],
        ),
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
    required BuildContext context,
    required List<ImmobilisationComptable> immobilisations,
    required Map<String, AssembleeLocale> assembleesParId,
    required Map<String, CentreAnalytique> centresParId,
  }) {
    immobilisations.sort(
      (a, b) => a.dateAcquisition.compareTo(b.dateAcquisition),
    );

    return ListView.builder(
      itemCount: immobilisations.length,
      itemBuilder: (context, index) {
        final immo = immobilisations[index];
        final assemblee = immo.idAssembleeLocale != null
            ? assembleesParId[immo.idAssembleeLocale]
            : null;
        final centre = immo.idCentreAnalytique != null
            ? centresParId[immo.idCentreAnalytique]
            : null;
        final calcul = _calculAmortissement(immo);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(immo.libelle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type : ${_libelleTypeImmobilisation(immo.type)} - Acquis le ${_formatDate(immo.dateAcquisition)}',
                ),
                if (assemblee != null) Text('Assemblee : ${assemblee.nom}'),
                if (centre != null) Text('Centre : ${centre.nom}'),
                Text(
                    'Valeur d\'origine : ${immo.valeurAcquisition.toStringAsFixed(0)}'),
                if (calcul.duree != null && calcul.duree! > 0)
                  Text(
                    'Duree : ${calcul.duree} ans - Dotation annuelle : ${calcul.dotationAnnuelle.toStringAsFixed(0)}',
                  ),
                Text(
                  'Amortissement cumule : ${calcul.amortissementCumule.toStringAsFixed(0)} - Valeur nette : ${calcul.valeurNette.toStringAsFixed(0)}',
                ),
                if (immo.estSortie)
                  Text(
                    'Immobilisation sortie le ${immo.dateSortie != null ? _formatDate(immo.dateSortie!) : ''}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _ouvrirDialogImmobilisation(context, immo),
            ),
          ),
        );
      },
    );
  }

  _Amortissement _calculAmortissement(ImmobilisationComptable immo) {
    final base = (immo.valeurAcquisition - (immo.valeurResiduelle ?? 0))
        .clamp(0, 1e14)
        .toDouble();
    final duree =
        immo.dureeUtiliteEnAnnees <= 0 ? null : immo.dureeUtiliteEnAnnees;
    final dotationAnnuelle = (duree == null || duree == 0)
        ? 0.0
        : base / duree.toDouble();
    var annees =
        DateTime.now().year - immo.dateAcquisition.year;
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
    final assembleesAsync = ref.read(assembleesLocalesProvider);
    final centresAsync = ref.read(centresAnalytiquesProvider);
    final assembleeActiveId = ref.read(assembleeActiveIdProvider);

    final comptes = comptesAsync.asData?.value ?? <CompteComptable>[];
    final assemblees = assembleesAsync.asData?.value ?? <AssembleeLocale>[];
    final centres = centresAsync.asData?.value ?? <CentreAnalytique>[];

    String libelle = immo?.libelle ?? '';
    var type = immo?.type ?? TypeImmobilisation.autre;
    var dateAcquisition = immo?.dateAcquisition ?? DateTime.now();
    var valeurAcquisitionStr = immo?.valeurAcquisition.toString() ?? '';
    var valeurResiduelleStr = immo?.valeurResiduelle?.toString() ?? '';
    var dureeStr = immo?.dureeUtiliteEnAnnees.toString() ?? '5';

    String? idCompteImmobilisation =
        immo?.idCompteImmobilisation ?? (comptes.isNotEmpty ? comptes.first.id : null);
    String? idCompteAmortissement = immo?.idCompteAmortissement;
    String? idCompteDotation = immo?.idCompteDotation;
    String? idAssembleeLocale = immo?.idAssembleeLocale ?? assembleeActiveId;
    String? idCentreAnalytique = immo?.idCentreAnalytique;

    var estSortie = immo?.estSortie ?? false;
    DateTime? dateSortie = immo?.dateSortie;
    var valeurCessionStr = immo?.valeurCession?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final dateAcqController =
                TextEditingController(text: _formatDate(dateAcquisition));
            final dateSortieController = TextEditingController(
              text: dateSortie != null ? _formatDate(dateSortie!) : '',
            );
            return AlertDialog(
              title: Text(
                immo == null
                    ? 'Nouvelle immobilisation'
                    : 'Modifier une immobilisation',
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: libelle,
                          decoration:
                              const InputDecoration(labelText: 'Libelle'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Libelle obligatoire'
                              : null,
                          onSaved: (v) => libelle = v!.trim(),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TypeImmobilisation>(
                          initialValue: type,
                          decoration:
                              const InputDecoration(labelText: 'Type'),
                          items: TypeImmobilisation.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child:
                                      Text(_libelleTypeImmobilisation(t)),
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
                              labelText: 'Date d\'acquisition'),
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
                              (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
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
                          validator: (v) =>
                              (v == null || int.tryParse(v) == null)
                                  ? 'Duree invalide'
                                  : null,
                          onSaved: (v) => dureeStr = v!.trim(),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
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
                            labelText:
                                'Compte de dotation (id texte, facultatif)',
                          ),
                          onSaved: (v) => idCompteDotation =
                              (v?.trim().isEmpty ?? true) ? null : v!.trim(),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: idAssembleeLocale,
                          decoration: const InputDecoration(
                            labelText: 'Assemblee (facultatif)',
                          ),
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
                          onChanged: (v) =>
                              setStateDialog(() => idAssembleeLocale = v),
                        ),
                        DropdownButtonFormField<String?>(
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
                          title:
                              const Text('Immobilisation sortie / cede'),
                          onChanged: (v) =>
                              setStateDialog(() => estSortie = v),
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
                              labelText:
                                  'Valeur de cession (facultatif)',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onSaved: (v) =>
                                valeurCessionStr = v?.trim() ?? '',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();

                    final valAcq =
                        double.parse(valeurAcquisitionStr.replaceAll(',', '.'));
                    final valRes = valeurResiduelleStr.isEmpty
                        ? null
                        : double.parse(
                            valeurResiduelleStr.replaceAll(',', '.'),
                          );
                    final duree = int.parse(dureeStr);
                    final valCession = valeurCessionStr.isEmpty
                        ? null
                        : double.parse(
                            valeurCessionStr.replaceAll(',', '.'),
                          );

                    final notifier =
                        ref.read(immobilisationsComptablesProvider.notifier);

                    if (immo == null) {
                      final nouvelle = ImmobilisationComptable(
                        id:
                            'immo_${DateTime.now().millisecondsSinceEpoch}',
                        libelle: libelle,
                        type: type,
                        dateAcquisition: dateAcquisition,
                        valeurAcquisition: valAcq,
                        valeurResiduelle: valRes,
                        dureeUtiliteEnAnnees: duree,
                        idCompteImmobilisation: idCompteImmobilisation ??
                            'compte_immo_inconnu',
                        idCompteAmortissement: idCompteAmortissement,
                        idCompteDotation: idCompteDotation,
                        idAssembleeLocale: idAssembleeLocale,
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
                        idCompteImmobilisation: idCompteImmobilisation ??
                            immo.idCompteImmobilisation,
                        idCompteAmortissement: idCompteAmortissement,
                        idCompteDotation: idCompteDotation,
                        idAssembleeLocale: idAssembleeLocale,
                        idCentreAnalytique: idCentreAnalytique,
                        estSortie: estSortie,
                        dateSortie: dateSortie,
                        valeurCession: valCession,
                      );
                      notifier.mettreAJourImmobilisation(maj);
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Enregistrer'),
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

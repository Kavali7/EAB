import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/centre_analytique.dart';
import '../../../models/compte_comptable.dart';
import '../../../models/compta_enums.dart';
import '../../../models/ecriture_comptable.dart';
import '../../../models/journal_comptable.dart';
import '../../../models/tiers.dart';
import '../../../core/constants.dart';
import '../../../providers/accounting_providers.dart';
import '../../../providers/user_profile_providers.dart';

class EcritureComptableFormDialog extends ConsumerStatefulWidget {
  const EcritureComptableFormDialog({super.key, this.ecritureExistante});

  final EcritureComptable? ecritureExistante;

  @override
  ConsumerState<EcritureComptableFormDialog> createState() =>
      _EcritureComptableFormDialogState();
}

class _EcritureComptableFormDialogState
    extends ConsumerState<EcritureComptableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  JournalComptable? _journalSelectionne;
  DateTime _date = DateTime.now();
  String _referencePiece = '';
  String _libelleGeneral = '';
  CentreAnalytique? _centrePrincipal;
  ModePaiement? _modePaiementGlobal;
  bool _initialise = false;

  final List<_LigneEditable> _lignes = [];

  @override
  void dispose() {
    for (final l in _lignes) {
      l.dispose();
    }
    super.dispose();
  }

  void _initialiserSiBesoin(
    List<JournalComptable> journaux,
    Map<String, CentreAnalytique> centreById,
  ) {
    if (_initialise) return;
    if (journaux.isEmpty) return;
    final existante = widget.ecritureExistante;
    _journalSelectionne = existante != null
        ? journaux.firstWhere(
            (j) => j.id == existante.idJournal,
            orElse: () => journaux.first,
          )
        : journaux.first;
    _date = existante?.date ?? DateTime.now();
    _referencePiece = existante?.referencePiece ?? '';
    _libelleGeneral = existante?.libelle ?? '';
    _centrePrincipal = existante?.idCentreAnalytiquePrincipal != null
        ? centreById[existante!.idCentreAnalytiquePrincipal!]
        : null;

    if (existante != null) {
      for (final l in existante.lignes) {
        _lignes.add(
          _LigneEditable(
            idTemp: l.id,
            idCompte: l.idCompteComptable,
            libelle: l.libelle ?? '',
            idCentre: l.idCentreAnalytique,
            idTiers: l.idTiers,
            mode: l.modePaiement,
            debitText:
                l.debit != null ? l.debit!.toStringAsFixed(0) : '',
            creditText:
                l.credit != null ? l.credit!.toStringAsFixed(0) : '',
          ),
        );
      }
    } else {
      _lignes.addAll([
        _LigneEditable(idTemp: _uuid.v4()),
        _LigneEditable(idTemp: _uuid.v4()),
      ]);
    }
    _initialise = true;
  }

  @override
  Widget build(BuildContext context) {
    final journauxAsync = ref.watch(journauxComptablesProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final centresAsync = ref.watch(centresAnalytiquesProvider);
    final tiersAsync = ref.watch(tiersProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);

    if (journauxAsync.isLoading ||
        comptesAsync.isLoading ||
        centresAsync.isLoading ||
        tiersAsync.isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (journauxAsync.hasError ||
        comptesAsync.hasError ||
        centresAsync.hasError ||
        tiersAsync.hasError) {
      return AlertDialog(
        title: const Text('Erreur'),
        content: const Text('Impossible de charger les donnees comptables.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      );
    }

    final journaux = journauxAsync.value ?? [];
    final comptes = comptesAsync.value ?? [];
    final centres = centresAsync.value ?? [];
    final tiers = tiersAsync.value ?? [];
    final centreById = {for (final c in centres) c.id: c};

    _initialiserSiBesoin(journaux, centreById);

    final centresFiltres = assembleeActiveId == null
        ? centres
        : centres.where((c) {
            if (c.idAssembleeLocale == null) return true;
            return c.idAssembleeLocale == assembleeActiveId;
          }).toList();

    return AlertDialog(
      title: Text(
        widget.ecritureExistante == null
            ? 'Nouvelle ecriture comptable'
            : 'Modifier une ecriture comptable',
      ),
      content: SizedBox(
        width: 800,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(journaux, centresFiltres),
                const SizedBox(height: 16),
                _buildLignesSection(comptes, centresFiltres, tiers),
                const SizedBox(height: 12),
                _buildTotauxSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _validerEtEnregistrer(
            journaux,
            centresFiltres,
            assembleeActiveId,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(
    List<JournalComptable> journaux,
    List<CentreAnalytique> centres,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<JournalComptable>(
                isExpanded: true,
                initialValue: _journalSelectionne,
                decoration: const InputDecoration(labelText: 'Journal'),
                items: journaux
                    .map(
                      (j) => DropdownMenuItem(
                        value: j,
                        child: Text('${j.code} - ${j.intitule}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _journalSelectionne = value),
                validator: (v) => v == null ? 'Journal requis' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 365 * 5)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(dateFormatter.format(_date)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _referencePiece,
                decoration:
                    const InputDecoration(labelText: 'Reference piece'),
                onChanged: (v) => _referencePiece = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _libelleGeneral,
                decoration: const InputDecoration(labelText: 'Libelle'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Libelle requis' : null,
                onChanged: (v) => _libelleGeneral = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CentreAnalytique?>(
          isExpanded: true,
          initialValue: _centrePrincipal,
          decoration:
              const InputDecoration(labelText: 'Centre analytique principal'),
          items: [
            const DropdownMenuItem<CentreAnalytique?>(
              value: null,
              child: Text('Aucun'),
            ),
            ...centres.map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text('${c.code} - ${c.nom}'),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _centrePrincipal = v),
        ),
      ],
    );
  }

  Widget _buildLignesSection(
    List<CompteComptable> comptes,
    List<CentreAnalytique> centres,
    List<Tiers> tiers,
  ) {
    final compteItems = comptes
        .map(
          (c) => DropdownMenuItem<String>(
            value: c.id,
            child: Text('${c.numero} - ${c.intitule}'),
          ),
        )
        .toList();
    final centreItems = [
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
    ];
    final tiersItems = [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Aucun'),
      ),
      ...tiers.map(
        (t) => DropdownMenuItem<String?>(
          value: t.id,
          child: Text(t.nom),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lignes',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            DropdownButton<ModePaiement?>(
              value: _modePaiementGlobal,
              hint: const Text('Mode pour nouvelles lignes'),
              items: [
                const DropdownMenuItem<ModePaiement?>(
                  value: null,
                  child: Text('Aucun'),
                ),
                ...ModePaiement.values.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(_modePaiementLabel(m)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _modePaiementGlobal = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var i = 0; i < _lignes.length; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _lignes[i].idCompte,
                              decoration:
                                  const InputDecoration(labelText: 'Compte'),
                              items: compteItems,
                              onChanged: (v) =>
                                  setState(() => _lignes[i].idCompte = v),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Compte requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lignes[i].libelleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Libelle de ligne',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              initialValue: _lignes[i].idCentre,
                              decoration:
                                  const InputDecoration(labelText: 'Centre'),
                              items: centreItems,
                              onChanged: (v) =>
                                  setState(() => _lignes[i].idCentre = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              initialValue: _lignes[i].idTiers,
                              decoration:
                                  const InputDecoration(labelText: 'Tiers'),
                              items: tiersItems,
                              onChanged: (v) =>
                                  setState(() => _lignes[i].idTiers = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<ModePaiement?>(
                              isExpanded: true,
                              initialValue:
                                  _lignes[i].mode ?? _modePaiementGlobal,
                              decoration:
                                  const InputDecoration(labelText: 'Mode'),
                              items: [
                                const DropdownMenuItem<ModePaiement?>(
                                  value: null,
                                  child: Text('Aucun'),
                                ),
                                ...ModePaiement.values.map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(_modePaiementLabel(m)),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _lignes[i].mode = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lignes[i].debitCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Debit'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lignes[i].creditCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Credit'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            onPressed: _lignes.length > 2
                                ? () => setState(() {
                                      _lignes.removeAt(i).dispose();
                                    })
                                : null,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Supprimer la ligne',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _lignes.add(
                      _LigneEditable(
                        idTemp: _uuid.v4(),
                        mode: _modePaiementGlobal,
                        idCentre: _centrePrincipal?.id,
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une ligne'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotauxSection() {
    final totalDebit = _lignes.fold<double>(
      0,
      (sum, l) => sum + (_parseDouble(l.debitCtrl.text) ?? 0),
    );
    final totalCredit = _lignes.fold<double>(
      0,
      (sum, l) => sum + (_parseDouble(l.creditCtrl.text) ?? 0),
    );
    final ecart = totalDebit - totalCredit;
    final desequilibre = ecart != 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Total debit : ${currencyFormatter.format(totalDebit)}'),
            const SizedBox(width: 16),
            Text('Total credit : ${currencyFormatter.format(totalCredit)}'),
            const SizedBox(width: 16),
            Text('Ecart : ${currencyFormatter.format(ecart)}'),
          ],
        ),
        if (desequilibre)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'Les totaux debit et credit doivent etre egaux.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Future<void> _validerEtEnregistrer(
    List<JournalComptable> journaux,
    List<CentreAnalytique> centres,
    String? assembleeActiveId,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_journalSelectionne == null) {
      _showMessage('Veuillez choisir un journal.');
      return;
    }
    if (assembleeActiveId == null) {
      _showMessage(
        "Aucune assemblee active n'est selectionnee : impossible d'enregistrer.",
      );
      return;
    }
    if (_lignes.length < 2) {
      _showMessage('Ajouter au moins deux lignes.');
      return;
    }

    final lignesConstruites = <LigneEcritureComptable>[];
    for (final l in _lignes) {
      if (l.idCompte == null || l.idCompte!.isEmpty) {
        _showMessage('Chaque ligne doit avoir un compte.');
        return;
      }
      final debit = _parseDouble(l.debitCtrl.text);
      final credit = _parseDouble(l.creditCtrl.text);
      if ((debit == null || debit == 0) && (credit == null || credit == 0)) {
        _showMessage('Chaque ligne doit avoir un debit ou un credit.');
        return;
      }
      final centre = l.idCentre ?? _centrePrincipal?.id;
      lignesConstruites.add(
        LigneEcritureComptable(
          id: l.idTemp.isNotEmpty ? l.idTemp : _uuid.v4(),
          idCompteComptable: l.idCompte!,
          debit: debit,
          credit: credit,
          idCentreAnalytique: centre,
          idTiers: l.idTiers,
          modePaiement: l.mode ?? _modePaiementGlobal,
          libelle: (l.libelleCtrl.text.trim().isNotEmpty
                  ? l.libelleCtrl.text.trim()
                  : _libelleGeneral)
              .trim(),
        ),
      );
    }

    final totalDebit = lignesConstruites.fold<double>(
      0,
      (sum, l) => sum + (l.debit ?? 0),
    );
    final totalCredit = lignesConstruites.fold<double>(
      0,
      (sum, l) => sum + (l.credit ?? 0),
    );
    if (totalDebit != totalCredit) {
      _showMessage('Les totaux debit et credit doivent etre egaux.');
      return;
    }

    final centrePrincipalChoisi = _centrePrincipal?.id;
    final ecriture = EcritureComptable(
      id: widget.ecritureExistante?.id ?? 'ecriture_${_uuid.v4()}',
      date: _date,
      idJournal: _journalSelectionne!.id,
      referencePiece: _referencePiece.trim().isEmpty
          ? null
          : _referencePiece.trim(),
      libelle: _libelleGeneral.trim(),
      lignes: lignesConstruites,
      idAssembleeLocale: assembleeActiveId,
      idCentreAnalytiquePrincipal: centrePrincipalChoisi,
    );

    final notifier = ref.read(ecrituresComptablesProvider.notifier);
    if (widget.ecritureExistante == null) {
      await notifier.ajouterEcriture(ecriture);
    } else {
      await notifier.mettreAJourEcriture(ecriture);
    }
    if (mounted) Navigator.of(context).pop();
  }

  double? _parseDouble(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  String _modePaiementLabel(ModePaiement mode) {
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
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _LigneEditable {
  _LigneEditable({
    required this.idTemp,
    this.idCompte,
    this.libelle = '',
    this.idCentre,
    this.idTiers,
    this.mode,
    String debitText = '',
    String creditText = '',
  })  : libelleCtrl = TextEditingController(text: libelle),
        debitCtrl = TextEditingController(text: debitText),
        creditCtrl = TextEditingController(text: creditText);

  final String idTemp;
  String? idCompte;
  String libelle;
  String? idCentre;
  String? idTiers;
  ModePaiement? mode;
  final TextEditingController libelleCtrl;
  final TextEditingController debitCtrl;
  final TextEditingController creditCtrl;

  void dispose() {
    libelleCtrl.dispose();
    debitCtrl.dispose();
    creditCtrl.dispose();
  }
}

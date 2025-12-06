import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/assemblee_locale.dart';
import '../../models/centre_analytique.dart';
import '../../models/compte_comptable.dart';
import '../../models/compta_enums.dart';
import '../../models/journal_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../models/tiers.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/members_provider.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';

class AccountingSettingsScreen extends ConsumerStatefulWidget {
  const AccountingSettingsScreen({super.key});

  @override
  ConsumerState<AccountingSettingsScreen> createState() =>
      _AccountingSettingsScreenState();
}

class _AccountingSettingsScreenState
    extends ConsumerState<AccountingSettingsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final _uuid = const Uuid();

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
    final profilCourant = ref.watch(profilUtilisateurCourantProvider);
    return AppShell(
      title: 'Parametrage comptable',
      currentRoute: '/accounting-settings',
      body: Column(
        children: [
          const ContextHeader(showPorteeComptable: true),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: ChurchTheme.navy,
            tabs: const [
              Tab(text: 'Plan de comptes'),
              Tab(text: 'Centres analytiques'),
              Tab(text: 'Tiers'),
              Tab(text: 'Journaux'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlanDeComptesTab(profilCourant),
                _buildCentresTab(profilCourant),
                _buildTiersTab(profilCourant),
                _buildJournauxTab(profilCourant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Plan de comptes ----
  Widget _buildPlanDeComptesTab(ProfilUtilisateur? profil) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final peutGerer = profil?.role == RoleUtilisateur.adminNational;
    return comptesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('Erreur de chargement du plan de comptes')),
      data: (comptes) {
        final sorted = [...comptes]..sort((a, b) => a.numero.compareTo(b.numero));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: peutGerer ? () => _ouvrirDialogCompte() : null,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un compte'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Numero')),
                    DataColumn(label: Text('Intitule')),
                    DataColumn(label: Text('Nature')),
                    DataColumn(label: Text('Actif')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: sorted
                      .map(
                        (c) => DataRow(
                          cells: [
                            DataCell(Text(c.numero)),
                            DataCell(Text(c.intitule)),
                            DataCell(Text(c.nature.name)),
                            DataCell(Text(c.actif ? 'Oui' : 'Non')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: peutGerer
                                    ? () => _ouvrirDialogCompte(compte: c)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ouvrirDialogCompte({CompteComptable? compte}) async {
    final formKey = GlobalKey<FormState>();
    final numeroCtrl = TextEditingController(text: compte?.numero ?? '');
    final intituleCtrl = TextEditingController(text: compte?.intitule ?? '');
    var nature = compte?.nature ?? NatureCompte.actif;
    var actif = compte?.actif ?? true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(compte == null ? 'Nouveau compte' : 'Modifier le compte'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numeroCtrl,
                  decoration: const InputDecoration(labelText: 'Numero'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Numero requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: intituleCtrl,
                  decoration: const InputDecoration(labelText: 'Intitule'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Intitule requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<NatureCompte>(
                  initialValue: nature,
                  decoration: const InputDecoration(labelText: 'Nature'),
                  items: NatureCompte.values
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text(n.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => nature = v ?? nature,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: actif,
                  onChanged: (v) => actif = v,
                  title: const Text('Actif'),
                  contentPadding: EdgeInsets.zero,
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final notifier = ref.read(comptesComptablesProvider.notifier);
              final navigator = Navigator.of(context);
              final nouveau = CompteComptable(
                id: compte?.id ?? 'compte_${numeroCtrl.text.trim()}',
                numero: numeroCtrl.text.trim(),
                intitule: intituleCtrl.text.trim(),
                nature: nature,
                actif: actif,
              );
              if (compte == null) {
                await notifier.ajouterCompte(nouveau);
              } else {
                await notifier.mettreAJourCompte(nouveau);
              }
              navigator.pop();
            },
            child: Text(compte == null ? 'Ajouter' : 'Mettre a jour'),
          ),
        ],
      ),
    );
    numeroCtrl.dispose();
    intituleCtrl.dispose();
  }

  // ---- Centres analytiques ----
  Widget _buildCentresTab(ProfilUtilisateur? profil) {
    final centresAsync = ref.watch(centresAnalytiquesProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assemblees = assembleesAsync.value ?? [];
    return centresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement des centres')),
      data: (centres) {
        final sorted = [...centres]..sort((a, b) => a.code.compareTo(b.code));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _ouvrirDialogCentre(profil, assemblees: assemblees),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un centre'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Assemblee')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: sorted
                      .map(
                        (c) => DataRow(
                          cells: [
                            DataCell(Text(c.code)),
                            DataCell(Text(c.nom)),
                            DataCell(Text(c.type.name)),
                            DataCell(
                              Text(c.idAssembleeLocale != null
                                  ? (assemblees
                                          .firstWhere(
                                            (a) => a.id == c.idAssembleeLocale,
                                            orElse: () => AssembleeLocale(
                                              id: c.idAssembleeLocale!,
                                              nom: c.idAssembleeLocale!,
                                              idDistrict: '',
                                            ),
                                          )
                                          .nom)
                                  : '--'),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _ouvrirDialogCentre(
                                  profil,
                                  centre: c,
                                  assemblees: assemblees,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ouvrirDialogCentre(
    ProfilUtilisateur? profil, {
    CentreAnalytique? centre,
    required List<AssembleeLocale> assemblees,
  }) async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: centre?.code ?? '');
    final nomCtrl = TextEditingController(text: centre?.nom ?? '');
    final descCtrl = TextEditingController(text: centre?.description ?? '');
    TypeCentreAnalytique type = centre?.type ?? TypeCentreAnalytique.assembleeLocale;
    String? idAssemblee = centre?.idAssembleeLocale;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(centre == null ? 'Nouveau centre' : 'Modifier le centre'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Code'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Code requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TypeCentreAnalytique>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: TypeCentreAnalytique.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => type = v ?? type,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: idAssemblee,
                    decoration:
                        const InputDecoration(labelText: 'Assemblee (optionnel)'),
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
                  TextFormField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final notifier = ref.read(centresAnalytiquesProvider.notifier);
              final navigator = Navigator.of(context);
              final nouveau = CentreAnalytique(
                id: centre?.id ?? 'centre_${_uuid.v4()}',
                code: codeCtrl.text.trim(),
                nom: nomCtrl.text.trim(),
                type: type,
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                idAssembleeLocale: idAssemblee,
              );
              if (centre == null) {
                await notifier.ajouterCentre(nouveau);
              } else {
                await notifier.mettreAJourCentre(nouveau);
              }
              navigator.pop();
            },
            child: Text(centre == null ? 'Ajouter' : 'Mettre a jour'),
          ),
        ],
      ),
    );
    codeCtrl.dispose();
    nomCtrl.dispose();
    descCtrl.dispose();
  }

  // ---- Tiers ----
  Widget _buildTiersTab(ProfilUtilisateur? profil) {
    final tiersAsync = ref.watch(tiersProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final membresAsync = ref.watch(membersProvider);
    final assemblees = assembleesAsync.value ?? [];
    final membres = membresAsync.value ?? [];
    return tiersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement des tiers')),
      data: (tiers) {
        final sorted = [...tiers]..sort((a, b) => a.nom.compareTo(b.nom));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _ouvrirDialogTiers(profil, assemblees: assemblees, membres: membres),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un tiers'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Assemblee')),
                    DataColumn(label: Text('Telephone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: sorted
                      .map(
                        (t) => DataRow(
                          cells: [
                            DataCell(Text(t.nom)),
                            DataCell(Text(t.type.name)),
                            DataCell(
                              Text(
                                t.idAssembleeLocale == null
                                    ? '--'
                                    : assemblees
                                            .firstWhere(
                                              (a) => a.id == t.idAssembleeLocale,
                                              orElse: () => AssembleeLocale(
                                                id: t.idAssembleeLocale!,
                                                nom: t.idAssembleeLocale!,
                                                idDistrict: '',
                                              ),
                                            )
                                            .nom,
                              ),
                            ),
                            DataCell(Text(t.telephone ?? '--')),
                            DataCell(Text(t.email ?? '--')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _ouvrirDialogTiers(
                                  profil,
                                  tiers: t,
                                  assemblees: assemblees,
                                  membres: membres,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ouvrirDialogTiers(
    ProfilUtilisateur? profil, {
    Tiers? tiers,
    required List<AssembleeLocale> assemblees,
    required List membres,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: tiers?.nom ?? '');
    final telCtrl = TextEditingController(text: tiers?.telephone ?? '');
    final emailCtrl = TextEditingController(text: tiers?.email ?? '');
    final adresseCtrl = TextEditingController(text: tiers?.adresse ?? '');
    String? idAssemblee = tiers?.idAssembleeLocale;
    String? idFidele = tiers?.idFideleLie;
    TypeTiers type = tiers?.type ?? TypeTiers.autre;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tiers == null ? 'Nouveau tiers' : 'Modifier le tiers'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TypeTiers>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: TypeTiers.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => type = v ?? type,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: idAssemblee,
                    decoration:
                        const InputDecoration(labelText: 'Assemblee (optionnel)'),
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
                    onChanged: (v) {
                      idAssemblee = v;
                      if (idAssemblee == null) idFidele = null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: idFidele,
                    decoration:
                        const InputDecoration(labelText: 'Fidele lie (optionnel)'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucun'),
                      ),
                      ...membres
                          .where((m) =>
                              idAssemblee == null ||
                              m.idAssembleeLocale == idAssemblee)
                          .map(
                            (m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(m.fullName),
                            ),
                          ),
                    ],
                    onChanged: (v) => idFidele = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telCtrl,
                    decoration: const InputDecoration(labelText: 'Telephone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adresseCtrl,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                    maxLines: 2,
                  ),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final notifier = ref.read(tiersProvider.notifier);
              final navigator = Navigator.of(context);
              final nouveau = Tiers(
                id: tiers?.id ?? 'tiers_${_uuid.v4()}',
                nom: nomCtrl.text.trim(),
                type: type,
                telephone: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                adresse:
                    adresseCtrl.text.trim().isEmpty ? null : adresseCtrl.text.trim(),
                idAssembleeLocale: idAssemblee,
                idFideleLie: idFidele,
              );
              if (tiers == null) {
                await notifier.ajouterTiers(nouveau);
              } else {
                await notifier.mettreAJourTiers(nouveau);
              }
              navigator.pop();
            },
            child: Text(tiers == null ? 'Ajouter' : 'Mettre a jour'),
          ),
        ],
      ),
    );

    nomCtrl.dispose();
    telCtrl.dispose();
    emailCtrl.dispose();
    adresseCtrl.dispose();
  }

  // ---- Journaux ----
  Widget _buildJournauxTab(ProfilUtilisateur? profil) {
    final journauxAsync = ref.watch(journauxComptablesProvider);
    final peutGerer = profil?.role == RoleUtilisateur.adminNational;
    return journauxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement des journaux')),
      data: (journaux) {
        final sorted = [...journaux]..sort((a, b) => a.code.compareTo(b.code));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: peutGerer ? () => _ouvrirDialogJournal() : null,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un journal'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Intitule')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Actif')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: sorted
                      .map(
                        (j) => DataRow(
                          cells: [
                            DataCell(Text(j.code)),
                            DataCell(Text(j.intitule)),
                            DataCell(Text(j.type.name)),
                            DataCell(Text(j.actif ? 'Oui' : 'Non')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: peutGerer
                                    ? () => _ouvrirDialogJournal(journal: j)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ouvrirDialogJournal({JournalComptable? journal}) async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: journal?.code ?? '');
    final intituleCtrl = TextEditingController(text: journal?.intitule ?? '');
    TypeJournalComptable type = journal?.type ?? TypeJournalComptable.caisse;
    var actif = journal?.actif ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(journal == null ? 'Nouveau journal' : 'Modifier le journal'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Code requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: intituleCtrl,
                  decoration: const InputDecoration(labelText: 'Intitule'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Intitule requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TypeJournalComptable>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TypeJournalComptable.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => type = v ?? type,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: actif,
                  onChanged: (v) => actif = v,
                  title: const Text('Actif'),
                  contentPadding: EdgeInsets.zero,
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final notifier = ref.read(journauxComptablesProvider.notifier);
              final navigator = Navigator.of(context);
              final nouveau = JournalComptable(
                id: journal?.id ?? 'journal_${_uuid.v4()}',
                code: codeCtrl.text.trim(),
                intitule: intituleCtrl.text.trim(),
                type: type,
                actif: actif,
              );
              if (journal == null) {
                await notifier.ajouterJournal(nouveau);
              } else {
                await notifier.mettreAJourJournal(nouveau);
              }
              navigator.pop();
            },
            child: Text(journal == null ? 'Ajouter' : 'Mettre a jour'),
          ),
        ],
      ),
    );
    codeCtrl.dispose();
    intituleCtrl.dispose();
  }
}

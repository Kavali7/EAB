import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/models/assemblee_locale.dart';
import 'package:eab/models/centre_analytique.dart';
import 'package:eab/models/compte_comptable.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/journal_comptable.dart';
import 'package:eab/models/profil_utilisateur.dart';
import 'package:eab/models/tiers.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';

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
      showBackButton: true,
      backRoute: '/accounting',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.lg : AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ContextHeader(showPorteeComptable: true),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsTabs(controller: _tabController),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPlanDeComptesTab(profilCourant, compact),
                          _buildCentresTab(profilCourant, compact),
                          _buildTiersTab(profilCourant, compact),
                          _buildJournauxTab(profilCourant, compact),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanDeComptesTab(ProfilUtilisateur? profil, bool compact) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final peutGerer = profil?.role == RoleUtilisateur.adminNational;
    return comptesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _EmptyState(message: 'Erreur de chargement du plan de comptes'),
      data: (comptes) {
        final sorted = [...comptes]
          ..sort((a, b) => a.numero.compareTo(b.numero));
        return _TabSurface(
          title: 'Plan de comptes',
          subtitle: '${sorted.length} comptes disponibles',
          action: ElevatedButton.icon(
            onPressed: peutGerer ? () => _ouvrirDialogCompte() : null,
            icon: const Icon(Icons.add),
            label: const Text('Compte'),
          ),
          child: sorted.isEmpty
              ? const _EmptyState(message: 'Aucun compte configure.')
              : compact
              ? _MobileList(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final c = sorted[index];
                    return _EntityCard(
                      title: '${c.numero} - ${c.intitule}',
                      subtitle: _natureLabel(c.nature),
                      badge: c.actif ? 'Actif' : 'Inactif',
                      badgeColor: c.actif ? AppColors.success : AppColors.error,
                      details: [
                        if (c.niveau != null) 'Niveau ${c.niveau}',
                        if (c.idCompteParent != null) 'Parent rattache',
                      ],
                      onEdit: peutGerer
                          ? () => _ouvrirDialogCompte(compte: c)
                          : null,
                    );
                  },
                )
              : _TableFrame(
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
                              DataCell(Text(_natureLabel(c.nature))),
                              DataCell(Text(c.actif ? 'Oui' : 'Non')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Modifier',
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => EabDialog(
          title: compte == null ? 'Nouveau compte' : 'Modifier le compte',
          width: 460,
          content: Form(
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
                const SizedBox(height: AppSpacing.fieldGap),
                TextFormField(
                  controller: intituleCtrl,
                  decoration: const InputDecoration(labelText: 'Intitule'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Intitule requis' : null,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                DropdownButtonFormField<NatureCompte>(
                  initialValue: nature,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Nature'),
                  items: NatureCompte.values
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text(_natureLabel(n)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => nature = v ?? nature,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                SwitchListTile(
                  value: actif,
                  onChanged: (v) => setDialogState(() => actif = v),
                  title: const Text('Actif'),
                  contentPadding: EdgeInsets.zero,
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
              label: compte == null ? 'Ajouter' : 'Mettre a jour',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final notifier = ref.read(comptesComptablesProvider.notifier);
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final nouveau = CompteComptable(
                  id: compte?.id ?? '',
                  numero: numeroCtrl.text.trim(),
                  intitule: intituleCtrl.text.trim(),
                  nature: nature,
                  actif: actif,
                );
                try {
                  if (compte == null) {
                    await notifier.ajouterCompte(nouveau);
                  } else {
                    await notifier.mettreAJourCompte(nouveau);
                  }
                  navigator.pop();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    numeroCtrl.dispose();
    intituleCtrl.dispose();
  }

  Widget _buildCentresTab(ProfilUtilisateur? profil, bool compact) {
    final centresAsync = ref.watch(centresAnalytiquesProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assemblees = assembleesAsync.value ?? [];
    return centresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _EmptyState(message: 'Erreur de chargement des centres'),
      data: (centres) {
        final sorted = [...centres]..sort((a, b) => a.code.compareTo(b.code));
        return _TabSurface(
          title: 'Centres analytiques',
          subtitle: '${sorted.length} centres de suivi',
          action: ElevatedButton.icon(
            onPressed: () =>
                _ouvrirDialogCentre(profil, assemblees: assemblees),
            icon: const Icon(Icons.add),
            label: const Text('Centre'),
          ),
          child: sorted.isEmpty
              ? const _EmptyState(message: 'Aucun centre analytique configure.')
              : compact
              ? _MobileList(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final c = sorted[index];
                    return _EntityCard(
                      title: '${c.code} - ${c.nom}',
                      subtitle: _centreTypeLabel(c.type),
                      badge: _assembleeName(c.idAssembleeLocale, assemblees),
                      badgeColor: AppColors.primary,
                      details: [
                        if (c.description?.isNotEmpty ?? false) c.description!,
                      ],
                      onEdit: () => _ouvrirDialogCentre(
                        profil,
                        centre: c,
                        assemblees: assemblees,
                      ),
                    );
                  },
                )
              : _TableFrame(
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
                              DataCell(Text(_centreTypeLabel(c.type))),
                              DataCell(
                                Text(
                                  _assembleeName(
                                    c.idAssembleeLocale,
                                    assemblees,
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Modifier',
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
    TypeCentreAnalytique type =
        centre?.type ?? TypeCentreAnalytique.assembleeLocale;
    String? idAssemblee = centre?.idAssembleeLocale;

    await showDialog<void>(
      context: context,
      builder: (context) => EabDialog(
        title: centre == null ? 'Nouveau centre' : 'Modifier le centre',
        width: 520,
        content: Form(
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
              const SizedBox(height: AppSpacing.fieldGap),
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              DropdownButtonFormField<TypeCentreAnalytique>(
                initialValue: type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: TypeCentreAnalytique.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_centreTypeLabel(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: idAssemblee,
                decoration: const InputDecoration(
                  labelText: 'Assemblee (optionnel)',
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
                onChanged: (v) => idAssemblee = v,
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
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
            label: centre == null ? 'Ajouter' : 'Mettre a jour',
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
          ),
        ],
      ),
    );
    codeCtrl.dispose();
    nomCtrl.dispose();
    descCtrl.dispose();
  }

  Widget _buildTiersTab(ProfilUtilisateur? profil, bool compact) {
    final tiersAsync = ref.watch(tiersProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final membresAsync = ref.watch(membersProvider);
    final assemblees = assembleesAsync.value ?? [];
    final membres = membresAsync.value ?? [];
    return tiersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _EmptyState(message: 'Erreur de chargement des tiers'),
      data: (tiers) {
        final sorted = [...tiers]..sort((a, b) => a.nom.compareTo(b.nom));
        return _TabSurface(
          title: 'Tiers',
          subtitle: '${sorted.length} contacts et partenaires',
          action: ElevatedButton.icon(
            onPressed: () => _ouvrirDialogTiers(
              profil,
              assemblees: assemblees,
              membres: membres,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tiers'),
          ),
          child: sorted.isEmpty
              ? const _EmptyState(message: 'Aucun tiers configure.')
              : compact
              ? _MobileList(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final t = sorted[index];
                    return _EntityCard(
                      title: t.nom,
                      subtitle: _tiersTypeLabel(t.type),
                      badge: _assembleeName(t.idAssembleeLocale, assemblees),
                      badgeColor: AppColors.teal,
                      details: [
                        if (t.telephone != null) t.telephone!,
                        if (t.email != null) t.email!,
                      ],
                      onEdit: () => _ouvrirDialogTiers(
                        profil,
                        tiers: t,
                        assemblees: assemblees,
                        membres: membres,
                      ),
                    );
                  },
                )
              : _TableFrame(
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
                              DataCell(Text(_tiersTypeLabel(t.type))),
                              DataCell(
                                Text(
                                  _assembleeName(
                                    t.idAssembleeLocale,
                                    assemblees,
                                  ),
                                ),
                              ),
                              DataCell(Text(t.telephone ?? '--')),
                              DataCell(Text(t.email ?? '--')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Modifier',
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => EabDialog(
          title: tiers == null ? 'Nouveau tiers' : 'Modifier le tiers',
          width: 560,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                DropdownButtonFormField<TypeTiers>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TypeTiers.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_tiersTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => type = v ?? type,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: idAssemblee,
                  decoration: const InputDecoration(
                    labelText: 'Assemblee (optionnel)',
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
                  onChanged: (v) {
                    setDialogState(() {
                      idAssemblee = v;
                      if (idAssemblee == null) idFidele = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: idFidele,
                  decoration: const InputDecoration(
                    labelText: 'Fidele lie (optionnel)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...membres
                        .where(
                          (m) =>
                              idAssemblee == null ||
                              m.idAssembleeLocale == idAssemblee,
                        )
                        .map(
                          (m) => DropdownMenuItem<String?>(
                            value: m.id,
                            child: Text(m.fullName),
                          ),
                        ),
                  ],
                  onChanged: (v) => idFidele = v,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                TextFormField(
                  controller: telCtrl,
                  decoration: const InputDecoration(labelText: 'Telephone'),
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                TextFormField(
                  controller: adresseCtrl,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                  maxLines: 2,
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
              label: tiers == null ? 'Ajouter' : 'Mettre a jour',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final notifier = ref.read(tiersProvider.notifier);
                final navigator = Navigator.of(context);
                final nouveau = Tiers(
                  id: tiers?.id ?? 'tiers_${_uuid.v4()}',
                  nom: nomCtrl.text.trim(),
                  type: type,
                  telephone: telCtrl.text.trim().isEmpty
                      ? null
                      : telCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty
                      ? null
                      : emailCtrl.text.trim(),
                  adresse: adresseCtrl.text.trim().isEmpty
                      ? null
                      : adresseCtrl.text.trim(),
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
            ),
          ],
        ),
      ),
    );

    nomCtrl.dispose();
    telCtrl.dispose();
    emailCtrl.dispose();
    adresseCtrl.dispose();
  }

  Widget _buildJournauxTab(ProfilUtilisateur? profil, bool compact) {
    final journauxAsync = ref.watch(journauxComptablesProvider);
    final peutGerer = profil?.role == RoleUtilisateur.adminNational;
    return journauxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const _EmptyState(message: 'Erreur de chargement des journaux'),
      data: (journaux) {
        final sorted = [...journaux]..sort((a, b) => a.code.compareTo(b.code));
        return _TabSurface(
          title: 'Journaux',
          subtitle: '${sorted.length} journaux comptables',
          action: ElevatedButton.icon(
            onPressed: peutGerer ? () => _ouvrirDialogJournal() : null,
            icon: const Icon(Icons.add),
            label: const Text('Journal'),
          ),
          child: sorted.isEmpty
              ? const _EmptyState(message: 'Aucun journal configure.')
              : compact
              ? _MobileList(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final j = sorted[index];
                    return _EntityCard(
                      title: '${j.code} - ${j.intitule}',
                      subtitle: _journalTypeLabel(j.type),
                      badge: j.actif ? 'Actif' : 'Inactif',
                      badgeColor: j.actif ? AppColors.success : AppColors.error,
                      onEdit: peutGerer
                          ? () => _ouvrirDialogJournal(journal: j)
                          : null,
                    );
                  },
                )
              : _TableFrame(
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
                              DataCell(Text(_journalTypeLabel(j.type))),
                              DataCell(Text(j.actif ? 'Oui' : 'Non')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Modifier',
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => EabDialog(
          title: journal == null ? 'Nouveau journal' : 'Modifier le journal',
          width: 460,
          content: Form(
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
                const SizedBox(height: AppSpacing.fieldGap),
                TextFormField(
                  controller: intituleCtrl,
                  decoration: const InputDecoration(labelText: 'Intitule'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Intitule requis' : null,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                DropdownButtonFormField<TypeJournalComptable>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TypeJournalComptable.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_journalTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => type = v ?? type,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                SwitchListTile(
                  value: actif,
                  onChanged: (v) => setDialogState(() => actif = v),
                  title: const Text('Actif'),
                  contentPadding: EdgeInsets.zero,
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
              label: journal == null ? 'Ajouter' : 'Mettre a jour',
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
            ),
          ],
        ),
      ),
    );
    codeCtrl.dispose();
    intituleCtrl.dispose();
  }
}

class _SettingsTabs extends StatelessWidget {
  const _SettingsTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tabs: const [
          Tab(icon: Icon(Icons.account_tree_outlined), text: 'Comptes'),
          Tab(icon: Icon(Icons.hub_outlined), text: 'Centres'),
          Tab(icon: Icon(Icons.people_alt_outlined), text: 'Tiers'),
          Tab(icon: Icon(Icons.book_outlined), text: 'Journaux'),
        ],
      ),
    );
  }
}

class _TabSurface extends StatelessWidget {
  const _TabSurface({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  const SizedBox(height: AppSpacing.sm),
                  action,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: titleBlock),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: child),
      ],
    );
  }
}

class _MobileList extends StatelessWidget {
  const _MobileList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: itemBuilder,
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    this.details = const [],
    this.onEdit,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<String> details;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Badge(label: subtitle, color: AppColors.primary),
                    _Badge(label: badge, color: badgeColor),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ...details.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(d, style: AppTextStyles.bodySmall),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableFrame extends StatelessWidget {
  const _TableFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: AppColors.textTertiary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

String _assembleeName(String? id, List<AssembleeLocale> assemblees) {
  if (id == null) return 'Toutes';
  return assemblees
      .firstWhere(
        (a) => a.id == id,
        orElse: () => AssembleeLocale(id: id, nom: id, idDistrict: ''),
      )
      .nom;
}

String _natureLabel(NatureCompte nature) {
  return switch (nature) {
    NatureCompte.actif => 'Actif',
    NatureCompte.passif => 'Passif',
    NatureCompte.charge => 'Charge',
    NatureCompte.produit => 'Produit',
    NatureCompte.horsActiviteOrdinaire => 'Hors activite',
    NatureCompte.engagement => 'Engagement',
    NatureCompte.autre => 'Autre',
  };
}

String _centreTypeLabel(TypeCentreAnalytique type) {
  return switch (type) {
    TypeCentreAnalytique.assembleeLocale => 'Assemblee locale',
    TypeCentreAnalytique.projet => 'Projet',
    TypeCentreAnalytique.activite => 'Activite',
    TypeCentreAnalytique.departement => 'Departement',
    TypeCentreAnalytique.autre => 'Autre',
  };
}

String _tiersTypeLabel(TypeTiers type) {
  return switch (type) {
    TypeTiers.membre => 'Membre',
    TypeTiers.fournisseur => 'Fournisseur',
    TypeTiers.bailleur => 'Bailleur',
    TypeTiers.employe => 'Employe',
    TypeTiers.partenaire => 'Partenaire',
    TypeTiers.autre => 'Autre',
  };
}

String _journalTypeLabel(TypeJournalComptable type) {
  return switch (type) {
    TypeJournalComptable.caisse => 'Caisse',
    TypeJournalComptable.banque => 'Banque',
    TypeJournalComptable.operationsDiverses => 'Operations diverses',
  };
}

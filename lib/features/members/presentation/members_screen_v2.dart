/// Écran Membres v2 — migré vers le design system UI Kit.
///
/// Utilise :
/// - [EabPageHeader] pour l'en-tête
/// - [EabTable] pour le tableau paginé avec tri
/// - [EabHierarchyFilter] pour les filtres structure
/// - [EabDialog.confirm] pour la confirmation de suppression
/// - [showMemberFormV2] pour l'ajout/modification
///
/// L'ancien écran `screens/members/members_screen.dart` reste fonctionnel
/// en parallèle (approche strangler).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';

import 'package:eab/models/member.dart';



import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/families_provider.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/info_card.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import 'member_form_dialog.dart';

const _roleLabels = {
  RoleFidele.membre: 'Membre',
  RoleFidele.pasteur: 'Pasteur',
  RoleFidele.ancien: 'Ancien',
  RoleFidele.diacre: 'Diacre',
  RoleFidele.diaconesse: 'Diaconesse',
  RoleFidele.evangeliste: 'Évangéliste',
  RoleFidele.autreOfficier: 'Autre officier',
};

const _statutFideleLabels = {
  StatutFidele.actif: 'Actif',
  StatutFidele.inactif: 'Inactif',
  StatutFidele.parti: 'Parti',
  StatutFidele.decede: 'Décédé',
  StatutFidele.transfere: 'Transféré',
};


/// Écran de gestion des fidèles (v2).
class MembersScreenV2 extends ConsumerStatefulWidget {
  const MembersScreenV2({super.key});

  @override
  ConsumerState<MembersScreenV2> createState() => _MembersScreenV2State();
}

class _MembersScreenV2State extends ConsumerState<MembersScreenV2> {
  String _query = '';
  Gender? _genderFilter;
  RoleFidele? _roleFilter;
  StatutFidele? _statutFilter;
  bool _onlyChildren = false;
  bool _onlyOfficers = false;

  bool _isChild(Member m) {
    final birth = m.dateNaissance ?? m.birthDate;
    final now = DateTime.now();
    return now.year - birth.year -
            ((now.month < birth.month ||
                    (now.month == birth.month && now.day < birth.day))
                ? 1
                : 0) <
        15;
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final familiesAsync = ref.watch(familiesProvider);
    final regionsAsync = ref.watch(regionsProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);

    final members = membersAsync.value ?? [];
    final families = familiesAsync.value ?? [];
    // regionsAsync / districtsAsync watched pour réactivité EabHierarchyFilter
    final assemblees = assembleesAsync.value ?? [];
    final assembleeById = {for (final a in assemblees) a.id: a};
    final familyById = {for (final f in families) f.id: f};

    // Filtrage
    final filtered = members.where((m) {
      if (_query.isNotEmpty &&
          !m.fullName.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_genderFilter != null && m.gender != _genderFilter) return false;
      if (_roleFilter != null && m.role != _roleFilter) return false;
      if (_statutFilter != null && m.statut != _statutFilter) return false;
      if (_onlyChildren && !_isChild(m)) return false;
      if (_onlyOfficers && !m.estOfficier) return false;
      if (assembleeActiveId != null &&
          m.idAssembleeLocale != assembleeActiveId) {
        return false;
      }
      return true;
    }).toList();

    // Statistiques
    final active =
        filtered.where((m) => m.statut == StatutFidele.actif).toList();
    final activeMale = active.where((m) => m.gender == Gender.male).length;
    final activeFemale = active.where((m) => m.gender == Gender.female).length;
    final childrenCount = filtered.where(_isChild).length;
    final officersCount = filtered.where((m) => m.estOfficier).length;
    final vulnerableCount =
        filtered.where((m) => m.vulnerabilites.isNotEmpty).length;

    return AppShell(
      title: 'Fidèles',
      currentRoute: '/members',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMemberFormV2(context, families: families),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ContextHeader(showPorteeComptable: false),
              const SizedBox(height: AppSpacing.cardGap),

              // Statistiques clés
              SectionCard(
                title: 'Statistiques clés',
                child: Wrap(
                  spacing: AppSpacing.cardGap,
                  runSpacing: AppSpacing.cardGap,
                  children: [
                    SizedBox(
                      width: 220,
                      child: InfoCard(
                        title: 'Membres actifs (H / F)',
                        value: '$activeMale H / $activeFemale F',
                        subtitle: 'Total actifs ${active.length}',
                        icon: Icons.verified_user_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: InfoCard(
                        title: 'Enfants (0-14 ans)',
                        value: '$childrenCount',
                        subtitle: 'Vue filtrée',
                        icon: Icons.child_care,
                        color: Colors.teal[700],
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: InfoCard(
                        title: 'Officiers',
                        value: '$officersCount',
                        subtitle: 'Pasteur / anciens / diacres',
                        icon: Icons.workspace_premium_outlined,
                        color: Colors.orange[700],
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: InfoCard(
                        title: 'Personnes vulnérables',
                        value: '$vulnerableCount',
                        subtitle: 'Orphelins, veufs, 3e âge...',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Filtres
              SectionCard(
                title: 'Filtres',
                child: Wrap(
                  spacing: AppSpacing.cardGap,
                  runSpacing: AppSpacing.cardGap,
                  children: [
                    SizedBox(
                      width: 240,
                      child: EabTextField(
                        label: 'Rechercher un nom',
                        prefixIcon: Icons.search,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: EabSelectField<Gender?>(
                        label: 'Genre',
                        value: _genderFilter,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous')),
                          ...Gender.values.map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(genderLabels[g]!),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _genderFilter = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: EabSelectField<RoleFidele?>(
                        label: 'Rôle',
                        value: _roleFilter,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous')),
                          ...RoleFidele.values.map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(_roleLabels[r]!),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _roleFilter = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: EabSelectField<StatutFidele?>(
                        label: 'Statut',
                        value: _statutFilter,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous')),
                          ...StatutFidele.values.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statutFideleLabels[s]!),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _statutFilter = v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: CheckboxListTile.adaptive(
                        value: _onlyChildren,
                        onChanged: (v) =>
                            setState(() => _onlyChildren = v ?? false),
                        dense: true,
                        title: const Text('Enfants uniquement'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: CheckboxListTile.adaptive(
                        value: _onlyOfficers,
                        onChanged: (v) =>
                            setState(() => _onlyOfficers = v ?? false),
                        dense: true,
                        title: const Text('Officiers seulement'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tableau des fidèles
              SectionCard(
                title: 'Liste des fidèles (${filtered.length})',
                child: EabTable<Member>(
                  isLoading: membersAsync.isLoading && members.isEmpty,
                  emptyMessage: 'Aucun fidèle trouvé',
                  emptyIcon: Icons.people_outline,
                  items: filtered,
                  rowsPerPage: 15,
                  onRowTap: (m) => showMemberFormV2(
                    context,
                    member: m,
                    families: families,
                  ),
                  columns: [
                    EabColumn<Member>(
                      label: 'Nom complet',
                      flex: 3,
                      sortKeyExtractor: (m) => m.fullName,
                      cellBuilder: (m) => Text(
                        m.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    EabColumn<Member>(
                      label: 'Genre',
                      flex: 1,
                      cellBuilder: (m) => Text(genderLabels[m.gender] ?? ''),
                    ),
                    EabColumn<Member>(
                      label: 'Naissance',
                      flex: 2,
                      sortKeyExtractor: (m) => m.birthDate,
                      cellBuilder: (m) =>
                          Text(dateFormatter.format(m.birthDate)),
                    ),
                    EabColumn<Member>(
                      label: 'Rôle',
                      flex: 2,
                      cellBuilder: (m) =>
                          Text(_roleLabels[m.role] ?? m.role.name),
                    ),
                    EabColumn<Member>(
                      label: 'Statut',
                      flex: 1,
                      cellBuilder: (m) =>
                          Text(_statutFideleLabels[m.statut] ?? m.statut.name),
                    ),
                    EabColumn<Member>(
                      label: 'Famille',
                      flex: 2,
                      cellBuilder: (m) =>
                          Text(m.idFamille != null
                              ? familyById[m.idFamille!]?.nom ?? '—'
                              : '—'),
                    ),
                    EabColumn<Member>(
                      label: 'Assemblée',
                      flex: 2,
                      cellBuilder: (m) => Text(
                        m.idAssembleeLocale != null
                            ? assembleeById[m.idAssembleeLocale!]?.nom ?? '—'
                            : '—',
                      ),
                    ),
                    EabColumn<Member>(
                      label: '',
                      flex: 1,
                      cellBuilder: (m) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => showMemberFormV2(
                              context,
                              member: m,
                              families: families,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _confirmDelete(m),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Member member) async {
    final confirm = await EabDialog.confirm(
      context,
      title: 'Supprimer un fidèle',
      message: 'Êtes-vous sûr de vouloir supprimer ${member.fullName} ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirm == true) {
      await ref.read(membersProvider.notifier).removeMember(member.id);
    }
  }
}

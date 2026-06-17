library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/core/utils/church_unit_scope.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/models/member.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/families_provider.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';

import 'member_detail_screen.dart';
import 'member_form_dialog.dart';

const _roleLabels = {
  RoleFidele.membre: 'Membre',
  RoleFidele.pasteur: 'Pasteur',
  RoleFidele.ancien: 'Ancien',
  RoleFidele.diacre: 'Diacre',
  RoleFidele.diaconesse: 'Diaconesse',
  RoleFidele.evangeliste: 'Evangeliste',
  RoleFidele.autreOfficier: 'Autre officier',
};

const _statutFideleLabels = {
  StatutFidele.actif: 'Actif',
  StatutFidele.inactif: 'Inactif',
  StatutFidele.parti: 'Parti',
  StatutFidele.decede: 'Decede',
  StatutFidele.transfere: 'Transfere',
};

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

  bool _isChild(Member member) {
    final birth = member.dateNaissance ?? member.birthDate;
    final now = DateTime.now();
    return now.year -
            birth.year -
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
    ref.watch(regionsProvider);
    ref.watch(districtsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final churchUnitActiveId = ref.watch(churchUnitActiveIdProvider);

    final members = membersAsync.value ?? [];
    final families = familiesAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final churchUnits = churchUnitsAsync.value ?? [];
    final assembleeById = {for (final a in assemblees) a.id: a};
    final churchUnitById = {for (final unit in churchUnits) unit.id: unit};
    final familyById = {for (final f in families) f.id: f};
    final scope = ChurchUnitScope.fromActiveContext(
      units: churchUnits,
      activeChurchUnitId: churchUnitActiveId,
      activeAssembleeId: assembleeActiveId,
    );

    final filtered = members.where((m) {
      final query = _query.trim().toLowerCase();
      if (query.isNotEmpty && !m.fullName.toLowerCase().contains(query)) {
        return false;
      }
      if (_genderFilter != null && m.gender != _genderFilter) return false;
      if (_roleFilter != null && m.role != _roleFilter) return false;
      if (_statutFilter != null && m.statut != _statutFilter) return false;
      if (_onlyChildren && !_isChild(m)) return false;
      if (_onlyOfficers && !m.estOfficier) return false;
      if (!scope.contains(
        churchUnitId: m.churchUnitId,
        legacyAssembleeId: m.idAssembleeLocale,
      )) {
        return false;
      }
      return true;
    }).toList();

    final active = filtered
        .where((m) => m.statut == StatutFidele.actif)
        .toList();
    final activeMale = active.where((m) => m.gender == Gender.male).length;
    final activeFemale = active.where((m) => m.gender == Gender.female).length;
    final childrenCount = filtered.where(_isChild).length;
    final officersCount = filtered.where((m) => m.estOfficier).length;
    final vulnerableCount = filtered
        .where((m) => m.vulnerabilites.isNotEmpty)
        .length;

    return AppShell(
      title: 'Fideles',
      currentRoute: '/members',
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ContextHeader(showPorteeComptable: false),
                  const SizedBox(height: AppSpacing.cardGap),
                  _MembersCommandBar(
                    total: filtered.length,
                    onAdd: () => showMemberFormV2(context, families: families),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsGrid(
                    stats: [
                      _MemberStat(
                        label: 'Actifs',
                        value: 'H: $activeMale | F: $activeFemale',
                        helper: 'Total ${active.length}',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.primary,
                      ),
                      _MemberStat(
                        label: 'Enfants',
                        value: '$childrenCount',
                        helper: '0 a 14 ans',
                        icon: Icons.child_care_outlined,
                        color: AppColors.teal,
                      ),
                      _MemberStat(
                        label: 'Officiers',
                        value: '$officersCount',
                        helper: 'Pasteurs, anciens, diacres',
                        icon: Icons.workspace_premium_outlined,
                        color: AppColors.secondary,
                      ),
                      _MemberStat(
                        label: 'Vulnerables',
                        value: '$vulnerableCount',
                        helper: 'Suivi pastoral prioritaire',
                        icon: Icons.volunteer_activism_outlined,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterPanel(
                    query: _query,
                    genderFilter: _genderFilter,
                    roleFilter: _roleFilter,
                    statutFilter: _statutFilter,
                    onlyChildren: _onlyChildren,
                    onlyOfficers: _onlyOfficers,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onGenderChanged: (value) =>
                        setState(() => _genderFilter = value),
                    onRoleChanged: (value) =>
                        setState(() => _roleFilter = value),
                    onStatutChanged: (value) =>
                        setState(() => _statutFilter = value),
                    onOnlyChildrenChanged: (value) =>
                        setState(() => _onlyChildren = value),
                    onOnlyOfficersChanged: (value) =>
                        setState(() => _onlyOfficers = value),
                    onClear: () => setState(() {
                      _query = '';
                      _genderFilter = null;
                      _roleFilter = null;
                      _statutFilter = null;
                      _onlyChildren = false;
                      _onlyOfficers = false;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MembersTablePanel(
                    membersAsync: membersAsync,
                    members: members,
                    filtered: filtered,
                    families: families,
                    familyById: familyById,
                    assembleeById: assembleeById,
                    churchUnitById: churchUnitById,
                    onEdit: (member) => showMemberFormV2(
                      context,
                      member: member,
                      families: families,
                    ),
                    onDelete: _confirmDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Member member) async {
    final confirm = await EabDialog.confirm(
      context,
      title: 'Supprimer un fidele',
      message: 'Voulez-vous supprimer ${member.fullName} ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirm == true) {
      await ref.read(membersProvider.notifier).removeMember(member.id);
    }
  }
}

class _MembersCommandBar extends StatelessWidget {
  const _MembersCommandBar({required this.total, required this.onAdd});

  final int total;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(Icons.groups_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registre des fideles', style: AppTextStyles.subtitle),
                Text(
                  '$total resultat${total > 1 ? "s" : ""} dans la vue active',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Ajouter un fidele'),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_MemberStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.cardGap)) /
            columns;
        return Wrap(
          spacing: AppSpacing.cardGap,
          runSpacing: AppSpacing.cardGap,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _MemberStatCard(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _MemberStat {
  const _MemberStat({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
}

class _MemberStatCard extends StatelessWidget {
  const _MemberStatCard({required this.stat});

  final _MemberStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.08),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(stat.icon, color: stat.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading2.copyWith(fontSize: 22),
                ),
                Text(
                  stat.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.query,
    required this.genderFilter,
    required this.roleFilter,
    required this.statutFilter,
    required this.onlyChildren,
    required this.onlyOfficers,
    required this.onQueryChanged,
    required this.onGenderChanged,
    required this.onRoleChanged,
    required this.onStatutChanged,
    required this.onOnlyChildrenChanged,
    required this.onOnlyOfficersChanged,
    required this.onClear,
  });

  final String query;
  final Gender? genderFilter;
  final RoleFidele? roleFilter;
  final StatutFidele? statutFilter;
  final bool onlyChildren;
  final bool onlyOfficers;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Gender?> onGenderChanged;
  final ValueChanged<RoleFidele?> onRoleChanged;
  final ValueChanged<StatutFidele?> onStatutChanged;
  final ValueChanged<bool> onOnlyChildrenChanged;
  final ValueChanged<bool> onOnlyOfficersChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text('Filtres', style: AppTextStyles.subtitle),
              const Spacer(),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Reinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.cardGap,
            runSpacing: AppSpacing.cardGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextFormField(
                  initialValue: query,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un nom',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: onQueryChanged,
                ),
              ),
              SizedBox(
                width: 190,
                child: EabSelectField<Gender?>(
                  label: 'Genre',
                  value: genderFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...Gender.values.map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(genderLabels[g] ?? g.name),
                      ),
                    ),
                  ],
                  onChanged: onGenderChanged,
                ),
              ),
              SizedBox(
                width: 210,
                child: EabSelectField<RoleFidele?>(
                  label: 'Role',
                  value: roleFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...RoleFidele.values.map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabels[r] ?? r.name),
                      ),
                    ),
                  ],
                  onChanged: onRoleChanged,
                ),
              ),
              SizedBox(
                width: 190,
                child: EabSelectField<StatutFidele?>(
                  label: 'Statut',
                  value: statutFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...StatutFidele.values.map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statutFideleLabels[s] ?? s.name),
                      ),
                    ),
                  ],
                  onChanged: onStatutChanged,
                ),
              ),
              _FilterToggle(
                label: 'Enfants',
                value: onlyChildren,
                onChanged: onOnlyChildrenChanged,
              ),
              _FilterToggle(
                label: 'Officiers',
                value: onlyOfficers,
                onChanged: onOnlyOfficersChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: value,
      label: Text(label),
      avatar: Icon(value ? Icons.check : Icons.add, size: 16),
      onSelected: onChanged,
      showCheckmark: false,
    );
  }
}

class _MembersTablePanel extends StatelessWidget {
  const _MembersTablePanel({
    required this.membersAsync,
    required this.members,
    required this.filtered,
    required this.families,
    required this.familyById,
    required this.assembleeById,
    required this.churchUnitById,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<Member>> membersAsync;
  final List<Member> members;
  final List<Member> filtered;
  final List<dynamic> families;
  final Map<String, dynamic> familyById;
  final Map<String, dynamic> assembleeById;
  final Map<String, ChurchUnit> churchUnitById;
  final ValueChanged<Member> onEdit;
  final ValueChanged<Member> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
            child: Row(
              children: [
                Text('Liste des fideles', style: AppTextStyles.subtitle),
                const Spacer(),
                Text(
                  '${filtered.length} ligne${filtered.length > 1 ? "s" : ""}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          EabTable<Member>(
            isLoading: membersAsync.isLoading && members.isEmpty,
            emptyMessage: 'Aucun fidele trouve',
            emptyIcon: Icons.people_outline,
            items: filtered,
            rowsPerPage: 15,
            onRowTap: (member) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MemberDetailScreen(member: member),
              ),
            ),
            columns: [
              EabColumn<Member>(
                label: 'Nom complet',
                flex: 3,
                sortKeyExtractor: (m) => m.fullName,
                cellBuilder: (m) => Text(
                  m.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EabColumn<Member>(
                label: 'Genre',
                fixedWidth: 82,
                cellBuilder: (m) => Text(genderLabels[m.gender] ?? ''),
              ),
              EabColumn<Member>(
                label: 'Naissance',
                fixedWidth: 120,
                sortKeyExtractor: (m) => m.birthDate,
                cellBuilder: (m) => Text(dateFormatter.format(m.birthDate)),
              ),
              EabColumn<Member>(
                label: 'Role',
                fixedWidth: 140,
                cellBuilder: (m) => Text(_roleLabels[m.role] ?? m.role.name),
              ),
              EabColumn<Member>(
                label: 'Statut',
                fixedWidth: 110,
                cellBuilder: (m) => _StatusPill(
                  label: _statutFideleLabels[m.statut] ?? m.statut.name,
                  color: _statusColor(m.statut),
                ),
              ),
              EabColumn<Member>(
                label: 'Famille',
                flex: 2,
                cellBuilder: (m) => Text(
                  m.idFamille != null
                      ? familyById[m.idFamille!]?.nom ?? '-'
                      : '-',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EabColumn<Member>(
                label: 'Unite',
                flex: 2,
                cellBuilder: (m) =>
                    Text(_memberUnitName(m), overflow: TextOverflow.ellipsis),
              ),
              EabColumn<Member>(
                label: '',
                fixedWidth: 100,
                cellBuilder: (m) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Modifier',
                      onPressed: () => onEdit(m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Supprimer',
                      color: AppColors.error,
                      onPressed: () => onDelete(m),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(StatutFidele statut) {
    switch (statut) {
      case StatutFidele.actif:
        return AppColors.success;
      case StatutFidele.inactif:
        return AppColors.warning;
      case StatutFidele.parti:
      case StatutFidele.transfere:
        return AppColors.accent;
      case StatutFidele.decede:
        return AppColors.textSecondary;
    }
  }

  String _memberUnitName(Member member) {
    final unit = member.churchUnitId == null
        ? null
        : churchUnitById[member.churchUnitId!];
    if (unit != null) return unit.nom;
    if (member.idAssembleeLocale != null) {
      return assembleeById[member.idAssembleeLocale!]?.nom ?? '-';
    }
    return '-';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

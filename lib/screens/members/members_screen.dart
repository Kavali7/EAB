
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/famille.dart';
import '../../models/member.dart';
import '../../models/region_eglise.dart';
import '../../models/district_eglise.dart';
import '../../models/assemblee_locale.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/families_provider.dart';
import '../../providers/members_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';

const roleLabels = {
  RoleFidele.membre: 'Membre',
  RoleFidele.pasteur: 'Pasteur',
  RoleFidele.ancien: 'Ancien',
  RoleFidele.diacre: 'Diacre',
  RoleFidele.diaconesse: 'Diaconesse',
  RoleFidele.evangeliste: 'Evangeliste',
  RoleFidele.autreOfficier: 'Autre officier',
};

const statutFideleLabels = {
  StatutFidele.actif: 'Actif',
  StatutFidele.inactif: 'Inactif',
  StatutFidele.parti: 'Parti',
  StatutFidele.decede: 'Decede',
  StatutFidele.transfere: 'Transfere',
};

const vulnerabiliteLabels = {
  VulnerabiliteFidele.orphelin: 'Orphelin',
  VulnerabiliteFidele.veuf: 'Veuf',
  VulnerabiliteFidele.veuve: 'Veuve',
  VulnerabiliteFidele.handicape: 'Handicape',
  VulnerabiliteFidele.troisiemeAge: '3e age',
  VulnerabiliteFidele.autre: 'Autre',
};

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';
  Gender? _genderFilter;
  MaritalStatus? _maritalFilter;
  int? _baptismYearFilter;
  RoleFidele? _roleFilter;
  StatutFidele? _statutFilter;
  bool _onlyChildren = false;
  bool _onlyOfficers = false;
  VulnerabiliteFidele? _vulnerabiliteFilter;
  String? _idRegionFilter;
  String? _idDistrictFilter;
  String? _idAssembleeLocaleFilter;

  bool _isChild(Member m) {
    final birth = m.dateNaissance ?? m.birthDate;
    final now = DateTime.now();
    final ageYears = now.year - birth.year -
        ((now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day))
            ? 1
            : 0);
    return ageYears < 15;
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final familiesAsync = ref.watch(familiesProvider);
    final regionsAsync = ref.watch(regionsProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final members = membersAsync.value ?? [];
    final families = familiesAsync.value ?? [];
    final regions = regionsAsync.value ?? [];
    final districts = districtsAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final districtById = {for (final d in districts) d.id: d};
    final regionById = {for (final r in regions) r.id: r};
    final assembleeById = {for (final a in assemblees) a.id: a};
    final filteredDistricts = _idRegionFilter == null
        ? districts
        : districts.where((d) => d.idRegion == _idRegionFilter).toList();
    final filteredAssemblees = _idDistrictFilter == null
        ? assemblees
        : assemblees.where((a) => a.idDistrict == _idDistrictFilter).toList();
    final familyById = {for (final f in families) f.id: f};

    final filtered = members.where((m) {
      final matchesQuery =
          _query.isEmpty || m.fullName.toLowerCase().contains(_query.toLowerCase());
      final matchesGender = _genderFilter == null || m.gender == _genderFilter;
      final matchesMarital =
          _maritalFilter == null || m.maritalStatus == _maritalFilter;
      final matchesYear =
          _baptismYearFilter == null || m.baptismDate?.year == _baptismYearFilter;
      final matchesRole = _roleFilter == null || m.role == _roleFilter;
      final matchesStatut = _statutFilter == null || m.statut == _statutFilter;
      final matchesChildren = !_onlyChildren || _isChild(m);
      final matchesOfficer = !_onlyOfficers || m.estOfficier;
      final matchesVulnerabilite = _vulnerabiliteFilter == null
          ? true
          : m.vulnerabilites.contains(_vulnerabiliteFilter);
      final assemblee = m.idAssembleeLocale != null
          ? assembleeById[m.idAssembleeLocale!]
          : null;
      final district = assemblee != null ? districtById[assemblee.idDistrict] : null;
      final regionId = district?.idRegion;
      final matchesStructure = () {
        if (_idAssembleeLocaleFilter != null) {
          return m.idAssembleeLocale == _idAssembleeLocaleFilter;
        }
        if (_idDistrictFilter != null) {
          return assemblee != null && assemblee.idDistrict == _idDistrictFilter;
        }
        if (_idRegionFilter != null) {
          return regionId == _idRegionFilter;
        }
        return true;
      }();
      return matchesQuery &&
          matchesGender &&
          matchesMarital &&
          matchesYear &&
          matchesRole &&
          matchesStatut &&
          matchesChildren &&
          matchesOfficer &&
          matchesVulnerabilite &&
          matchesStructure;
    }).toList();

    final baptismYears = {
      for (final m in members)
        if (m.baptismDate != null) m.baptismDate!.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final active = filtered.where((m) => m.statut == StatutFidele.actif).toList();
    final activeMale = active.where((m) => m.gender == Gender.male).length;
    final activeFemale = active.where((m) => m.gender == Gender.female).length;
    final childrenCount = filtered.where(_isChild).length;
    final officersCount = filtered.where((m) => m.estOfficier).length;
    final vulnerableCount =
        filtered.where((m) => m.vulnerabilites.isNotEmpty).length;

    return AppShell(
      title: 'Fideles',
      currentRoute: '/members',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, families: families),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 220,
                child: InfoCard(
                  title: 'Membres actifs (H / F)',
                  value: '$activeMale H / $activeFemale F',
                  subtitle: 'Total actifs ${active.length}',
                  icon: Icons.verified_user_outlined,
                  color: ChurchTheme.navy,
                ),
              ),
              SizedBox(
                width: 220,
                child: InfoCard(
                  title: 'Enfants (0-14 ans)',
                  value: '$childrenCount',
                  subtitle: 'Vue filtree',
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
                  title: 'Personnes vulnerables',
                  value: '$vulnerableCount',
                  subtitle: 'Orphelins, veufs, 3e age...',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un nom',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(
                width: 200,
                      child: DropdownButtonFormField<Gender?>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Genre'),
                  initialValue: _genderFilter,
                  items: const [
                    DropdownMenuItem<Gender?>(value: null, child: Text('Tous')),
                  ]
                      .followedBy(
                        Gender.values.map(
                          (g) => DropdownMenuItem<Gender?>(
                            value: g,
                            child: Text(genderLabels[g]!),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _genderFilter = value),
                ),
              ),
              SizedBox(
                width: 220,
                      child: DropdownButtonFormField<MaritalStatus?>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Statut marital (legacy)',
                        ),
                  initialValue: _maritalFilter,
                  items: const [
                    DropdownMenuItem<MaritalStatus?>(
                      value: null,
                      child: Text('Tous'),
                    ),
                  ]
                      .followedBy(
                        MaritalStatus.values.map(
                          (s) => DropdownMenuItem<MaritalStatus?>(
                            value: s,
                            child: Text(maritalStatusLabels[s]!),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _maritalFilter = value),
                ),
              ),
              SizedBox(
                width: 220,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Annee de bapteme',
                        ),
                  initialValue: _baptismYearFilter,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Toutes'),
                    ),
                    ...baptismYears.map(
                      (y) => DropdownMenuItem<int?>(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: (value) => setState(() => _baptismYearFilter = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<RoleFidele?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Role'),
                  initialValue: _roleFilter,
                  items: [
                    const DropdownMenuItem<RoleFidele?>(
                      value: null,
                      child: Text('Tous les roles'),
                    ),
                    ...RoleFidele.values.map(
                      (r) => DropdownMenuItem<RoleFidele?>(
                        value: r,
                        child: Text(roleLabels[r]!),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _roleFilter = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<StatutFidele?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  initialValue: _statutFilter,
                  items: [
                    const DropdownMenuItem<StatutFidele?>(
                      value: null,
                      child: Text('Tous les statuts'),
                    ),
                    ...StatutFidele.values.map(
                      (s) => DropdownMenuItem<StatutFidele?>(
                        value: s,
                        child: Text(statutFideleLabels[s]!),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _statutFilter = value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<VulnerabiliteFidele?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Vulnerabilite'),
                  initialValue: _vulnerabiliteFilter,
                  items: [
                    const DropdownMenuItem<VulnerabiliteFidele?>(
                      value: null,
                      child: Text('Toutes'),
                    ),
                    ...VulnerabiliteFidele.values.map(
                      (v) => DropdownMenuItem<VulnerabiliteFidele?>(
                        value: v,
                        child: Text(vulnerabiliteLabels[v]!),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _vulnerabiliteFilter = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Region'),
                  initialValue: _idRegionFilter,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toutes les regions'),
                    ),
                    ...regions.map(
                      (r) => DropdownMenuItem<String?>(
                        value: r.id,
                        child: Text(r.nom),
                      ),
                    ),
                  ],
                  onChanged: regionsAsync.isLoading
                      ? null
                      : (value) => setState(() {
                            _idRegionFilter = value;
                            _idDistrictFilter = null;
                            _idAssembleeLocaleFilter = null;
                          }),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'District'),
                  initialValue: _idDistrictFilter,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tous les districts'),
                    ),
                    ...filteredDistricts.map(
                      (d) => DropdownMenuItem<String?>(
                        value: d.id,
                        child: Text(d.nom),
                      ),
                    ),
                  ],
                  onChanged: districtsAsync.isLoading
                      ? null
                      : (value) => setState(() {
                            _idDistrictFilter = value;
                            _idAssembleeLocaleFilter = null;
                          }),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Assemblee locale'),
                  initialValue: _idAssembleeLocaleFilter,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toutes les assemblees'),
                    ),
                    ...filteredAssemblees.map(
                      (a) => DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text(a.nom),
                      ),
                    ),
                  ],
                  onChanged: assembleesAsync.isLoading
                      ? null
                      : (value) => setState(() => _idAssembleeLocaleFilter = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: CheckboxListTile(
                  value: _onlyChildren,
                  onChanged: (v) => setState(() => _onlyChildren = v ?? false),
                  dense: true,
                  title: const Text('Enfants seulement'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 200,
                child: CheckboxListTile(
                  value: _onlyOfficers,
                  onChanged: (v) => setState(() => _onlyOfficers = v ?? false),
                  dense: true,
                  title: const Text('Officiers seulement'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: membersAsync.isLoading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth = constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : MediaQuery.of(context).size.width;
                        return SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: tableWidth,
                                maxWidth: tableWidth,
                              ),
                              child: PaginatedDataTable(
                                header: Text('Fideles (${filtered.length})'),
                                rowsPerPage: 8,
                                columns: const [
                                  DataColumn(label: Text('Nom complet')),
                                  DataColumn(label: Text('Genre')),
                                  DataColumn(label: Text('Naissance')),
                                  DataColumn(label: Text('Statut marital')),
                                  DataColumn(label: Text('Role')),
                                  DataColumn(label: Text('Statut')),
                                  DataColumn(label: Text('Famille')),
                                  DataColumn(label: Text('Assemblee')),
                                  DataColumn(label: Text('Vulnerable')),
                                  DataColumn(label: Text('Bapteme')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                source: _MembersDataSource(
                                  members: filtered,
                                  familyById: familyById,
                                  assembleeById: assembleeById,
                                  districtById: districtById,
                                  regionById: regionById,
                                  onEdit: (m) =>
                                      _openForm(context, member: m, families: families),
                                  onDelete: _confirmDelete,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Member? member, List<Famille>? families}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => MemberFormDialog(member: member, families: families ?? const []),
    );
  }

  Future<void> _confirmDelete(Member member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer ${member.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(membersProvider.notifier).removeMember(member.id);
    }
  }
}

class _MembersDataSource extends DataTableSource {
  _MembersDataSource({
    required this.members,
    required this.familyById,
    required this.assembleeById,
    required this.districtById,
    required this.regionById,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Member> members;
  final Map<String, Famille> familyById;
  final Map<String, AssembleeLocale> assembleeById;
  final Map<String, DistrictEglise> districtById;
  final Map<String, RegionEglise> regionById;
  final void Function(Member) onEdit;
  final Future<void> Function(Member) onDelete;

  String _role(Member m) => roleLabels[m.role] ?? m.role.name;
  String _statut(Member m) => statutFideleLabels[m.statut] ?? m.statut.name;

  String? _family(Member m) {
    if (m.idFamille == null) return null;
    return familyById[m.idFamille!]?.nom;
  }

  String? _vulnerabiliteTooltip(Member m) {
    if (m.vulnerabilites.isEmpty) return null;
    return m.vulnerabilites.map((v) => vulnerabiliteLabels[v] ?? v.name).join(', ');
  }

  String _assemblee(Member m) {
    if (m.idAssembleeLocale == null) return '--';
    final assemblee = assembleeById[m.idAssembleeLocale!];
    return assemblee?.nom ?? '--';
  }

  String? _assembleeTooltip(Member m) {
    if (m.idAssembleeLocale == null) return null;
    final assemblee = assembleeById[m.idAssembleeLocale!];
    if (assemblee == null) return null;
    final district = districtById[assemblee.idDistrict];
    final region = district != null ? regionById[district.idRegion] : null;
    final parts = <String>[];
    if (district != null) parts.add('District: ${district.nom}');
    if (region != null) parts.add('Region: ${region.nom}');
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  @override
  DataRow? getRow(int index) {
    if (index >= members.length) return null;
    final m = members[index];
    final familyName = _family(m);
    final vulnTooltip = _vulnerabiliteTooltip(m);
    final assembleeName = _assemblee(m);
    final assembleeTooltip = _assembleeTooltip(m);
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(m.fullName)),
        DataCell(Text(genderLabels[m.gender]!)),
        DataCell(Text(dateFormatter.format(m.birthDate))),
        DataCell(Text(maritalStatusLabels[m.maritalStatus]!)),
        DataCell(Text(_role(m))),
        DataCell(Text(_statut(m))),
        DataCell(Text(familyName ?? '—')),
        DataCell(
          assembleeTooltip == null
              ? Text(assembleeName)
              : Tooltip(message: assembleeTooltip, child: Text(assembleeName)),
        ),
        DataCell(
          vulnTooltip == null
              ? const Text('—')
              : Tooltip(
                  message: vulnTooltip,
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                ),
        ),
        DataCell(
          Text(
            m.baptismDate != null ? dateFormatter.format(m.baptismDate!) : '-',
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => onEdit(m),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => onDelete(m),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => members.length;

  @override
  int get selectedRowCount => 0;
}

class MemberFormDialog extends ConsumerStatefulWidget {
  const MemberFormDialog({super.key, this.member, required this.families});

  final Member? member;
  final List<Famille> families;

  @override
  ConsumerState<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _motifSortieCtrl = TextEditingController();

  Gender? _gender;
  MaritalStatus? _maritalStatus;
  StatutMatrimonial? _statutMatrimonial;
  RoleFidele _role = RoleFidele.membre;
  StatutFidele _statut = StatutFidele.actif;
  DateTime? _birthDate;
  DateTime? _dateConversion;
  DateTime? _dateBapteme;
  DateTime? _dateMainAssociation;
  DateTime? _dateEntree;
  DateTime? _dateSortie;
  DateTime? _dateDeces;
  Set<VulnerabiliteFidele> _vulnerabilites = {};
  String? _idFamille;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    if (m != null) {
      _nameCtrl.text = m.fullName;
      _phoneCtrl.text = m.phone ?? '';
      _emailCtrl.text = m.email ?? '';
      _addressCtrl.text = m.address ?? '';
      _gender = m.gender;
      _maritalStatus = m.maritalStatus;
      _statutMatrimonial = m.statutMatrimonial;
      _birthDate = m.dateNaissance ?? m.birthDate;
      _dateConversion = m.dateConversion;
      _dateBapteme = m.dateBapteme ?? m.baptismDate;
      _dateMainAssociation = m.dateMainAssociation;
      _dateEntree = m.dateEntree;
      _dateSortie = m.dateSortie;
      _dateDeces = m.dateDeces;
      _role = m.role;
      _statut = m.statut;
      _vulnerabilites = {...m.vulnerabilites};
      _motifSortieCtrl.text = m.motifSortie ?? '';
      _idFamille = m.idFamille;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _motifSortieCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;
    final families = widget.families;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier un fidele' : 'Nouveau fidele'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Gender>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Genre'),
                        items: Gender.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(genderLabels[g]!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<MaritalStatus>(
                        initialValue: _maritalStatus,
                        decoration: const InputDecoration(labelText: 'Statut marital (legacy)'),
                        items: MaritalStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(maritalStatusLabels[s]!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _maritalStatus = value),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StatutMatrimonial>(
                  initialValue: _statutMatrimonial,
                  decoration: const InputDecoration(labelText: 'Statut matrimonial'),
                  items: StatutMatrimonial.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _statutMatrimonial = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RoleFidele>(
                        initialValue: _role,
                        decoration: const InputDecoration(labelText: 'Role dans l\'assemblee'),
                        items: RoleFidele.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(roleLabels[r]!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _role = value ?? RoleFidele.membre),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<StatutFidele>(
                        initialValue: _statut,
                        decoration: const InputDecoration(labelText: 'Statut du fidele'),
                        items: StatutFidele.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(statutFideleLabels[s]!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _statut = value ?? StatutFidele.actif),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Date de naissance',
                        value: _birthDate,
                        onSelected: (d) => setState(() => _birthDate = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Date d\'entree',
                        value: _dateEntree,
                        onSelected: (d) => setState(() => _dateEntree = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Date de conversion',
                        value: _dateConversion,
                        onSelected: (d) => setState(() => _dateConversion = d),
                        allowEmpty: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Date de bapteme',
                        value: _dateBapteme,
                        onSelected: (d) => setState(() => _dateBapteme = d),
                        allowEmpty: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Date main d\'association',
                        value: _dateMainAssociation,
                        onSelected: (d) => setState(() => _dateMainAssociation = d),
                        allowEmpty: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _idFamille,
                        decoration: const InputDecoration(labelText: 'Famille'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Aucune'),
                          ),
                          ...families.map(
                            (f) => DropdownMenuItem<String?>(
                              value: f.id,
                              child: Text(f.nom),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _idFamille = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_statut == StatutFidele.parti || _statut == StatutFidele.transfere)
                  Column(
                    children: [
                      _DateField(
                        label: 'Date de sortie',
                        value: _dateSortie,
                        onSelected: (d) => setState(() => _dateSortie = d),
                        allowEmpty: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _motifSortieCtrl,
                        decoration: const InputDecoration(labelText: 'Motif de sortie'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                if (_statut == StatutFidele.decede)
                  Column(
                    children: [
                      _DateField(
                        label: 'Date de deces',
                        value: _dateDeces,
                        onSelected: (d) => setState(() => _dateDeces = d),
                        allowEmpty: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Vulnerabilites',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VulnerabiliteFidele.values
                      .map(
                        (v) => FilterChip(
                          label: Text(vulnerabiliteLabels[v] ?? v.name),
                          selected: _vulnerabilites.contains(v),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _vulnerabilites.add(v);
                              } else {
                                _vulnerabilites.remove(v);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telephone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
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
          onPressed: _submit,
          child: Text(isEditing ? 'Mettre a jour' : 'Enregistrer'),
        ),
      ],
    );
  }

  bool _validateDates() {
    if (_birthDate == null) {
      _showError('Veuillez renseigner la date de naissance.');
      return false;
    }
    if (_dateEntree == null) {
      _showError('Veuillez renseigner la date d\'entree.');
      return false;
    }
    if (_dateBapteme != null) {
      if (_birthDate != null && _dateBapteme!.isBefore(_birthDate!)) {
        _showError('La date de bapteme doit etre apres la naissance.');
        return false;
      }
      if (_dateConversion != null && _dateBapteme!.isBefore(_dateConversion!)) {
        _showError('La date de bapteme doit etre apres la conversion.');
        return false;
      }
    }
    if ((_statut == StatutFidele.parti || _statut == StatutFidele.transfere) &&
        _dateSortie == null) {
      _showError('Veuillez renseigner la date de sortie.');
      return false;
    }
    if (_statut == StatutFidele.decede && _dateDeces == null) {
      _showError('Veuillez renseigner la date de deces.');
      return false;
    }
    return true;
  }

  MaritalStatus _deriveMaritalStatus() {
    switch (_statutMatrimonial) {
      case StatutMatrimonial.marie:
        return MaritalStatus.married;
      case StatutMatrimonial.veuf:
      case StatutMatrimonial.veuve:
        return MaritalStatus.widowed;
      case StatutMatrimonial.divorce:
      case StatutMatrimonial.separe:
        return MaritalStatus.divorced;
      case StatutMatrimonial.celibataire:
      default:
        return MaritalStatus.single;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateDates()) return;

    final id = widget.member?.id ?? const Uuid().v4();
    final member = Member(
      id: id,
      fullName: _nameCtrl.text.trim(),
      gender: _gender!,
      birthDate: _birthDate!,
      maritalStatus: _maritalStatus ?? _deriveMaritalStatus(),
      baptismDate: _dateBapteme,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      dateNaissance: _birthDate,
      statutMatrimonial: _statutMatrimonial,
      dateConversion: _dateConversion,
      dateBapteme: _dateBapteme,
      dateMainAssociation: _dateMainAssociation,
      statut: _statut,
      dateEntree: _dateEntree,
      dateSortie: _dateSortie,
      motifSortie: _motifSortieCtrl.text.trim().isEmpty
          ? null
          : _motifSortieCtrl.text.trim(),
      dateDeces: _dateDeces,
      role: _role,
      vulnerabilites: _vulnerabilites,
      idFamille: _idFamille,
    );

    final notifier = ref.read(membersProvider.notifier);
    if (widget.member == null) {
      await notifier.addMember(member);
    } else {
      await notifier.updateMember(member);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onSelected,
    this.allowEmpty = false,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime?) onSelected;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1940),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null || allowEmpty) {
          onSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: allowEmpty ? () => onSelected(null) : null,
                )
              : const Icon(Icons.date_range),
        ),
        child: Text(
          value != null
              ? dateFormatter.format(value!)
              : (allowEmpty ? 'Optionnel' : 'Choisir'),
          style: TextStyle(
            color: value != null ? ChurchTheme.slate : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/member.dart';
import '../../providers/members_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final members = membersAsync.value ?? [];
    final filtered = members.where((m) {
      final matchesQuery =
          _query.isEmpty ||
          m.fullName.toLowerCase().contains(_query.toLowerCase());
      final matchesGender = _genderFilter == null || m.gender == _genderFilter;
      final matchesMarital =
          _maritalFilter == null || m.maritalStatus == _maritalFilter;
      final matchesYear =
          _baptismYearFilter == null ||
          m.baptismDate?.year == _baptismYearFilter;
      return matchesQuery && matchesGender && matchesMarital && matchesYear;
    }).toList();
    final baptismYears = {
      for (final m in members)
        if (m.baptismDate != null) m.baptismDate!.year,
    }.toList()..sort((a, b) => b.compareTo(a));
    final maleCount = members.where((m) => m.gender == Gender.male).length;
    final femaleCount = members.where((m) => m.gender == Gender.female).length;
    final marriedCount = members
        .where((m) => m.maritalStatus == MaritalStatus.married)
        .length;

    return AppShell(
      title: 'Fideles',
      currentRoute: '/members',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
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
                  title: 'Genre',
                  value: '$maleCount H / $femaleCount F',
                  subtitle: 'Total ${members.length}',
                  icon: Icons.people_outline,
                  color: ChurchTheme.navy,
                ),
              ),
              SizedBox(
                width: 220,
                child: InfoCard(
                  title: 'Maries',
                  value: '$marriedCount',
                  subtitle: 'Statut marital',
                  icon: Icons.favorite_outline,
                  color: Colors.pink[400],
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
                  decoration: const InputDecoration(labelText: 'Genre'),
                  initialValue: _genderFilter,
                  items: [
                    const DropdownMenuItem<Gender?>(
                      value: null,
                      child: Text('Tous'),
                    ),
                    ...Gender.values.map(
                      (g) => DropdownMenuItem<Gender?>(
                        value: g,
                        child: Text(genderLabels[g]!),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _genderFilter = value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<MaritalStatus?>(
                  decoration: const InputDecoration(
                    labelText: 'Statut marital',
                  ),
                  initialValue: _maritalFilter,
                  items: [
                    const DropdownMenuItem<MaritalStatus?>(
                      value: null,
                      child: Text('Tous'),
                    ),
                    ...MaritalStatus.values.map(
                      (s) => DropdownMenuItem<MaritalStatus?>(
                        value: s,
                        child: Text(maritalStatusLabels[s]!),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _maritalFilter = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
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
                      (y) =>
                          DropdownMenuItem<int?>(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _baptismYearFilter = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: membersAsync.isLoading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: PaginatedDataTable(
                        header: Text('Fideles (${filtered.length})'),
                        rowsPerPage: 8,
                        columns: const [
                          DataColumn(label: Text('Nom complet')),
                          DataColumn(label: Text('Genre')),
                          DataColumn(label: Text('Naissance')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Bapteme')),
                          DataColumn(label: Text('Actions')),
                        ],
                        source: _MembersDataSource(
                          members: filtered,
                          onEdit: (m) => _openForm(context, member: m),
                          onDelete: _confirmDelete,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Member? member}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => MemberFormDialog(member: member),
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
    required this.onEdit,
    required this.onDelete,
  });

  final List<Member> members;
  final void Function(Member) onEdit;
  final Future<void> Function(Member) onDelete;

  @override
  DataRow? getRow(int index) {
    if (index >= members.length) return null;
    final m = members[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(m.fullName)),
        DataCell(Text(genderLabels[m.gender]!)),
        DataCell(Text(dateFormatter.format(m.birthDate))),
        DataCell(Text(maritalStatusLabels[m.maritalStatus]!)),
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
  const MemberFormDialog({super.key, this.member});

  final Member? member;

  @override
  ConsumerState<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Gender? _gender;
  MaritalStatus? _maritalStatus;
  DateTime? _birthDate;
  DateTime? _baptismDate;

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
      _birthDate = m.birthDate;
      _baptismDate = m.baptismDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier un fidele' : 'Nouveau fidele'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Champ obligatoire' : null,
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
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: MaritalStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(maritalStatusLabels[s]!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _maritalStatus = value),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Naissance',
                        value: _birthDate,
                        onSelected: (d) => setState(() => _birthDate = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Bapteme',
                        value: _baptismDate,
                        onSelected: (d) => setState(() => _baptismDate = d),
                        allowEmpty: true,
                      ),
                    ),
                  ],
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) return;
    final notifier = ref.read(membersProvider.notifier);
    final id = widget.member?.id ?? const Uuid().v4();
    final member = Member(
      id: id,
      fullName: _nameCtrl.text.trim(),
      gender: _gender!,
      birthDate: _birthDate!,
      maritalStatus: _maritalStatus!,
      baptismDate: _baptismDate,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
    );
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
          lastDate: DateTime.now().add(const Duration(days: 365)),
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

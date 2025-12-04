import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../models/program.dart';
import '../../providers/members_provider.dart';
import '../../providers/programs_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _query = '';
  TypeProgramme? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final programs = programsAsync.value ?? [];
    final filtered = programs.where((p) {
      final matchesQuery =
          _query.isEmpty ||
          typeProgrammeLabels[p.type]!.toLowerCase().contains(
            _query.toLowerCase(),
          ) ||
          p.location.toLowerCase().contains(_query.toLowerCase());
      final matchesType = _typeFilter == null || p.type == _typeFilter;
      return matchesQuery && matchesType;
    }).toList();

    return AppShell(
      title: 'Programmes',
      currentRoute: '/programs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau programme'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher (type ou lieu)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<TypeProgramme?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Type'),
                  initialValue: _typeFilter,
                  items: [
                    const DropdownMenuItem<TypeProgramme?>(
                      value: null,
                      child: Text('Tous'),
                    ),
                    ...TypeProgramme.values.map(
                      (t) => DropdownMenuItem<TypeProgramme?>(
                        value: t,
                        child: Text(typeProgrammeLabels[t]!),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _typeFilter = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: programsAsync.isLoading && programs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Lieu')),
                            DataColumn(label: Text('Participants')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered
                              .map(
                                (p) => DataRow(
                                  cells: [
                                    DataCell(Text(typeProgrammeLabels[p.type]!)),
                                    DataCell(Text(dateFormatter.format(p.date))),
                                    DataCell(Text(p.location)),
                                    DataCell(Text('${p.participantIds.length}')),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                            ),
                                            onPressed: () => _showDetails(p),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () =>
                                                _openForm(context, program: p),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () => _confirmDelete(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Program? program}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ProgramFormDialog(program: program),
    );
  }

  Future<void> _confirmDelete(Program program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
          'Supprimer le programme ${typeProgrammeLabels[program.type]} ?',
        ),
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
      await ref.read(programsProvider.notifier).removeProgram(program.id);
    }
  }

  Future<void> _showDetails(Program program) async {
    final members = ref.read(membersProvider).value ?? [];
    final participants = members
        .where((m) => program.participantIds.contains(m.id))
        .toList();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Programme ${typeProgrammeLabels[program.type]}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(
                title: 'Date et lieu',
                value: dateFormatter.format(program.date),
                subtitle: program.location,
                icon: Icons.event_available,
              ),
              const SizedBox(height: 8),
              if (program.description != null)
                Text(
                  program.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Text(
                'Participants (${participants.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: participants
                    .map((m) => Chip(label: Text(m.fullName)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Observations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(program.observations ?? 'Aucune note'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class ProgramFormDialog extends ConsumerStatefulWidget {
  const ProgramFormDialog({super.key, this.program});

  final Program? program;

  @override
  ConsumerState<ProgramFormDialog> createState() => _ProgramFormDialogState();
}

class _ProgramFormDialogState extends ConsumerState<ProgramFormDialog> {
  final _formKey = GlobalKey<FormState>();
  TypeProgramme? _type;
  DateTime? _date;
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _selectedParticipants = <String>{};

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    if (p != null) {
      _type = p.type;
      _date = p.date;
      _locationCtrl.text = p.location;
      _descriptionCtrl.text = p.description ?? '';
      _observationsCtrl.text = p.observations ?? '';
      _selectedParticipants.addAll(p.participantIds);
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.program != null;
    final membersAsync = ref.watch(membersProvider);
    final members = membersAsync.value ?? [];
    return AlertDialog(
      title: Text(isEditing ? 'Modifier le programme' : 'Nouveau programme'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TypeProgramme>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TypeProgramme.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(typeProgrammeLabels[t]!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _type = value),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date et heure',
                  value: _date,
                  onSelected: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Lieu'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Lieu requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observationsCtrl,
                  decoration: const InputDecoration(labelText: 'Observations'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Participants',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                membersAsync.isLoading && members.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: members
                            .map(
                              (m) => FilterChip(
                                label: Text(m.fullName),
                                selected: _selectedParticipants.contains(m.id),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedParticipants.add(m.id);
                                    } else {
                                      _selectedParticipants.remove(m.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
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
    if (_date == null) return;
    final notifier = ref.read(programsProvider.notifier);
    final id = widget.program?.id ?? const Uuid().v4();
    final program = Program(
      id: id,
      type: _type!,
      date: _date!,
      location: _locationCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      observations: _observationsCtrl.text.trim().isEmpty
          ? null
          : _observationsCtrl.text.trim(),
      participantIds: _selectedParticipants.toList(),
    );
    if (widget.program == null) {
      await notifier.addProgram(program);
    } else {
      await notifier.updateProgram(program);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime?) onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (pickedDate == null) return;
        if (!context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );
        if (!context.mounted) return;
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? 0,
          pickedTime?.minute ?? 0,
        );
        onSelected(combined);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.event_available),
        ),
        child: Text(
          value != null
              ? '${dateFormatter.format(value!)} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
              : 'Choisir une date',
        ),
      ),
    );
  }
}

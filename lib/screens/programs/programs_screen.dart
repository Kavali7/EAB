import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../models/program.dart';
import '../../models/region_eglise.dart';
import '../../models/district_eglise.dart';
import '../../models/assemblee_locale.dart';
import '../../models/profil_utilisateur.dart';
import '../../providers/church_structure_providers.dart';
import '../../providers/members_provider.dart';
import '../../providers/programs_provider.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';

const typeVisiteLabels = {
  TypeVisite.fidele: 'Fidele',
  TypeVisite.autorite: 'Autorite',
  TypeVisite.partenaire: 'Partenaire',
  TypeVisite.autreAssemblee: 'Autre assemblee',
  TypeVisite.autre: 'Autre',
};

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _query = '';
  TypeProgramme? _typeFilter;
  TypeVisite? _typeVisiteFilter;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _idRegionFilter;
  String? _idDistrictFilter;
  String? _idAssembleeLocaleFilter;
  String? _profileAppliedId;

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final regionsAsync = ref.watch(regionsProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final profilCourant = ref.watch(profilUtilisateurCourantProvider);
    final programs = programsAsync.value ?? [];
    final regions = regionsAsync.value ?? [];
    final districts = districtsAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final regionById = {for (final r in regions) r.id: r};
    final districtById = {for (final d in districts) d.id: d};
    final assembleeById = {for (final a in assemblees) a.id: a};
    if (profilCourant != null && _profileAppliedId != profilCourant.id) {
      _applyProfileScope(profilCourant);
      _profileAppliedId = profilCourant.id;
    }
    final filteredDistricts = _idRegionFilter == null
        ? districts
        : districts.where((d) => d.idRegion == _idRegionFilter).toList();
    final filteredAssemblees = _idDistrictFilter == null
        ? assemblees
        : assemblees.where((a) => a.idDistrict == _idDistrictFilter).toList();
    final filtered = programs.where((p) {
      final matchesQuery =
          _query.isEmpty ||
          typeProgrammeLabels[p.type]!.toLowerCase().contains(
            _query.toLowerCase(),
          ) ||
          p.location.toLowerCase().contains(_query.toLowerCase());
      final matchesType = _typeFilter == null || p.type == _typeFilter;
      final matchesTypeVisite = _typeVisiteFilter == null
          ? true
          : (p.type == TypeProgramme.visite &&
              p.typeVisite == _typeVisiteFilter);
      final matchesDateDebut =
          _dateDebut == null || !p.date.isBefore(_dateDebut!);
      final matchesDateFin = _dateFin == null || !p.date.isAfter(_dateFin!);
      final assemblee =
          p.idAssembleeLocale != null ? assembleeById[p.idAssembleeLocale!] : null;
      final district = assemblee != null ? districtById[assemblee.idDistrict] : null;
      final regionId = district?.idRegion;
      final matchesStructure = () {
        if (_idAssembleeLocaleFilter != null) {
          return p.idAssembleeLocale == _idAssembleeLocaleFilter;
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
          matchesType &&
          matchesTypeVisite &&
          matchesDateDebut &&
          matchesDateFin &&
          matchesStructure;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

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
                width: 240,
                child: DropdownButtonFormField<TypeProgramme?>(
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Type de programme'),
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
                  onChanged: (value) => setState(() {
                    _typeFilter = value;
                    if (_typeFilter != TypeProgramme.visite) {
                      _typeVisiteFilter = null;
                    }
                  }),
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
                      : _isRegionLocked(profilCourant)
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
                      : _isDistrictLocked(profilCourant)
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
                      : _isAssembleeLocked(profilCourant)
                          ? null
                          : (value) => setState(() => _idAssembleeLocaleFilter = value),
                ),
              ),
              if (_typeFilter == TypeProgramme.visite)
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<TypeVisite?>(
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Type de visite'),
                    initialValue: _typeVisiteFilter,
                    items: [
                      const DropdownMenuItem<TypeVisite?>(
                        value: null,
                        child: Text('Tous'),
                      ),
                      ...TypeVisite.values.map(
                        (t) => DropdownMenuItem<TypeVisite?>(
                          value: t,
                          child: Text(typeVisiteLabels[t]!),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _typeVisiteFilter = value),
                  ),
                ),
              SizedBox(
                width: 180,
                child: _DateFilterField(
                  label: 'Du',
                  value: _dateDebut,
                  onSelected: (d) => setState(() => _dateDebut = d),
                ),
              ),
              SizedBox(
                width: 180,
                child: _DateFilterField(
                  label: 'Au',
                  value: _dateFin,
                  onSelected: (d) => setState(() => _dateFin = d),
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
                            DataColumn(label: Text('Assemblee')),
                            DataColumn(label: Text('Participants')),
                            DataColumn(label: Text('Conversions')),
                            DataColumn(label: Text('Ecole du dimanche')),
                            DataColumn(label: Text('Visite')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered
                              .map(
                                (p) => DataRow(
                                  cells: [
                                    DataCell(Text(typeProgrammeLabels[p.type]!)),
                                    DataCell(Text(dateFormatter.format(p.date))),
                                    DataCell(Text(p.location)),
                                    DataCell(_buildAssembleeCell(
                                      p,
                                      assembleeById,
                                      districtById,
                                      regionById,
                                    )),
                                    DataCell(Text(_formatParticipants(p))),
                                    DataCell(_buildConversionsCell(p)),
                                    DataCell(_buildEcoleCell(p)),
                                    DataCell(_buildVisiteCell(p)),
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

  bool _isEvangelisation(Program program) =>
      program.type == TypeProgramme.evangelisationMasse ||
      program.type == TypeProgramme.evangelisationPorteAPorte;

  String _formatParticipants(Program program) {
    final values = [
      program.nombreHommes,
      program.nombreFemmes,
      program.nombreGarcons,
      program.nombreFilles,
    ];
    if (values.every((v) => v == null)) {
      return '--';
    }
    return 'H: ${program.nombreHommes ?? 0}, F: ${program.nombreFemmes ?? 0}, G: ${program.nombreGarcons ?? 0}, Fi: ${program.nombreFilles ?? 0}';
  }

  Widget _buildAssembleeCell(
    Program program,
    Map<String, AssembleeLocale> assembleeById,
    Map<String, DistrictEglise> districtById,
    Map<String, RegionEglise> regionById,
  ) {
    if (program.idAssembleeLocale == null) return const Text('--');
    final assemblee = assembleeById[program.idAssembleeLocale!];
    if (assemblee == null) return const Text('--');
    final district = districtById[assemblee.idDistrict];
    final region = district != null ? regionById[district.idRegion] : null;
    final tooltipParts = <String>[];
    if (district != null) tooltipParts.add('District: ${district.nom}');
    if (region != null) tooltipParts.add('Region: ${region.nom}');
    final child = Text(assemblee.nom);
    if (tooltipParts.isEmpty) return child;
    return Tooltip(message: tooltipParts.join('\n'), child: child);
  }

  Widget _buildConversionsCell(Program program) {
    final text = _formatConversionsText(program);
    return text == '--' ? const Text('--') : Text(text);
  }

  String _formatConversionsText(Program program) {
    if (!_isEvangelisation(program)) return '--';
    final values = [
      program.conversionsHommes,
      program.conversionsFemmes,
      program.conversionsGarcons,
      program.conversionsFilles,
    ];
    if (values.every((v) => v == null)) return '--';
    return 'H: ${program.conversionsHommes ?? 0}, F: ${program.conversionsFemmes ?? 0}, G: ${program.conversionsGarcons ?? 0}, Fi: ${program.conversionsFilles ?? 0}';
  }

  Widget _buildEcoleCell(Program program) {
    if (program.type != TypeProgramme.ecoleDuDimanche) {
      return const Text('--');
    }
    final content =
        'Classes: ${program.nombreClassesEcoleDuDimanche ?? 0}, Moniteurs: ${program.nombreMoniteursHommes ?? 0} H / ${program.nombreMonitricesFemmes ?? 0} F';
    final lesson = program.derniereLeconEcoleDuDimanche;
    if (lesson == null || lesson.isEmpty) {
      return Text(content);
    }
    return Tooltip(
      message: lesson,
      child: Text(content),
    );
  }

  Widget _buildVisiteCell(Program program) {
    if (program.type != TypeProgramme.visite) return const Text('--');
    final label = typeVisiteLabels[program.typeVisite] ?? 'Non precise';
    final compte = program.compteRenduVisite;
    final text = Text(label);
    if (compte == null || compte.isEmpty) return text;
    return Tooltip(
      message: compte,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sticky_note_2_outlined, size: 16),
          const SizedBox(width: 4),
          text,
        ],
      ),
    );
  }

  void _applyProfileScope(ProfilUtilisateur profil) {
    switch (profil.role) {
      case RoleUtilisateur.adminNational:
        return;
      case RoleUtilisateur.responsableRegion:
        _idRegionFilter = profil.idRegion ?? _idRegionFilter;
        _idDistrictFilter = null;
        _idAssembleeLocaleFilter = null;
        return;
      case RoleUtilisateur.surintendantDistrict:
        _idRegionFilter = profil.idRegion ?? _idRegionFilter;
        _idDistrictFilter = profil.idDistrict ?? _idDistrictFilter;
        _idAssembleeLocaleFilter = null;
        return;
      case RoleUtilisateur.tresorierAssemblee:
        _idRegionFilter = profil.idRegion ?? _idRegionFilter;
        _idDistrictFilter = profil.idDistrict ?? _idDistrictFilter;
        _idAssembleeLocaleFilter = profil.idAssembleeLocale ?? _idAssembleeLocaleFilter;
        return;
    }
  }

  bool _isRegionLocked(ProfilUtilisateur? profil) {
    if (profil == null) return false;
    return profil.role != RoleUtilisateur.adminNational;
  }

  bool _isDistrictLocked(ProfilUtilisateur? profil) {
    if (profil == null) return false;
    return profil.role == RoleUtilisateur.surintendantDistrict ||
        profil.role == RoleUtilisateur.tresorierAssemblee;
  }

  bool _isAssembleeLocked(ProfilUtilisateur? profil) {
    if (profil == null) return false;
    return profil.role == RoleUtilisateur.tresorierAssemblee;
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
                'Effectifs: ${_formatParticipants(program)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_isEvangelisation(program)) ...[
                const SizedBox(height: 4),
                Text(
                  'Conversions: ${_formatConversionsText(program)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (program.type == TypeProgramme.ecoleDuDimanche) ...[
                const SizedBox(height: 4),
                Text(
                  'Ecole du dimanche: Classes ${program.nombreClassesEcoleDuDimanche ?? 0}, Moniteurs ${program.nombreMoniteursHommes ?? 0} H / ${program.nombreMonitricesFemmes ?? 0} F',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (program.derniereLeconEcoleDuDimanche != null &&
                    program.derniereLeconEcoleDuDimanche!.isNotEmpty)
                  Text(
                    'Derniere lecon: ${program.derniereLeconEcoleDuDimanche}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              if (program.type == TypeProgramme.visite) ...[
                const SizedBox(height: 4),
                Text(
                  'Type de visite: ${typeVisiteLabels[program.typeVisite] ?? 'Non precise'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (program.compteRenduVisite != null &&
                    program.compteRenduVisite!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      program.compteRenduVisite!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
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
  final _nombreHommesCtrl = TextEditingController();
  final _nombreFemmesCtrl = TextEditingController();
  final _nombreGarconsCtrl = TextEditingController();
  final _nombreFillesCtrl = TextEditingController();
  final _convHommesCtrl = TextEditingController();
  final _convFemmesCtrl = TextEditingController();
  final _convGarconsCtrl = TextEditingController();
  final _convFillesCtrl = TextEditingController();
  final _classesCtrl = TextEditingController();
  final _moniteursHommesCtrl = TextEditingController();
  final _monitricesFemmesCtrl = TextEditingController();
  final _derniereLeconCtrl = TextEditingController();
  final _compteRenduVisiteCtrl = TextEditingController();
  TypeVisite? _typeVisite;
  final _selectedParticipants = <String>{};

  bool get _isEvangelisationType =>
      _type == TypeProgramme.evangelisationMasse ||
      _type == TypeProgramme.evangelisationPorteAPorte;

  bool get _isEcoleType => _type == TypeProgramme.ecoleDuDimanche;

  bool get _isVisiteType => _type == TypeProgramme.visite;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _type = p?.type ?? TypeProgramme.culte;
    _date = p?.date ?? DateTime.now();
    if (p != null) {
      _locationCtrl.text = p.location;
      _descriptionCtrl.text = p.description ?? '';
      _observationsCtrl.text = p.observations ?? '';
      _selectedParticipants.addAll(p.participantIds);
      _nombreHommesCtrl.text = p.nombreHommes?.toString() ?? '';
      _nombreFemmesCtrl.text = p.nombreFemmes?.toString() ?? '';
      _nombreGarconsCtrl.text = p.nombreGarcons?.toString() ?? '';
      _nombreFillesCtrl.text = p.nombreFilles?.toString() ?? '';
      _convHommesCtrl.text = p.conversionsHommes?.toString() ?? '';
      _convFemmesCtrl.text = p.conversionsFemmes?.toString() ?? '';
      _convGarconsCtrl.text = p.conversionsGarcons?.toString() ?? '';
      _convFillesCtrl.text = p.conversionsFilles?.toString() ?? '';
      _classesCtrl.text = p.nombreClassesEcoleDuDimanche?.toString() ?? '';
      _moniteursHommesCtrl.text =
          p.nombreMoniteursHommes?.toString() ?? '';
      _monitricesFemmesCtrl.text =
          p.nombreMonitricesFemmes?.toString() ?? '';
      _derniereLeconCtrl.text = p.derniereLeconEcoleDuDimanche ?? '';
      _typeVisite = p.typeVisite;
      _compteRenduVisiteCtrl.text = p.compteRenduVisite ?? '';
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _observationsCtrl.dispose();
    _nombreHommesCtrl.dispose();
    _nombreFemmesCtrl.dispose();
    _nombreGarconsCtrl.dispose();
    _nombreFillesCtrl.dispose();
    _convHommesCtrl.dispose();
    _convFemmesCtrl.dispose();
    _convGarconsCtrl.dispose();
    _convFillesCtrl.dispose();
    _classesCtrl.dispose();
    _moniteursHommesCtrl.dispose();
    _monitricesFemmesCtrl.dispose();
    _derniereLeconCtrl.dispose();
    _compteRenduVisiteCtrl.dispose();
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
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TypeProgramme>(
                  initialValue: _type,
                  decoration:
                      const InputDecoration(labelText: 'Type de programme'),
                  items: TypeProgramme.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(typeProgrammeLabels[t]!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _type = value;
                    if (_type != TypeProgramme.visite) {
                      _typeVisite = null;
                    }
                  }),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Participants (effectifs)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 160,
                      child: _buildIntField(
                        label: 'Nombre d hommes',
                        controller: _nombreHommesCtrl,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: _buildIntField(
                        label: 'Nombre de femmes',
                        controller: _nombreFemmesCtrl,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: _buildIntField(
                        label: 'Nombre de garcons',
                        controller: _nombreGarconsCtrl,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: _buildIntField(
                        label: 'Nombre de filles',
                        controller: _nombreFillesCtrl,
                      ),
                    ),
                  ],
                ),
                if (_isEvangelisationType) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Conversions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 160,
                        child: _buildIntField(
                          label: 'Conversions hommes',
                          controller: _convHommesCtrl,
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: _buildIntField(
                          label: 'Conversions femmes',
                          controller: _convFemmesCtrl,
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: _buildIntField(
                          label: 'Conversions garcons',
                          controller: _convGarconsCtrl,
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: _buildIntField(
                          label: 'Conversions filles',
                          controller: _convFillesCtrl,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isEcoleType) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ecole du dimanche',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: _buildIntField(
                          label: 'Nombre de classes',
                          controller: _classesCtrl,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: _buildIntField(
                          label: 'Moniteurs hommes',
                          controller: _moniteursHommesCtrl,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: _buildIntField(
                          label: 'Monitrices femmes',
                          controller: _monitricesFemmesCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _derniereLeconCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Derniere lecon etudiee',
                    ),
                  ),
                ],
                if (_isVisiteType) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Visite',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TypeVisite>(
                    initialValue: _typeVisite,
                    decoration:
                        const InputDecoration(labelText: 'Type de visite'),
                    items: TypeVisite.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(typeVisiteLabels[t]!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _typeVisite = value),
                    validator: (v) {
                      if (!_isVisiteType) return null;
                      return v == null ? 'Requis' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _compteRenduVisiteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Compte-rendu de la visite',
                    ),
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Participants identifies',
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

  Widget _buildIntField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final trimmed = v?.trim() ?? '';
        if (trimmed.isEmpty) return null;
        final parsed = int.tryParse(trimmed);
        if (parsed == null) return 'Nombre invalide';
        if (parsed < 0) return 'Doit etre >= 0';
        return null;
      },
    );
  }

  int? _intFromCtrl(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null) {
      _showMessage('Merci de choisir un type de programme');
      return;
    }
    if (_date == null) {
      _showMessage('Merci de choisir une date et une heure');
      return;
    }
    if (_isVisiteType && _typeVisite == null) {
      _showMessage('Merci de choisir un type de visite');
      return;
    }
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
      nombreHommes: _intFromCtrl(_nombreHommesCtrl),
      nombreFemmes: _intFromCtrl(_nombreFemmesCtrl),
      nombreGarcons: _intFromCtrl(_nombreGarconsCtrl),
      nombreFilles: _intFromCtrl(_nombreFillesCtrl),
      conversionsHommes:
          _isEvangelisationType ? _intFromCtrl(_convHommesCtrl) : null,
      conversionsFemmes:
          _isEvangelisationType ? _intFromCtrl(_convFemmesCtrl) : null,
      conversionsGarcons:
          _isEvangelisationType ? _intFromCtrl(_convGarconsCtrl) : null,
      conversionsFilles:
          _isEvangelisationType ? _intFromCtrl(_convFillesCtrl) : null,
      nombreClassesEcoleDuDimanche:
          _isEcoleType ? _intFromCtrl(_classesCtrl) : null,
      nombreMoniteursHommes:
          _isEcoleType ? _intFromCtrl(_moniteursHommesCtrl) : null,
      nombreMonitricesFemmes:
          _isEcoleType ? _intFromCtrl(_monitricesFemmesCtrl) : null,
      derniereLeconEcoleDuDimanche: _isEcoleType &&
              _derniereLeconCtrl.text.trim().isNotEmpty
          ? _derniereLeconCtrl.text.trim()
          : null,
      typeVisite: _isVisiteType ? _typeVisite : null,
      compteRenduVisite: _isVisiteType &&
              _compteRenduVisiteCtrl.text.trim().isNotEmpty
          ? _compteRenduVisiteCtrl.text.trim()
          : null,
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

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
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
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (pickedDate != null) {
          onSelected(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.event)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onSelected(null),
                    ),
                    const Icon(Icons.event),
                  ],
                ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 48),
        ),
        child: Text(
          value != null ? dateFormatter.format(value!) : 'Aucune date',
        ),
      ),
    );
  }
}

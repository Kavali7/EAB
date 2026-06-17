/// Ecran Programmes v2.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/core/utils/church_unit_scope.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/models/program.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

import 'program_form_dialog.dart';

const _typeVisiteLabels = {
  TypeVisite.fidele: 'Fidele',
  TypeVisite.autorite: 'Autorite',
  TypeVisite.partenaire: 'Partenaire',
  TypeVisite.autreAssemblee: 'Autre assemblee',
  TypeVisite.autre: 'Autre',
};

class ProgramsScreenV2 extends ConsumerStatefulWidget {
  const ProgramsScreenV2({super.key});

  @override
  ConsumerState<ProgramsScreenV2> createState() => _ProgramsScreenV2State();
}

class _ProgramsScreenV2State extends ConsumerState<ProgramsScreenV2> {
  final _queryController = TextEditingController();
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  String _query = '';
  TypeProgramme? _typeFilter;
  TypeVisite? _typeVisiteFilter;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final churchUnitActiveId = ref.watch(churchUnitActiveIdProvider);

    final programs = programsAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final churchUnits = churchUnitsAsync.value ?? [];
    final assembleeById = {for (final a in assemblees) a.id: a};
    final churchUnitById = {for (final unit in churchUnits) unit.id: unit};
    final scope = ChurchUnitScope.fromActiveContext(
      units: churchUnits,
      activeChurchUnitId: churchUnitActiveId,
      activeAssembleeId: assembleeActiveId,
    );

    final filtered = programs.where((program) {
      if (!scope.contains(
        churchUnitId: program.churchUnitId,
        legacyAssembleeId: program.idAssembleeLocale,
      )) {
        return false;
      }

      if (_query.isNotEmpty) {
        final query = _query.toLowerCase();
        final type = (typeProgrammeLabels[program.type] ?? '').toLowerCase();
        final location = program.location.toLowerCase();
        final description = (program.description ?? '').toLowerCase();
        if (!type.contains(query) &&
            !location.contains(query) &&
            !description.contains(query)) {
          return false;
        }
      }

      if (_typeFilter != null && program.type != _typeFilter) return false;
      if (_typeVisiteFilter != null &&
          (program.type != TypeProgramme.visite ||
              program.typeVisite != _typeVisiteFilter)) {
        return false;
      }
      if (_dateDebut != null &&
          program.date.isBefore(_startOfDay(_dateDebut!))) {
        return false;
      }
      if (_dateFin != null && program.date.isAfter(_endOfDay(_dateFin!))) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return AppShell(
      title: 'Programmes',
      currentRoute: '/programs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProgramFormV2(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau programme'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final horizontalPadding = compact ? AppSpacing.md : AppSpacing.xl;

          if (compact) {
            return _buildCompactBody(
              programsAsync: programsAsync,
              filtered: filtered,
              assembleeById: assembleeById,
              churchUnitById: churchUnitById,
              horizontalPadding: horizontalPadding,
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.xl,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EabPageHeader(
                  title: 'Programmes',
                  subtitle:
                      'Planification, suivi des activites et comptes rendus.',
                  icon: Icons.event_note_outlined,
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/calendar'),
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Calendrier'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () => showProgramFormV2(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nouveau programme'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ProgramFilterPanel(
                  compact: compact,
                  queryController: _queryController,
                  query: _query,
                  typeFilter: _typeFilter,
                  typeVisiteFilter: _typeVisiteFilter,
                  dateDebut: _dateDebut,
                  dateFin: _dateFin,
                  onQueryChanged: (value) =>
                      setState(() => _query = value.trim()),
                  onTypeChanged: (value) => setState(() {
                    _typeFilter = value;
                    if (_typeFilter != TypeProgramme.visite) {
                      _typeVisiteFilter = null;
                    }
                  }),
                  onTypeVisiteChanged: (value) =>
                      setState(() => _typeVisiteFilter = value),
                  onDateDebutChanged: (value) =>
                      setState(() => _dateDebut = value),
                  onDateFinChanged: (value) => setState(() => _dateFin = value),
                  onClear: _clearFilters,
                ),
                const SizedBox(height: AppSpacing.md),
                _ProgramSummaryStrip(programs: filtered, compact: compact),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: programsAsync.when(
                    loading: () => programs.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _buildProgramList(
                            filtered,
                            assembleeById,
                            churchUnitById,
                            compact,
                            isRefreshing: true,
                          ),
                    error: (error, _) => ErrorState(
                      message: 'Erreur lors du chargement : $error',
                      onRetry: () => ref.invalidate(programsProvider),
                    ),
                    data: (_) => _buildProgramList(
                      filtered,
                      assembleeById,
                      churchUnitById,
                      compact,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramList(
    List<Program> programs,
    Map<String, dynamic> assembleeById,
    Map<String, ChurchUnit> churchUnitById,
    bool compact, {
    bool isRefreshing = false,
  }) {
    if (programs.isEmpty) {
      return compact
          ? const _ProgramEmptyState()
          : const Padding(
              padding: EdgeInsets.only(bottom: 96),
              child: EmptyState(
                icon: Icons.event_busy_outlined,
                message: 'Aucun programme trouve.',
              ),
            );
    }

    if (compact) {
      return Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.only(bottom: 104),
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final program = programs[index];
              return _ProgramCard(
                program: program,
                dateTimeFormat: _dateTimeFormat,
                assembleeName: _unitName(
                  program,
                  assembleeById,
                  churchUnitById,
                ),
                onOpenDetails: () =>
                    _showDetails(program, assembleeById, churchUnitById),
                onEdit: () => showProgramFormV2(context, program: program),
                onDelete: () => _confirmDelete(program),
              );
            },
          ),
          if (isRefreshing)
            const Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${programs.length} programme${programs.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRefreshing) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: EabTable<Program>(
            items: programs,
            rowsPerPage: 15,
            emptyMessage: 'Aucun programme trouve',
            emptyIcon: Icons.event_busy_outlined,
            onRowTap: (program) =>
                _showDetails(program, assembleeById, churchUnitById),
            columns: [
              EabColumn<Program>(
                label: 'Type',
                flex: 2,
                sortKeyExtractor: (program) =>
                    typeProgrammeLabels[program.type] ?? '',
                cellBuilder: (program) => Text(
                  typeProgrammeLabels[program.type] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              EabColumn<Program>(
                label: 'Date',
                fixedWidth: 150,
                sortKeyExtractor: (program) => program.date,
                cellBuilder: (program) =>
                    Text(_dateTimeFormat.format(program.date)),
              ),
              EabColumn<Program>(
                label: 'Lieu',
                flex: 2,
                cellBuilder: (program) =>
                    Text(program.location, overflow: TextOverflow.ellipsis),
              ),
              EabColumn<Program>(
                label: 'Unite',
                flex: 2,
                cellBuilder: (program) => Text(
                  _unitName(program, assembleeById, churchUnitById),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EabColumn<Program>(
                label: 'Participants',
                fixedWidth: 120,
                numeric: true,
                cellBuilder: (program) => Text(
                  '${_participantTotal(program)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              EabColumn<Program>(
                label: 'Actions',
                fixedWidth: 108,
                cellBuilder: (program) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Modifier',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          showProgramFormV2(context, program: program),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      onPressed: () => _confirmDelete(program),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBody({
    required AsyncValue<List<Program>> programsAsync,
    required List<Program> filtered,
    required Map<String, dynamic> assembleeById,
    required Map<String, ChurchUnit> churchUnitById,
    required double horizontalPadding,
  }) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        104,
      ),
      children: [
        _ProgramsMobileHeader(
          onOpenCalendar: () => Navigator.of(context).pushNamed('/calendar'),
        ),
        const SizedBox(height: AppSpacing.md),
        _ProgramFilterPanel(
          compact: true,
          queryController: _queryController,
          query: _query,
          typeFilter: _typeFilter,
          typeVisiteFilter: _typeVisiteFilter,
          dateDebut: _dateDebut,
          dateFin: _dateFin,
          onQueryChanged: (value) => setState(() => _query = value.trim()),
          onTypeChanged: (value) => setState(() {
            _typeFilter = value;
            if (_typeFilter != TypeProgramme.visite) {
              _typeVisiteFilter = null;
            }
          }),
          onTypeVisiteChanged: (value) =>
              setState(() => _typeVisiteFilter = value),
          onDateDebutChanged: (value) => setState(() => _dateDebut = value),
          onDateFinChanged: (value) => setState(() => _dateFin = value),
          onClear: _clearFilters,
        ),
        const SizedBox(height: AppSpacing.md),
        _ProgramSummaryStrip(programs: filtered, compact: true),
        const SizedBox(height: AppSpacing.md),
        programsAsync.when(
          loading: () => const _ProgramLoadingState(),
          error: (error, _) => SizedBox(
            height: 240,
            child: ErrorState(
              message: 'Erreur lors du chargement : $error',
              onRetry: () => ref.invalidate(programsProvider),
            ),
          ),
          data: (_) => _buildCompactProgramCards(
            filtered,
            assembleeById,
            churchUnitById,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactProgramCards(
    List<Program> programs,
    Map<String, dynamic> assembleeById,
    Map<String, ChurchUnit> churchUnitById,
  ) {
    if (programs.isEmpty) return const _ProgramEmptyState();

    return Column(
      children: [
        for (var i = 0; i < programs.length; i++) ...[
          _ProgramCard(
            program: programs[i],
            dateTimeFormat: _dateTimeFormat,
            assembleeName: _unitName(
              programs[i],
              assembleeById,
              churchUnitById,
            ),
            onOpenDetails: () =>
                _showDetails(programs[i], assembleeById, churchUnitById),
            onEdit: () => showProgramFormV2(context, program: programs[i]),
            onDelete: () => _confirmDelete(programs[i]),
          ),
          if (i < programs.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _queryController.clear();
      _query = '';
      _typeFilter = null;
      _typeVisiteFilter = null;
      _dateDebut = null;
      _dateFin = null;
    });
  }

  void _showDetails(
    Program program,
    Map<String, dynamic> assembleeById,
    Map<String, ChurchUnit> churchUnitById,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.56,
        minChildSize: 0.34,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _ProgramTypeIcon(type: program.type, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeProgrammeLabels[program.type] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _dateTimeFormat.format(program.date),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailTile(
              icon: Icons.location_on_outlined,
              label: 'Lieu',
              value: program.location,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailTile(
              icon: Icons.church_outlined,
              label: 'Unite',
              value: _unitName(program, assembleeById, churchUnitById),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailTile(
              icon: Icons.groups_outlined,
              label: 'Participants',
              value:
                  '${_participantTotal(program)} personnes - ${_participantBreakdown(program)}',
            ),
            if (_conversionTotal(program) > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _DetailTile(
                icon: Icons.volunteer_activism_outlined,
                label: 'Conversions',
                value: '${_conversionTotal(program)}',
              ),
            ],
            if (program.type == TypeProgramme.visite &&
                program.typeVisite != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _DetailTile(
                icon: Icons.handshake_outlined,
                label: 'Type de visite',
                value: _typeVisiteLabels[program.typeVisite] ?? '-',
              ),
            ],
            if ((program.description ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _TextBlock(title: 'Description', text: program.description!),
            ],
            if ((program.compteRenduVisite ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _TextBlock(
                title: 'Compte rendu',
                text: program.compteRenduVisite!,
              ),
            ],
            if ((program.observations ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _TextBlock(title: 'Observations', text: program.observations!),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showProgramFormV2(context, program: program);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _confirmDelete(program);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Program program) async {
    final confirm = await EabDialog.confirm(
      context,
      title: 'Supprimer un programme',
      message: 'Supprimer le programme ${typeProgrammeLabels[program.type]} ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirm == true) {
      await ref.read(programsProvider.notifier).removeProgram(program.id);
    }
  }

  String _unitName(
    Program program,
    Map<String, dynamic> assembleeById,
    Map<String, ChurchUnit> churchUnitById,
  ) {
    final unit = program.churchUnitId == null
        ? null
        : churchUnitById[program.churchUnitId!];
    if (unit != null) return unit.nom;
    if (program.idAssembleeLocale == null) return '-';
    final assemblee = assembleeById[program.idAssembleeLocale];
    return assemblee?.nom ?? '-';
  }

  int _participantTotal(Program program) =>
      (program.nombreHommes ?? 0) +
      (program.nombreFemmes ?? 0) +
      (program.nombreGarcons ?? 0) +
      (program.nombreFilles ?? 0);

  String _participantBreakdown(Program program) {
    final parts = [
      'H ${program.nombreHommes ?? 0}',
      'F ${program.nombreFemmes ?? 0}',
      'G ${program.nombreGarcons ?? 0}',
      'Fi ${program.nombreFilles ?? 0}',
    ];
    return parts.join(' | ');
  }

  int _conversionTotal(Program program) =>
      (program.conversionsHommes ?? 0) +
      (program.conversionsFemmes ?? 0) +
      (program.conversionsGarcons ?? 0) +
      (program.conversionsFilles ?? 0);

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

class _ProgramsMobileHeader extends StatelessWidget {
  const _ProgramsMobileHeader({required this.onOpenCalendar});

  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.event_note_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programmes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Activites et comptes rendus.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenCalendar,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('Ouvrir le calendrier'),
          ),
        ),
      ],
    );
  }
}

class _ProgramFilterPanel extends StatelessWidget {
  const _ProgramFilterPanel({
    required this.compact,
    required this.queryController,
    required this.query,
    required this.typeFilter,
    required this.typeVisiteFilter,
    required this.dateDebut,
    required this.dateFin,
    required this.onQueryChanged,
    required this.onTypeChanged,
    required this.onTypeVisiteChanged,
    required this.onDateDebutChanged,
    required this.onDateFinChanged,
    required this.onClear,
  });

  final bool compact;
  final TextEditingController queryController;
  final String query;
  final TypeProgramme? typeFilter;
  final TypeVisite? typeVisiteFilter;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TypeProgramme?> onTypeChanged;
  final ValueChanged<TypeVisite?> onTypeVisiteChanged;
  final ValueChanged<DateTime?> onDateDebutChanged;
  final ValueChanged<DateTime?> onDateFinChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final queryField = EabTextField(
      label: 'Rechercher',
      hint: 'type, lieu, description',
      controller: queryController,
      prefixIcon: Icons.search,
      onChanged: onQueryChanged,
    );

    final typeField = EabSelectField<TypeProgramme?>(
      label: 'Type',
      value: typeFilter,
      prefixIcon: Icons.category_outlined,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous')),
        ...TypeProgramme.values.map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(typeProgrammeLabels[type] ?? type.name),
          ),
        ),
      ],
      onChanged: onTypeChanged,
    );

    final typeVisiteField = EabSelectField<TypeVisite?>(
      label: 'Visite',
      value: typeVisiteFilter,
      prefixIcon: Icons.handshake_outlined,
      items: [
        const DropdownMenuItem(value: null, child: Text('Toutes')),
        ...TypeVisite.values.map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(_typeVisiteLabels[type] ?? type.name),
          ),
        ),
      ],
      onChanged: onTypeVisiteChanged,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              children: [
                queryField,
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: typeField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: typeFilter == TypeProgramme.visite
                          ? typeVisiteField
                          : EabDateField(
                              label: 'Du',
                              value: dateDebut,
                              onChanged: onDateDebutChanged,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: typeFilter == TypeProgramme.visite
                          ? EabDateField(
                              label: 'Du',
                              value: dateDebut,
                              onChanged: onDateDebutChanged,
                            )
                          : EabDateField(
                              label: 'Au',
                              value: dateFin,
                              onChanged: onDateFinChanged,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: typeFilter == TypeProgramme.visite
                          ? EabDateField(
                              label: 'Au',
                              value: dateFin,
                              onChanged: onDateFinChanged,
                            )
                          : OutlinedButton.icon(
                              onPressed: onClear,
                              icon: const Icon(Icons.clear, size: 18),
                              label: const Text('Effacer'),
                            ),
                    ),
                  ],
                ),
                if (typeFilter == TypeProgramme.visite) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Effacer'),
                    ),
                  ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: queryField),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: typeField),
                if (typeFilter == TypeProgramme.visite) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: typeVisiteField),
                ],
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 160,
                  child: EabDateField(
                    label: 'Du',
                    value: dateDebut,
                    onChanged: onDateDebutChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 160,
                  child: EabDateField(
                    label: 'Au',
                    value: dateFin,
                    onChanged: onDateFinChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Effacer'),
                ),
              ],
            ),
    );
  }
}

class _ProgramSummaryStrip extends StatelessWidget {
  const _ProgramSummaryStrip({required this.programs, required this.compact});

  final List<Program> programs;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = programs
        .where((program) => program.date.isAfter(now))
        .length;
    final visits = programs
        .where((program) => program.type == TypeProgramme.visite)
        .length;
    final participants = programs.fold<int>(
      0,
      (total, program) =>
          total +
          (program.nombreHommes ?? 0) +
          (program.nombreFemmes ?? 0) +
          (program.nombreGarcons ?? 0) +
          (program.nombreFilles ?? 0),
    );

    final items = [
      _SummaryTile(
        label: 'Total',
        value: '${programs.length}',
        icon: Icons.event_note_outlined,
      ),
      _SummaryTile(
        label: 'A venir',
        value: '$upcoming',
        icon: Icons.upcoming_outlined,
        color: AppColors.info,
      ),
      _SummaryTile(
        label: 'Visites',
        value: '$visits',
        icon: Icons.handshake_outlined,
        color: AppColors.teal,
      ),
      _SummaryTile(
        label: 'Participants',
        value: '$participants',
        icon: Icons.groups_outlined,
        color: AppColors.success,
      ),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              SizedBox(width: 136, child: items[i]),
              if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramEmptyState extends StatelessWidget {
  const _ProgramEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 104),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 28,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Aucun programme trouve.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramLoadingState extends StatelessWidget {
  const _ProgramLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Chargement des programmes...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.dateTimeFormat,
    required this.assembleeName,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Program program;
  final DateFormat dateTimeFormat;
  final String assembleeName;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final participantTotal =
        (program.nombreHommes ?? 0) +
        (program.nombreFemmes ?? 0) +
        (program.nombreGarcons ?? 0) +
        (program.nombreFilles ?? 0);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgramTypeIcon(type: program.type),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeProgrammeLabels[program.type] ??
                              program.type.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateTimeFormat.format(program.date),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                    color: AppColors.error,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                program.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                assembleeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _MiniMetric(
                    icon: Icons.groups_outlined,
                    label: '$participantTotal pers.',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (program.type == TypeProgramme.visite &&
                      program.typeVisite != null)
                    Expanded(
                      child: _MiniMetric(
                        icon: Icons.handshake_outlined,
                        label: _typeVisiteLabels[program.typeVisite] ?? '-',
                      ),
                    )
                  else
                    Expanded(
                      child: _MiniMetric(
                        icon: Icons.chevron_right,
                        label: 'Voir details',
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramTypeIcon extends StatelessWidget {
  const _ProgramTypeIcon({required this.type, this.size = 40});

  final TypeProgramme type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = _styleForType(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.5),
    );
  }

  ({IconData icon, Color color}) _styleForType(TypeProgramme type) =>
      switch (type) {
        TypeProgramme.culte => (
          icon: Icons.church_outlined,
          color: AppColors.primary,
        ),
        TypeProgramme.evangelisationMasse ||
        TypeProgramme.evangelisationPorteAPorte => (
          icon: Icons.campaign_outlined,
          color: AppColors.error,
        ),
        TypeProgramme.visite => (
          icon: Icons.handshake_outlined,
          color: AppColors.teal,
        ),
        TypeProgramme.ecoleDuDimanche => (
          icon: Icons.school_outlined,
          color: AppColors.info,
        ),
        TypeProgramme.reunionPriere => (
          icon: Icons.volunteer_activism_outlined,
          color: AppColors.indigo,
        ),
        _ => (icon: Icons.event_note_outlined, color: AppColors.warning),
      };
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

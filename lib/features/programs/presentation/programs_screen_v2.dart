/// Écran Programmes v2 — migré vers le design system UI Kit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/models/program.dart';



import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import 'program_form_dialog.dart';

const _typeVisiteLabels = {
  TypeVisite.fidele: 'Fidèle',
  TypeVisite.autorite: 'Autorité',
  TypeVisite.partenaire: 'Partenaire',
  TypeVisite.autreAssemblee: 'Autre assemblée',
  TypeVisite.autre: 'Autre',
};

/// Écran de gestion des programmes (v2).
class ProgramsScreenV2 extends ConsumerStatefulWidget {
  const ProgramsScreenV2({super.key});

  @override
  ConsumerState<ProgramsScreenV2> createState() => _ProgramsScreenV2State();
}

class _ProgramsScreenV2State extends ConsumerState<ProgramsScreenV2> {
  String _query = '';
  TypeProgramme? _typeFilter;
  TypeVisite? _typeVisiteFilter;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);

    final programs = programsAsync.value ?? [];
    final assemblees = assembleesAsync.value ?? [];
    final assembleeById = {for (final a in assemblees) a.id: a};

    // Filtrage
    final filtered = programs.where((p) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchName =
            typeProgrammeLabels[p.type]!.toLowerCase().contains(q);
        final matchLoc = p.location.toLowerCase().contains(q);
        if (!matchName && !matchLoc) return false;
      }
      if (_typeFilter != null && p.type != _typeFilter) return false;
      if (_typeVisiteFilter != null &&
          (p.type != TypeProgramme.visite ||
              p.typeVisite != _typeVisiteFilter)) {
        return false;
      }
      if (_dateDebut != null && p.date.isBefore(_dateDebut!)) return false;
      if (_dateFin != null && p.date.isAfter(_dateFin!)) return false;
      if (assembleeActiveId != null &&
          p.idAssembleeLocale != assembleeActiveId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return AppShell(
      title: 'Programmes',
      currentRoute: '/programs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProgramFormV2(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau programme'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ContextHeader(showPorteeComptable: false),
              const SizedBox(height: AppSpacing.cardGap),

              // Filtres
              SectionCard(
                title: 'Filtres',
                child: Wrap(
                  spacing: AppSpacing.cardGap,
                  runSpacing: AppSpacing.cardGap,
                  children: [
                    SizedBox(
                      width: 260,
                      child: EabTextField(
                        label: 'Rechercher (type ou lieu)',
                        prefixIcon: Icons.search,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: EabSelectField<TypeProgramme?>(
                        label: 'Type de programme',
                        value: _typeFilter,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous')),
                          ...TypeProgramme.values.map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(typeProgrammeLabels[t]!),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _typeFilter = v;
                          if (_typeFilter != TypeProgramme.visite) {
                            _typeVisiteFilter = null;
                          }
                        }),
                      ),
                    ),
                    if (_typeFilter == TypeProgramme.visite)
                      SizedBox(
                        width: 200,
                        child: EabSelectField<TypeVisite?>(
                          label: 'Type de visite',
                          value: _typeVisiteFilter,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Tous')),
                            ...TypeVisite.values.map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(_typeVisiteLabels[t]!),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _typeVisiteFilter = v),
                        ),
                      ),
                    SizedBox(
                      width: 180,
                      child: EabDateField(
                        label: 'Du',
                        value: _dateDebut,
                        onChanged: (d) => setState(() => _dateDebut = d),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: EabDateField(
                        label: 'Au',
                        value: _dateFin,
                        onChanged: (d) => setState(() => _dateFin = d),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tableau
              SectionCard(
                title: 'Programmes (${filtered.length})',
                child: EabTable<Program>(
                  isLoading: programsAsync.isLoading && programs.isEmpty,
                  emptyMessage: 'Aucun programme trouvé',
                  emptyIcon: Icons.event_note,
                  items: filtered,
                  rowsPerPage: 15,
                  onRowTap: (p) => showProgramFormV2(context, program: p),
                  columns: [
                    EabColumn<Program>(
                      label: 'Type',
                      flex: 2,
                      cellBuilder: (p) =>
                          Text(typeProgrammeLabels[p.type] ?? ''),
                    ),
                    EabColumn<Program>(
                      label: 'Date',
                      flex: 2,
                      sortKeyExtractor: (p) => p.date,
                      cellBuilder: (p) =>
                          Text(dateFormatter.format(p.date)),
                    ),
                    EabColumn<Program>(
                      label: 'Lieu',
                      flex: 2,
                      cellBuilder: (p) => Text(
                        p.location,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    EabColumn<Program>(
                      label: 'Assemblée',
                      flex: 2,
                      cellBuilder: (p) => Text(
                        p.idAssembleeLocale != null
                            ? assembleeById[p.idAssembleeLocale!]?.nom ?? '—'
                            : '—',
                      ),
                    ),
                    EabColumn<Program>(
                      label: 'Participants',
                      flex: 2,
                      cellBuilder: (p) => Text(_formatParticipants(p)),
                    ),
                    EabColumn<Program>(
                      label: 'Conversions',
                      flex: 1,
                      cellBuilder: (p) => Text(_conversionsLabel(p)),
                    ),
                    EabColumn<Program>(
                      label: '',
                      flex: 1,
                      cellBuilder: (p) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                showProgramFormV2(context, program: p),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _confirmDelete(p),
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

  String _formatParticipants(Program p) {
    final h = p.nombreHommes ?? 0;
    final f = p.nombreFemmes ?? 0;
    final g = p.nombreGarcons ?? 0;
    final fi = p.nombreFilles ?? 0;
    final total = h + f + g + fi;
    return '$total pers.';
  }

  String _conversionsLabel(Program p) {
    final isEvangelisation =
        p.type == TypeProgramme.evangelisationMasse ||
        p.type == TypeProgramme.evangelisationPorteAPorte;
    if (!isEvangelisation) return '-';
    final conv = (p.conversionsHommes ?? 0) +
        (p.conversionsFemmes ?? 0) +
        (p.conversionsGarcons ?? 0) +
        (p.conversionsFilles ?? 0);
    return conv == 0 ? '-' : '$conv';
  }

  Future<void> _confirmDelete(Program program) async {
    final confirm = await EabDialog.confirm(
      context,
      title: 'Supprimer un programme',
      message:
          'Êtes-vous sûr de vouloir supprimer le programme ${typeProgrammeLabels[program.type]} ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirm == true) {
      await ref.read(programsProvider.notifier).removeProgram(program.id);
    }
  }
}

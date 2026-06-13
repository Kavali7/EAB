/// Calendrier des activites - vue mensuelle des programmes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/models/program.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';

import 'program_form_dialog.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final programs = programsAsync.value ?? [];
    final churchUnits = churchUnitsAsync.value ?? [];
    final churchUnitById = {for (final unit in churchUnits) unit.id: unit};
    final scopedPrograms = _programsForActiveScope(
      programs,
      churchUnitById,
      assembleeActiveId,
    );
    final monthPrograms = _programsForMonth(scopedPrograms);
    final byDay = _groupByDay(monthPrograms);
    final monthLabel = _capitalize(
      DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth),
    );
    final activeDays = byDay.length;
    final now = DateTime.now();
    final upcoming = monthPrograms.where((p) => !p.date.isBefore(now)).length;

    return AppShell(
      title: 'Calendrier des activites',
      currentRoute: '/calendar',
      showBackButton: true,
      backRoute: '/programs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProgramFormV2(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau programme'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final padding = compact ? AppSpacing.lg : AppSpacing.pagePadding;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ContextHeader(showPorteeComptable: false),
                    const SizedBox(height: AppSpacing.cardGap),
                    _MonthControls(
                      monthLabel: monthLabel,
                      onPrevious: _previousMonth,
                      onToday: _goToday,
                      onNext: _nextMonth,
                    ),
                    const SizedBox(height: AppSpacing.cardGap),
                    _SummaryRow(
                      compact: compact,
                      items: [
                        _SummaryItem(
                          label: 'Activites',
                          value: monthPrograms.length.toString(),
                          icon: Icons.event_available_outlined,
                          color: AppColors.primary,
                        ),
                        _SummaryItem(
                          label: 'Jours actifs',
                          value: activeDays.toString(),
                          icon: Icons.calendar_view_month_outlined,
                          color: AppColors.teal,
                        ),
                        _SummaryItem(
                          label: 'A venir',
                          value: upcoming.toString(),
                          icon: Icons.schedule_outlined,
                          color: AppColors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.cardGap),
                    if (compact) ...[
                      _CalendarPanel(
                        currentMonth: _currentMonth,
                        programsByDay: byDay,
                        onDayTap: _showDayDetail,
                        typeStyle: _typeStyle,
                      ),
                      const SizedBox(height: AppSpacing.cardGap),
                      _AgendaPanel(
                        programs: monthPrograms,
                        compact: true,
                        typeStyle: _typeStyle,
                        onTapProgram: (p) =>
                            showProgramFormV2(context, program: p),
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _CalendarPanel(
                              currentMonth: _currentMonth,
                              programsByDay: byDay,
                              onDayTap: _showDayDetail,
                              typeStyle: _typeStyle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.cardGap),
                          Expanded(
                            flex: 5,
                            child: _AgendaPanel(
                              programs: monthPrograms,
                              compact: false,
                              typeStyle: _typeStyle,
                              onTapProgram: (p) =>
                                  showProgramFormV2(context, program: p),
                            ),
                          ),
                        ],
                      ),
                    if (programsAsync.isLoading && programs.isEmpty) ...[
                      const SizedBox(height: AppSpacing.cardGap),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Program> _programsForMonth(List<Program> programs) {
    return programs.where((p) {
      return p.date.year == _currentMonth.year &&
          p.date.month == _currentMonth.month;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Program> _programsForActiveScope(
    List<Program> programs,
    Map<String, ChurchUnit> churchUnitById,
    String? assembleeActiveId,
  ) {
    if (assembleeActiveId == null) return programs;
    return programs.where((program) {
      if (program.idAssembleeLocale == assembleeActiveId) return true;
      final unit = program.churchUnitId == null
          ? null
          : churchUnitById[program.churchUnitId!];
      return unit?.legacyAssembleeId == assembleeActiveId;
    }).toList();
  }

  Map<int, List<Program>> _groupByDay(List<Program> programs) {
    final byDay = <int, List<Program>>{};
    for (final p in programs) {
      byDay.putIfAbsent(p.date.day, () => []).add(p);
    }
    return byDay;
  }

  void _showDayDetail(int day, List<Program> events) {
    final dateLabel = _capitalize(
      DateFormat(
        'EEEE d MMMM yyyy',
        'fr_FR',
      ).format(DateTime(_currentMonth.year, _currentMonth.month, day)),
    );

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final p = events[index];
                      return _ProgramCard(
                        program: p,
                        compact: true,
                        style: _typeStyle(p.type),
                        onTap: () {
                          Navigator.of(context).pop();
                          showProgramFormV2(context, program: p);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  _ProgramTypeStyle _typeStyle(TypeProgramme t) => switch (t) {
    TypeProgramme.culte => const _ProgramTypeStyle(
      icon: Icons.church,
      color: Colors.indigo,
    ),
    TypeProgramme.evangelisationMasse => const _ProgramTypeStyle(
      icon: Icons.campaign,
      color: Colors.orange,
    ),
    TypeProgramme.evangelisationPorteAPorte => const _ProgramTypeStyle(
      icon: Icons.door_front_door,
      color: Colors.teal,
    ),
    TypeProgramme.baptemes => const _ProgramTypeStyle(
      icon: Icons.water_drop,
      color: Colors.blue,
    ),
    TypeProgramme.mainsAssociation => const _ProgramTypeStyle(
      icon: Icons.handshake,
      color: Colors.green,
    ),
    TypeProgramme.sainteCene => const _ProgramTypeStyle(
      icon: Icons.wine_bar,
      color: Colors.purple,
    ),
    TypeProgramme.reunionPriere => _ProgramTypeStyle(
      icon: Icons.self_improvement,
      color: Colors.amber.shade700,
    ),
    TypeProgramme.mariage => const _ProgramTypeStyle(
      icon: Icons.favorite,
      color: Colors.pink,
    ),
    TypeProgramme.discipline => const _ProgramTypeStyle(
      icon: Icons.gavel,
      color: Colors.brown,
    ),
    TypeProgramme.visite => const _ProgramTypeStyle(
      icon: Icons.home_work,
      color: Colors.cyan,
    ),
    TypeProgramme.ecoleDuDimanche => _ProgramTypeStyle(
      icon: Icons.school,
      color: Colors.lime.shade700,
    ),
    TypeProgramme.autre => const _ProgramTypeStyle(
      icon: Icons.event,
      color: Colors.grey,
    ),
  };
}

class _ProgramTypeStyle {
  const _ProgramTypeStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class _MonthControls extends StatelessWidget {
  const _MonthControls({
    required this.monthLabel,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final String monthLabel;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: AppSpacing.sm),
                Text(monthLabel, style: AppTextStyles.sectionTitle),
              ],
            ),
            const SpacerLike(),
            IconButton.filledTonal(
              tooltip: 'Mois precedent',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            OutlinedButton.icon(
              onPressed: onToday,
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text("Aujourd'hui"),
            ),
            IconButton.filledTonal(
              tooltip: 'Mois suivant',
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class SpacerLike extends StatelessWidget {
  const SpacerLike({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 1);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.compact, required this.items});

  final bool compact;
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact ? 1 : 3;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.cardGap) /
            columns;
        return Wrap(
          spacing: AppSpacing.cardGap,
          runSpacing: AppSpacing.cardGap,
          children: [
            for (final item in items) SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(value, style: AppTextStyles.heading3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.currentMonth,
    required this.programsByDay,
    required this.onDayTap,
    required this.typeStyle,
  });

  final DateTime currentMonth;
  final Map<int, List<Program>> programsByDay;
  final void Function(int day, List<Program> events) onDayTap;
  final _ProgramTypeStyle Function(TypeProgramme type) typeStyle;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    ).weekday;
    final blanks = firstWeekday - 1;
    final totalCells = blanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final cellCount = rowCount * 7;
    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grille mensuelle', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final day in const [
                  'Lun',
                  'Mar',
                  'Mer',
                  'Jeu',
                  'Ven',
                  'Sam',
                  'Dim',
                ])
                  Expanded(
                    child: Center(
                      child: Text(day, style: AppTextStyles.caption),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: compact ? 4 : 8,
                    crossAxisSpacing: compact ? 4 : 8,
                    childAspectRatio: compact ? 0.82 : 1.05,
                  ),
                  itemCount: cellCount,
                  itemBuilder: (context, index) {
                    final day = index - blanks + 1;
                    if (day < 1 || day > daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final events = programsByDay[day] ?? const <Program>[];
                    final isToday =
                        today.year == currentMonth.year &&
                        today.month == currentMonth.month &&
                        today.day == day;
                    return _DayCell(
                      day: day,
                      events: events,
                      isToday: isToday,
                      typeStyle: typeStyle,
                      onTap: events.isEmpty
                          ? null
                          : () => onDayTap(day, events),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.typeStyle,
    required this.onTap,
  });

  final int day;
  final List<Program> events;
  final bool isToday;
  final _ProgramTypeStyle Function(TypeProgramme type) typeStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: isToday ? AppColors.primary : AppColors.divider,
            width: isToday ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: AppTextStyles.subtitle.copyWith(
                color: isToday ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            if (events.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 2,
                children: [
                  for (final event in events.take(4))
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: typeStyle(event.type).color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AgendaPanel extends StatelessWidget {
  const _AgendaPanel({
    required this.programs,
    required this.compact,
    required this.typeStyle,
    required this.onTapProgram,
  });

  final List<Program> programs;
  final bool compact;
  final _ProgramTypeStyle Function(TypeProgramme type) typeStyle;
  final ValueChanged<Program> onTapProgram;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${programs.length} activite${programs.length > 1 ? "s" : ""} ce mois',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            if (programs.isEmpty)
              const EmptyState(
                icon: Icons.event_busy,
                message: 'Aucune activite ce mois',
              )
            else
              Column(
                children: [
                  for (final program in programs)
                    _ProgramCard(
                      program: program,
                      compact: compact,
                      style: typeStyle(program.type),
                      onTap: () => onTapProgram(program),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.compact,
    required this.style,
    required this.onTap,
  });

  final Program program;
  final bool compact;
  final _ProgramTypeStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel = typeProgrammeLabels[program.type] ?? program.type.name;
    final date = DateFormat('EEE d MMM', 'fr_FR').format(program.date);
    final time = DateFormat('HH:mm', 'fr_FR').format(program.date);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(style.icon, color: style.color, size: 21),
        ),
        title: Text(
          typeLabel,
          style: AppTextStyles.subtitle,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$date - $time - ${program.location}',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
        trailing: program.participantIds.isNotEmpty
            ? Tooltip(
                message: 'Participants',
                child: Chip(
                  label: Text('${program.participantIds.length}'),
                  avatar: const Icon(Icons.people_outline, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
              )
            : null,
      ),
    );
  }
}

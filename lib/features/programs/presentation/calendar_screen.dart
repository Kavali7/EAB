/// Calendrier des activités — vue mensuelle des programmes.
///
/// Affiche un calendrier simplifié avec les programmes du mois.
/// Flèche retour pour revenir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/program.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import '../application/programs_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final programs = programsAsync.value ?? [];
    final dateFormat = DateFormat('HH:mm', 'fr_FR');
    final monthLabel =
        DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth);

    // Filtrer les programmes du mois courant
    final monthPrograms = programs.where((p) {
      return p.date.year == _currentMonth.year &&
          p.date.month == _currentMonth.month;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Grouper par jour
    final byDay = <int, List<Program>>{};
    for (final p in monthPrograms) {
      byDay.putIfAbsent(p.date.day, () => []).add(p);
    }

    // Jours du mois
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    return AppShell(
      title: 'Calendrier des activités',
      currentRoute: '/calendar',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ContextHeader(showPorteeComptable: false),
              const SizedBox(height: AppSpacing.cardGap),

              // ── Navigation mois ──
              SectionCard(
                title: monthLabel[0].toUpperCase() + monthLabel.substring(1),
                icon: Icons.calendar_month,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _currentMonth = DateTime(
                            DateTime.now().year, DateTime.now().month);
                      }),
                      child: const Text("Aujourd'hui"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // En-têtes jours de la semaine
                    Row(
                      children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(d,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      )),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 4),

                    // Grille du calendrier
                    ..._buildCalendarGrid(
                        daysInMonth, firstWeekday, byDay, context),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),

              // ── Liste des programmes du mois ──
              SectionCard(
                title: '${monthPrograms.length} activité${monthPrograms.length > 1 ? "s" : ""} ce mois',
                icon: Icons.event_note,
                child: monthPrograms.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: EmptyState(
                          icon: Icons.event_busy,
                          message: 'Aucune activité ce mois',
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: monthPrograms.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = monthPrograms[i];
                          final typeLabel =
                              typeProgrammeLabels[p.type] ?? p.type.name;
                          final style = _typeStyle(p.type);
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  style.color.withValues(alpha: 0.15),
                              child:
                                  Icon(style.icon, color: style.color, size: 18),
                            ),
                            title: Text(typeLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              '${DateFormat('EEEE d', 'fr_FR').format(p.date)} • ${dateFormat.format(p.date)} • ${p.location}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            trailing: p.participantIds.isNotEmpty
                                ? Chip(
                                    label: Text('${p.participantIds.length}',
                                        style: const TextStyle(fontSize: 11)),
                                    avatar: const Icon(Icons.people, size: 14),
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarGrid(
    int daysInMonth,
    int firstWeekday,
    Map<int, List<Program>> byDay,
    BuildContext context,
  ) {
    final rows = <Widget>[];
    var dayIndex = 1;
    final today = DateTime.now();

    // firstWeekday: 1=Mon, 7=Sun
    final blanks = firstWeekday - 1;

    var currentRow = <Widget>[];
    // Blanks before the 1st
    for (var i = 0; i < blanks; i++) {
      currentRow.add(const Expanded(child: SizedBox(height: 48)));
    }

    while (dayIndex <= daysInMonth) {
      final day = dayIndex;
      final events = byDay[day] ?? [];
      final isToday = today.year == _currentMonth.year &&
          today.month == _currentMonth.month &&
          today.day == day;

      currentRow.add(Expanded(
        child: InkWell(
          onTap: events.isNotEmpty
              ? () => _showDayDetail(context, day, events)
              : null,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isToday
                  ? ChurchTheme.navy.withValues(alpha: 0.08)
                  : null,
              border: isToday
                  ? Border.all(color: ChurchTheme.navy, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.w400,
                    color: isToday ? ChurchTheme.navy : null,
                  ),
                ),
                if (events.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((e) {
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _typeStyle(e.type).color,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ));

      if (currentRow.length == 7) {
        rows.add(Row(children: currentRow));
        rows.add(const SizedBox(height: 2));
        currentRow = [];
      }
      dayIndex++;
    }

    // Fill remaining cells
    while (currentRow.length < 7) {
      currentRow.add(const Expanded(child: SizedBox(height: 48)));
    }
    if (currentRow.isNotEmpty) {
      rows.add(Row(children: currentRow));
    }

    return rows;
  }

  void _showDayDetail(BuildContext context, int day, List<Program> events) {
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(
      DateTime(_currentMonth.year, _currentMonth.month, day),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel[0].toUpperCase() + dateLabel.substring(1),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...events.map((p) {
              final style = _typeStyle(p.type);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(style.icon, color: style.color),
                title: Text(typeProgrammeLabels[p.type] ?? p.type.name),
                subtitle: Text(p.location),
              );
            }),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _typeStyle(TypeProgramme t) => switch (t) {
        TypeProgramme.culte => (icon: Icons.church, color: Colors.indigo),
        TypeProgramme.evangelisationMasse =>
          (icon: Icons.campaign, color: Colors.orange),
        TypeProgramme.evangelisationPorteAPorte =>
          (icon: Icons.door_front_door, color: Colors.teal),
        TypeProgramme.baptemes =>
          (icon: Icons.water_drop, color: Colors.blue),
        TypeProgramme.mainsAssociation =>
          (icon: Icons.handshake, color: Colors.green),
        TypeProgramme.sainteCene =>
          (icon: Icons.wine_bar, color: Colors.purple),
        TypeProgramme.reunionPriere =>
          (icon: Icons.self_improvement, color: Colors.amber.shade700),
        TypeProgramme.mariage =>
          (icon: Icons.favorite, color: Colors.pink),
        TypeProgramme.discipline =>
          (icon: Icons.gavel, color: Colors.brown),
        TypeProgramme.visite =>
          (icon: Icons.home_work, color: Colors.cyan),
        TypeProgramme.ecoleDuDimanche =>
          (icon: Icons.school, color: Colors.lime.shade700),
        TypeProgramme.autre =>
          (icon: Icons.event, color: Colors.grey),
      };
}

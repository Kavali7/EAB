/// Dashboard v2 — design amélioré avec UI Kit.
///
/// Améliorations par rapport au v1 :
/// - [KpiCard] avec icônes colorées et tendance optionnelle
/// - [QuickActionCard] raccourcis d'actions rapides
/// - [SkeletonLoader] pendant le chargement
/// - [AppSpacing] pour les espacements
/// - [SectionCard] pour les sections
/// - Conserve les graphiques fl_chart existants
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/ecriture_comptable.dart';
import 'package:eab/models/program.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/features/exercices/application/exercices_providers.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';


class DashboardScreenV2 extends ConsumerWidget {
  const DashboardScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    final programsAsync = ref.watch(programsProvider);
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final members = membersAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final ecritures = ecrituresAsync.value ?? [];
    final _ = assembleesAsync.value ?? [];
    final isLoading = membersAsync.isLoading ||
        programsAsync.isLoading ||
        ecrituresAsync.isLoading ||
        assembleesAsync.isLoading;

    final filteredMembers = assembleeActiveId == null
        ? members
        : members
            .where((m) => m.idAssembleeLocale == assembleeActiveId)
            .toList();
    final filteredPrograms = assembleeActiveId == null
        ? programs
        : programs
            .where((p) => p.idAssembleeLocale == assembleeActiveId)
            .toList();
    final filteredEcritures = assembleeActiveId == null
        ? ecritures
        : ecritures
            .where((e) => e.idAssembleeLocale == assembleeActiveId)
            .toList();

    // Totaux financiers
    double totalIncome = 0;
    double totalExpense = 0;
    for (final ecriture in filteredEcritures) {
      for (final ligne in ecriture.lignes) {
        totalIncome += ligne.credit ?? 0;
        totalExpense += ligne.debit ?? 0;
      }
    }

    final maleCount =
        filteredMembers.where((m) => m.gender == Gender.male).length;
    final femaleCount =
        filteredMembers.where((m) => m.gender == Gender.female).length;
    final baptized =
        filteredMembers.where((m) => m.baptismDate != null).length;
    final newConverts = filteredMembers
        .where(
          (m) =>
              m.baptismDate != null &&
              m.baptismDate!.isAfter(
                DateTime.now().subtract(const Duration(days: 90)),
              ),
        )
        .length;

    final monthly = _monthlyCashflow(filteredEcritures);
    final programStats = _programDistribution(filteredPrograms);
    final maritalStats = _maritalDistribution(filteredMembers);

    return AppShell(
      title: 'Tableau de bord',
      currentRoute: '/',
      body: isLoading &&
              members.isEmpty &&
              programs.isEmpty &&
              ecritures.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: SkeletonLoader(lineCount: 8, lineHeight: 24),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ContextHeader(showPorteeComptable: false),
                    const SizedBox(height: AppSpacing.cardGap),

                    // ── Raccourcis d'actions rapides ──
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        QuickActionCard(
                          label: 'Nouveau fidèle',
                          icon: Icons.person_add,
                          onTap: () => Navigator.pushNamed(
                              context, '/members'),
                        ),
                        QuickActionCard(
                          label: 'Nouveau programme',
                          icon: Icons.event_note,
                          onTap: () => Navigator.pushNamed(
                              context, '/programs'),
                          color: Colors.indigo,
                        ),
                        QuickActionCard(
                          label: 'Nouvelle écriture',
                          icon: Icons.receipt_long,
                          onTap: () => Navigator.pushNamed(
                              context, '/accounting'),
                          color: Colors.green[700],
                        ),
                        QuickActionCard(
                          label: 'Rapport mensuel',
                          icon: Icons.description,
                          onTap: () => Navigator.pushNamed(
                              context, '/rapport-mensuel'),
                          color: Colors.orange[700],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── KPI Cards ──
                    Wrap(
                      spacing: AppSpacing.cardGap,
                      runSpacing: AppSpacing.cardGap,
                      children: [
                        SizedBox(
                          width: 260,
                          child: KpiCard(
                            title: 'Fidèles',
                            value: '$maleCount H / $femaleCount F',
                            subtitle:
                                'Total ${filteredMembers.length} | Baptisés $baptized',
                            icon: Icons.people_alt_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () =>
                                Navigator.pushNamed(context, '/members'),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: KpiCard(
                            title: 'Recettes',
                            value: currencyFormatter.format(totalIncome),
                            subtitle:
                                'Sur ${filteredEcritures.length} écritures',
                            icon: Icons.trending_up,
                            color: Colors.green[700],
                            trend: totalIncome > totalExpense
                                ? KpiTrend.up
                                : KpiTrend.down,
                            trendLabel: totalIncome > 0
                                ? '${((totalIncome - totalExpense) / totalIncome * 100).abs().toStringAsFixed(0)}%'
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: KpiCard(
                            title: 'Dépenses',
                            value: currencyFormatter.format(totalExpense),
                            subtitle:
                                'Balance ${currencyFormatter.format(totalIncome - totalExpense)}',
                            icon: Icons.trending_down,
                            color: Colors.red[600],
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: KpiCard(
                            title: 'Programmes',
                            value: '${filteredPrograms.length}',
                            subtitle: programStats.entries.isNotEmpty
                                ? '${programStats.entries.first.value} ${programStats.entries.first.key}'
                                : 'Aucun',
                            icon: Icons.event_note_outlined,
                            color: Colors.indigo,
                            onTap: () =>
                                Navigator.pushNamed(context, '/programs'),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: KpiCard(
                            title: 'Nouveaux convertis (90j)',
                            value: '$newConverts',
                            subtitle: 'Baptisés récents',
                            icon: Icons.star_rate_outlined,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Alertes ──
                    Builder(builder: (_) {
                      final alerts = <Widget>[];
                      final brouillons = filteredEcritures
                          .where((e) => e.statut.name == 'brouillon')
                          .length;
                      if (brouillons > 0) {
                        alerts.add(_alertTile(
                          icon: Icons.edit_note,
                          color: Colors.orange,
                          text: '$brouillons écriture${brouillons > 1 ? "s" : ""} en brouillon',
                          actionLabel: 'Voir',
                          onAction: () => Navigator.pushNamed(context, '/accounting'),
                        ));
                      }

                      final exerciceAsync = ref.watch(exerciceOuvertProvider);
                      exerciceAsync.when(
                        data: (ex) {
                          if (ex == null) {
                            alerts.add(_alertTile(
                              icon: Icons.warning_amber,
                              color: Colors.red,
                              text: 'Aucun exercice ouvert — les saisies sont bloquées',
                              actionLabel: 'Ouvrir',
                              onAction: () => Navigator.pushNamed(context, '/accounting-exercices'),
                            ));
                          }
                        },
                        error: (_, __) {},
                        loading: () {},
                      );

                      if (newConverts > 0) {
                        alerts.add(_alertTile(
                          icon: Icons.celebration,
                          color: Colors.green,
                          text: '$newConverts nouveau${newConverts > 1 ? "x" : ""} converti${newConverts > 1 ? "s" : ""} ces 90 derniers jours !',
                        ));
                      }

                      if (alerts.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alertes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          ...alerts,
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      );
                    }),

                    // ── Activité récente ──
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final recentEcritures = [...filteredEcritures]
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final recentMembers = [...filteredMembers];

                      return Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.lg,
                        children: [
                          // Dernières écritures
                          SizedBox(
                            width: isWide
                                ? constraints.maxWidth * 0.48
                                : constraints.maxWidth,
                            child: SectionCard(
                              title: 'Dernières écritures',
                              child: Column(
                                children: [
                                  if (recentEcritures.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Aucune écriture', style: TextStyle(color: Colors.grey)),
                                    )
                                  else
                                    ...recentEcritures.take(5).map((e) => ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                        child: const Icon(Icons.receipt_long, size: 16, color: Colors.blue),
                                      ),
                                      title: Text(e.libelle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(
                                        '${dateFormatter.format(e.date)} • ${e.referencePiece ?? ""}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      trailing: e.statut.name == 'brouillon'
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('Brouillon', style: TextStyle(fontSize: 10, color: Colors.orange)),
                                            )
                                          : null,
                                    )),
                                ],
                              ),
                            ),
                          ),
                          // Derniers membres
                          SizedBox(
                            width: isWide
                                ? constraints.maxWidth * 0.48
                                : constraints.maxWidth,
                            child: SectionCard(
                              title: 'Derniers fidèles inscrits',
                              child: Column(
                                children: [
                                  if (recentMembers.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Aucun fidèle', style: TextStyle(color: Colors.grey)),
                                    )
                                  else
                                    ...recentMembers.take(5).map((m) => ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: ChurchTheme.navy.withOpacity(0.1),
                                        child: Text(
                                          m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ChurchTheme.navy),
                                        ),
                                      ),
                                      title: Text(m.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(
                                        m.phone ?? m.email ?? '',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Graphiques ──
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        return Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: [
                            // Flux mensuels
                            SizedBox(
                              width: isWide
                                  ? constraints.maxWidth * 0.55
                                  : constraints.maxWidth,
                              child: SectionCard(
                                title: 'Flux mensuels',
                                child: SizedBox(
                                  height: 240,
                                  child: LineChart(
                                    _cashflowLineChart(monthly),
                                  ),
                                ),
                              ),
                            ),
                            // Répartition par genre
                            SizedBox(
                              width: isWide
                                  ? constraints.maxWidth * 0.4 - 16
                                  : constraints.maxWidth,
                              child: SectionCard(
                                title: 'Répartition par genre',
                                child: SizedBox(
                                  height: 240,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          value: maleCount.toDouble(),
                                          color: ChurchTheme.navy,
                                          title: 'Hommes',
                                        ),
                                        PieChartSectionData(
                                          value: femaleCount.toDouble(),
                                          color: ChurchTheme.gold,
                                          title: 'Femmes',
                                        ),
                                      ],
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Statut marital
                            SizedBox(
                              width: isWide
                                  ? constraints.maxWidth * 0.4 - 16
                                  : constraints.maxWidth,
                              child: SectionCard(
                                title: 'Statut marital',
                                child: SizedBox(
                                  height: 240,
                                  child: PieChart(
                                    PieChartData(
                                      sections: maritalStats.entries
                                          .map(
                                            (e) => PieChartSectionData(
                                              value: e.value.toDouble(),
                                              title: e.key,
                                              color:
                                                  _colorForMarital(e.key),
                                            ),
                                          )
                                          .toList(),
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Programmes par type
                            SizedBox(
                              width: isWide
                                  ? constraints.maxWidth * 0.45
                                  : constraints.maxWidth,
                              child: SectionCard(
                                title: 'Programmes par type',
                                child: SizedBox(
                                  height: 240,
                                  child: BarChart(
                                    _programBarChart(programStats),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de données (identiques au v1)
  // ---------------------------------------------------------------------------

  Map<String, int> _programDistribution(List<Program> programs) {
    final Map<String, int> stats = {};
    for (final p in programs) {
      final label = programTypeLabels[p.type] ?? p.type.name;
      stats[label] = (stats[label] ?? 0) + 1;
    }
    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  Map<String, int> _maritalDistribution(List members) {
    final Map<String, int> stats = {};
    for (final m in members) {
      final label = maritalStatusLabels[m.maritalStatus] ?? 'Autre';
      stats[label] = (stats[label] ?? 0) + 1;
    }
    return stats;
  }

  Color _colorForMarital(String label) {
    switch (label) {
      case 'Marié':
        return Colors.teal;
      case 'Célibataire':
        return Colors.purple;
      case 'Divorcé':
        return Colors.blueGrey;
      case 'Veuf/Veuve':
        return Colors.brown;
      default:
        return ChurchTheme.navy;
    }
  }

  Map<int, _CashflowPoint> _monthlyCashflow(
      List<EcritureComptable> ecritures) {
    final Map<int, _CashflowPoint> map = {};
    for (final ecriture in ecritures) {
      final key = DateTime(ecriture.date.year, ecriture.date.month)
          .millisecondsSinceEpoch;
      final existing = map[key] ??
          _CashflowPoint(
              DateTime(ecriture.date.year, ecriture.date.month), 0, 0);
      double creditSum = 0;
      double debitSum = 0;
      for (final ligne in ecriture.lignes) {
        creditSum += ligne.credit ?? 0;
        debitSum += ligne.debit ?? 0;
      }
      map[key] = existing.copyWith(
        income: existing.income + creditSum,
        expense: existing.expense + debitSum,
      );
    }
    final sorted = map.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    return {
      for (final item in sorted) item.month.millisecondsSinceEpoch: item
    };
  }

  LineChartData _cashflowLineChart(Map<int, _CashflowPoint> data) {
    final points = data.values.toList();
    if (points.isEmpty) {
      final now = DateTime.now();
      points.add(_CashflowPoint(now, 0, 0));
    }
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), points[i].income / 1000));
      expenseSpots.add(FlSpot(i.toDouble(), points[i].expense / 1000));
    }
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  monthFormatter.format(points[index].month),
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}k'),
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: Colors.green[700],
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: Colors.red[600],
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  BarChartData _programBarChart(Map<String, int> data) {
    final entries = data.entries.toList();
    return BarChartData(
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= entries.length) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  entries[index].key,
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < entries.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: ChurchTheme.navy,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
      ],
    );
  }

  static Widget _alertTile({
    required IconData icon,
    required Color color,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color.withOpacity(0.9))),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 30),
              ),
              child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _CashflowPoint {
  const _CashflowPoint(this.month, this.income, this.expense);

  final DateTime month;
  final double income;
  final double expense;

  _CashflowPoint copyWith(
      {DateTime? month, double? income, double? expense}) {
    return _CashflowPoint(
      month ?? this.month,
      income ?? this.income,
      expense ?? this.expense,
    );
  }
}

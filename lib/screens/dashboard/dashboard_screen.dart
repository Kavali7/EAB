import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/accounting_entry.dart';
import '../../models/program.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/members_provider.dart';
import '../../providers/programs_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    final programsAsync = ref.watch(programsProvider);
    final entriesAsync = ref.watch(accountingEntriesProvider);
    final members = membersAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final entries = entriesAsync.value ?? [];
    final isLoading =
        membersAsync.isLoading &&
        programsAsync.isLoading &&
        entriesAsync.isLoading;

    final totalIncome = entries
        .where((e) => e.type == AccountingType.income)
        .fold<double>(0, (p, e) => p + e.amount);
    final totalExpense = entries
        .where((e) => e.type == AccountingType.expense)
        .fold<double>(0, (p, e) => p + e.amount);
    final maleCount = members.where((m) => m.gender == Gender.male).length;
    final femaleCount = members.where((m) => m.gender == Gender.female).length;
    final baptized = members.where((m) => m.baptismDate != null).length;
    final newConverts = members
        .where(
          (m) =>
              m.baptismDate != null &&
              m.baptismDate!.isAfter(
                DateTime.now().subtract(const Duration(days: 90)),
              ),
        )
        .length;

    final monthly = _monthlyCashflow(entries);
    final programStats = _programDistribution(programs);
    final maritalStats = _maritalDistribution(members);

    return AppShell(
      title: 'Tableau de bord',
      currentRoute: '/',
      body: isLoading && members.isEmpty && programs.isEmpty && entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Fideles',
                          value: '$maleCount H / $femaleCount F',
                          subtitle:
                              'Total ${members.length} | Baptises $baptized',
                          icon: Icons.people_alt_outlined,
                          color: ChurchTheme.navy,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Recettes du mois',
                          value: currencyFormatter.format(totalIncome),
                          subtitle: 'Sur ${entries.length} ecritures',
                          icon: Icons.trending_up,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Depenses du mois',
                          value: currencyFormatter.format(totalExpense),
                          subtitle:
                              'Balance ${currencyFormatter.format(totalIncome - totalExpense)}',
                          icon: Icons.trending_down,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Programmes planifies',
                          value: '${programs.length}',
                          subtitle:
                              'Dont ${programStats.entries.isNotEmpty ? programStats.entries.first.value : 0} ${programStats.entries.isNotEmpty ? programStats.entries.first.key : ''}',
                          icon: Icons.event_note_outlined,
                          color: Colors.indigo,
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Nouveaux convertis (90j)',
                          value: '$newConverts',
                          subtitle: 'Baptises recents',
                          icon: Icons.star_rate_outlined,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isWide
                                ? constraints.maxWidth * 0.55
                                : constraints.maxWidth,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Flux mensuels',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 240,
                                      child: LineChart(
                                        _cashflowLineChart(monthly),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isWide
                                ? constraints.maxWidth * 0.4 - 16
                                : constraints.maxWidth,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Repartition par genre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isWide
                                ? constraints.maxWidth * 0.4 - 16
                                : constraints.maxWidth,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Statut marital',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 240,
                                      child: PieChart(
                                        PieChartData(
                                          sections: maritalStats.entries
                                              .map(
                                                (e) => PieChartSectionData(
                                                  value: e.value.toDouble(),
                                                  title: e.key,
                                                  color: _colorForMarital(
                                                    e.key,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          sectionsSpace: 4,
                                          centerSpaceRadius: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isWide
                                ? constraints.maxWidth * 0.45
                                : constraints.maxWidth,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Programmes par type',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 240,
                                      child: BarChart(
                                        _programBarChart(programStats),
                                      ),
                                    ),
                                  ],
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
    );
  }

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
      case 'Marie':
        return Colors.teal;
      case 'Celibataire':
        return Colors.purple;
      case 'Divorce':
        return Colors.blueGrey;
      case 'Veuf/Veuve':
        return Colors.brown;
      default:
        return ChurchTheme.navy;
    }
  }

  Map<int, _CashflowPoint> _monthlyCashflow(List<AccountingEntry> entries) {
    final Map<int, _CashflowPoint> map = {};
    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month).millisecondsSinceEpoch;
      final existing =
          map[key] ?? _CashflowPoint(DateTime(e.date.year, e.date.month), 0, 0);
      if (e.type == AccountingType.income) {
        map[key] = existing.copyWith(income: existing.income + e.amount);
      } else {
        map[key] = existing.copyWith(expense: existing.expense + e.amount);
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    return {for (final item in sorted) item.month.millisecondsSinceEpoch: item};
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
              if (index < 0 || index >= points.length) return const SizedBox();
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= entries.length) return const SizedBox();
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
}

class _CashflowPoint {
  const _CashflowPoint(this.month, this.income, this.expense);

  final DateTime month;
  final double income;
  final double expense;

  _CashflowPoint copyWith({DateTime? month, double? income, double? expense}) {
    return _CashflowPoint(
      month ?? this.month,
      income ?? this.income,
      expense ?? this.expense,
    );
  }
}

library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/core/utils/church_unit_scope.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/exercices/application/exercices_providers.dart';
import 'package:eab/models/ecriture_comptable.dart';
import 'package:eab/models/program.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';

class DashboardScreenV2 extends ConsumerWidget {
  const DashboardScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    final programsAsync = ref.watch(programsProvider);
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider);
    final assembleesAsync = ref.watch(assembleesLocalesProvider);
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final assembleeActiveId = ref.watch(assembleeActiveIdProvider);
    final churchUnitActiveId = ref.watch(churchUnitActiveIdProvider);

    final members = membersAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final ecritures = ecrituresAsync.value ?? [];
    final churchUnits = churchUnitsAsync.value ?? [];
    final isLoading =
        membersAsync.isLoading ||
        programsAsync.isLoading ||
        ecrituresAsync.isLoading ||
        assembleesAsync.isLoading ||
        churchUnitsAsync.isLoading;
    final scope = ChurchUnitScope.fromActiveContext(
      units: churchUnits,
      activeChurchUnitId: churchUnitActiveId,
      activeAssembleeId: assembleeActiveId,
    );

    final filteredMembers = members
        .where(
          (m) => scope.contains(
            churchUnitId: m.churchUnitId,
            legacyAssembleeId: m.idAssembleeLocale,
          ),
        )
        .toList();
    final filteredPrograms = programs
        .where(
          (p) => scope.contains(
            churchUnitId: p.churchUnitId,
            legacyAssembleeId: p.idAssembleeLocale,
          ),
        )
        .toList();
    final filteredEcritures = ecritures
        .where(
          (e) => scope.contains(
            churchUnitId: e.churchUnitId,
            legacyAssembleeId: e.idAssembleeLocale,
          ),
        )
        .toList();

    double totalIncome = 0;
    double totalExpense = 0;
    for (final ecriture in filteredEcritures) {
      for (final ligne in ecriture.lignes) {
        totalIncome += ligne.credit ?? 0;
        totalExpense += ligne.debit ?? 0;
      }
    }

    final maleCount = filteredMembers
        .where((m) => m.gender == Gender.male)
        .length;
    final femaleCount = filteredMembers
        .where((m) => m.gender == Gender.female)
        .length;
    final baptized = filteredMembers.where((m) => m.baptismDate != null).length;
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
      body:
          isLoading && members.isEmpty && programs.isEmpty && ecritures.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: SkeletonLoader(lineCount: 8, lineHeight: 24),
            )
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ContextHeader(showPorteeComptable: false),
                        const SizedBox(height: AppSpacing.cardGap),
                        _DashboardCommandBar(
                          actions: [
                            _DashboardAction(
                              label: 'Nouveau fidele',
                              icon: Icons.person_add,
                              color: AppColors.primary,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/members'),
                            ),
                            _DashboardAction(
                              label: 'Nouveau programme',
                              icon: Icons.event_note,
                              color: AppColors.indigo,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/programs'),
                            ),
                            _DashboardAction(
                              label: 'Nouvelle ecriture',
                              icon: Icons.receipt_long,
                              color: AppColors.success,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/accounting'),
                            ),
                            _DashboardAction(
                              label: 'Rapport mensuel',
                              icon: Icons.description,
                              color: AppColors.secondary,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/reports-rapport-mensuel',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ResponsiveKpiGrid(
                          children: [
                            KpiCard(
                              title: 'Fideles',
                              value: 'H: $maleCount | F: $femaleCount',
                              subtitle:
                                  'Total ${filteredMembers.length} | Baptises $baptized',
                              icon: Icons.people_alt_outlined,
                              color: AppColors.primary,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/members'),
                            ),
                            KpiCard(
                              title: 'Recettes',
                              value: currencyFormatter.format(totalIncome),
                              subtitle:
                                  'Sur ${filteredEcritures.length} ecritures',
                              icon: Icons.trending_up,
                              color: AppColors.success,
                              trend: totalIncome > totalExpense
                                  ? KpiTrend.up
                                  : KpiTrend.down,
                              trendLabel: totalIncome > 0
                                  ? '${((totalIncome - totalExpense) / totalIncome * 100).abs().toStringAsFixed(0)}%'
                                  : null,
                            ),
                            KpiCard(
                              title: 'Depenses',
                              value: currencyFormatter.format(totalExpense),
                              subtitle:
                                  'Balance ${currencyFormatter.format(totalIncome - totalExpense)}',
                              icon: Icons.trending_down,
                              color: AppColors.error,
                            ),
                            KpiCard(
                              title: 'Programmes',
                              value: '${filteredPrograms.length}',
                              subtitle: programStats.entries.isNotEmpty
                                  ? '${programStats.entries.first.value} ${programStats.entries.first.key}'
                                  : 'Aucun programme',
                              icon: Icons.event_note_outlined,
                              color: AppColors.indigo,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/programs'),
                            ),
                            KpiCard(
                              title: 'Nouveaux convertis',
                              value: '$newConverts',
                              subtitle: '90 derniers jours',
                              icon: Icons.star_rate_outlined,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AlertsBlock(
                          filteredEcritures: filteredEcritures,
                          newConverts: newConverts,
                          exerciceAsync: ref.watch(exerciceOuvertProvider),
                        ),
                        _RecentActivityBlock(
                          filteredEcritures: filteredEcritures,
                          filteredMembers: filteredMembers,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChartsBlock(
                          monthly: monthly,
                          maleCount: maleCount,
                          femaleCount: femaleCount,
                          maritalStats: maritalStats,
                          programStats: programStats,
                          cashflowLineChart: _cashflowLineChart,
                          programBarChart: _programBarChart,
                          colorForMarital: _colorForMarital,
                        ),
                      ],
                    ),
                  ),
                ),
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
        return AppColors.teal;
      case 'Celibataire':
        return AppColors.indigo;
      case 'Divorce':
        return Colors.blueGrey;
      case 'Veuf/Veuve':
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }

  Map<int, _CashflowPoint> _monthlyCashflow(List<EcritureComptable> ecritures) {
    final Map<int, _CashflowPoint> map = {};
    for (final ecriture in ecritures) {
      final key = DateTime(
        ecriture.date.year,
        ecriture.date.month,
      ).millisecondsSinceEpoch;
      final existing =
          map[key] ??
          _CashflowPoint(
            DateTime(ecriture.date.year, ecriture.date.month),
            0,
            0,
          );
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
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
          color: AppColors.success,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: AppColors.error,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                color: AppColors.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
      ],
    );
  }
}

class _DashboardCommandBar extends StatelessWidget {
  const _DashboardCommandBar({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions
            .map(
              (action) => _CommandButton(
                label: action.label,
                icon: action.icon,
                color: action.color,
                onTap: action.onTap,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveKpiGrid extends StatelessWidget {
  const _ResponsiveKpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.cardGap)) /
            columns;
        return Wrap(
          spacing: AppSpacing.cardGap,
          runSpacing: AppSpacing.cardGap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _AlertsBlock extends StatelessWidget {
  const _AlertsBlock({
    required this.filteredEcritures,
    required this.newConverts,
    required this.exerciceAsync,
  });

  final List<EcritureComptable> filteredEcritures;
  final int newConverts;
  final AsyncValue<Object?> exerciceAsync;

  @override
  Widget build(BuildContext context) {
    final alerts = <Widget>[];
    final brouillons = filteredEcritures
        .where((e) => e.statut.name == 'brouillon')
        .length;

    if (brouillons > 0) {
      alerts.add(
        _alertTile(
          icon: Icons.edit_note,
          color: AppColors.warning,
          text: '$brouillons ecriture${brouillons > 1 ? "s" : ""} en brouillon',
          actionLabel: 'Voir',
          onAction: () => Navigator.pushNamed(context, '/accounting'),
        ),
      );
    }

    exerciceAsync.when(
      data: (ex) {
        if (ex == null) {
          alerts.add(
            _alertTile(
              icon: Icons.warning_amber,
              color: AppColors.error,
              text: 'Aucun exercice ouvert. Les saisies sont bloquees.',
              actionLabel: 'Ouvrir',
              onAction: () =>
                  Navigator.pushNamed(context, '/accounting-exercices'),
            ),
          );
        }
      },
      error: (_, __) {},
      loading: () {},
    );

    if (newConverts > 0) {
      alerts.add(
        _alertTile(
          icon: Icons.celebration,
          color: AppColors.success,
          text:
              '$newConverts nouveau${newConverts > 1 ? "x" : ""} converti${newConverts > 1 ? "s" : ""} ces 90 derniers jours',
        ),
      );
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SectionCard(
        title: 'Alertes',
        child: Column(children: alerts),
      ),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.95),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                minimumSize: const Size(0, 32),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

class _RecentActivityBlock extends StatelessWidget {
  const _RecentActivityBlock({
    required this.filteredEcritures,
    required this.filteredMembers,
  });

  final List<EcritureComptable> filteredEcritures;
  final List<dynamic> filteredMembers;

  @override
  Widget build(BuildContext context) {
    final recentEcritures = [...filteredEcritures]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentMembers = [...filteredMembers];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final width = isWide
            ? (constraints.maxWidth - AppSpacing.lg) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: width,
              child: SectionCard(
                title: 'Dernieres ecritures',
                child: _RecentEcrituresList(
                  items: recentEcritures.take(5).toList(),
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: SectionCard(
                title: 'Derniers fideles inscrits',
                child: _RecentMembersList(
                  items: recentMembers.take(5).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentEcrituresList extends StatelessWidget {
  const _RecentEcrituresList({required this.items});

  final List<EcritureComptable> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyInlineState(label: 'Aucune ecriture recente');
    }
    return Column(
      children: [
        for (final e in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: _SoftIcon(
              icon: Icons.receipt_long,
              color: AppColors.accent,
            ),
            title: Text(
              e.libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${dateFormatter.format(e.date)} | ${e.referencePiece ?? ""}',
              style: AppTextStyles.caption,
            ),
            trailing: e.statut.name == 'brouillon'
                ? const _StatusPill(label: 'Brouillon')
                : null,
          ),
      ],
    );
  }
}

class _RecentMembersList extends StatelessWidget {
  const _RecentMembersList({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyInlineState(label: 'Aucun fidele recent');
    }
    return Column(
      children: [
        for (final m in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              child: Text(
                m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              m.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              m.phone ?? m.email ?? '',
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }
}

class _ChartsBlock extends StatelessWidget {
  const _ChartsBlock({
    required this.monthly,
    required this.maleCount,
    required this.femaleCount,
    required this.maritalStats,
    required this.programStats,
    required this.cashflowLineChart,
    required this.programBarChart,
    required this.colorForMarital,
  });

  final Map<int, _CashflowPoint> monthly;
  final int maleCount;
  final int femaleCount;
  final Map<String, int> maritalStats;
  final Map<String, int> programStats;
  final LineChartData Function(Map<int, _CashflowPoint>) cashflowLineChart;
  final BarChartData Function(Map<String, int>) programBarChart;
  final Color Function(String) colorForMarital;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final half = isWide
            ? (constraints.maxWidth - AppSpacing.lg) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: isWide
                  ? constraints.maxWidth * 0.58
                  : constraints.maxWidth,
              child: SectionCard(
                title: 'Flux mensuels',
                child: SizedBox(
                  height: 250,
                  child: LineChart(cashflowLineChart(monthly)),
                ),
              ),
            ),
            SizedBox(
              width: isWide
                  ? constraints.maxWidth -
                        (constraints.maxWidth * 0.58) -
                        AppSpacing.lg
                  : constraints.maxWidth,
              child: SectionCard(
                title: 'Repartition par genre',
                child: _DistributionDonut(
                  items: [
                    _DistributionDatum(
                      label: 'Hommes',
                      value: maleCount,
                      color: AppColors.primary,
                    ),
                    _DistributionDatum(
                      label: 'Femmes',
                      value: femaleCount,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: SectionCard(
                title: 'Statut marital',
                child: _DistributionDonut(
                  items: maritalStats.entries
                      .map(
                        (e) => _DistributionDatum(
                          label: e.key,
                          value: e.value,
                          color: colorForMarital(e.key),
                        ),
                      )
                      .toList(),
                  emptyLabel: 'Aucune donnee',
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: SectionCard(
                title: 'Programmes par type',
                child: SizedBox(
                  height: 250,
                  child: programStats.isEmpty
                      ? const _EmptyInlineState(label: 'Aucun programme')
                      : BarChart(programBarChart(programStats)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DistributionDonut extends StatelessWidget {
  const _DistributionDonut({
    required this.items,
    this.emptyLabel = 'Aucune donnee',
  });

  final List<_DistributionDatum> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.value > 0).toList();
    final total = visibleItems.fold<int>(0, (sum, item) => sum + item.value);
    if (total == 0) {
      return _EmptyInlineState(label: emptyLabel);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 380;
        final chart = SizedBox(
          width: horizontal ? 150 : double.infinity,
          height: horizontal ? 150 : 160,
          child: PieChart(
            PieChartData(
              sections: visibleItems
                  .map(
                    (item) => PieChartSectionData(
                      value: item.value.toDouble(),
                      color: item.color,
                      title: '',
                      radius: 36,
                    ),
                  )
                  .toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 44,
            ),
          ),
        );
        final legend = _DistributionLegend(items: visibleItems, total: total);

        if (horizontal) {
          return Row(
            children: [
              chart,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: legend),
            ],
          );
        }

        return Column(
          children: [
            chart,
            const SizedBox(height: AppSpacing.sm),
            legend,
          ],
        );
      },
    );
  }
}

class _DistributionLegend extends StatelessWidget {
  const _DistributionLegend({required this.items, required this.total});

  final List<_DistributionDatum> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final percent = total == 0 ? 0 : (item.value / total * 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${item.value}',
                style: AppTextStyles.subtitle.copyWith(fontSize: 13),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '(${percent.toStringAsFixed(0)}%)',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DistributionDatum {
  const _DistributionDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.warning,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  const _EmptyInlineState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(child: Text(label, style: AppTextStyles.bodySmall)),
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

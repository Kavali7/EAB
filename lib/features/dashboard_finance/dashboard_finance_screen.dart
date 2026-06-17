/// Dashboard financier avance.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

import 'dashboard_finance_providers.dart';

final _fmt = NumberFormat('#,##0', 'fr_FR');

class DashboardFinanceScreen extends ConsumerWidget {
  const DashboardFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final org = orgAsync.value;
    final orgId = org?.id;
    if (orgAsync.isLoading || orgId == null || orgId.isEmpty) {
      return const AppShell(
        title: 'Dashboard financier',
        currentRoute: '/dashboard-finance',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final kpisAsync = ref.watch(financeKpisProvider(orgId));
    final evoAsync = ref.watch(financeEvolutionProvider(orgId));
    final repAsync = ref.watch(financeRepartitionProvider(orgId));

    return AppShell(
      title: 'Dashboard financier',
      currentRoute: '/dashboard-finance',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.lg : AppSpacing.pagePadding,
                ),
                children: [
                  _PageIntro(compact: compact),
                  const SizedBox(height: AppSpacing.md),
                  kpisAsync.when(
                    loading: () => const SkeletonLoader(lineCount: 2),
                    error: (e, _) => _InlineError(message: 'Erreur KPIs : $e'),
                    data: (kpis) => _KpiGrid(kpis: kpis),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Panel(
                    title: 'Evolution mensuelle',
                    subtitle: 'Produits, charges et solde net',
                    child: SizedBox(
                      height: compact ? 260 : 320,
                      child: evoAsync.when(
                        loading: () =>
                            const Center(child: SkeletonLoader(lineCount: 6)),
                        error: (e, _) => Center(child: Text('Erreur : $e')),
                        data: (data) => data.isEmpty
                            ? const EmptyState(
                                icon: Icons.show_chart,
                                message: 'Aucune donnee.',
                              )
                            : _EvolutionChart(data: data, compact: compact),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  repAsync.when(
                    loading: () => const SkeletonLoader(lineCount: 4),
                    error: (e, _) => _InlineError(message: 'Erreur : $e'),
                    data: (data) => data.isEmpty
                        ? const EmptyState(
                            icon: Icons.pie_chart,
                            message: 'Aucune donnee.',
                          )
                        : _RepartitionBlock(data: data),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.insights_outlined, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Synthese financiere', style: AppTextStyles.heading3),
              if (!compact)
                Text(
                  'Lecture rapide des tendances et repartitions comptables.',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final FinanceKpis kpis;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.info,
        label: 'Tresorerie',
        value: kpis.tresorerieActuelle,
      ),
      _KpiData(
        icon: Icons.trending_up_outlined,
        color: kpis.resultatMois >= 0 ? AppColors.success : AppColors.error,
        label: 'Resultat du mois',
        value: kpis.resultatMois,
        variation: kpis.variation,
      ),
      _KpiData(
        icon: Icons.south_west_outlined,
        color: AppColors.success,
        label: 'Produits du mois',
        value: kpis.totalProduits,
      ),
      _KpiData(
        icon: Icons.north_east_outlined,
        color: AppColors.warning,
        label: 'Charges du mois',
        value: kpis.totalCharges,
      ),
      _KpiData(
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
        label: 'Ecritures du mois',
        value: kpis.nbEcrituresMois.toDouble(),
        isCurrency: false,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 720
            ? 3
            : 2;
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.sm)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: width.clamp(150, constraints.maxWidth).toDouble(),
                  child: _KpiCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(data.icon, color: data.color, size: 19),
              ),
              const Spacer(),
              if (data.variation != null && data.variation != 0)
                _VariationBadge(value: data.variation!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.isCurrency ? _money(data.value) : _fmt.format(data.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle.copyWith(color: data.color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(data.label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.data, required this.compact});

  final List<EvolutionMensuelle> data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ChartLegend(
          items: [
            _LegendData('Produits', AppColors.success),
            _LegendData('Charges', AppColors.error),
            _LegendData('Solde net', AppColors.info),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.divider, strokeWidth: 0.6),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !compact,
                    reservedSize: 56,
                    getTitlesWidget: (value, meta) =>
                        Text(_shortMoney(value), style: AppTextStyles.caption),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: compact ? 2 : 1,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final label = data[idx].labelMois;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label.length > 3 ? label.substring(0, 3) : label,
                          style: AppTextStyles.caption,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _line(data.map((e) => e.produits).toList(), AppColors.success),
                _line(data.map((e) => e.charges).toList(), AppColors.error),
                _line(
                  data.map((e) => e.soldeNet).toList(),
                  AppColors.info,
                  dashed: true,
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    const labels = ['Produits', 'Charges', 'Solde net'];
                    const colors = [
                      AppColors.success,
                      AppColors.error,
                      AppColors.info,
                    ];
                    return spots
                        .map(
                          (spot) => LineTooltipItem(
                            '${labels[spot.barIndex]}\n${_money(spot.y)}',
                            TextStyle(
                              color: colors[spot.barIndex],
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(
    List<double> values,
    Color color, {
    bool dashed = false,
  }) {
    return LineChartBarData(
      spots: values
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2.6,
      dashArray: dashed ? [6, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.05),
      ),
    );
  }
}

class _RepartitionBlock extends StatelessWidget {
  const _RepartitionBlock({required this.data});

  final List<RepartitionCategorie> data;

  @override
  Widget build(BuildContext context) {
    final produits = data.where((d) => d.section == 'produits').toList();
    final charges = data.where((d) => d.section == 'charges').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final cards = [
          _RepartitionCard(
            title: 'Produits',
            items: produits,
            colors: _produitsColors,
          ),
          _RepartitionCard(
            title: 'Charges',
            items: charges,
            colors: _chargesColors,
          ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[1]),
            ],
          );
        }
        return Column(
          children: [
            cards[0],
            const SizedBox(height: AppSpacing.md),
            cards[1],
          ],
        );
      },
    );
  }

  static const _produitsColors = [
    Color(0xFF16A34A),
    Color(0xFF0F766E),
    Color(0xFF22C55E),
    Color(0xFF2563EB),
    Color(0xFF4F46E5),
    Color(0xFFD89B27),
  ];

  static const _chargesColors = [
    Color(0xFFDC2626),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
    Color(0xFFB91C1C),
    Color(0xFF991B1B),
    Color(0xFF667085),
  ];
}

class _RepartitionCard extends StatelessWidget {
  const _RepartitionCard({
    required this.title,
    required this.items,
    required this.colors,
  });

  final String title;
  final List<RepartitionCategorie> items;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.montant > 0).toList();
    final total = visibleItems.fold<double>(
      0,
      (sum, item) => sum + item.montant,
    );

    return _Panel(
      title: title,
      subtitle: _money(total),
      child: visibleItems.isEmpty
          ? const EmptyState(icon: Icons.pie_chart, message: 'Aucune donnee.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 460;
                final chart = SizedBox(
                  width: horizontal ? 170 : double.infinity,
                  height: horizontal ? 170 : 190,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 48,
                      sections: visibleItems.asMap().entries.map((entry) {
                        final color = colors[entry.key % colors.length];
                        return PieChartSectionData(
                          value: entry.value.montant,
                          color: color,
                          radius: 38,
                          title: '',
                        );
                      }).toList(),
                    ),
                  ),
                );
                final legend = _RepartitionLegend(
                  items: visibleItems,
                  colors: colors,
                  total: total,
                );
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
            ),
    );
  }
}

class _RepartitionLegend extends StatelessWidget {
  const _RepartitionLegend({
    required this.items,
    required this.colors,
    required this.total,
  });

  final List<RepartitionCategorie> items;
  final List<Color> colors;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final color = colors[entry.key % colors.length];
        final percent = total == 0 ? 0 : item.montant / total * 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${item.compteNumero} - ${item.compteIntitule}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: AppTextStyles.subtitle.copyWith(fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.heading3)),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<_LegendData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(item.label, style: AppTextStyles.caption),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _VariationBadge extends StatelessWidget {
  const _VariationBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value > 0;
    final color = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        '${positive ? '+' : ''}${value.toStringAsFixed(1)}%',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.variation,
    this.isCurrency = true,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final double? variation;
  final bool isCurrency;
}

class _LegendData {
  const _LegendData(this.label, this.color);

  final String label;
  final Color color;
}

String _money(double value) => '${_fmt.format(value)} FCFA';

String _shortMoney(double value) {
  final abs = value.abs();
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return _fmt.format(value);
}

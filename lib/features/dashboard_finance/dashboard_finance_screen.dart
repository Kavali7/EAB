/// Écran du dashboard financier avancé (H4).
///
/// Affiche : KPIs financiers, courbe d'évolution 12 mois,
/// camemberts de répartition produits/charges.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'dashboard_finance_providers.dart';

final _fmt = NumberFormat('#,##0', 'fr_FR');

class DashboardFinanceScreen extends ConsumerWidget {
  const DashboardFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilUtilisateurCourantProvider);
    if (profil == null) {
      return const AppShell(
        title: 'Dashboard financier',
        currentRoute: '/dashboard-finance',
        body: Center(child: Text('Veuillez vous connecter.')),
      );
    }

    final orgId = profil.id;
    final kpisAsync = ref.watch(financeKpisProvider(orgId));
    final evoAsync = ref.watch(financeEvolutionProvider(orgId));
    final repAsync = ref.watch(financeRepartitionProvider(orgId));

    return AppShell(
      title: 'Dashboard financier',
      currentRoute: '/dashboard-finance',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPIs ──
            kpisAsync.when(
              loading: () => const SkeletonLoader(lineCount: 2),
              error: (e, _) => Text('Erreur KPIs : $e'),
              data: (kpis) => _KpiRow(kpis: kpis),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Courbe d'évolution ──
            Text('Évolution mensuelle', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 300,
              child: evoAsync.when(
                loading: () => const Center(child: SkeletonLoader(lineCount: 6)),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (data) => data.isEmpty
                    ? const EmptyState(icon: Icons.show_chart, message: 'Aucune donnée.')
                    : _EvolutionChart(data: data),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Répartition ──
            Text('Répartition par catégorie', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),
            repAsync.when(
              loading: () => const SkeletonLoader(lineCount: 4),
              error: (e, _) => Text('Erreur : $e'),
              data: (data) => data.isEmpty
                  ? const EmptyState(icon: Icons.pie_chart, message: 'Aucune donnée.')
                  : _RepartitionRow(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KPI ROW
// ══════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis});
  final FinanceKpis kpis;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.cardGap,
      runSpacing: AppSpacing.cardGap,
      children: [
        _kpiCard(
          icon: Icons.account_balance_wallet,
          color: AppColors.info,
          label: 'Trésorerie',
          value: kpis.tresorerieActuelle,
        ),
        _kpiCard(
          icon: Icons.trending_up,
          color: kpis.resultatMois >= 0 ? AppColors.success : AppColors.error,
          label: 'Résultat du mois',
          value: kpis.resultatMois,
          variation: kpis.variation,
        ),
        _kpiCard(
          icon: Icons.arrow_downward,
          color: AppColors.success,
          label: 'Produits du mois',
          value: kpis.totalProduits,
        ),
        _kpiCard(
          icon: Icons.arrow_upward,
          color: AppColors.warning,
          label: 'Charges du mois',
          value: kpis.totalCharges,
        ),
        _kpiCard(
          icon: Icons.receipt_long,
          color: AppColors.primary,
          label: 'Écritures du mois',
          value: kpis.nbEcrituresMois.toDouble(),
          isCurrency: false,
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color color,
    required String label,
    required double value,
    double? variation,
    bool isCurrency = true,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (variation != null && variation != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: variation > 0 ? AppColors.successLight : AppColors.errorLight,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    '${variation > 0 ? "+" : ""}${variation.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: variation > 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isCurrency ? '${_fmt.format(value)} FCFA' : _fmt.format(value),
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// COURBE D'ÉVOLUTION (fl_chart)
// ══════════════════════════════════════════════════════════════

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.data});
  final List<EvolutionMensuelle> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppElevation.cardShadow,
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.divider,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) => Text(
                  _fmt.format(value),
                  style: AppTextStyles.caption,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final label = data[idx].labelMois;
                  // Show abbreviated month
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
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Produits (vert)
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.produits)).toList(),
              isCurved: true,
              color: AppColors.success,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.success.withOpacity(0.05)),
            ),
            // Charges (rouge)
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.charges)).toList(),
              isCurved: true,
              color: AppColors.error,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.error.withOpacity(0.05)),
            ),
            // Solde net (bleu, dashed)
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.soldeNet)).toList(),
              isCurved: true,
              color: AppColors.info,
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final colors = [AppColors.success, AppColors.error, AppColors.info];
                final labels = ['Produits', 'Charges', 'Solde net'];
                return LineTooltipItem(
                  '${labels[spot.barIndex]}\n${_fmt.format(spot.y)} FCFA',
                  TextStyle(color: colors[spot.barIndex], fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// RÉPARTITION (camemberts)
// ══════════════════════════════════════════════════════════════

class _RepartitionRow extends StatelessWidget {
  const _RepartitionRow({required this.data});
  final List<RepartitionCategorie> data;

  @override
  Widget build(BuildContext context) {
    final produits = data.where((d) => d.section == 'produits').toList();
    final charges = data.where((d) => d.section == 'charges').toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _pieCard('Produits', produits, _produitsColors)),
        const SizedBox(width: AppSpacing.cardGap),
        Expanded(child: _pieCard('Charges', charges, _chargesColors)),
      ],
    );
  }

  static const _produitsColors = [
    Color(0xFF16A34A),
    Color(0xFF22C55E),
    Color(0xFF4ADE80),
    Color(0xFF86EFAC),
    Color(0xFFBBF7D0),
    Color(0xFF059669),
    Color(0xFF10B981),
  ];

  static const _chargesColors = [
    Color(0xFFDC2626),
    Color(0xFFEF4444),
    Color(0xFFF87171),
    Color(0xFFFCA5A5),
    Color(0xFFFECACA),
    Color(0xFFB91C1C),
    Color(0xFF991B1B),
  ];

  Widget _pieCard(String title, List<RepartitionCategorie> items, List<Color> colors) {
    final total = items.fold(0.0, (s, i) => s + i.montant);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.heading3),
          Text('${_fmt.format(total)} FCFA', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: items.isEmpty
                ? const Center(child: Text('—'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: items.asMap().entries.map((e) {
                        final color = colors[e.key % colors.length];
                        return PieChartSectionData(
                          value: e.value.montant,
                          color: color,
                          radius: 50,
                          title: '${e.value.pourcentage.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Légende
          ...items.asMap().entries.map((e) {
            final color = colors[e.key % colors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${e.value.compteNumero} — ${e.value.compteIntitule}',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_fmt.format(e.value.montant)} FCFA',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

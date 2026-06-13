/// Fiche detaillee d'un tiers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/ecriture_comptable.dart';
import 'package:eab/models/tiers.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

class TiersDetailScreen extends ConsumerWidget {
  const TiersDetailScreen({super.key, required this.tiers});

  final Tiers tiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider);

    return AppShell(
      title: tiers.nom,
      currentRoute: '/accounting-settings',
      showBackButton: true,
      backRoute: '/accounting-settings',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.lg : AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TiersHeader(tiers: tiers),
                    if (tiers.telephone != null ||
                        tiers.email != null ||
                        tiers.adresse != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text('Coordonnees', style: AppTextStyles.heading3),
                      const SizedBox(height: AppSpacing.md),
                      _ContactsCard(tiers: tiers),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text('Operations', style: AppTextStyles.heading3),
                    const SizedBox(height: AppSpacing.md),
                    ecrituresAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => _InfoPanel(message: 'Erreur : $err'),
                      data: (ecritures) {
                        final operations = _operationsForTiers(ecritures, tiers)
                          ..sort((a, b) => b.date.compareTo(a.date));
                        final totalDebit = operations.fold<double>(
                          0,
                          (sum, e) =>
                              sum +
                              e.lignes.fold<double>(
                                0,
                                (lineSum, l) => lineSum + (l.debit ?? 0),
                              ),
                        );
                        final totalCredit = operations.fold<double>(
                          0,
                          (sum, e) =>
                              sum +
                              e.lignes.fold<double>(
                                0,
                                (lineSum, l) => lineSum + (l.credit ?? 0),
                              ),
                        );

                        if (operations.isEmpty) {
                          return const _InfoPanel(
                            message: 'Aucune operation pour ce tiers.',
                          );
                        }

                        return Column(
                          children: [
                            _BalanceCard(
                              debit: totalDebit,
                              credit: totalCredit,
                              solde: totalDebit - totalCredit,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _OperationsList(
                              operations: operations.take(20).toList(),
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
        },
      ),
    );
  }

  static List<EcritureComptable> _operationsForTiers(
    List<EcritureComptable> ecritures,
    Tiers tiers,
  ) {
    return ecritures.where((e) {
      final nameMatch = e.libelle.toLowerCase().contains(
        tiers.nom.toLowerCase(),
      );
      final lineMatch = e.lignes.any((l) => l.idTiers == tiers.id);
      return nameMatch || lineMatch;
    }).toList();
  }
}

class _TiersHeader extends StatelessWidget {
  const _TiersHeader({required this.tiers});

  final Tiers tiers;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(tiers.type);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.lgAll,
            ),
            child: Icon(_typeIcon(tiers.type), color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tiers.nom, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                _Badge(label: _typeLabel(tiers.type), color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.tiers});

  final Tiers tiers;

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
        children: [
          if (tiers.telephone != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telephone',
              value: tiers.telephone!,
            ),
          if (tiers.email != null)
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: tiers.email!,
            ),
          if (tiers.adresse != null)
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Adresse',
              value: tiers.adresse!,
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.debit,
    required this.credit,
    required this.solde,
  });

  final double debit;
  final double credit;
  final double solde;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final metrics = [
          _Metric(label: 'Debit', value: debit, color: AppColors.error),
          _Metric(label: 'Credit', value: credit, color: AppColors.success),
          _Metric(
            label: 'Solde',
            value: solde,
            color: solde >= 0 ? AppColors.error : AppColors.success,
          ),
        ];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.divider),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: metrics,
                )
              : Row(
                  children: metrics
                      .map((metric) => Expanded(child: metric))
                      .toList(),
                ),
        );
      },
    );
  }
}

class _OperationsList extends StatelessWidget {
  const _OperationsList({required this.operations});

  final List<EcritureComptable> operations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: operations
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      e.statut == StatutEcriture.brouillon
                          ? Icons.edit_note_outlined
                          : Icons.check_circle_outline,
                      color: e.statut == StatutEcriture.brouillon
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.libelle, style: AppTextStyles.subtitle),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            dateFormatter.format(e.date),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 92, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.subtitle)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currencyFormatter.format(value.abs()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

Color _typeColor(TypeTiers type) {
  return switch (type) {
    TypeTiers.membre => AppColors.primary,
    TypeTiers.fournisseur => AppColors.info,
    TypeTiers.bailleur => AppColors.indigo,
    TypeTiers.employe => AppColors.warning,
    TypeTiers.partenaire => AppColors.teal,
    TypeTiers.autre => AppColors.textSecondary,
  };
}

IconData _typeIcon(TypeTiers type) {
  return switch (type) {
    TypeTiers.membre => Icons.person_outline,
    TypeTiers.fournisseur => Icons.store_outlined,
    TypeTiers.bailleur => Icons.volunteer_activism_outlined,
    TypeTiers.employe => Icons.badge_outlined,
    TypeTiers.partenaire => Icons.handshake_outlined,
    TypeTiers.autre => Icons.business_outlined,
  };
}

String _typeLabel(TypeTiers type) {
  return switch (type) {
    TypeTiers.membre => 'Membre',
    TypeTiers.fournisseur => 'Fournisseur',
    TypeTiers.bailleur => 'Bailleur',
    TypeTiers.employe => 'Employe',
    TypeTiers.partenaire => 'Partenaire',
    TypeTiers.autre => 'Autre',
  };
}

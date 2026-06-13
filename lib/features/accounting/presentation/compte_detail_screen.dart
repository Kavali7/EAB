/// Fiche detaillee d'un compte comptable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/compte_comptable.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

class CompteDetailScreen extends ConsumerWidget {
  const CompteDetailScreen({super.key, required this.compte});

  final CompteComptable compte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider);

    return AppShell(
      title: compte.numero,
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
                    _CompteHeader(compte: compte),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Mouvements recents', style: AppTextStyles.heading3),
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
                        final mouvements = <_Mouvement>[];
                        for (final e in ecritures) {
                          for (final l in e.lignes) {
                            if (l.idCompteComptable == compte.id) {
                              mouvements.add(
                                _Mouvement(
                                  date: e.date,
                                  libelle: l.libelle ?? e.libelle,
                                  debit: l.debit ?? 0,
                                  credit: l.credit ?? 0,
                                  statut: e.statut,
                                ),
                              );
                            }
                          }
                        }
                        mouvements.sort((a, b) => b.date.compareTo(a.date));
                        final recent = mouvements.take(30).toList();
                        final solde = mouvements.fold<double>(
                          0,
                          (sum, m) => sum + _signedAmount(m, compte.nature),
                        );

                        if (recent.isEmpty) {
                          return const _InfoPanel(
                            message: 'Aucun mouvement sur ce compte.',
                          );
                        }

                        return Column(
                          children: [
                            _SoldeCard(solde: solde),
                            const SizedBox(height: AppSpacing.md),
                            if (compact)
                              _MouvementsList(mouvements: recent)
                            else
                              _MouvementsTable(mouvements: recent),
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

  static double _signedAmount(_Mouvement mouvement, NatureCompte nature) {
    if (nature == NatureCompte.actif || nature == NatureCompte.charge) {
      return mouvement.debit - mouvement.credit;
    }
    return mouvement.credit - mouvement.debit;
  }
}

class _CompteHeader extends StatelessWidget {
  const _CompteHeader({required this.compte});

  final CompteComptable compte;

  @override
  Widget build(BuildContext context) {
    final color = _natureColor(compte.nature);
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.lgAll,
            ),
            child: Text(
              compte.numero.substring(
                0,
                compte.numero.length > 2 ? 2 : compte.numero.length,
              ),
              style: AppTextStyles.subtitle.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(compte.intitule, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Badge(label: _natureLabel(compte.nature), color: color),
                    _Badge(
                      label: compte.actif ? 'Actif' : 'Inactif',
                      color: compte.actif ? AppColors.success : AppColors.error,
                    ),
                    if (compte.niveau != null)
                      _Badge(
                        label: 'Niveau ${compte.niveau}',
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldeCard extends StatelessWidget {
  const _SoldeCard({required this.solde});

  final double solde;

  @override
  Widget build(BuildContext context) {
    final color = solde >= 0 ? AppColors.success : AppColors.error;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: color),
            const SizedBox(width: AppSpacing.md),
            Text('Solde actuel', style: AppTextStyles.subtitle),
          ],
        );
        final amount = Text(
          currencyFormatter.format(solde),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading3.copyWith(color: color),
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    const SizedBox(height: AppSpacing.sm),
                    amount,
                  ],
                )
              : Row(
                  children: [
                    label,
                    const Spacer(),
                    Flexible(child: amount),
                  ],
                ),
        );
      },
    );
  }
}

class _MouvementsList extends StatelessWidget {
  const _MouvementsList({required this.mouvements});

  final List<_Mouvement> mouvements;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: mouvements
          .map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.libelle, style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dateFormatter.format(m.date),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AmountRow(label: 'Debit', value: m.debit),
                    _AmountRow(label: 'Credit', value: m.credit),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MouvementsTable extends StatelessWidget {
  const _MouvementsTable({required this.mouvements});

  final List<_Mouvement> mouvements;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Statut')),
        ],
        rows: mouvements
            .map(
              (m) => DataRow(
                cells: [
                  DataCell(Text(dateFormatter.format(m.date))),
                  DataCell(Text(m.libelle)),
                  DataCell(
                    Text(m.debit > 0 ? currencyFormatter.format(m.debit) : '-'),
                  ),
                  DataCell(
                    Text(
                      m.credit > 0 ? currencyFormatter.format(m.credit) : '-',
                    ),
                  ),
                  DataCell(Text(_statutLabel(m.statut))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text(currencyFormatter.format(value), style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _TableFrame extends StatelessWidget {
  const _TableFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
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

class _Mouvement {
  const _Mouvement({
    required this.date,
    required this.libelle,
    required this.debit,
    required this.credit,
    required this.statut,
  });

  final DateTime date;
  final String libelle;
  final double debit;
  final double credit;
  final StatutEcriture statut;
}

Color _natureColor(NatureCompte nature) {
  return switch (nature) {
    NatureCompte.actif => AppColors.info,
    NatureCompte.passif => AppColors.indigo,
    NatureCompte.charge => AppColors.error,
    NatureCompte.produit => AppColors.success,
    NatureCompte.horsActiviteOrdinaire => AppColors.warning,
    NatureCompte.engagement => AppColors.teal,
    NatureCompte.autre => AppColors.textSecondary,
  };
}

String _natureLabel(NatureCompte nature) {
  return switch (nature) {
    NatureCompte.actif => 'Actif',
    NatureCompte.passif => 'Passif',
    NatureCompte.charge => 'Charge',
    NatureCompte.produit => 'Produit',
    NatureCompte.horsActiviteOrdinaire => 'Hors activite',
    NatureCompte.engagement => 'Engagement',
    NatureCompte.autre => 'Autre',
  };
}

String _statutLabel(StatutEcriture statut) {
  return switch (statut) {
    StatutEcriture.brouillon => 'Brouillon',
    StatutEcriture.validee => 'Validee',
    StatutEcriture.cloturee => 'Cloturee',
  };
}

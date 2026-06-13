import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../providers/accounting_providers.dart';
import '../../widgets/print_preview_shell.dart';

class AccountingBalancePrintScreen extends ConsumerWidget {
  const AccountingBalancePrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return comptesAsync.when(
      loading: () => const _LoadingPrintScreen(title: 'Balance generale'),
      error: (err, st) => const _ErrorPrintScreen(
        title: 'Balance generale',
        message: 'Erreur chargement plan de comptes',
      ),
      data: (comptes) =>
          _BalancePreview(comptes: comptes, ecritures: ecritures),
    );
  }
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview({required this.comptes, required this.ecritures});

  final List<CompteComptable> comptes;
  final List<EcritureComptable> ecritures;

  @override
  Widget build(BuildContext context) {
    final lignes = _buildLines();
    final totalDebits = lignes.fold(0.0, (sum, line) => sum + line.debit);
    final totalCredits = lignes.fold(0.0, (sum, line) => sum + line.credit);
    final ecart = totalDebits - totalCredits;

    return PrintPreviewShell(
      title: 'Balance generale',
      subtitle: '${lignes.length} comptes mouvementes',
      icon: Icons.account_balance_outlined,
      children: [
        PrintMetricGrid(
          metrics: [
            PrintMetric(
              label: 'Comptes',
              value: lignes.length.toString(),
              icon: Icons.format_list_numbered_outlined,
            ),
            PrintMetric(
              label: 'Total debit',
              value: _formatAmount(totalDebits),
              icon: Icons.south_west_outlined,
              color: AppColors.success,
            ),
            PrintMetric(
              label: 'Total credit',
              value: _formatAmount(totalCredits),
              icon: Icons.north_east_outlined,
              color: AppColors.info,
            ),
            PrintMetric(
              label: 'Ecart',
              value: _formatAmount(ecart),
              icon: ecart == 0
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: ecart == 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        PrintSection(
          title: 'Lignes de balance',
          subtitle: 'Apercu optimise pour lecture avant impression',
          icon: Icons.receipt_long_outlined,
          child: lignes.isEmpty
              ? const PrintEmptyState(
                  message: 'Aucun mouvement comptable pour cette periode.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 700;
                    if (compact) return _BalanceCardList(lignes: lignes);
                    return _BalanceTable(lignes: lignes);
                  },
                ),
        ),
      ],
    );
  }

  List<_LigneBalance> _buildLines() {
    final comptesParId = {for (final c in comptes) c.id: c};
    final debitsParCompte = <String, double>{};
    final creditsParCompte = <String, double>{};

    for (final e in ecritures) {
      for (final l in e.lignes) {
        final compte = comptesParId[l.idCompteComptable];
        if (compte == null) continue;
        debitsParCompte[compte.id] =
            (debitsParCompte[compte.id] ?? 0) + (l.debit ?? 0);
        creditsParCompte[compte.id] =
            (creditsParCompte[compte.id] ?? 0) + (l.credit ?? 0);
      }
    }

    final lignes = <_LigneBalance>[];
    for (final compte in comptes) {
      final debit = debitsParCompte[compte.id] ?? 0;
      final credit = creditsParCompte[compte.id] ?? 0;
      if (debit == 0 && credit == 0) continue;
      lignes.add(
        _LigneBalance(
          numero: compte.numero,
          intitule: compte.intitule,
          debit: debit,
          credit: credit,
          solde: debit - credit,
        ),
      );
    }

    lignes.sort((a, b) => a.numero.compareTo(b.numero));
    return lignes;
  }
}

class _BalanceCardList extends StatelessWidget {
  const _BalanceCardList({required this.lignes});

  final List<_LigneBalance> lignes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lignes.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _BalanceCard(line: lignes[i]),
        ],
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.line});

  final _LigneBalance line;

  @override
  Widget build(BuildContext context) {
    final soldeColor = line.solde >= 0 ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(line.numero, style: AppTextStyles.mono),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(line.intitule, style: AppTextStyles.subtitle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AmountPill(label: 'Debit', value: line.debit),
              _AmountPill(label: 'Credit', value: line.credit),
              _AmountPill(label: 'Solde', value: line.solde, color: soldeColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            _formatAmount(value),
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({required this.lignes});

  final List<_LigneBalance> lignes;

  @override
  Widget build(BuildContext context) {
    final totalDebits = lignes.fold(0.0, (sum, line) => sum + line.debit);
    final totalCredits = lignes.fold(0.0, (sum, line) => sum + line.credit);
    final ecart = totalDebits - totalCredits;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Compte')),
          DataColumn(label: Text('Intitule')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde')),
        ],
        rows: [
          ...lignes.map(
            (line) => DataRow(
              cells: [
                DataCell(Text(line.numero)),
                DataCell(Text(line.intitule)),
                DataCell(Text(_formatAmount(line.debit))),
                DataCell(Text(_formatAmount(line.credit))),
                DataCell(
                  Text(
                    _formatAmount(line.solde),
                    style: TextStyle(
                      color: line.solde >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DataRow(
            selected: true,
            cells: [
              const DataCell(Text('TOTAL')),
              const DataCell(Text('')),
              DataCell(Text(_formatAmount(totalDebits))),
              DataCell(Text(_formatAmount(totalCredits))),
              DataCell(
                Text(
                  _formatAmount(ecart),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ecart == 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingPrintScreen extends StatelessWidget {
  const _LoadingPrintScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return PrintPreviewShell(
      title: title,
      subtitle: 'Chargement des donnees',
      icon: Icons.print_outlined,
      children: const [
        PrintSection(
          title: 'Chargement',
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorPrintScreen extends StatelessWidget {
  const _ErrorPrintScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PrintPreviewShell(
      title: title,
      subtitle: 'Impossible de preparer l apercu',
      icon: Icons.error_outline,
      children: [PrintEmptyState(message: message, icon: Icons.error_outline)],
    );
  }
}

class _LigneBalance {
  _LigneBalance({
    required this.numero,
    required this.intitule,
    required this.debit,
    required this.credit,
    required this.solde,
  });

  final String numero;
  final String intitule;
  final double debit;
  final double credit;
  final double solde;
}

String _formatAmount(double value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(' ');
  }
  return '$sign$buffer';
}

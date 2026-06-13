import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../providers/accounting_providers.dart';
import '../../widgets/print_preview_shell.dart';

class AccountingLedgerPrintScreen extends ConsumerWidget {
  const AccountingLedgerPrintScreen({
    super.key,
    required this.idCompteComptable,
  });

  final String idCompteComptable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return comptesAsync.when(
      loading: () => const _LedgerStateScreen(
        title: 'Grand livre',
        subtitle: 'Chargement des donnees',
        message: 'Preparation de l apercu...',
        loading: true,
      ),
      error: (err, st) => const _LedgerStateScreen(
        title: 'Grand livre',
        subtitle: 'Impossible de charger les comptes',
        message: 'Erreur chargement comptes',
      ),
      data: (comptes) {
        if (comptes.isEmpty) {
          return const _LedgerStateScreen(
            title: 'Grand livre',
            subtitle: 'Aucun compte disponible',
            message: 'Le plan comptable est vide.',
          );
        }

        final compte =
            comptes.where((c) => c.id == idCompteComptable).isNotEmpty
            ? comptes.firstWhere((c) => c.id == idCompteComptable)
            : comptes.first;

        return _LedgerPreview(compte: compte, ecritures: ecritures);
      },
    );
  }
}

class _LedgerPreview extends StatelessWidget {
  const _LedgerPreview({required this.compte, required this.ecritures});

  final CompteComptable compte;
  final List<EcritureComptable> ecritures;

  @override
  Widget build(BuildContext context) {
    final lignes = _buildLines();
    final totalDebits = lignes.fold(0.0, (sum, line) => sum + line.debit);
    final totalCredits = lignes.fold(0.0, (sum, line) => sum + line.credit);
    final soldeFinal = lignes.isEmpty ? 0.0 : lignes.last.solde;

    return PrintPreviewShell(
      title: 'Grand livre',
      subtitle: '${compte.numero} - ${compte.intitule}',
      icon: Icons.menu_book_outlined,
      children: [
        PrintMetricGrid(
          metrics: [
            PrintMetric(
              label: 'Mouvements',
              value: lignes.length.toString(),
              icon: Icons.swap_vert_outlined,
            ),
            PrintMetric(
              label: 'Debit',
              value: _formatAmount(totalDebits),
              icon: Icons.south_west_outlined,
              color: AppColors.success,
            ),
            PrintMetric(
              label: 'Credit',
              value: _formatAmount(totalCredits),
              icon: Icons.north_east_outlined,
              color: AppColors.info,
            ),
            PrintMetric(
              label: 'Solde final',
              value: _formatAmount(soldeFinal),
              icon: Icons.account_balance_wallet_outlined,
              color: soldeFinal >= 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        PrintSection(
          title: 'Mouvements du compte',
          subtitle: 'Lecture chronologique avec solde progressif',
          icon: Icons.timeline_outlined,
          child: lignes.isEmpty
              ? const PrintEmptyState(
                  message: 'Aucun mouvement pour ce compte.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    if (compact) return _LedgerCardList(lignes: lignes);
                    return _LedgerTable(lignes: lignes);
                  },
                ),
        ),
      ],
    );
  }

  List<_LigneGrandLivre> _buildLines() {
    final mouvements = <_MouvementCompte>[];

    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable != compte.id) continue;
        mouvements.add(
          _MouvementCompte(
            date: e.date,
            libelle: (l.libelle?.isNotEmpty ?? false) ? l.libelle! : e.libelle,
            reference: e.referencePiece,
            debit: l.debit ?? 0,
            credit: l.credit ?? 0,
          ),
        );
      }
    }

    mouvements.sort((a, b) => a.date.compareTo(b.date));

    var solde = 0.0;
    return [
      for (final m in mouvements)
        _LigneGrandLivre(
          date: m.date,
          reference: m.reference,
          libelle: m.libelle,
          debit: m.debit,
          credit: m.credit,
          solde: solde += m.debit - m.credit,
        ),
    ];
  }
}

class _LedgerCardList extends StatelessWidget {
  const _LedgerCardList({required this.lignes});

  final List<_LigneGrandLivre> lignes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lignes.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _LedgerCard(line: lignes[i]),
        ],
      ],
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.line});

  final _LigneGrandLivre line;

  @override
  Widget build(BuildContext context) {
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
            children: [
              Text(_formatDate(line.date), style: AppTextStyles.subtitle),
              const Spacer(),
              Text(
                line.reference?.isNotEmpty == true ? line.reference! : '-',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(line.libelle, style: AppTextStyles.body),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerAmount(label: 'Debit', value: line.debit),
              _LedgerAmount(label: 'Credit', value: line.credit),
              _LedgerAmount(
                label: 'Solde',
                value: line.solde,
                color: line.solde >= 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerAmount extends StatelessWidget {
  const _LedgerAmount({
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

class _LedgerTable extends StatelessWidget {
  const _LedgerTable({required this.lignes});

  final List<_LigneGrandLivre> lignes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Reference')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Solde')),
        ],
        rows: [
          for (final line in lignes)
            DataRow(
              cells: [
                DataCell(Text(_formatDate(line.date))),
                DataCell(Text(line.reference ?? '')),
                DataCell(Text(line.libelle)),
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
        ],
      ),
    );
  }
}

class _LedgerStateScreen extends StatelessWidget {
  const _LedgerStateScreen({
    required this.title,
    required this.subtitle,
    required this.message,
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PrintPreviewShell(
      title: title,
      subtitle: subtitle,
      icon: loading ? Icons.print_outlined : Icons.error_outline,
      children: [
        PrintSection(
          title: loading ? 'Chargement' : 'Apercu indisponible',
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : PrintEmptyState(message: message, icon: Icons.info_outline),
        ),
      ],
    );
  }
}

class _MouvementCompte {
  _MouvementCompte({
    required this.date,
    required this.libelle,
    required this.reference,
    required this.debit,
    required this.credit,
  });

  final DateTime date;
  final String libelle;
  final String? reference;
  final double debit;
  final double credit;
}

class _LigneGrandLivre extends _MouvementCompte {
  _LigneGrandLivre({
    required super.date,
    required super.libelle,
    required super.reference,
    required super.debit,
    required super.credit,
    required this.solde,
  });

  final double solde;
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

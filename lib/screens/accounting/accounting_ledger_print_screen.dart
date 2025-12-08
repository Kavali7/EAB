import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../providers/accounting_providers.dart';

class AccountingLedgerPrintScreen extends ConsumerWidget {
  final String idCompteComptable;

  const AccountingLedgerPrintScreen({
    super.key,
    required this.idCompteComptable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apercu imprimable - Grand livre'),
      ),
      body: comptesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            const Center(child: Text('Erreur chargement comptes')),
        data: (comptes) {
          final compte = comptes.firstWhere(
            (c) => c.id == idCompteComptable,
            orElse: () => comptes.first,
          );
          return _buildLedgerTable(context, compte, ecritures);
        },
      ),
    );
  }

  Widget _buildLedgerTable(
    BuildContext context,
    CompteComptable compte,
    List<EcritureComptable> ecritures,
  ) {
    final mouvements = <_MouvementCompte>[];

    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable == compte.id) {
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
    }

    mouvements.sort((a, b) => a.date.compareTo(b.date));

    double solde = 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grand livre - ${compte.numero} ${compte.intitule}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Libelle')),
                DataColumn(label: Text('Debit')),
                DataColumn(label: Text('Credit')),
                DataColumn(label: Text('Solde')),
              ],
              rows: mouvements.map((m) {
                solde += (m.debit - m.credit);
                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(m.date))),
                    DataCell(Text(m.reference ?? '')),
                    DataCell(Text(m.libelle)),
                    DataCell(Text(m.debit.toStringAsFixed(0))),
                    DataCell(Text(m.credit.toStringAsFixed(0))),
                    DataCell(
                      Text(
                        solde.toStringAsFixed(0),
                        style: TextStyle(
                          color: solde >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
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

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

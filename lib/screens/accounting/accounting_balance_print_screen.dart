import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../providers/accounting_providers.dart';

class AccountingBalancePrintScreen extends ConsumerWidget {
  const AccountingBalancePrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apercu imprimable - Balance generale'),
      ),
      body: comptesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            const Center(child: Text('Erreur chargement plan de comptes')),
        data: (comptes) => _buildBalanceTable(context, comptes, ecritures),
      ),
    );
  }

  Widget _buildBalanceTable(
    BuildContext context,
    List<CompteComptable> comptes,
    List<EcritureComptable> ecritures,
  ) {
    final comptesParId = {for (final c in comptes) c.id: c};
    final debitsParCompte = <String, double>{};
    final creditsParCompte = <String, double>{};

    for (final e in ecritures) {
      for (final l in e.lignes) {
        final compte = comptesParId[l.idCompteComptable];
        if (compte == null) continue;
        final d = l.debit ?? 0;
        final c = l.credit ?? 0;
        debitsParCompte[compte.id] = (debitsParCompte[compte.id] ?? 0) + d;
        creditsParCompte[compte.id] = (creditsParCompte[compte.id] ?? 0) + c;
      }
    }

    final lignes = <_LigneBalance>[];
    for (final compte in comptes) {
      final totalD = debitsParCompte[compte.id] ?? 0;
      final totalC = creditsParCompte[compte.id] ?? 0;
      if (totalD == 0 && totalC == 0) continue;
      final solde = totalD - totalC;
      lignes.add(
        _LigneBalance(
          numero: compte.numero,
          intitule: compte.intitule,
          debit: totalD,
          credit: totalC,
          solde: solde,
        ),
      );
    }
    lignes.sort((a, b) => a.numero.compareTo(b.numero));

    double totalDebits = 0;
    double totalCredits = 0;
    for (final l in lignes) {
      totalDebits += l.debit;
      totalCredits += l.credit;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance generale',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
              columns: const [
                DataColumn(label: Text('Compte')),
                DataColumn(label: Text('Intitule')),
                DataColumn(label: Text('Debit')),
                DataColumn(label: Text('Credit')),
                DataColumn(label: Text('Solde')),
              ],
              rows: [
                ...lignes.map(
                  (l) => DataRow(
                    cells: [
                      DataCell(Text(l.numero)),
                      DataCell(Text(l.intitule)),
                      DataCell(Text(l.debit.toStringAsFixed(0))),
                      DataCell(Text(l.credit.toStringAsFixed(0))),
                      DataCell(
                        Text(
                          l.solde.toStringAsFixed(0),
                          style: TextStyle(
                            color: l.solde >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DataRow(
                  selected: true,
                  cells: [
                    const DataCell(Text('TOTALS')),
                    const DataCell(Text('')),
                    DataCell(Text(totalDebits.toStringAsFixed(0))),
                    DataCell(Text(totalCredits.toStringAsFixed(0))),
                    DataCell(
                      Text(
                        (totalDebits - totalCredits).toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (totalDebits - totalCredits) == 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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

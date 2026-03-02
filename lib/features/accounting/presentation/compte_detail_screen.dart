/// Fiche détaillée d'un compte comptable.
///
/// Affiche le numéro, intitulé, nature, et les mouvements récents.
/// Flèche retour pour revenir à la liste.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/models/compte_comptable.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/ecriture_comptable.dart';
import 'package:eab/providers/accounting_providers.dart';

class CompteDetailScreen extends ConsumerWidget {
  const CompteDetailScreen({super.key, required this.compte});

  final CompteComptable compte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider);
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final numberFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${compte.numero} — ${compte.intitule}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête du compte ──
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          _natureColor(compte.nature).withValues(alpha: 0.15),
                      child: Text(
                        compte.numero.substring(
                            0, compte.numero.length > 2 ? 2 : compte.numero.length),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _natureColor(compte.nature),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            compte.intitule,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _natureColor(compte.nature)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _natureLabel(compte.nature),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _natureColor(compte.nature),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'N° ${compte.numero}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                              if (compte.niveau != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Niveau ${compte.niveau}',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Badge actif/inactif
                    Chip(
                      label: Text(
                        compte.actif ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 11,
                          color: compte.actif ? Colors.green : Colors.red,
                        ),
                      ),
                      backgroundColor: compte.actif
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      side: BorderSide(
                        color: compte.actif
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Mouvements récents ──
            _sectionTitle(context, Icons.receipt_long, 'Mouvements récents'),
            ecrituresAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur : $err'),
                ),
              ),
              data: (ecritures) {
                // Filtrer les écritures qui touchent ce compte
                final mouvements = <_Mouvement>[];
                for (final e in ecritures) {
                  for (final l in e.lignes) {
                    if (l.idCompteComptable == compte.id) {
                      mouvements.add(_Mouvement(
                        date: e.date,
                        libelle: e.libelle,
                        debit: l.debit,
                        credit: l.credit,
                        statut: e.statut,
                      ));
                    }
                  }
                }

                // Trier par date décroissante, garder les 30 derniers
                mouvements.sort((a, b) => b.date.compareTo(a.date));
                final recent = mouvements.take(30).toList();

                if (recent.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Aucun mouvement sur ce compte',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Calcul du solde cumulé
                double solde = 0;
                for (final m in mouvements.reversed) {
                  if (compte.nature == NatureCompte.actif ||
                      compte.nature == NatureCompte.charge) {
                    solde += m.debit - m.credit;
                  } else {
                    solde += m.credit - m.debit;
                  }
                }

                return Column(
                  children: [
                    // Solde actuel
                    Card(
                      color: _soldeColor(solde).withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: _soldeColor(solde)),
                            const SizedBox(width: 12),
                            Text('Solde actuel',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700])),
                            const Spacer(),
                            Text(
                              numberFormat.format(solde),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _soldeColor(solde),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tableau des mouvements
                    Card(
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowColor: WidgetStateProperty.all(
                          ChurchTheme.navy.withValues(alpha: 0.05),
                        ),
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Libellé')),
                          DataColumn(
                              label: Text('Débit'), numeric: true),
                          DataColumn(
                              label: Text('Crédit'), numeric: true),
                        ],
                        rows: recent.map((m) {
                          return DataRow(cells: [
                            DataCell(Text(dateFormat.format(m.date),
                                style: const TextStyle(fontSize: 12))),
                            DataCell(
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                child: Text(
                                  m.libelle,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(Text(
                              m.debit > 0
                                  ? numberFormat.format(m.debit)
                                  : '',
                              style: const TextStyle(fontSize: 12),
                            )),
                            DataCell(Text(
                              m.credit > 0
                                  ? numberFormat.format(m.credit)
                                  : '',
                              style: const TextStyle(fontSize: 12),
                            )),
                          ]);
                        }).toList(),
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

  Widget _sectionTitle(BuildContext context, IconData icon, String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ChurchTheme.navy),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ChurchTheme.navy,
                  ),
            ),
          ],
        ),
      );

  static Color _natureColor(NatureCompte n) => switch (n) {
        NatureCompte.actif => Colors.blue,
        NatureCompte.passif => Colors.purple,
        NatureCompte.charge => Colors.red,
        NatureCompte.produit => Colors.green,
      };

  static String _natureLabel(NatureCompte n) => switch (n) {
        NatureCompte.actif => 'Actif',
        NatureCompte.passif => 'Passif',
        NatureCompte.charge => 'Charge',
        NatureCompte.produit => 'Produit',
      };

  static Color _soldeColor(double solde) =>
      solde >= 0 ? Colors.green.shade700 : Colors.red.shade700;
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

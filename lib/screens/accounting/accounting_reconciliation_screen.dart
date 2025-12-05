import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/releve_bancaire.dart';
import '../../providers/accounting_providers.dart';

class AccountingReconciliationScreen extends ConsumerStatefulWidget {
  const AccountingReconciliationScreen({super.key});

  @override
  ConsumerState<AccountingReconciliationScreen> createState() =>
      _AccountingReconciliationScreenState();
}

class _AccountingReconciliationScreenState
    extends ConsumerState<AccountingReconciliationScreen> {
  String? _compteBanqueSelectionneId;

  @override
  Widget build(BuildContext context) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);
    final relevesAsync = ref.watch(lignesRelevesBancairesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapprochement bancaire'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: comptesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => const Center(
            child: Text('Erreur chargement plan de comptes'),
          ),
          data: (comptes) {
            final releves = relevesAsync.asData?.value ?? [];
            final comptesBanque =
                comptes.where((c) => c.numero.startsWith('512')).toList();
            return _buildContent(
              context: context,
              comptesBanque: comptesBanque,
              ecritures: ecritures,
              releves: releves,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required List<CompteComptable> comptesBanque,
    required List<EcritureComptable> ecritures,
    required List<LigneReleveBancaire> releves,
  }) {
    var selectedId = _compteBanqueSelectionneId;
    if (selectedId == null && comptesBanque.isNotEmpty) {
      selectedId = comptesBanque.first.id;
      _compteBanqueSelectionneId = selectedId;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Compte bancaire :'),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedId,
              items: comptesBanque
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.numero} - ${c.intitule}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _compteBanqueSelectionneId = v;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (selectedId == null)
          const Text('Aucun compte bancaire disponible.')
        else
          _buildReconciliationPanels(
            context: context,
            compteId: selectedId,
            ecritures: ecritures,
            releves: releves,
          ),
      ],
    );
  }

  Widget _buildReconciliationPanels({
    required BuildContext context,
    required String compteId,
    required List<EcritureComptable> ecritures,
    required List<LigneReleveBancaire> releves,
  }) {
    final ecrituresCompte = ecritures
        .where(
          (e) =>
              e.lignes.any((l) => l.idCompteComptable == compteId),
        )
        .toList();
    final relevesCompte = releves
        .where((r) => r.idCompteBanque == compteId)
        .toList()
      ..sort((a, b) => a.dateOperation.compareTo(b.dateOperation));

    final soldeComptable = _calculerSoldeActif(compteId, ecritures);
    final soldeReleve =
        relevesCompte.isEmpty ? 0 : relevesCompte.last.soldeApresOperation;
    final ecart = soldeComptable - soldeReleve;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildEcrituresTable(
                    ecrituresCompte: ecrituresCompte,
                    compteId: compteId,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReleveTable(
                    releves: relevesCompte,
                    ecritures: ecrituresCompte,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Solde comptable : ${soldeComptable.toStringAsFixed(0)}'),
              const SizedBox(width: 16),
              Text('Solde releve : ${soldeReleve.toStringAsFixed(0)}'),
              const SizedBox(width: 16),
              Text(
                'Ecart : ${ecart.toStringAsFixed(0)}',
                style: TextStyle(
                  color: ecart.abs() < 0.01 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcrituresTable({
    required List<EcritureComptable> ecrituresCompte,
    required String compteId,
  }) {
    final lignes = <_LigneEcritureCompte>[];
    for (final e in ecrituresCompte) {
      double debit = 0;
      double credit = 0;
      for (final l in e.lignes) {
        if (l.idCompteComptable == compteId) {
          debit += l.debit ?? 0;
          credit += l.credit ?? 0;
        }
      }
      lignes.add(
        _LigneEcritureCompte(
          date: e.date,
          libelle: e.libelle,
          reference: e.referencePiece,
          debit: debit,
          credit: credit,
        ),
      );
    }
    lignes.sort((a, b) => a.date.compareTo(b.date));

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Libelle')),
            DataColumn(label: Text('Debit')),
            DataColumn(label: Text('Credit')),
            DataColumn(label: Text('Pointe')),
          ],
          rows: lignes
              .map(
                (l) => DataRow(
                  cells: [
                    DataCell(Text(_formatDate(l.date))),
                    DataCell(Text(l.reference ?? '')),
                    DataCell(Text(l.libelle)),
                    DataCell(Text(l.debit.toStringAsFixed(0))),
                    DataCell(Text(l.credit.toStringAsFixed(0))),
                    const DataCell(Icon(Icons.check_circle_outline)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildReleveTable({
    required List<LigneReleveBancaire> releves,
    required List<EcritureComptable> ecritures,
  }) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Libelle')),
            DataColumn(label: Text('Montant')),
            DataColumn(label: Text('Solde')),
            DataColumn(label: Text('Pointe')),
            DataColumn(label: Text('Associer')),
          ],
          rows: releves
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(Text(_formatDate(r.dateOperation))),
                    DataCell(Text(r.libelle)),
                    DataCell(Text(r.montant.toStringAsFixed(0))),
                    DataCell(Text(r.soldeApresOperation.toStringAsFixed(0))),
                    DataCell(
                      Checkbox(
                        value: r.estPointe,
                        onChanged: (v) {
                          final notifier = ref.read(
                            lignesRelevesBancairesProvider.notifier,
                          );
                          notifier.mettreAJourLigneReleve(
                            r.copyWith(estPointe: v ?? false),
                          );
                        },
                      ),
                    ),
                    DataCell(
                      TextButton(
                        onPressed: () => _ouvrirDialogAssociation(
                          r,
                          ecritures,
                        ),
                        child: const Text('Associer'),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _ouvrirDialogAssociation(
    LigneReleveBancaire ligne,
    List<EcritureComptable> ecritures,
  ) async {
    EcritureComptable? selection;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Associer a une ecriture'),
        content: SizedBox(
          width: 420,
          height: 360,
          child: ListView.builder(
            itemCount: ecritures.length,
            itemBuilder: (context, index) {
              final e = ecritures[index];
              return ListTile(
                title: Text(e.libelle),
                subtitle: Text(
                  '${_formatDate(e.date)} - Ref: ${e.referencePiece ?? ''}',
                ),
                onTap: () {
                  selection = e;
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selection != null) {
      final notifier = ref.read(lignesRelevesBancairesProvider.notifier);
      notifier.mettreAJourLigneReleve(
        ligne.copyWith(
          estPointe: true,
          idEcritureComptableLiee: selection!.id,
        ),
      );
    }
  }

  double _calculerSoldeActif(
    String idCompte,
    List<EcritureComptable> ecritures,
  ) {
    double debit = 0;
    double credit = 0;
    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable == idCompte) {
          debit += l.debit ?? 0;
          credit += l.credit ?? 0;
        }
      }
    }
    return debit - credit;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _LigneEcritureCompte {
  _LigneEcritureCompte({
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

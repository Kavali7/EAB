import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/profil_utilisateur.dart';
import '../../providers/accounting_providers.dart';
import '../../providers/user_profile_providers.dart';

class AccountingTreasuryScreen extends ConsumerStatefulWidget {
  const AccountingTreasuryScreen({super.key});

  @override
  ConsumerState<AccountingTreasuryScreen> createState() =>
      _AccountingTreasuryScreenState();
}

class _AccountingTreasuryScreenState
    extends ConsumerState<AccountingTreasuryScreen> {
  String? _compteSelectionneId;

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profilUtilisateurCourantProvider);
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tresorerie (Caisses & Banques)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: comptesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => const Center(
            child: Text('Erreur chargement plan de comptes'),
          ),
          data: (comptes) {
            return _buildContent(
              context: context,
              profil: profil,
              comptes: comptes,
              ecritures: ecritures,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required ProfilUtilisateur? profil,
    required List<CompteComptable> comptes,
    required List<EcritureComptable> ecritures,
  }) {
    final comptesCaisse =
        comptes.where((c) => c.numero.startsWith('531')).toList();
    final comptesBanque =
        comptes.where((c) => c.numero.startsWith('512')).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caisses',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildTableTresorerie(
            comptes: comptesCaisse,
            ecritures: ecritures,
            titreActions: 'Voir details',
          ),
          const SizedBox(height: 24),
          Text(
            'Banques',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildTableTresorerie(
            comptes: comptesBanque,
            ecritures: ecritures,
            titreActions: 'Voir details',
          ),
          const SizedBox(height: 24),
          if (_compteSelectionneId != null)
            _buildDetailsCompte(
              context: context,
              ecritures: ecritures,
            )
          else
            const Text(
              'Selectionnez un compte pour voir le detail des mouvements.',
            ),
        ],
      ),
    );
  }

  Widget _buildTableTresorerie({
    required List<CompteComptable> comptes,
    required List<EcritureComptable> ecritures,
    required String titreActions,
  }) {
    if (comptes.isEmpty) {
      return const Text('Aucun compte trouve.');
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Compte')),
            DataColumn(label: Text('Intitule')),
            DataColumn(label: Text('Solde')),
            DataColumn(label: Text('Actions')),
          ],
          rows: comptes.map((c) {
            final solde = _calculerSoldeActif(c.id, ecritures);
            return DataRow(
              cells: [
                DataCell(Text(c.numero)),
                DataCell(Text(c.intitule)),
                DataCell(Text(solde.toStringAsFixed(0))),
                DataCell(
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _compteSelectionneId = c.id;
                      });
                    },
                    child: Text(titreActions),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailsCompte({
    required BuildContext context,
    required List<EcritureComptable> ecritures,
  }) {
    final mouvements = _extraireMouvements(_compteSelectionneId!, ecritures);
    final solde = _calculerSoldeActif(_compteSelectionneId!, ecritures);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mouvements du compte',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Solde calcule : ${solde.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: mouvements.length,
                itemBuilder: (context, index) {
                  final m = mouvements[index];
                  return ListTile(
                    dense: true,
                    title: Text(m.libelle),
                    subtitle: Text(
                      '${_formatDate(m.date)} - Ref: ${m.reference ?? ''}',
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Debit: ${m.debit.toStringAsFixed(0)}'),
                        Text('Credit: ${m.credit.toStringAsFixed(0)}'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  List<_MouvementTresorerie> _extraireMouvements(
    String idCompte,
    List<EcritureComptable> ecritures,
  ) {
    final result = <_MouvementTresorerie>[];
    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable == idCompte) {
          final debit = l.debit ?? 0;
          final credit = l.credit ?? 0;
          result.add(
            _MouvementTresorerie(
              date: e.date,
              libelle: (l.libelle?.isNotEmpty ?? false) ? l.libelle! : e.libelle,
              debit: debit,
              credit: credit,
              reference: e.referencePiece,
            ),
          );
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MouvementTresorerie {
  _MouvementTresorerie({
    required this.date,
    required this.libelle,
    required this.debit,
    required this.credit,
    required this.reference,
  });

  final DateTime date;
  final String libelle;
  final double debit;
  final double credit;
  final String? reference;
}

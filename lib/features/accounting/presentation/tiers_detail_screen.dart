/// Fiche détaillée d'un tiers — historique des opérations et balance.
///
/// Affiche les informations du tiers et ses écritures comptables.
/// Flèche retour pour revenir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/models/tiers.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/ecriture_comptable.dart';
import 'package:eab/providers/accounting_providers.dart';

class TiersDetailScreen extends ConsumerWidget {
  const TiersDetailScreen({super.key, required this.tiers});

  final Tiers tiers;

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
        title: Text(tiers.nom),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête tiers ──
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          _typeColor(tiers.type).withValues(alpha: 0.15),
                      child: Icon(_typeIcon(tiers.type),
                          size: 28, color: _typeColor(tiers.type)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tiers.nom,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor(tiers.type)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _typeLabel(tiers.type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _typeColor(tiers.type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Coordonnées ──
            if (tiers.telephone != null ||
                tiers.email != null ||
                tiers.adresse != null) ...[
              _sectionTitle(context, Icons.contact_mail, 'Coordonnées'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (tiers.telephone != null)
                        _infoRow(Icons.phone, 'Téléphone', tiers.telephone!),
                      if (tiers.email != null)
                        _infoRow(Icons.email, 'Email', tiers.email!),
                      if (tiers.adresse != null)
                        _infoRow(
                            Icons.location_on, 'Adresse', tiers.adresse!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Historique des opérations ──
            _sectionTitle(context, Icons.receipt_long, 'Opérations'),
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
                // Trouver les écritures liées à ce tiers
                final tiersEcritures = ecritures.where((e) {
                  // Recherche dans le libellé ou dans les lignes
                  final nameMatch = e.libelle
                      .toLowerCase()
                      .contains(tiers.nom.toLowerCase());
                  return nameMatch;
                }).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                if (tiersEcritures.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune opération pour ce tiers',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Calcul balance
                double totalDebit = 0;
                double totalCredit = 0;
                for (final e in tiersEcritures) {
                  for (final l in e.lignes) {
                    totalDebit += l.debit;
                    totalCredit += l.credit;
                  }
                }

                return Column(
                  children: [
                    // Balance tiers
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _balanceItem('Débit', totalDebit, Colors.red,
                                numberFormat),
                            const SizedBox(width: 16),
                            _balanceItem('Crédit', totalCredit,
                                Colors.green, numberFormat),
                            const SizedBox(width: 16),
                            _balanceItem(
                              'Solde',
                              totalDebit - totalCredit,
                              (totalDebit - totalCredit) >= 0
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              numberFormat,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Liste des opérations
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tiersEcritures.length.clamp(0, 20),
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = tiersEcritures[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              e.statut == StatutEcriture.brouillon
                                  ? Icons.edit_note
                                  : Icons.check_circle,
                              color: e.statut == StatutEcriture.brouillon
                                  ? Colors.orange
                                  : Colors.green,
                              size: 20,
                            ),
                            title: Text(e.libelle,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              dateFormat.format(e.date),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                            ),
                          );
                        },
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

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _balanceItem(
          String label, double value, Color color, NumberFormat fmt) =>
      Expanded(
        child: Column(
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              fmt.format(value.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  static Color _typeColor(TypeTiers t) => switch (t) {
        TypeTiers.fournisseur => Colors.blue,
        TypeTiers.client => Colors.green,
        TypeTiers.employe => Colors.orange,
        TypeTiers.autre => Colors.grey,
      };

  static IconData _typeIcon(TypeTiers t) => switch (t) {
        TypeTiers.fournisseur => Icons.store,
        TypeTiers.client => Icons.person,
        TypeTiers.employe => Icons.badge,
        TypeTiers.autre => Icons.business,
      };

  static String _typeLabel(TypeTiers t) => switch (t) {
        TypeTiers.fournisseur => 'Fournisseur',
        TypeTiers.client => 'Client',
        TypeTiers.employe => 'Employé',
        TypeTiers.autre => 'Autre',
      };
}

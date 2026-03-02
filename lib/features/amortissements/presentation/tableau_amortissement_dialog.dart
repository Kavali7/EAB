/// Dialog affichant le tableau d'amortissement d'une immobilisation.
///
/// Affiche année par année : dotation, cumul, VNC.
/// Bouton pour générer l'écriture de dotation annuelle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


import 'package:eab/models/immobilisation_comptable.dart';
import 'package:eab/ui/ui.dart';
import '../application/amortissement_providers.dart';
import '../services/amortissement_service.dart';

final _fmt = NumberFormat('#,##0', 'fr_FR');

/// Ouvre le dialog du tableau d'amortissement.
Future<void> showTableauAmortissement(
  BuildContext context,
  ImmobilisationComptable immo,
) async {
  await showDialog(
    context: context,
    builder: (_) => _TableauAmortissementDialog(immo: immo),
  );
}

class _TableauAmortissementDialog extends ConsumerStatefulWidget {
  const _TableauAmortissementDialog({required this.immo});

  final ImmobilisationComptable immo;

  @override
  ConsumerState<_TableauAmortissementDialog> createState() =>
      _TableauAmortissementDialogState();
}

class _TableauAmortissementDialogState
    extends ConsumerState<_TableauAmortissementDialog> {
  late List<LigneAmortissement> _lignes;


  @override
  void initState() {
    super.initState();
    _calculer();
  }

  void _calculer() {
    final service = ref.read(amortissementServiceProvider);
    _lignes = service.calculerTableau(widget.immo);
  }

  @override
  Widget build(BuildContext context) {
    final immo = widget.immo;
    final vnc = _lignes.isNotEmpty
        ? _lignes.last.valeurNetteComptable
        : immo.valeurAcquisition;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tableau d\'amortissement',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          immo.libelle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Résumé
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _resumeItem('Valeur acquisition', immo.valeurAcquisition),
                  _resumeItem('Résiduelle', immo.valeurResiduelle ?? 0),
                  _resumeItem('Base amortissable',
                      immo.valeurAcquisition - (immo.valeurResiduelle ?? 0)),
                  _resumeItem('Durée', immo.dureeUtiliteEnAnnees.toDouble(),
                      suffix: ' ans'),
                  _resumeItem('VNC actuelle', vnc),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tableau
            Expanded(
              child: _lignes.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.timeline,
                        message: 'Aucun amortissement calculable.',
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Année', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Base', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                            DataColumn(label: Text('Dotation', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                            DataColumn(label: Text('Cumul', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                            DataColumn(label: Text('VNC', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          ],
                          rows: _lignes.map((l) {
                            final isCurrent = l.annee == DateTime.now().year;
                            final isPast = l.annee < DateTime.now().year;
                            return DataRow(
                              color: isCurrent
                                  ? WidgetStateProperty.all(Colors.blue.withValues(alpha: 0.05))
                                  : null,
                              cells: [
                                DataCell(Row(children: [
                                  Text(
                                    '${l.annee}',
                                    style: TextStyle(
                                      fontWeight: isCurrent ? FontWeight.bold : null,
                                      color: isPast ? Colors.grey : null,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Actuel',
                                          style: TextStyle(fontSize: 9, color: Colors.blue)),
                                    ),
                                  ],
                                ])),
                                DataCell(Text(_fmt.format(l.baseAmortissable))),
                                DataCell(Text(
                                  '${_fmt.format(l.dotation)} FCFA',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                )),
                                DataCell(Text('${_fmt.format(l.amortissementCumule)} FCFA')),
                                DataCell(Text(
                                  '${_fmt.format(l.valeurNetteComptable)} FCFA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: l.valeurNetteComptable > 0
                                        ? Colors.green[700]
                                        : Colors.grey,
                                  ),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),

            // Footer actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumeItem(String label, double value, {String suffix = ' FCFA'}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          '${_fmt.format(value)}$suffix',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

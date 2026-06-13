/// Dialog affichant le tableau d'amortissement d'une immobilisation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/models/immobilisation_comptable.dart';
import 'package:eab/ui/ui.dart';
import '../application/amortissement_providers.dart';
import '../services/amortissement_service.dart';

final _fmt = NumberFormat('#,##0', 'fr_FR');

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
    final tableHeight = (MediaQuery.sizeOf(context).height * 0.46).clamp(
      240.0,
      420.0,
    );
    final vnc = _lignes.isNotEmpty
        ? _lignes.last.valeurNetteComptable
        : immo.valeurAcquisition;

    return EabDialog(
      title: 'Tableau d\'amortissement',
      width: 860,
      scrollable: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            immo.libelle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _resumeItem('Valeur acquisition', immo.valeurAcquisition),
              _resumeItem('Residuelle', immo.valeurResiduelle ?? 0),
              _resumeItem(
                'Base amortissable',
                immo.valeurAcquisition - (immo.valeurResiduelle ?? 0),
              ),
              _resumeItem(
                'Duree',
                immo.dureeUtiliteEnAnnees.toDouble(),
                suffix: ' ans',
              ),
              _resumeItem('VNC actuelle', vnc),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          SizedBox(
            height: tableHeight,
            child: _lignes.isEmpty
                ? const Center(
                    child: EmptyState(
                      icon: Icons.timeline,
                      message: 'Aucun amortissement calculable.',
                    ),
                  )
                : Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade100,
                          ),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Annee',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Base',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Dotation',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Cumul',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'VNC',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                          ],
                          rows: _lignes.map((l) {
                            final isCurrent = l.annee == DateTime.now().year;
                            final isPast = l.annee < DateTime.now().year;
                            return DataRow(
                              color: isCurrent
                                  ? WidgetStateProperty.all(
                                      Colors.blue.withValues(alpha: 0.05),
                                    )
                                  : null,
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Text(
                                        '${l.annee}',
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : null,
                                          color: isPast ? Colors.grey : null,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Actuel',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                DataCell(Text(_fmt.format(l.baseAmortissable))),
                                DataCell(
                                  Text(
                                    '${_fmt.format(l.dotation)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${_fmt.format(l.amortissementCumule)} FCFA',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${_fmt.format(l.valeurNetteComptable)} FCFA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: l.valeurNetteComptable > 0
                                          ? Colors.green[700]
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      actions: [
        EabButton(
          label: 'Fermer',
          variant: EabButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _resumeItem(String label, double value, {String suffix = ' FCFA'}) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            '${_fmt.format(value)}$suffix',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

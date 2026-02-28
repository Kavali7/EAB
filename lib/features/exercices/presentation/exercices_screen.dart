/// Écran de gestion des exercices comptables.
///
/// Permet de créer, ouvrir et clôturer les exercices.
/// Affiche un badge de l'exercice ouvert et un tableau avec les détails.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/exercice_comptable.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import '../application/exercices_providers.dart';
import '../data/exercices_repository.dart';
import 'exercice_form_dialog.dart';

/// Labels des statuts d'exercice.
const _statutLabels = {
  StatutExercice.brouillon: 'Brouillon',
  StatutExercice.ouvert: 'Ouvert',
  StatutExercice.cloture: 'Clôturé',
};

Color _statutColor(StatutExercice s) => switch (s) {
      StatutExercice.brouillon => Colors.grey,
      StatutExercice.ouvert => Colors.green,
      StatutExercice.cloture => Colors.blue,
    };

class ExercicesScreen extends ConsumerStatefulWidget {
  const ExercicesScreen({super.key});

  @override
  ConsumerState<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends ConsumerState<ExercicesScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final exercicesAsync = ref.watch(exercicesListProvider);
    final exerciceOuvert = ref.watch(exerciceOuvertProvider);
    final exercices = exercicesAsync.value ?? [];

    return AppShell(
      title: 'Exercices comptables',
      currentRoute: '/accounting-exercices',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExerciceFormDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel exercice'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ContextHeader(showPorteeComptable: false),
              const SizedBox(height: AppSpacing.cardGap),

              // Badge exercice ouvert
              exerciceOuvert.when(
                data: (ouvert) => ouvert != null
                    ? Card(
                        color: Colors.green.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green[700]),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exercice ouvert : ${ouvert.annee}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${dateFormatter.format(ouvert.dateDebut)} → ${dateFormatter.format(ouvert.dateFin)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        color: Colors.red.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700]),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Aucun exercice ouvert — la saisie d\'écritures est bloquée.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Table des exercices
              SectionCard(
                title: 'Exercices (${exercices.length})',
                child: EabTable<ExerciceComptable>(
                  isLoading: exercicesAsync.isLoading && exercices.isEmpty,
                  emptyMessage: 'Aucun exercice',
                  emptyIcon: Icons.calendar_month,
                  items: exercices,
                  rowsPerPage: 10,
                  columns: [
                    EabColumn<ExerciceComptable>(
                      label: 'Année',
                      flex: 1,
                      sortKeyExtractor: (e) => e.annee,
                      cellBuilder: (e) => Text(
                        '${e.annee}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    EabColumn<ExerciceComptable>(
                      label: 'Période',
                      flex: 2,
                      cellBuilder: (e) => Text(
                        '${dateFormatter.format(e.dateDebut)} → ${dateFormatter.format(e.dateFin)}',
                      ),
                    ),
                    EabColumn<ExerciceComptable>(
                      label: 'Libellé',
                      flex: 2,
                      cellBuilder: (e) => Text(e.libelle ?? '—'),
                    ),
                    EabColumn<ExerciceComptable>(
                      label: 'Statut',
                      flex: 1,
                      cellBuilder: (e) => Chip(
                        label: Text(
                          _statutLabels[e.statut] ?? e.statut.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: _statutColor(e.statut),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    EabColumn<ExerciceComptable>(
                      label: 'Clôturé le',
                      flex: 2,
                      cellBuilder: (e) => Text(
                        e.clotureAt != null
                            ? dateFormatter.format(e.clotureAt!)
                            : '—',
                      ),
                    ),
                    EabColumn<ExerciceComptable>(
                      label: 'Actions',
                      flex: 2,
                      cellBuilder: (e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (e.statut == StatutExercice.brouillon)
                            EabButton(
                              label: 'Ouvrir',
                              variant: EabButtonVariant.secondary,
                              size: EabButtonSize.small,
                              isLoading: _isProcessing,
                              onPressed: () => _openExercice(e),
                            ),
                          if (e.statut == StatutExercice.ouvert) ...[
                            EabButton(
                              label: 'Clôturer',
                              variant: EabButtonVariant.danger,
                              size: EabButtonSize.small,
                              isLoading: _isProcessing,
                              onPressed: () => _cloturerExercice(e),
                            ),
                          ],
                          if (e.statut == StatutExercice.brouillon) ...[
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _deleteExercice(e),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExercice(ExerciceComptable exercice) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Ouvrir l\'exercice ${exercice.annee}',
      message:
          'L\'exercice ${exercice.annee} sera ouvert pour la saisie. '
          'Un seul exercice peut être ouvert à la fois.',
      confirmLabel: 'Ouvrir',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(exercicesRepositoryProvider).openExercice(exercice.id);
      ref.invalidate(exercicesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Exercice ${exercice.annee} ouvert avec succès.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cloturerExercice(ExerciceComptable exercice) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Clôturer l\'exercice ${exercice.annee}',
      message:
          '⚠️ La clôture est irréversible. '
          'Toutes les écritures seront verrouillées.\n\n'
          'Une écriture de résultat (classes 6/7) et des à-nouveaux '
          '(classes 1-5) seront automatiquement créées.',
      confirmLabel: 'Clôturer',
      isDanger: true,
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(exercicesRepositoryProvider)
          .cloturerExercice(exercice.id);
      ref.invalidate(exercicesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Exercice ${exercice.annee} clôturé avec succès.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteExercice(ExerciceComptable exercice) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Supprimer l\'exercice ${exercice.annee}',
      message: 'Êtes-vous sûr de vouloir supprimer cet exercice ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;

    await ref.read(exercicesRepositoryProvider).delete(exercice.id);
    ref.invalidate(exercicesListProvider);
  }
}

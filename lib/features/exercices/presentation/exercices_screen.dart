/// Ecran de gestion des exercices comptables.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/exercice_comptable.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';

import '../application/exercices_providers.dart';
import 'exercice_form_dialog.dart';

const _statutLabels = {
  StatutExercice.brouillon: 'Brouillon',
  StatutExercice.ouvert: 'Ouvert',
  StatutExercice.cloture: 'Cloture',
};

Color _statutColor(StatutExercice statut) {
  return switch (statut) {
    StatutExercice.brouillon => AppColors.textSecondary,
    StatutExercice.ouvert => AppColors.success,
    StatutExercice.cloture => AppColors.info,
  };
}

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
      showBackButton: true,
      backRoute: '/accounting',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final sorted = [...exercices]
            ..sort((a, b) => b.annee.compareTo(a.annee));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.lg : AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ContextHeader(showPorteeComptable: false),
                    const SizedBox(height: AppSpacing.md),
                    _HeaderActions(
                      count: sorted.length,
                      compact: compact,
                      onCreate: () => showExerciceFormDialog(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    exerciceOuvert.when(
                      data: (ouvert) => _OpenExerciseBanner(exercice: ouvert),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: exercicesAsync.isLoading && sorted.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : sorted.isEmpty
                          ? const _EmptyState(
                              message: 'Aucun exercice comptable cree.',
                            )
                          : compact
                          ? ListView.separated(
                              itemCount: sorted.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) => _ExerciseCard(
                                exercice: sorted[index],
                                isProcessing: _isProcessing,
                                onOpen: _openExercice,
                                onClose: _cloturerExercice,
                                onDelete: _deleteExercice,
                              ),
                            )
                          : _ExerciseTable(
                              exercices: sorted,
                              isProcessing: _isProcessing,
                              onOpen: _openExercice,
                              onClose: _cloturerExercice,
                              onDelete: _deleteExercice,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openExercice(ExerciceComptable exercice) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Ouvrir l exercice ${exercice.annee}',
      message:
          'L exercice ${exercice.annee} sera ouvert pour la saisie. '
          'Un seul exercice peut etre ouvert a la fois.',
      confirmLabel: 'Ouvrir',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(exercicesRepositoryProvider).openExercice(exercice.id);
      ref.invalidate(exercicesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exercice ${exercice.annee} ouvert.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cloturerExercice(ExerciceComptable exercice) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Cloturer l exercice ${exercice.annee}',
      message:
          'La cloture est irreversible. Toutes les ecritures seront verrouillees. '
          'Les ecritures de resultat et les a-nouveaux seront crees automatiquement.',
      confirmLabel: 'Cloturer',
      isDanger: true,
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(exercicesRepositoryProvider).cloturerExercice(exercice.id);
      ref.invalidate(exercicesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exercice ${exercice.annee} cloture.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteExercice(ExerciceComptable exercice) async {
    final confirmed = await EabDialog.confirm(
      context,
      title: 'Supprimer l exercice ${exercice.annee}',
      message: 'Voulez-vous supprimer cet exercice en brouillon ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;

    await ref.read(exercicesRepositoryProvider).delete(exercice.id);
    ref.invalidate(exercicesListProvider);
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.count,
    required this.compact,
    required this.onCreate,
  });

  final int count;
  final bool compact;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cycle comptable', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text('$count exercices suivis', style: AppTextStyles.bodySmall),
      ],
    );
    final action = ElevatedButton.icon(
      onPressed: onCreate,
      icon: const Icon(Icons.add),
      label: const Text('Nouvel exercice'),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: AppSpacing.sm),
          action,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: titleBlock),
        action,
      ],
    );
  }
}

class _OpenExerciseBanner extends StatelessWidget {
  const _OpenExerciseBanner({required this.exercice});

  final ExerciceComptable? exercice;

  @override
  Widget build(BuildContext context) {
    final opened = exercice != null;
    final color = opened ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            opened ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: opened
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercice ouvert : ${exercice!.annee}',
                        style: AppTextStyles.subtitle.copyWith(color: color),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${dateFormatter.format(exercice!.dateDebut)} - ${dateFormatter.format(exercice!.dateFin)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  )
                : Text(
                    'Aucun exercice ouvert. La saisie d ecritures est bloquee.',
                    style: AppTextStyles.subtitle.copyWith(color: color),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercice,
    required this.isProcessing,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
  });

  final ExerciceComptable exercice;
  final bool isProcessing;
  final ValueChanged<ExerciceComptable> onOpen;
  final ValueChanged<ExerciceComptable> onClose;
  final ValueChanged<ExerciceComptable> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${exercice.annee} - ${exercice.libelle ?? 'Exercice comptable'}',
                  style: AppTextStyles.subtitle,
                ),
              ),
              _StatusBadge(statut: exercice.statut),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${dateFormatter.format(exercice.dateDebut)} - ${dateFormatter.format(exercice.dateFin)}',
            style: AppTextStyles.bodySmall,
          ),
          if (exercice.clotureAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cloture le ${dateFormatter.format(exercice.clotureAt!)}',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _ExerciseActions(
            exercice: exercice,
            isProcessing: isProcessing,
            onOpen: onOpen,
            onClose: onClose,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ExerciseTable extends StatelessWidget {
  const _ExerciseTable({
    required this.exercices,
    required this.isProcessing,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
  });

  final List<ExerciceComptable> exercices;
  final bool isProcessing;
  final ValueChanged<ExerciceComptable> onOpen;
  final ValueChanged<ExerciceComptable> onClose;
  final ValueChanged<ExerciceComptable> onDelete;

  @override
  Widget build(BuildContext context) {
    return _TableFrame(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Annee')),
          DataColumn(label: Text('Periode')),
          DataColumn(label: Text('Libelle')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Cloture le')),
          DataColumn(label: Text('Actions')),
        ],
        rows: exercices
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text('${e.annee}', style: AppTextStyles.subtitle)),
                  DataCell(
                    Text(
                      '${dateFormatter.format(e.dateDebut)} - ${dateFormatter.format(e.dateFin)}',
                    ),
                  ),
                  DataCell(Text(e.libelle ?? '-')),
                  DataCell(_StatusBadge(statut: e.statut)),
                  DataCell(
                    Text(
                      e.clotureAt != null
                          ? dateFormatter.format(e.clotureAt!)
                          : '-',
                    ),
                  ),
                  DataCell(
                    _ExerciseActions(
                      exercice: e,
                      isProcessing: isProcessing,
                      onOpen: onOpen,
                      onClose: onClose,
                      onDelete: onDelete,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ExerciseActions extends StatelessWidget {
  const _ExerciseActions({
    required this.exercice,
    required this.isProcessing,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
  });

  final ExerciceComptable exercice;
  final bool isProcessing;
  final ValueChanged<ExerciceComptable> onOpen;
  final ValueChanged<ExerciceComptable> onClose;
  final ValueChanged<ExerciceComptable> onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (exercice.statut == StatutExercice.brouillon)
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => onOpen(exercice),
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Ouvrir'),
          ),
        if (exercice.statut == StatutExercice.ouvert)
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => onClose(exercice),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Cloturer'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
        if (exercice.statut == StatutExercice.brouillon)
          IconButton(
            onPressed: isProcessing ? null : () => onDelete(exercice),
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.statut});

  final StatutExercice statut;

  @override
  Widget build(BuildContext context) {
    final color = _statutColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        _statutLabels[statut] ?? statut.name,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableFrame extends StatelessWidget {
  const _TableFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(message, style: AppTextStyles.bodySmall),
      ),
    );
  }
}

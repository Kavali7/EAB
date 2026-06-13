/// Formulaire de creation d'un exercice comptable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/models/compta_enums.dart';
import 'package:eab/models/exercice_comptable.dart';
import 'package:eab/ui/ui.dart';

import '../application/exercices_providers.dart';

Future<void> showExerciceFormDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _ExerciceFormDialog(),
  );
}

class _ExerciceFormDialog extends ConsumerStatefulWidget {
  const _ExerciceFormDialog();

  @override
  ConsumerState<_ExerciceFormDialog> createState() =>
      _ExerciceFormDialogState();
}

class _ExerciceFormDialogState extends ConsumerState<_ExerciceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _anneeCtrl = TextEditingController();
  final _libelleCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anneeCtrl.text = now.year.toString();
    _dateDebut = DateTime(now.year, 1, 1);
    _dateFin = DateTime(now.year, 12, 31);
    _libelleCtrl.text = 'Exercice ${now.year}';
  }

  @override
  void dispose() {
    _anneeCtrl.dispose();
    _libelleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EabDialog(
      title: 'Nouvel exercice comptable',
      width: 520,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = MediaQuery.sizeOf(context).width < 620;
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EabNumberField(
                  label: 'Annee',
                  controller: _anneeCtrl,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2000 || n > 2100) {
                      return 'Annee invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                EabTextField(label: 'Libelle', controller: _libelleCtrl),
                const SizedBox(height: AppSpacing.fieldGap),
                if (compact) ...[
                  EabDateField(
                    label: 'Date debut',
                    value: _dateDebut,
                    onChanged: (d) => setState(() => _dateDebut = d),
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  EabDateField(
                    label: 'Date fin',
                    value: _dateFin,
                    onChanged: (d) => setState(() => _dateFin = d),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: EabDateField(
                          label: 'Date debut',
                          value: _dateDebut,
                          onChanged: (d) => setState(() => _dateDebut = d),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.cardGap),
                      Expanded(
                        child: EabDateField(
                          label: 'Date fin',
                          value: _dateFin,
                          onChanged: (d) => setState(() => _dateFin = d),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        EabButton(
          label: 'Annuler',
          variant: EabButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        EabButton(
          label: 'Creer en brouillon',
          variant: EabButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dates requises')));
      return;
    }
    if (_dateDebut!.isAfter(_dateFin!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date debut doit preceder la date fin'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(exercicesRepositoryProvider);
      await repo.create(
        ExerciceComptable(
          id: '',
          organizationId: '',
          annee: int.parse(_anneeCtrl.text),
          dateDebut: _dateDebut!,
          dateFin: _dateFin!,
          libelle: _libelleCtrl.text.trim().isEmpty
              ? null
              : _libelleCtrl.text.trim(),
          statut: StatutExercice.brouillon,
        ),
      );
      ref.invalidate(exercicesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercice cree avec succes.')),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

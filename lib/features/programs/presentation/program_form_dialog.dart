/// Formulaire d'ajout / modification de programme — v2 avec UI Kit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/models/program.dart';
import 'package:eab/models/member.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/programs_provider.dart';
import 'package:eab/ui/ui.dart';

const _typeVisiteLabels = {
  TypeVisite.fidele: 'Fidèle',
  TypeVisite.autorite: 'Autorité',
  TypeVisite.partenaire: 'Partenaire',
  TypeVisite.autreAssemblee: 'Autre assemblée',
  TypeVisite.autre: 'Autre',
};

/// Ouvre le formulaire d'ajout/modification de programme.
Future<void> showProgramFormV2(BuildContext context, {Program? program}) {
  return showDialog(
    context: context,
    builder: (_) => _ProgramFormV2(program: program),
  );
}

class _ProgramFormV2 extends ConsumerStatefulWidget {
  const _ProgramFormV2({this.program});
  final Program? program;

  @override
  ConsumerState<_ProgramFormV2> createState() => _ProgramFormV2State();
}

class _ProgramFormV2State extends ConsumerState<_ProgramFormV2> {
  final _formKey = GlobalKey<FormState>();
  TypeProgramme? _type;
  DateTime? _date;
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _nombreHommesCtrl = TextEditingController();
  final _nombreFemmesCtrl = TextEditingController();
  final _nombreGarconsCtrl = TextEditingController();
  final _nombreFillesCtrl = TextEditingController();
  final _convHommesCtrl = TextEditingController();
  final _convFemmesCtrl = TextEditingController();
  final _convGarconsCtrl = TextEditingController();
  final _convFillesCtrl = TextEditingController();
  final _classesCtrl = TextEditingController();
  final _moniteursHommesCtrl = TextEditingController();
  final _monitricesFemmesCtrl = TextEditingController();
  final _derniereLeconCtrl = TextEditingController();
  final _compteRenduVisiteCtrl = TextEditingController();
  TypeVisite? _typeVisite;
  final _selectedParticipants = <String>{};
  bool _isSaving = false;

  bool get _isEditing => widget.program != null;
  bool get _isEvangelisationType =>
      _type == TypeProgramme.evangelisationMasse ||
      _type == TypeProgramme.evangelisationPorteAPorte;
  bool get _isEcoleType => _type == TypeProgramme.ecoleDuDimanche;
  bool get _isVisiteType => _type == TypeProgramme.visite;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _type = p?.type ?? TypeProgramme.culte;
    _date = p?.date ?? DateTime.now();
    if (p != null) {
      _locationCtrl.text = p.location;
      _descriptionCtrl.text = p.description ?? '';
      _observationsCtrl.text = p.observations ?? '';
      _selectedParticipants.addAll(p.participantIds);
      _nombreHommesCtrl.text = p.nombreHommes?.toString() ?? '';
      _nombreFemmesCtrl.text = p.nombreFemmes?.toString() ?? '';
      _nombreGarconsCtrl.text = p.nombreGarcons?.toString() ?? '';
      _nombreFillesCtrl.text = p.nombreFilles?.toString() ?? '';
      _convHommesCtrl.text = p.conversionsHommes?.toString() ?? '';
      _convFemmesCtrl.text = p.conversionsFemmes?.toString() ?? '';
      _convGarconsCtrl.text = p.conversionsGarcons?.toString() ?? '';
      _convFillesCtrl.text = p.conversionsFilles?.toString() ?? '';
      _classesCtrl.text = p.nombreClassesEcoleDuDimanche?.toString() ?? '';
      _moniteursHommesCtrl.text = p.nombreMoniteursHommes?.toString() ?? '';
      _monitricesFemmesCtrl.text = p.nombreMonitricesFemmes?.toString() ?? '';
      _derniereLeconCtrl.text = p.derniereLeconEcoleDuDimanche ?? '';
      _typeVisite = p.typeVisite;
      _compteRenduVisiteCtrl.text = p.compteRenduVisite ?? '';
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _observationsCtrl.dispose();
    _nombreHommesCtrl.dispose();
    _nombreFemmesCtrl.dispose();
    _nombreGarconsCtrl.dispose();
    _nombreFillesCtrl.dispose();
    _convHommesCtrl.dispose();
    _convFemmesCtrl.dispose();
    _convGarconsCtrl.dispose();
    _convFillesCtrl.dispose();
    _classesCtrl.dispose();
    _moniteursHommesCtrl.dispose();
    _monitricesFemmesCtrl.dispose();
    _derniereLeconCtrl.dispose();
    _compteRenduVisiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final members = membersAsync.value ?? [];

    return EabDialog(
      title: _isEditing ? 'Modifier le programme' : 'Nouveau programme',
      width: 640,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type + Date
            EabSelectField<TypeProgramme>(
              label: 'Type de programme',
              value: _type,
              items: TypeProgramme.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(typeProgrammeLabels[t]!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _type = v;
                if (_type != TypeProgramme.visite) _typeVisite = null;
              }),
              validator: (v) => v == null ? 'Requis' : null,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            EabDateField(
              label: 'Date et heure',
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // Lieu + Description + Observations
            EabTextField(
              label: 'Lieu',
              controller: _locationCtrl,
              prefixIcon: Icons.location_on,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Lieu requis' : null,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            EabTextField(
              label: 'Description',
              controller: _descriptionCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            EabTextField(
              label: 'Observations',
              controller: _observationsCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Effectifs
            _sectionTitle('Participants (effectifs)'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.cardGap,
              runSpacing: AppSpacing.cardGap,
              children: [
                SizedBox(
                    width: 140,
                    child: EabNumberField(
                        label: 'Hommes', controller: _nombreHommesCtrl)),
                SizedBox(
                    width: 140,
                    child: EabNumberField(
                        label: 'Femmes', controller: _nombreFemmesCtrl)),
                SizedBox(
                    width: 140,
                    child: EabNumberField(
                        label: 'Garçons', controller: _nombreGarconsCtrl)),
                SizedBox(
                    width: 140,
                    child: EabNumberField(
                        label: 'Filles', controller: _nombreFillesCtrl)),
              ],
            ),

            // Conversions (évangélisation)
            if (_isEvangelisationType) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Conversions'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.cardGap,
                runSpacing: AppSpacing.cardGap,
                children: [
                  SizedBox(
                      width: 140,
                      child: EabNumberField(
                          label: 'Hommes', controller: _convHommesCtrl)),
                  SizedBox(
                      width: 140,
                      child: EabNumberField(
                          label: 'Femmes', controller: _convFemmesCtrl)),
                  SizedBox(
                      width: 140,
                      child: EabNumberField(
                          label: 'Garçons', controller: _convGarconsCtrl)),
                  SizedBox(
                      width: 140,
                      child: EabNumberField(
                          label: 'Filles', controller: _convFillesCtrl)),
                ],
              ),
            ],

            // École du dimanche
            if (_isEcoleType) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('École du dimanche'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.cardGap,
                runSpacing: AppSpacing.cardGap,
                children: [
                  SizedBox(
                      width: 160,
                      child: EabNumberField(
                          label: 'Nb classes', controller: _classesCtrl)),
                  SizedBox(
                      width: 160,
                      child: EabNumberField(
                          label: 'Moniteurs H',
                          controller: _moniteursHommesCtrl)),
                  SizedBox(
                      width: 160,
                      child: EabNumberField(
                          label: 'Monitrices F',
                          controller: _monitricesFemmesCtrl)),
                ],
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              EabTextField(
                label: 'Dernière leçon étudiée',
                controller: _derniereLeconCtrl,
              ),
            ],

            // Visite
            if (_isVisiteType) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Visite'),
              const SizedBox(height: AppSpacing.sm),
              EabSelectField<TypeVisite>(
                label: 'Type de visite',
                value: _typeVisite,
                items: TypeVisite.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeVisiteLabels[t]!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _typeVisite = v),
                validator: (v) =>
                    _isVisiteType && v == null ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              EabTextField(
                label: 'Compte-rendu de la visite',
                controller: _compteRenduVisiteCtrl,
                maxLines: 3,
              ),
            ],

            // Participants identifiés
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle('Participants identifiés'),
            const SizedBox(height: AppSpacing.sm),
            if (membersAsync.isLoading && members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: CircularProgressIndicator(),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: members
                    .map(
                      (m) => FilterChip(
                        label: Text(m.fullName),
                        selected: _selectedParticipants.contains(m.id),
                        onSelected: (sel) {
                          setState(() {
                            sel
                                ? _selectedParticipants.add(m.id)
                                : _selectedParticipants.remove(m.id);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      actions: [
        EabButton(
          label: 'Annuler',
          variant: EabButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        EabButton(
          label: _isEditing ? 'Mettre à jour' : 'Enregistrer',
          variant: EabButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  int? _intFromCtrl(TextEditingController c) {
    final raw = c.text.trim();
    return raw.isEmpty ? null : int.tryParse(raw);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null) {
      _snack('Merci de choisir un type de programme');
      return;
    }
    if (_date == null) {
      _snack('Merci de choisir une date');
      return;
    }
    if (_isVisiteType && _typeVisite == null) {
      _snack('Merci de choisir un type de visite');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(programsProvider.notifier);
      final id = widget.program?.id ?? const Uuid().v4();
      final program = Program(
        id: id,
        type: _type!,
        date: _date!,
        location: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        observations: _observationsCtrl.text.trim().isEmpty
            ? null
            : _observationsCtrl.text.trim(),
        participantIds: _selectedParticipants.toList(),
        nombreHommes: _intFromCtrl(_nombreHommesCtrl),
        nombreFemmes: _intFromCtrl(_nombreFemmesCtrl),
        nombreGarcons: _intFromCtrl(_nombreGarconsCtrl),
        nombreFilles: _intFromCtrl(_nombreFillesCtrl),
        conversionsHommes:
            _isEvangelisationType ? _intFromCtrl(_convHommesCtrl) : null,
        conversionsFemmes:
            _isEvangelisationType ? _intFromCtrl(_convFemmesCtrl) : null,
        conversionsGarcons:
            _isEvangelisationType ? _intFromCtrl(_convGarconsCtrl) : null,
        conversionsFilles:
            _isEvangelisationType ? _intFromCtrl(_convFillesCtrl) : null,
        nombreClassesEcoleDuDimanche:
            _isEcoleType ? _intFromCtrl(_classesCtrl) : null,
        nombreMoniteursHommes:
            _isEcoleType ? _intFromCtrl(_moniteursHommesCtrl) : null,
        nombreMonitricesFemmes:
            _isEcoleType ? _intFromCtrl(_monitricesFemmesCtrl) : null,
        derniereLeconEcoleDuDimanche:
            _isEcoleType && _derniereLeconCtrl.text.trim().isNotEmpty
                ? _derniereLeconCtrl.text.trim()
                : null,
        typeVisite: _isVisiteType ? _typeVisite : null,
        compteRenduVisite:
            _isVisiteType && _compteRenduVisiteCtrl.text.trim().isNotEmpty
                ? _compteRenduVisiteCtrl.text.trim()
                : null,
      );

      if (widget.program == null) {
        await notifier.addProgram(program);
      } else {
        await notifier.updateProgram(program);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programme enregistré avec succès.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Formulaire d'ajout / modification d'un fidèle — v2 avec UI Kit.
///
/// Utilise les composants du design system (EabTextField, EabSelectField,
/// EabDateField, EabDialog, EabButton) pour garantir la cohérence visuelle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../models/famille.dart';
import '../../../models/member.dart';
import '../../../providers/members_provider.dart';
import '../../../ui/ui.dart';

const _roleLabels = {
  RoleFidele.membre: 'Membre',
  RoleFidele.pasteur: 'Pasteur',
  RoleFidele.ancien: 'Ancien',
  RoleFidele.diacre: 'Diacre',
  RoleFidele.diaconesse: 'Diaconesse',
  RoleFidele.evangeliste: 'Évangéliste',
  RoleFidele.autreOfficier: 'Autre officier',
};

const _statutFideleLabels = {
  StatutFidele.actif: 'Actif',
  StatutFidele.inactif: 'Inactif',
  StatutFidele.parti: 'Parti',
  StatutFidele.decede: 'Décédé',
  StatutFidele.transfere: 'Transféré',
};

const _vulnerabiliteLabels = {
  VulnerabiliteFidele.orphelin: 'Orphelin',
  VulnerabiliteFidele.veuf: 'Veuf',
  VulnerabiliteFidele.veuve: 'Veuve',
  VulnerabiliteFidele.handicape: 'Handicapé',
  VulnerabiliteFidele.troisiemeAge: '3e âge',
  VulnerabiliteFidele.autre: 'Autre',
};

/// Ouvre le formulaire d'ajout/modification d'un fidèle.
Future<void> showMemberFormV2(
  BuildContext context, {
  Member? member,
  List<Famille> families = const [],
}) {
  return showDialog(
    context: context,
    builder: (_) => _MemberFormV2(member: member, families: families),
  );
}

class _MemberFormV2 extends ConsumerStatefulWidget {
  const _MemberFormV2({this.member, required this.families});
  final Member? member;
  final List<Famille> families;

  @override
  ConsumerState<_MemberFormV2> createState() => _MemberFormV2State();
}

class _MemberFormV2State extends ConsumerState<_MemberFormV2> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _motifSortieCtrl = TextEditingController();

  Gender? _gender;
  MaritalStatus? _maritalStatus;
  StatutMatrimonial? _statutMatrimonial;
  RoleFidele _role = RoleFidele.membre;
  StatutFidele _statut = StatutFidele.actif;
  DateTime? _birthDate;
  DateTime? _dateConversion;
  DateTime? _dateBapteme;
  DateTime? _dateMainAssociation;
  DateTime? _dateEntree;
  DateTime? _dateSortie;
  DateTime? _dateDeces;
  Set<VulnerabiliteFidele> _vulnerabilites = {};
  String? _idFamille;
  bool _isSaving = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    if (m != null) {
      _nameCtrl.text = m.fullName;
      _phoneCtrl.text = m.phone ?? '';
      _emailCtrl.text = m.email ?? '';
      _addressCtrl.text = m.address ?? '';
      _gender = m.gender;
      _maritalStatus = m.maritalStatus;
      _statutMatrimonial = m.statutMatrimonial;
      _birthDate = m.dateNaissance ?? m.birthDate;
      _dateConversion = m.dateConversion;
      _dateBapteme = m.dateBapteme ?? m.baptismDate;
      _dateMainAssociation = m.dateMainAssociation;
      _dateEntree = m.dateEntree;
      _dateSortie = m.dateSortie;
      _dateDeces = m.dateDeces;
      _role = m.role;
      _statut = m.statut;
      _vulnerabilites = {...m.vulnerabilites};
      _motifSortieCtrl.text = m.motifSortie ?? '';
      _idFamille = m.idFamille;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _motifSortieCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EabDialog(
      title: _isEditing ? 'Modifier un fidèle' : 'Nouveau fidèle',
      width: 580,
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Identité ---
            EabTextField(
              label: 'Nom complet',
              controller: _nameCtrl,
              prefixIcon: Icons.person,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nom obligatoire' : null,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            Row(
              children: [
                Expanded(
                  child: EabSelectField<Gender>(
                    label: 'Genre',
                    value: _gender,
                    items: Gender.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(genderLabels[g]!),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (v) =>
                        v == null ? 'Genre obligatoire' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: EabSelectField<MaritalStatus>(
                    label: 'Statut marital',
                    value: _maritalStatus,
                    items: MaritalStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(maritalStatusLabels[s]!),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _maritalStatus = v),
                    validator: (v) =>
                        v == null ? 'Statut marital obligatoire' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            EabSelectField<StatutMatrimonial>(
              label: 'Statut matrimonial',
              value: _statutMatrimonial,
              items: StatutMatrimonial.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _statutMatrimonial = v),
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // --- Rôle & statut ---
            Row(
              children: [
                Expanded(
                  child: EabSelectField<RoleFidele>(
                    label: 'Rôle dans l\'assemblée',
                    value: _role,
                    items: RoleFidele.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(_roleLabels[r]!),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _role = v ?? RoleFidele.membre),
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: EabSelectField<StatutFidele>(
                    label: 'Statut du fidèle',
                    value: _statut,
                    items: StatutFidele.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statutFideleLabels[s]!),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _statut = v ?? StatutFidele.actif),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // --- Dates ---
            Row(
              children: [
                Expanded(
                  child: EabDateField(
                    label: 'Date de naissance',
                    value: _birthDate,
                    onChanged: (d) => setState(() => _birthDate = d),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: EabDateField(
                    label: 'Date d\'entrée',
                    value: _dateEntree,
                    onChanged: (d) => setState(() => _dateEntree = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            Row(
              children: [
                Expanded(
                  child: EabDateField(
                    label: 'Date de conversion',
                    value: _dateConversion,
                    onChanged: (d) => setState(() => _dateConversion = d),
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: EabDateField(
                    label: 'Date de baptême',
                    value: _dateBapteme,
                    onChanged: (d) => setState(() => _dateBapteme = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            Row(
              children: [
                Expanded(
                  child: EabDateField(
                    label: 'Date main d\'association',
                    value: _dateMainAssociation,
                    onChanged: (d) =>
                        setState(() => _dateMainAssociation = d),
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: EabSelectField<String?>(
                    label: 'Famille',
                    value: _idFamille,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Aucune'),
                      ),
                      ...widget.families.map(
                        (f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.nom),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _idFamille = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // --- Champs conditionnels ---
            if (_statut == StatutFidele.parti ||
                _statut == StatutFidele.transfere) ...[
              EabDateField(
                label: 'Date de sortie',
                value: _dateSortie,
                onChanged: (d) => setState(() => _dateSortie = d),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              EabTextField(
                label: 'Motif de sortie',
                controller: _motifSortieCtrl,
              ),
              const SizedBox(height: AppSpacing.fieldGap),
            ],
            if (_statut == StatutFidele.decede) ...[
              EabDateField(
                label: 'Date de décès',
                value: _dateDeces,
                onChanged: (d) => setState(() => _dateDeces = d),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
            ],

            // --- Vulnérabilités ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vulnérabilités',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: VulnerabiliteFidele.values
                  .map(
                    (v) => FilterChip(
                      label: Text(_vulnerabiliteLabels[v] ?? v.name),
                      selected: _vulnerabilites.contains(v),
                      onSelected: (sel) {
                        setState(() {
                          sel
                              ? _vulnerabilites.add(v)
                              : _vulnerabilites.remove(v);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // --- Contact ---
            EabTextField(
              label: 'Téléphone',
              controller: _phoneCtrl,
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            EabTextField(
              label: 'Email',
              controller: _emailCtrl,
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            EabTextField(
              label: 'Adresse',
              controller: _addressCtrl,
              prefixIcon: Icons.location_on,
              maxLines: 2,
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

  // ---------------------------------------------------------------------------
  // Validation et soumission
  // ---------------------------------------------------------------------------

  bool _validateDates() {
    if (_birthDate == null) {
      _snack('Veuillez renseigner la date de naissance.');
      return false;
    }
    if (_dateEntree == null) {
      _snack('Veuillez renseigner la date d\'entrée.');
      return false;
    }
    if (_dateBapteme != null) {
      if (_birthDate != null && _dateBapteme!.isBefore(_birthDate!)) {
        _snack('La date de baptême doit être après la naissance.');
        return false;
      }
      if (_dateConversion != null &&
          _dateBapteme!.isBefore(_dateConversion!)) {
        _snack('La date de baptême doit être après la conversion.');
        return false;
      }
    }
    if ((_statut == StatutFidele.parti ||
            _statut == StatutFidele.transfere) &&
        _dateSortie == null) {
      _snack('Veuillez renseigner la date de sortie.');
      return false;
    }
    if (_statut == StatutFidele.decede && _dateDeces == null) {
      _snack('Veuillez renseigner la date de décès.');
      return false;
    }
    return true;
  }

  MaritalStatus _deriveMaritalStatus() {
    switch (_statutMatrimonial) {
      case StatutMatrimonial.marie:
        return MaritalStatus.married;
      case StatutMatrimonial.veuf:
      case StatutMatrimonial.veuve:
        return MaritalStatus.widowed;
      case StatutMatrimonial.divorce:
      case StatutMatrimonial.separe:
        return MaritalStatus.divorced;
      case StatutMatrimonial.celibataire:
      default:
        return MaritalStatus.single;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Veuillez corriger les erreurs avant de continuer.');
      return;
    }
    if (!_validateDates()) return;

    final id = widget.member?.id ?? const Uuid().v4();
    final member = Member(
      id: id,
      fullName: _nameCtrl.text.trim(),
      gender: _gender!,
      birthDate: _birthDate!,
      maritalStatus: _maritalStatus ?? _deriveMaritalStatus(),
      baptismDate: _dateBapteme,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      dateNaissance: _birthDate,
      statutMatrimonial: _statutMatrimonial,
      dateConversion: _dateConversion,
      dateBapteme: _dateBapteme,
      dateMainAssociation: _dateMainAssociation,
      statut: _statut,
      dateEntree: _dateEntree,
      dateSortie: _dateSortie,
      motifSortie: _motifSortieCtrl.text.trim().isEmpty
          ? null
          : _motifSortieCtrl.text.trim(),
      dateDeces: _dateDeces,
      role: _role,
      vulnerabilites: _vulnerabilites,
      idFamille: _idFamille,
    );

    final notifier = ref.read(membersProvider.notifier);
    setState(() => _isSaving = true);
    try {
      if (widget.member == null) {
        await notifier.addMember(member);
      } else {
        await notifier.updateMember(member);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fidèle enregistré avec succès.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

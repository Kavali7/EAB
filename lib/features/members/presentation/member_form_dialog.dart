library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/models/famille.dart';
import 'package:eab/models/member.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';

const _noChurchUnitValue = '__none__';

const _roleLabels = {
  RoleFidele.membre: 'Membre',
  RoleFidele.pasteur: 'Pasteur',
  RoleFidele.ancien: 'Ancien',
  RoleFidele.diacre: 'Diacre',
  RoleFidele.diaconesse: 'Diaconesse',
  RoleFidele.evangeliste: 'Evangeliste',
  RoleFidele.autreOfficier: 'Autre officier',
};

const _statutFideleLabels = {
  StatutFidele.actif: 'Actif',
  StatutFidele.inactif: 'Inactif',
  StatutFidele.parti: 'Parti',
  StatutFidele.decede: 'Decede',
  StatutFidele.transfere: 'Transfere',
};

const _vulnerabiliteLabels = {
  VulnerabiliteFidele.orphelin: 'Orphelin',
  VulnerabiliteFidele.veuf: 'Veuf',
  VulnerabiliteFidele.veuve: 'Veuve',
  VulnerabiliteFidele.handicape: 'Handicape',
  VulnerabiliteFidele.troisiemeAge: '3e age',
  VulnerabiliteFidele.autre: 'Autre',
};

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
  String? _churchUnitId;
  bool _churchUnitTouched = false;
  bool _churchUnitInitialized = false;
  bool _isSaving = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member != null) {
      _nameCtrl.text = member.fullName;
      _phoneCtrl.text = member.phone ?? '';
      _emailCtrl.text = member.email ?? '';
      _addressCtrl.text = member.address ?? '';
      _gender = member.gender;
      _maritalStatus = member.maritalStatus;
      _statutMatrimonial = member.statutMatrimonial;
      _birthDate = member.dateNaissance ?? member.birthDate;
      _dateConversion = member.dateConversion;
      _dateBapteme = member.dateBapteme ?? member.baptismDate;
      _dateMainAssociation = member.dateMainAssociation;
      _dateEntree = member.dateEntree;
      _dateSortie = member.dateSortie;
      _dateDeces = member.dateDeces;
      _role = member.role;
      _statut = member.statut;
      _vulnerabilites = {...member.vulnerabilites};
      _motifSortieCtrl.text = member.motifSortie ?? '';
      _idFamille = member.idFamille;
      _churchUnitId = member.churchUnitId;
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
    final churchUnitsAsync = ref.watch(churchUnitsProvider);
    final activeAssembleeId = ref.watch(assembleeActiveIdProvider);
    final memberUnits = _memberAssignableUnits(churchUnitsAsync.value ?? []);
    _initializeChurchUnit(memberUnits, activeAssembleeId);

    return EabDialog(
      title: _isEditing ? 'Modifier un fidele' : 'Nouveau fidele',
      width: 780,
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 620;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormSection(
                  title: 'Identite',
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: [
                      EabTextField(
                        label: 'Nom complet',
                        controller: _nameCtrl,
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Nom obligatoire'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      _ResponsiveFields(
                        twoColumns: twoColumns,
                        children: [
                          EabSelectField<Gender>(
                            label: 'Genre',
                            value: _gender,
                            items: Gender.values
                                .map(
                                  (gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(genderLabels[gender]!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _gender = value),
                            validator: (value) =>
                                value == null ? 'Genre obligatoire' : null,
                          ),
                          EabSelectField<MaritalStatus>(
                            label: 'Statut marital',
                            value: _maritalStatus,
                            items: MaritalStatus.values
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(maritalStatusLabels[status]!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _maritalStatus = value),
                            validator: (value) => value == null
                                ? 'Statut marital obligatoire'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      EabSelectField<StatutMatrimonial>(
                        label: 'Statut matrimonial',
                        value: _statutMatrimonial,
                        items: StatutMatrimonial.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _statutMatrimonial = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _FormSection(
                  title: 'Role et rattachement',
                  icon: Icons.account_tree_outlined,
                  child: Column(
                    children: [
                      _ResponsiveFields(
                        twoColumns: twoColumns,
                        children: [
                          EabSelectField<RoleFidele>(
                            label: 'Role dans l\'assemblee',
                            value: _role,
                            items: RoleFidele.values
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(_roleLabels[role]!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _role = value ?? RoleFidele.membre,
                            ),
                          ),
                          EabSelectField<StatutFidele>(
                            label: 'Statut du fidele',
                            value: _statut,
                            items: StatutFidele.values
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(_statutFideleLabels[status]!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _statut = value ?? StatutFidele.actif,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      EabSelectField<String?>(
                        label: 'Famille',
                        value: _idFamille,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Aucune'),
                          ),
                          ...widget.families.map(
                            (family) => DropdownMenuItem(
                              value: family.id,
                              child: Text(family.nom),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _idFamille = value),
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      EabSelectField<String>(
                        label: 'Unite / eglise locale',
                        value: _churchUnitId ?? _noChurchUnitValue,
                        items: [
                          const DropdownMenuItem(
                            value: _noChurchUnitValue,
                            child: Text('Aucune unite rattachee'),
                          ),
                          ...memberUnits.map(
                            (unit) => DropdownMenuItem(
                              value: unit.id,
                              child: Text(_unitLabel(unit)),
                            ),
                          ),
                        ],
                        onChanged: churchUnitsAsync.isLoading
                            ? null
                            : (value) => setState(() {
                                _churchUnitTouched = true;
                                _churchUnitId = value == _noChurchUnitValue
                                    ? null
                                    : value;
                              }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _FormSection(
                  title: 'Dates de parcours',
                  icon: Icons.event_available_outlined,
                  child: Column(
                    children: [
                      _ResponsiveFields(
                        twoColumns: twoColumns,
                        children: [
                          EabDateField(
                            label: 'Date de naissance',
                            value: _birthDate,
                            onChanged: (date) =>
                                setState(() => _birthDate = date),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          ),
                          EabDateField(
                            label: 'Date d\'entree',
                            value: _dateEntree,
                            onChanged: (date) =>
                                setState(() => _dateEntree = date),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      _ResponsiveFields(
                        twoColumns: twoColumns,
                        children: [
                          EabDateField(
                            label: 'Date de conversion',
                            value: _dateConversion,
                            onChanged: (date) =>
                                setState(() => _dateConversion = date),
                          ),
                          EabDateField(
                            label: 'Date de bapteme',
                            value: _dateBapteme,
                            onChanged: (date) =>
                                setState(() => _dateBapteme = date),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      EabDateField(
                        label: 'Date main d\'association',
                        value: _dateMainAssociation,
                        onChanged: (date) =>
                            setState(() => _dateMainAssociation = date),
                      ),
                    ],
                  ),
                ),
                if (_statut == StatutFidele.parti ||
                    _statut == StatutFidele.transfere ||
                    _statut == StatutFidele.decede) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _FormSection(
                    title: 'Sortie du registre',
                    icon: Icons.logout_outlined,
                    child: Column(
                      children: [
                        if (_statut == StatutFidele.parti ||
                            _statut == StatutFidele.transfere) ...[
                          EabDateField(
                            label: 'Date de sortie',
                            value: _dateSortie,
                            onChanged: (date) =>
                                setState(() => _dateSortie = date),
                          ),
                          const SizedBox(height: AppSpacing.fieldGap),
                          EabTextField(
                            label: 'Motif de sortie',
                            controller: _motifSortieCtrl,
                          ),
                        ],
                        if (_statut == StatutFidele.decede)
                          EabDateField(
                            label: 'Date de deces',
                            value: _dateDeces,
                            onChanged: (date) =>
                                setState(() => _dateDeces = date),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _FormSection(
                  title: 'Vulnerabilites',
                  icon: Icons.volunteer_activism_outlined,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: VulnerabiliteFidele.values
                        .map(
                          (vulnerability) => FilterChip(
                            label: Text(
                              _vulnerabiliteLabels[vulnerability] ??
                                  vulnerability.name,
                            ),
                            selected: _vulnerabilites.contains(vulnerability),
                            onSelected: (selected) {
                              setState(() {
                                selected
                                    ? _vulnerabilites.add(vulnerability)
                                    : _vulnerabilites.remove(vulnerability);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _FormSection(
                  title: 'Contact',
                  icon: Icons.contact_phone_outlined,
                  child: Column(
                    children: [
                      _ResponsiveFields(
                        twoColumns: twoColumns,
                        children: [
                          EabTextField(
                            label: 'Telephone',
                            controller: _phoneCtrl,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          EabTextField(
                            label: 'Email',
                            controller: _emailCtrl,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      EabTextField(
                        label: 'Adresse',
                        controller: _addressCtrl,
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        EabButton(
          label: 'Annuler',
          variant: EabButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ),
        EabButton(
          label: _isEditing ? 'Mettre a jour' : 'Enregistrer',
          variant: EabButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _submit,
        ),
      ],
    );
  }

  bool _validateDates() {
    if (_birthDate == null) {
      _snack('Veuillez renseigner la date de naissance.');
      return false;
    }
    if (_dateEntree == null) {
      _snack('Veuillez renseigner la date d\'entree.');
      return false;
    }
    if (_dateBapteme != null) {
      if (_birthDate != null && _dateBapteme!.isBefore(_birthDate!)) {
        _snack('La date de bapteme doit etre apres la naissance.');
        return false;
      }
      if (_dateConversion != null && _dateBapteme!.isBefore(_dateConversion!)) {
        _snack('La date de bapteme doit etre apres la conversion.');
        return false;
      }
    }
    if ((_statut == StatutFidele.parti || _statut == StatutFidele.transfere) &&
        _dateSortie == null) {
      _snack('Veuillez renseigner la date de sortie.');
      return false;
    }
    if (_statut == StatutFidele.decede && _dateDeces == null) {
      _snack('Veuillez renseigner la date de deces.');
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
    final selectedUnit = _unitById(
      ref.read(churchUnitsProvider).value ?? [],
    )[_churchUnitId];
    final legacyAssembleeId =
        selectedUnit?.legacyAssembleeId ??
        (_churchUnitTouched ? null : widget.member?.idAssembleeLocale);
    final member = Member(
      id: id,
      fullName: _nameCtrl.text.trim(),
      gender: _gender!,
      birthDate: _birthDate!,
      maritalStatus: _maritalStatus ?? _deriveMaritalStatus(),
      baptismDate: _dateBapteme,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
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
      churchUnitId: _churchUnitId,
      idAssembleeLocale: legacyAssembleeId,
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
          const SnackBar(content: Text('Fidele enregistre avec succes.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<ChurchUnit> _memberAssignableUnits(List<ChurchUnit> units) {
    final result =
        units
            .where(
              (unit) => unit.active && (unit.canHaveMembers || unit.isLocal),
            )
            .toList()
          ..sort((a, b) {
            final order = a.levelOrder.compareTo(b.levelOrder);
            if (order != 0) return order;
            return a.nom.compareTo(b.nom);
          });
    return result;
  }

  void _initializeChurchUnit(
    List<ChurchUnit> units,
    String? activeAssembleeId,
  ) {
    if (_churchUnitInitialized || units.isEmpty) return;

    final member = widget.member;
    final legacyAssembleeId = member?.idAssembleeLocale ?? activeAssembleeId;
    if (_churchUnitId == null && legacyAssembleeId != null) {
      for (final unit in units) {
        if (unit.legacyAssembleeId == legacyAssembleeId) {
          _churchUnitId = unit.id;
          break;
        }
      }
    }
    _churchUnitInitialized = true;
  }

  Map<String, ChurchUnit> _unitById(List<ChurchUnit> units) {
    return {for (final unit in units) unit.id: unit};
  }

  String _unitLabel(ChurchUnit unit) {
    final code = unit.code == null || unit.code!.trim().isEmpty
        ? ''
        : ' - ${unit.code}';
    return '${unit.nom}$code';
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.twoColumns, required this.children});

  final bool twoColumns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!twoColumns) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const SizedBox(height: AppSpacing.fieldGap),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1)
            const SizedBox(width: AppSpacing.fieldGap),
        ],
      ],
    );
  }
}

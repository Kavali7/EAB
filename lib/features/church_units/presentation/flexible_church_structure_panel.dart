import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/errors/error_handler.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/section_card.dart';

class FlexibleChurchStructurePanel extends ConsumerWidget {
  const FlexibleChurchStructurePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(churchUnitsProvider);
    final typesAsync = ref.watch(churchUnitTypesProvider);
    final organization = ref.watch(currentOrganizationProvider).value;
    final repository = ref.watch(churchUnitsRepositoryProvider);
    final types = typesAsync.value ?? const <ChurchUnitType>[];
    final canEdit =
        repository != null &&
        organization != null &&
        types.isNotEmpty &&
        !types.any((type) => type.id.startsWith('legacy_'));

    return unitsAsync.when(
      loading: () => const SectionCard(
        title: 'Architecture configurable',
        child: SkeletonLoader(lineCount: 3),
      ),
      error: (error, _) => SectionCard(
        title: 'Architecture configurable',
        child: Text(
          'Structure flexible indisponible : $error',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      data: (units) {
        final childrenByParent = _childrenByParent(units);
        final unitIds = units.map((unit) => unit.id).toSet();
        final roots = units
            .where(
              (unit) =>
                  unit.parentId == null || !unitIds.contains(unit.parentId),
            )
            .toList();
        final localCount = units.where((unit) => unit.isLocal).length;
        final financialScopes = units
            .where((unit) => unit.isFinancialScope)
            .length;

        return SectionCard(
          title: 'Architecture configurable',
          actions: [
            _MetricChip(label: 'Unites', value: units.length.toString()),
            _MetricChip(label: 'Locales', value: localCount.toString()),
            _MetricChip(label: 'Perimetres', value: financialScopes.toString()),
            if (canEdit) ...[
              EabButton(
                label: 'Niveaux',
                icon: Icons.layers_outlined,
                size: EabButtonSize.small,
                variant: EabButtonVariant.outline,
                onPressed: () =>
                    _openTypesManager(context, ref, types: types, units: units),
              ),
              EabButton(
                label: 'Unite',
                icon: Icons.add,
                size: EabButtonSize.small,
                onPressed: () => _openUnitDialog(
                  context,
                  ref,
                  types: types,
                  units: units,
                  organizationId: organization.id,
                ),
              ),
            ] else
              const _MetricChip(label: 'Mode', value: 'lecture'),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!canEdit) const _ReadOnlyNotice() else const _EditNotice(),
              const SizedBox(height: AppSpacing.md),
              if (units.isEmpty)
                EmptyState(
                  icon: Icons.account_tree_outlined,
                  message: canEdit
                      ? 'Aucune unite configuree. Creez la premiere unite.'
                      : 'Aucune structure flexible disponible.',
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final root in roots)
                          _UnitNode(
                            unit: root,
                            childrenByParent: childrenByParent,
                            depth: 0,
                            canEdit: canEdit,
                            onAddChild: (unit) => _openUnitDialog(
                              context,
                              ref,
                              types: types,
                              units: units,
                              organizationId: organization!.id,
                              parentId: unit.id,
                            ),
                            onEdit: (unit) => _openUnitDialog(
                              context,
                              ref,
                              types: types,
                              units: units,
                              organizationId: organization!.id,
                              unit: unit,
                            ),
                            onArchive: (unit) => _archiveUnit(
                              context,
                              ref,
                              unit: unit,
                              childrenByParent: childrenByParent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Map<String?, List<ChurchUnit>> _childrenByParent(List<ChurchUnit> units) {
    final map = <String?, List<ChurchUnit>>{};
    for (final unit in units) {
      map.putIfAbsent(unit.parentId, () => []).add(unit);
    }
    for (final children in map.values) {
      children.sort((a, b) {
        final level = a.levelOrder.compareTo(b.levelOrder);
        if (level != 0) return level;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });
    }
    return map;
  }

  Future<void> _openTypesManager(
    BuildContext context,
    WidgetRef ref, {
    required List<ChurchUnitType> types,
    required List<ChurchUnit> units,
  }) async {
    final organization = ref.read(currentOrganizationProvider).value;
    if (organization == null) return;

    await EabDialog.show<void>(
      context,
      title: 'Niveaux de structure',
      width: 620,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in types)
            _TypeTile(
              type: type,
              unitsCount: units.where((unit) => unit.typeId == type.id).length,
              onEdit: () {
                Navigator.of(context).pop();
                _openTypeDialog(
                  context,
                  ref,
                  organizationId: organization.id,
                  type: type,
                );
              },
              onDelete: () {
                Navigator.of(context).pop();
                _deleteType(context, ref, type: type, units: units);
              },
            ),
        ],
      ),
      actions: [
        EabButton(
          label: 'Fermer',
          variant: EabButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        EabButton(
          label: 'Ajouter un niveau',
          icon: Icons.add,
          onPressed: () {
            Navigator.of(context).pop();
            _openTypeDialog(
              context,
              ref,
              organizationId: organization.id,
              nextOrder: types.length,
            );
          },
        ),
      ],
    );
  }

  Future<void> _openTypeDialog(
    BuildContext context,
    WidgetRef ref, {
    required String organizationId,
    ChurchUnitType? type,
    int nextOrder = 0,
  }) async {
    final repository = ref.read(churchUnitsRepositoryProvider);
    if (repository == null) return;

    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: type?.code ?? '');
    final labelCtrl = TextEditingController(text: type?.label ?? '');
    final orderCtrl = TextEditingController(
      text: (type?.levelOrder ?? nextOrder).toString(),
    );
    var isLocal = type?.isLocal ?? false;
    var isFinancialScope = type?.isFinancialScope ?? false;
    var canHaveMembers = type?.canHaveMembers ?? false;

    await EabDialog.show<void>(
      context,
      title: type == null ? 'Nouveau niveau' : 'Modifier le niveau',
      width: 520,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EabTextField(
                  label: 'Libelle *',
                  controller: labelCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) =>
                      _required(value, 'Le libelle est obligatoire.'),
                ),
                const SizedBox(height: AppSpacing.md),
                EabTextField(
                  label: 'Code technique *',
                  controller: codeCtrl,
                  helper: 'Minuscules, chiffres et underscores.',
                  validator: _validateCode,
                ),
                const SizedBox(height: AppSpacing.md),
                EabTextField(
                  label: 'Ordre',
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  validator: (value) => int.tryParse(value ?? '') == null
                      ? 'Nombre requis.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isLocal,
                  title: const Text('Eglise locale'),
                  onChanged: (value) =>
                      setDialogState(() => isLocal = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isFinancialScope,
                  title: const Text('Perimetre comptable'),
                  onChanged: (value) =>
                      setDialogState(() => isFinancialScope = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: canHaveMembers,
                  title: const Text('Peut contenir des fideles'),
                  onChanged: (value) =>
                      setDialogState(() => canHaveMembers = value ?? false),
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        EabButton(
          label: type == null ? 'Creer' : 'Enregistrer',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              if (type == null) {
                await repository.createType(
                  organizationId: organizationId,
                  code: codeCtrl.text.trim(),
                  label: labelCtrl.text.trim(),
                  levelOrder: int.parse(orderCtrl.text.trim()),
                  isLocal: isLocal,
                  isFinancialScope: isFinancialScope,
                  canHaveMembers: canHaveMembers,
                );
              } else {
                await repository.updateType(
                  id: type.id,
                  code: codeCtrl.text.trim(),
                  label: labelCtrl.text.trim(),
                  levelOrder: int.parse(orderCtrl.text.trim()),
                  isLocal: isLocal,
                  isFinancialScope: isFinancialScope,
                  canHaveMembers: canHaveMembers,
                );
              }
              ref.invalidate(churchUnitTypesProvider);
              ref.invalidate(churchUnitsProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                context.showSuccess('Niveau enregistre.');
              }
            } catch (e) {
              if (context.mounted) context.showError(e);
            }
          },
        ),
      ],
    );
  }

  Future<void> _deleteType(
    BuildContext context,
    WidgetRef ref, {
    required ChurchUnitType type,
    required List<ChurchUnit> units,
  }) async {
    final repository = ref.read(churchUnitsRepositoryProvider);
    if (repository == null) return;

    final unitsCount = units.where((unit) => unit.typeId == type.id).length;
    if (unitsCount > 0) {
      context.showWarning(
        'Impossible de supprimer ce niveau : $unitsCount unite(s) l\'utilisent.',
      );
      return;
    }

    final confirmed = await EabDialog.confirm(
      context,
      title: 'Supprimer le niveau',
      message: 'Supprimer definitivement le niveau "${type.label}" ?',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;

    try {
      await repository.deleteType(type.id);
      ref.invalidate(churchUnitTypesProvider);
      if (context.mounted) context.showSuccess('Niveau supprime.');
    } catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  Future<void> _openUnitDialog(
    BuildContext context,
    WidgetRef ref, {
    required List<ChurchUnitType> types,
    required List<ChurchUnit> units,
    required String organizationId,
    ChurchUnit? unit,
    String? parentId,
  }) async {
    final repository = ref.read(churchUnitsRepositoryProvider);
    if (repository == null) return;

    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: unit?.nom ?? '');
    final codeCtrl = TextEditingController(text: unit?.code ?? '');
    final descCtrl = TextEditingController(text: unit?.description ?? '');
    final villeCtrl = TextEditingController(text: unit?.ville ?? '');
    final quartierCtrl = TextEditingController(text: unit?.quartier ?? '');
    final adresseCtrl = TextEditingController(text: unit?.adresse ?? '');
    final telCtrl = TextEditingController(text: unit?.telephone ?? '');
    final emailCtrl = TextEditingController(text: unit?.email ?? '');
    var selectedTypeId = unit?.typeId ?? types.first.id;
    var selectedParentId = unit?.parentId ?? parentId;
    final forbiddenParents = unit == null
        ? <String>{}
        : {unit.id, ..._descendantIds(unit.id, _childrenByParent(units))};
    final parentCandidates = units
        .where((candidate) => !forbiddenParents.contains(candidate.id))
        .toList();

    await EabDialog.show<void>(
      context,
      title: unit == null ? 'Nouvelle unite' : 'Modifier l\'unite',
      width: 640,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveFormRow(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedTypeId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Niveau *'),
                      items: [
                        for (final type in types)
                          DropdownMenuItem(
                            value: type.id,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedTypeId = value);
                      },
                      validator: (value) =>
                          value == null ? 'Choisir un niveau.' : null,
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedParentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Controle par',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Aucune unite parente'),
                        ),
                        for (final candidate in parentCandidates)
                          DropdownMenuItem<String?>(
                            value: candidate.id,
                            child: Text(candidate.nom),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedParentId = value),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ResponsiveFormRow(
                  children: [
                    EabTextField(
                      label: 'Nom *',
                      controller: nomCtrl,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) =>
                          _required(value, 'Le nom est obligatoire.'),
                    ),
                    EabTextField(label: 'Code', controller: codeCtrl),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                EabTextField(
                  label: 'Description',
                  controller: descCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                ResponsiveFormRow(
                  children: [
                    EabTextField(label: 'Ville', controller: villeCtrl),
                    EabTextField(label: 'Quartier', controller: quartierCtrl),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                EabTextField(label: 'Adresse', controller: adresseCtrl),
                const SizedBox(height: AppSpacing.md),
                ResponsiveFormRow(
                  children: [
                    EabTextField(label: 'Telephone', controller: telCtrl),
                    EabTextField(
                      label: 'Email',
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        EabButton(
          label: unit == null ? 'Creer' : 'Enregistrer',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              if (unit == null) {
                await repository.createUnit(
                  organizationId: organizationId,
                  typeId: selectedTypeId,
                  parentId: selectedParentId,
                  nom: nomCtrl.text.trim(),
                  code: codeCtrl.text,
                  description: descCtrl.text,
                  ville: villeCtrl.text,
                  quartier: quartierCtrl.text,
                  adresse: adresseCtrl.text,
                  telephone: telCtrl.text,
                  email: emailCtrl.text,
                );
              } else {
                await repository.updateUnit(
                  id: unit.id,
                  typeId: selectedTypeId,
                  parentId: selectedParentId,
                  nom: nomCtrl.text.trim(),
                  code: codeCtrl.text,
                  description: descCtrl.text,
                  ville: villeCtrl.text,
                  quartier: quartierCtrl.text,
                  adresse: adresseCtrl.text,
                  telephone: telCtrl.text,
                  email: emailCtrl.text,
                );
              }
              ref.invalidate(churchUnitsProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                context.showSuccess('Unite enregistree.');
              }
            } catch (e) {
              if (context.mounted) context.showError(e);
            }
          },
        ),
      ],
    );
  }

  Future<void> _archiveUnit(
    BuildContext context,
    WidgetRef ref, {
    required ChurchUnit unit,
    required Map<String?, List<ChurchUnit>> childrenByParent,
  }) async {
    final repository = ref.read(churchUnitsRepositoryProvider);
    if (repository == null) return;

    final children = childrenByParent[unit.id] ?? const <ChurchUnit>[];
    if (children.isNotEmpty) {
      context.showWarning(
        'Cette unite controle encore ${children.length} sous-unite(s). Deplacez-les avant archivage.',
      );
      return;
    }

    final confirmed = await EabDialog.confirm(
      context,
      title: 'Archiver l\'unite',
      message: 'Archiver "${unit.nom}" ? Elle ne sera plus affichee.',
      confirmLabel: 'Archiver',
      isDanger: true,
    );
    if (confirmed != true) return;

    try {
      await repository.archiveUnit(unit.id);
      ref.invalidate(churchUnitsProvider);
      if (context.mounted) context.showSuccess('Unite archivee.');
    } catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  Set<String> _descendantIds(
    String unitId,
    Map<String?, List<ChurchUnit>> childrenByParent,
  ) {
    final result = <String>{};
    void visit(String id) {
      for (final child in childrenByParent[id] ?? const <ChurchUnit>[]) {
        if (result.add(child.id)) visit(child.id);
      }
    }

    visit(unitId);
    return result;
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _validateCode(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return 'Le code est obligatoire.';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(clean)) {
      return 'Utilisez seulement minuscules, chiffres et underscores.';
    }
    return null;
  }
}

class _UnitNode extends StatelessWidget {
  const _UnitNode({
    required this.unit,
    required this.childrenByParent,
    required this.depth,
    required this.canEdit,
    required this.onAddChild,
    required this.onEdit,
    required this.onArchive,
  });

  final ChurchUnit unit;
  final Map<String?, List<ChurchUnit>> childrenByParent;
  final int depth;
  final bool canEdit;
  final ValueChanged<ChurchUnit> onAddChild;
  final ValueChanged<ChurchUnit> onEdit;
  final ValueChanged<ChurchUnit> onArchive;

  @override
  Widget build(BuildContext context) {
    final children = childrenByParent[unit.id] ?? const <ChurchUnit>[];
    final theme = Theme.of(context);
    final left = depth * 14.0;

    return Padding(
      padding: EdgeInsets.only(left: left, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: depth == 0
                  ? const Color(0xFFF8FBFC)
                  : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E7EC)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(unit), color: const Color(0xFF0F4C5C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              unit.nom,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            _LevelChip(label: unit.typeLabel),
                            if (unit.code != null && unit.code!.isNotEmpty)
                              _LevelChip(label: unit.code!),
                          ],
                        ),
                        if (_subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (children.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        children.length.toString(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF0F4C5C),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (canEdit) ...[
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      tooltip: 'Actions',
                      onSelected: (value) {
                        switch (value) {
                          case 'add':
                            onAddChild(unit);
                          case 'edit':
                            onEdit(unit);
                          case 'archive':
                            onArchive(unit);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'add',
                          child: Text('Ajouter dessous'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifier / deplacer'),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text('Archiver'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final child in children)
              _UnitNode(
                unit: child,
                childrenByParent: childrenByParent,
                depth: depth + 1,
                canEdit: canEdit,
                onAddChild: onAddChild,
                onEdit: onEdit,
                onArchive: onArchive,
              ),
          ],
        ],
      ),
    );
  }

  String get _subtitle {
    return [
      unit.ville,
      unit.quartier,
      unit.adresse,
      unit.telephone,
      unit.email,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' | ');
  }

  IconData _iconFor(ChurchUnit unit) {
    switch (unit.typeCode) {
      case 'organization':
        return Icons.account_balance_outlined;
      case 'region':
        return Icons.account_tree_outlined;
      case 'district':
        return Icons.map_outlined;
      case 'local_church':
        return Icons.church_outlined;
      default:
        return Icons.business_outlined;
    }
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.unitsCount,
    required this.onEdit,
    required this.onDelete,
  });

  final ChurchUnitType type;
  final int unitsCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE1E7EC)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(type.label),
          subtitle: Text('${type.code} | ordre ${type.levelOrder}'),
          trailing: Wrap(
            spacing: 4,
            children: [
              _LevelChip(label: '$unitsCount unite(s)'),
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'La structure est affichee en lecture. Appliquez la migration 00018 pour activer la gestion directe.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
    );
  }
}

class _EditNotice extends StatelessWidget {
  const _EditNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ajoutez des niveaux, creez des sous-unites et modifiez le champ "Controle par" pour definir qui controle qui.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFF0F4C5C),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/section_card.dart';

class FlexibleChurchStructurePanel extends ConsumerWidget {
  const FlexibleChurchStructurePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(churchUnitsProvider);

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
        if (units.isEmpty) return const SizedBox.shrink();
        final childrenByParent = _childrenByParent(units);
        final roots = childrenByParent[null] ?? const <ChurchUnit>[];
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
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final root in roots)
                    _UnitNode(
                      unit: root,
                      childrenByParent: childrenByParent,
                      depth: 0,
                    ),
                ],
              ),
            ),
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
}

class _UnitNode extends StatelessWidget {
  const _UnitNode({
    required this.unit,
    required this.childrenByParent,
    required this.depth,
  });

  final ChurchUnit unit;
  final Map<String?, List<ChurchUnit>> childrenByParent;
  final int depth;

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
                    Text(
                      children.length.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF0F4C5C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

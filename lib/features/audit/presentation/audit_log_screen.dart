/// Ecran du journal d'audit.
///
/// Affiche l'historique des actions avec filtres par action, table et
/// utilisateur. Accessible uniquement aux profils autorises par le backend.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

import '../application/audit_providers.dart';

const _actionLabels = {
  'INSERT': 'Creation',
  'UPDATE': 'Modification',
  'DELETE': 'Suppression',
  'SOFT_DELETE': 'Archivage',
  'LOGIN': 'Connexion',
  'LOGOUT': 'Deconnexion',
  'VALIDATION': 'Validation',
  'CLOTURE': 'Cloture',
};

const _tableLabels = {
  'membres': 'Fideles',
  'ecritures_comptables': 'Ecritures',
  'exercices_comptables': 'Exercices',
  'comptes_comptables': 'Comptes',
  'budgets_comptables': 'Budgets',
  'immobilisations_comptables': 'Immobilisations',
  'programmes': 'Programmes',
  'familles': 'Familles',
  'tiers': 'Tiers',
  'organizations': 'Organisation',
  'profiles': 'Profils',
};

({IconData icon, Color color}) _actionStyle(String action) => switch (action) {
      'INSERT' => (icon: Icons.add_circle_outline, color: AppColors.success),
      'UPDATE' => (icon: Icons.edit_outlined, color: AppColors.warning),
      'DELETE' => (icon: Icons.delete_outline, color: AppColors.error),
      'SOFT_DELETE' => (icon: Icons.archive_outlined, color: AppColors.error),
      'LOGIN' => (icon: Icons.login, color: AppColors.info),
      'LOGOUT' => (icon: Icons.logout, color: AppColors.textSecondary),
      'VALIDATION' => (icon: Icons.check_circle_outline, color: AppColors.teal),
      'CLOTURE' => (icon: Icons.lock_outline, color: AppColors.indigo),
      _ => (icon: Icons.info_outline, color: AppColors.textSecondary),
    };

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _emailController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  String? _selectedAction;
  String? _selectedTable;

  final _actions = const [
    'INSERT',
    'UPDATE',
    'DELETE',
    'SOFT_DELETE',
    'VALIDATION',
    'CLOTURE',
  ];

  final _tables = const [
    'membres',
    'ecritures_comptables',
    'exercices_comptables',
    'comptes_comptables',
    'budgets_comptables',
    'immobilisations_comptables',
    'programmes',
    'familles',
    'tiers',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final email = _emailController.text.trim();
    ref.read(auditFilterProvider.notifier).setFilter(
          AuditFilter(
            action: _selectedAction,
            tableName: _selectedTable,
            userEmail: email.isEmpty ? null : email,
          ),
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedAction = null;
      _selectedTable = null;
      _emailController.clear();
    });
    ref.read(auditFilterProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);

    return AppShell(
      title: 'Journal d\'audit',
      currentRoute: '/audit-log',
      showBackButton: true,
      backRoute: '/',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final horizontalPadding = compact ? AppSpacing.md : AppSpacing.xl;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? AppSpacing.md : AppSpacing.xl,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EabPageHeader(
                  title: 'Journal d\'audit',
                  subtitle: compact
                      ? 'Suivi des actions sensibles.'
                      : 'Suivi des creations, modifications, suppressions et validations.',
                  icon: Icons.history_outlined,
                ),
                _AuditFilterPanel(
                  compact: compact,
                  actions: _actions,
                  tables: _tables,
                  selectedAction: _selectedAction,
                  selectedTable: _selectedTable,
                  emailController: _emailController,
                  onActionChanged: (value) {
                    setState(() => _selectedAction = value);
                    _applyFilters();
                  },
                  onTableChanged: (value) {
                    setState(() => _selectedTable = value);
                    _applyFilters();
                  },
                  onApply: _applyFilters,
                  onClear: _clearFilters,
                ),
                const SizedBox(height: AppSpacing.md),
                logsAsync.maybeWhen(
                  data: (logs) => _AuditSummaryStrip(
                    logs: logs,
                    compact: compact,
                  ),
                  orElse: () => _AuditSummaryStrip(
                    logs: const [],
                    compact: compact,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: logsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => ErrorState(
                      message: 'Erreur lors du chargement des logs : $err',
                      onRetry: () => ref.invalidate(auditLogsProvider),
                    ),
                    data: (logs) => _buildLogsList(logs, compact),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsList(List<AuditLogEntry> logs, bool compact) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 32),
        child: EmptyState(
          icon: Icons.history_outlined,
          message: 'Aucune entree d\'audit trouvee.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${logs.length} entree${logs.length > 1 ? 's' : ''}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            itemCount: logs.length,
            separatorBuilder: (_, __) => SizedBox(
              height: compact ? AppSpacing.sm : AppSpacing.xs,
            ),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _AuditLogCard(
                log: log,
                dateFormat: _dateFormat,
                compact: compact,
                onTap: () => _showLogDetail(log),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLogDetail(AuditLogEntry log) {
    final style = _actionStyle(log.action);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.36,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _ActionIcon(action: log.action, size: 46),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _actionLabels[log.action] ?? log.action,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _tableLabels[log.tableName] ?? log.tableName ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailGrid(
              children: [
                _DetailTile(
                  icon: Icons.person_outline,
                  label: 'Utilisateur',
                  value: log.userEmail ?? 'Systeme',
                ),
                _DetailTile(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: log.userRole ?? '-',
                ),
                _DetailTile(
                  icon: Icons.access_time,
                  label: 'Date',
                  value: _dateFormat.format(log.createdAt.toLocal()),
                ),
                if (log.recordId != null)
                  _DetailTile(
                    icon: Icons.key_outlined,
                    label: 'Enregistrement',
                    value: log.recordId!.length > 8
                        ? log.recordId!.substring(0, 8)
                        : log.recordId!,
                  ),
              ],
            ),
            if (log.changes != null && log.changes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${log.changes!.length} changement${log.changes!.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: style.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...log.changes!.entries.map(
                (entry) => _ChangeRow(
                  field: entry.key,
                  value: '${entry.value}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuditFilterPanel extends StatelessWidget {
  const _AuditFilterPanel({
    required this.compact,
    required this.actions,
    required this.tables,
    required this.selectedAction,
    required this.selectedTable,
    required this.emailController,
    required this.onActionChanged,
    required this.onTableChanged,
    required this.onApply,
    required this.onClear,
  });

  final bool compact;
  final List<String> actions;
  final List<String> tables;
  final String? selectedAction;
  final String? selectedTable;
  final TextEditingController emailController;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onTableChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final actionField = DropdownButtonFormField<String>(
      initialValue: selectedAction,
      decoration: const InputDecoration(
        labelText: 'Action',
        prefixIcon: Icon(Icons.bolt_outlined),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Toutes')),
        ...actions.map(
          (action) => DropdownMenuItem(
            value: action,
            child: Text(_actionLabels[action] ?? action),
          ),
        ),
      ],
      onChanged: onActionChanged,
    );

    final tableField = DropdownButtonFormField<String>(
      initialValue: selectedTable,
      decoration: const InputDecoration(
        labelText: 'Table',
        prefixIcon: Icon(Icons.table_chart_outlined),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Toutes')),
        ...tables.map(
          (table) => DropdownMenuItem(
            value: table,
            child: Text(_tableLabels[table] ?? table),
          ),
        ),
      ],
      onChanged: onTableChanged,
    );

    final emailField = TextField(
      controller: emailController,
      decoration: const InputDecoration(
        labelText: 'Utilisateur',
        hintText: 'email',
        prefixIcon: Icon(Icons.person_search_outlined),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onApply(),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              children: [
                emailField,
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: actionField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: tableField),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Effacer'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApply,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Filtrer'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: emailField),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: actionField),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: tableField),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Effacer'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Filtrer'),
                ),
              ],
            ),
    );
  }
}

class _AuditSummaryStrip extends StatelessWidget {
  const _AuditSummaryStrip({required this.logs, required this.compact});

  final List<AuditLogEntry> logs;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final updates = logs.where((log) => log.action == 'UPDATE').length;
    final deletions = logs
        .where((log) => log.action == 'DELETE' || log.action == 'SOFT_DELETE')
        .length;
    final validations = logs.where((log) => log.action == 'VALIDATION').length;

    final items = [
      _SummaryTile(
        label: 'Total',
        value: '${logs.length}',
        icon: Icons.history_outlined,
      ),
      _SummaryTile(
        label: 'Modifs',
        value: '$updates',
        icon: Icons.edit_outlined,
        color: AppColors.warning,
      ),
      _SummaryTile(
        label: 'Suppressions',
        value: '$deletions',
        icon: Icons.delete_outline,
        color: AppColors.error,
      ),
      _SummaryTile(
        label: 'Validations',
        value: '$validations',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              SizedBox(width: 132, child: items[i]),
              if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({
    required this.log,
    required this.dateFormat,
    required this.compact,
    required this.onTap,
  });

  final AuditLogEntry log;
  final DateFormat dateFormat;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _actionStyle(log.action);
    final actionLabel = _actionLabels[log.action] ?? log.action;
    final tableLabel = _tableLabels[log.tableName] ?? log.tableName ?? '-';
    final changeCount = log.changes?.length ?? 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActionIcon(action: log.action),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          actionLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: style.color,
                          ),
                        ),
                        Text(
                          tableLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      log.userEmail ?? 'Systeme',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateFormat.format(log.createdAt.toLocal()),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (changeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$changeCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.action, this.size = 40});

  final String action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = _actionStyle(action);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.48),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.field, required this.value});

  final String field;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.compare_arrows,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

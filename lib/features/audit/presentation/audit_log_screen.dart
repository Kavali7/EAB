/// Écran du journal d'audit.
///
/// Affiche l'historique des actions (INSERT, UPDATE, DELETE, VALIDATION, CLOTURE)
/// avec filtres par action, table et utilisateur.
/// Accessible uniquement aux admins (RLS côté backend).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/context_header.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import '../application/audit_providers.dart';

/// Labels lisibles pour les actions d'audit.
const _actionLabels = {
  'INSERT': 'Création',
  'UPDATE': 'Modification',
  'DELETE': 'Suppression',
  'SOFT_DELETE': 'Archivage',
  'LOGIN': 'Connexion',
  'LOGOUT': 'Déconnexion',
  'VALIDATION': 'Validation',
  'CLOTURE': 'Clôture',
};

/// Labels lisibles pour les tables.
const _tableLabels = {
  'membres': 'Fidèles',
  'ecritures_comptables': 'Écritures',
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

/// Icône et couleur par type d'action.
({IconData icon, Color color}) _actionStyle(String action) => switch (action) {
      'INSERT' => (icon: Icons.add_circle_outline, color: Colors.green),
      'UPDATE' => (icon: Icons.edit_outlined, color: Colors.orange),
      'DELETE' => (icon: Icons.delete_outline, color: Colors.red),
      'SOFT_DELETE' => (icon: Icons.archive_outlined, color: Colors.red.shade300),
      'LOGIN' => (icon: Icons.login, color: Colors.blue),
      'LOGOUT' => (icon: Icons.logout, color: Colors.grey),
      'VALIDATION' => (icon: Icons.check_circle_outline, color: Colors.teal),
      'CLOTURE' => (icon: Icons.lock_outline, color: Colors.indigo),
      _ => (icon: Icons.info_outline, color: Colors.grey),
    };

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String? _selectedAction;
  String? _selectedTable;
  String _searchEmail = '';

  final _actions = [
    'INSERT',
    'UPDATE',
    'DELETE',
    'SOFT_DELETE',
    'VALIDATION',
    'CLOTURE',
  ];

  final _tables = [
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

  void _applyFilters() {
    ref.read(auditFilterProvider.notifier).state = AuditFilter(
      action: _selectedAction,
      tableName: _selectedTable,
      userEmail: _searchEmail.isEmpty ? null : _searchEmail,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedAction = null;
      _selectedTable = null;
      _searchEmail = '';
    });
    ref.read(auditFilterProvider.notifier).state = const AuditFilter();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return AppShell(
      title: 'Journal d\'audit',
      currentRoute: '/audit-log',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ContextHeader(showPorteeComptable: false),
              const SizedBox(height: AppSpacing.cardGap),

              // ── Filtres ──
              SectionCard(
                title: 'Filtres',
                icon: Icons.filter_list,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    // Filtre par action
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _selectedAction,
                        decoration: const InputDecoration(
                          labelText: 'Action',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Toutes'),
                          ),
                          ..._actions.map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(_actionLabels[a] ?? a),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedAction = val);
                          _applyFilters();
                        },
                      ),
                    ),

                    // Filtre par table
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTable,
                        decoration: const InputDecoration(
                          labelText: 'Table',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Toutes'),
                          ),
                          ..._tables.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(_tableLabels[t] ?? t),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedTable = val);
                          _applyFilters();
                        },
                      ),
                    ),

                    // Recherche par email
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Utilisateur (email)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_search),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) {
                          _searchEmail = val;
                        },
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),

                    // Bouton effacer
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear),
                      label: const Text('Effacer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),

              // ── Liste des logs ──
              logsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => ErrorState(
                  message: 'Erreur lors du chargement des logs : $err',
                  onRetry: () => ref.invalidate(auditLogsProvider),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.history_outlined,
                      message: 'Aucune entrée d\'audit trouvée',
                    );
                  }

                  return SectionCard(
                    title: '${logs.length} entrée${logs.length > 1 ? 's' : ''}',
                    icon: Icons.history,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final style = _actionStyle(log.action);
                        final actionLabel =
                            _actionLabels[log.action] ?? log.action;
                        final tableLabel =
                            _tableLabels[log.tableName] ?? log.tableName ?? '—';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                style.color.withValues(alpha: 0.15),
                            child: Icon(style.icon,
                                color: style.color, size: 20),
                          ),
                          title: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$actionLabel ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: style.color,
                                  ),
                                ),
                                TextSpan(
                                  text: tableLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            '${log.userEmail ?? 'Système'} • ${dateFormat.format(log.createdAt.toLocal())}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: log.changes != null &&
                                  log.changes!.isNotEmpty
                              ? Chip(
                                  label: Text(
                                    '${log.changes!.length} champ${log.changes!.length > 1 ? 's' : ''}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.grey.shade100,
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onTap: () =>
                              _showLogDetail(context, log, dateFormat),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche le détail d'un log dans une bottom sheet.
  void _showLogDetail(
      BuildContext context, AuditLogEntry log, DateFormat dateFormat) {
    final style = _actionStyle(log.action);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // En-tête
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: style.color.withValues(alpha: 0.15),
                    child:
                        Icon(style.icon, color: style.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actionLabels[log.action] ?? log.action,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _tableLabels[log.tableName] ??
                              log.tableName ??
                              '—',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Métadonnées
              _detailRow(Icons.person, 'Utilisateur',
                  log.userEmail ?? 'Système'),
              _detailRow(Icons.badge, 'Rôle', log.userRole ?? '—'),
              _detailRow(Icons.access_time, 'Date',
                  dateFormat.format(log.createdAt.toLocal())),
              if (log.recordId != null)
                _detailRow(Icons.key, 'ID enregistrement',
                    log.recordId!.substring(0, 8)),

              // Changements
              if (log.changes != null && log.changes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Changements',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...log.changes!.entries.map((entry) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.compare_arrows,
                              size: 16,
                              color: ChurchTheme.navy
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.value}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: ChurchTheme.navy.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ),
          ],
        ),
      );
}

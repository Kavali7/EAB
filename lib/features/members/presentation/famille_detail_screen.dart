/// Vue famille enrichie — affiche les liens parent-enfant et les stats.
///
/// Accessible depuis le tap sur une famille dans l'écran des fidèles.
/// Flèche retour pour revenir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/models/famille.dart';
import 'package:eab/models/member.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'member_detail_screen.dart';

class FamilleDetailScreen extends ConsumerWidget {
  const FamilleDetailScreen({super.key, required this.famille});

  final Famille famille;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    final allMembers = membersAsync.value ?? [];
    final theme = Theme.of(context);

    // Résoudre les membres de la famille
    final epoux = _findMember(allMembers, famille.idEpoux);
    final epouse = _findMember(allMembers, famille.idEpouse);
    final enfants = famille.idsEnfants
        .map((id) => _findMember(allMembers, id))
        .where((m) => m != null)
        .cast<Member>()
        .toList();

    return AppShell(
      title: 'Famille ${famille.nom}',
      currentRoute: '/members',
      showBackButton: true,
      backRoute: '/members',
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête famille ──
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: ChurchTheme.navy.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.family_restroom,
                              size: 32,
                              color: ChurchTheme.navy,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Famille ${famille.nom}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${enfants.length} enfant${enfants.length > 1 ? "s" : ""}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Parents ──
                  _sectionTitle(context, Icons.people, 'Parents'),
                  if (epoux != null || epouse != null)
                    Card(
                      child: Column(
                        children: [
                          if (epoux != null)
                            _memberTile(context, epoux, 'Époux'),
                          if (epoux != null && epouse != null)
                            const Divider(height: 1),
                          if (epouse != null)
                            _memberTile(context, epouse, 'Épouse'),
                        ],
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aucun parent renseigné',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Enfants ──
                  _sectionTitle(
                    context,
                    Icons.child_care,
                    'Enfants (${enfants.length})',
                  ),
                  if (enfants.isNotEmpty)
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: enfants.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) =>
                            _memberTile(context, enfants[i], 'Enfant'),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aucun enfant renseigné',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Statistiques ──
                  _sectionTitle(context, Icons.analytics, 'Statistiques'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _stat(
                            'Membres',
                            '${(epoux != null ? 1 : 0) + (epouse != null ? 1 : 0) + enfants.length}',
                          ),
                          _stat('Enfants', '${enfants.length}'),
                          _stat(
                            'Officiers',
                            '${[epoux, epouse, ...enfants].where((m) => m != null && m.estOfficier).length}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Member? _findMember(List<Member> members, String? id) {
    if (id == null) return null;
    try {
      return members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _memberTile(BuildContext context, Member member, String role) =>
      ListTile(
        leading: CircleAvatar(
          backgroundColor: ChurchTheme.navy.withValues(alpha: 0.1),
          child: Text(
            member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ChurchTheme.navy,
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          role,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member)),
        ),
      );

  Widget _sectionTitle(BuildContext context, IconData icon, String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ChurchTheme.navy),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ChurchTheme.navy,
              ),
            ),
          ],
        ),
      );

  Widget _stat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ChurchTheme.navy,
        ),
      ),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
    ],
  );
}

/// Fiche détaillée d'un fidèle (membre).
///
/// Affiche le profil complet avec informations personnelles,
/// dates clés, rôle, statut, assemblée, et vulnérabilités.
/// Flèche retour pour revenir à la liste.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/constants.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/models/member.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final theme = Theme.of(context);

    return AppShell(
      title: member.fullName,
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
                  // ── En-tête avec avatar ──
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: ChurchTheme.navy.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            _initials(member.fullName),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ChurchTheme.navy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _roleLabel(member.role),
                          style: TextStyle(
                            color: ChurchTheme.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StatusBadge(
                          label: _statutLabel(member.statut),
                          icon: _statutIcon(member.statut),
                          color: _statutColor(member.statut),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Informations personnelles ──
                  _sectionTitle(
                    context,
                    Icons.person,
                    'Informations personnelles',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow('Sexe', genderLabels[member.gender] ?? '—'),
                          _infoRow(
                            'Date de naissance',
                            member.dateNaissance != null
                                ? dateFormat.format(member.dateNaissance!)
                                : dateFormat.format(member.birthDate),
                          ),
                          _infoRow(
                            'Situation matrimoniale',
                            member.statutMatrimonial != null
                                ? _matrimonialLabel(member.statutMatrimonial!)
                                : maritalStatusLabels[member.maritalStatus] ??
                                      '—',
                          ),
                          if (member.phone != null)
                            _infoRow('Téléphone', member.phone!),
                          if (member.email != null)
                            _infoRow('Email', member.email!),
                          if (member.address != null)
                            _infoRow('Adresse', member.address!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Parcours spirituel ──
                  _sectionTitle(context, Icons.church, 'Parcours spirituel'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (member.dateConversion != null)
                            _infoRow(
                              'Date de conversion',
                              dateFormat.format(member.dateConversion!),
                            ),
                          _infoRow(
                            'Date de baptême',
                            member.dateBapteme != null
                                ? dateFormat.format(member.dateBapteme!)
                                : member.baptismDate != null
                                ? dateFormat.format(member.baptismDate!)
                                : '—',
                          ),
                          if (member.dateMainAssociation != null)
                            _infoRow(
                              'Main d\'association',
                              dateFormat.format(member.dateMainAssociation!),
                            ),
                          if (member.dateEntree != null)
                            _infoRow(
                              'Date d\'entrée',
                              dateFormat.format(member.dateEntree!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Vulnérabilités ──
                  if (member.vulnerabilites.isNotEmpty) ...[
                    _sectionTitle(context, Icons.favorite, 'Vulnérabilités'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: member.vulnerabilites.map((v) {
                            return Chip(
                              avatar: Icon(
                                _vulnIcon(v),
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              label: Text(_vulnLabel(v)),
                              backgroundColor: Colors.orange.shade50,
                              side: BorderSide(color: Colors.orange.shade200),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

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

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  static Color _statutColor(StatutFidele s) => switch (s) {
    StatutFidele.actif => Colors.green,
    StatutFidele.inactif => Colors.orange,
    StatutFidele.parti => Colors.grey,
    StatutFidele.decede => Colors.blueGrey,
    StatutFidele.transfere => Colors.blue,
  };

  static IconData _statutIcon(StatutFidele s) => switch (s) {
    StatutFidele.actif => Icons.check_circle,
    StatutFidele.inactif => Icons.pause_circle,
    StatutFidele.parti => Icons.exit_to_app,
    StatutFidele.decede => Icons.star,
    StatutFidele.transfere => Icons.swap_horiz,
  };

  static String _statutLabel(StatutFidele s) => switch (s) {
    StatutFidele.actif => 'Actif',
    StatutFidele.inactif => 'Inactif',
    StatutFidele.parti => 'Parti',
    StatutFidele.decede => 'Décédé',
    StatutFidele.transfere => 'Transféré',
  };

  static String _roleLabel(RoleFidele r) => switch (r) {
    RoleFidele.membre => 'Membre',
    RoleFidele.pasteur => 'Pasteur',
    RoleFidele.ancien => 'Ancien',
    RoleFidele.diacre => 'Diacre',
    RoleFidele.diaconesse => 'Diaconesse',
    RoleFidele.evangeliste => 'Évangéliste',
    RoleFidele.autreOfficier => 'Officier',
  };

  static String _matrimonialLabel(StatutMatrimonial s) => switch (s) {
    StatutMatrimonial.celibataire => 'Célibataire',
    StatutMatrimonial.marie => 'Marié(e)',
    StatutMatrimonial.veuf => 'Veuf',
    StatutMatrimonial.veuve => 'Veuve',
    StatutMatrimonial.divorce => 'Divorcé(e)',
    StatutMatrimonial.separe => 'Séparé(e)',
  };

  static IconData _vulnIcon(VulnerabiliteFidele v) => switch (v) {
    VulnerabiliteFidele.orphelin => Icons.child_care,
    VulnerabiliteFidele.veuf => Icons.person,
    VulnerabiliteFidele.veuve => Icons.person,
    VulnerabiliteFidele.handicape => Icons.accessible,
    VulnerabiliteFidele.troisiemeAge => Icons.elderly,
    VulnerabiliteFidele.autre => Icons.info_outline,
  };

  static String _vulnLabel(VulnerabiliteFidele v) => switch (v) {
    VulnerabiliteFidele.orphelin => 'Orphelin',
    VulnerabiliteFidele.veuf => 'Veuf',
    VulnerabiliteFidele.veuve => 'Veuve',
    VulnerabiliteFidele.handicape => 'Handicapé',
    VulnerabiliteFidele.troisiemeAge => '3ème âge',
    VulnerabiliteFidele.autre => 'Autre',
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.full == 999
            ? BorderRadius.circular(AppRadius.full)
            : AppRadius.mdAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

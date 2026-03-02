/// Écran des paramètres de l'organisation.
///
/// Permet de modifier : nom, description, couleurs, logo, contact.
/// Accessible uniquement aux administrateurs nationaux.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:eab/core/errors/error_handler.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/section_card.dart';
import 'package:eab/ui/ui.dart';
import '../application/organization_providers.dart';
import '../data/organization_model.dart';

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends ConsumerState<OrganizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _couleurPrimaireCtrl = TextEditingController();
  final _couleurSecondaireCtrl = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();
  String _inviteRole = 'tresorierAssemblee';
  bool _saving = false;
  bool _inviting = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _siteCtrl.dispose();
    _couleurPrimaireCtrl.dispose();
    _couleurSecondaireCtrl.dispose();
    _inviteEmailCtrl.dispose();
    super.dispose();
  }

  void _populateFields(Organization org) {
    _nomCtrl.text = org.nom;
    _descCtrl.text = org.description ?? '';
    _adresseCtrl.text = org.adresse ?? '';
    _telCtrl.text = org.telephone ?? '';
    _emailCtrl.text = org.email ?? '';
    _siteCtrl.text = org.siteWeb ?? '';
    _couleurPrimaireCtrl.text = org.couleurPrimaire ?? '#1B2A4A';
    _couleurSecondaireCtrl.text = org.couleurSecondaire ?? '#D4A843';
  }

  Future<void> _save(Organization org) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = Organization(
        id: org.id,
        nom: _nomCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        logoUrl: org.logoUrl,
        couleurPrimaire: _couleurPrimaireCtrl.text.trim(),
        couleurSecondaire: _couleurSecondaireCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        siteWeb: _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
        devise: org.devise,
        parametres: org.parametres,
        createdAt: org.createdAt,
      );
      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateOrganization(updated);
      await ref.read(currentOrganizationProvider.notifier).refresh();
      if (mounted) context.showSuccess('Organisation mise à jour.');
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _inviteUser(String orgId) async {
    if (_inviteEmailCtrl.text.trim().isEmpty) return;
    setState(() => _inviting = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.inviteUser(
        orgId: orgId,
        email: _inviteEmailCtrl.text.trim(),
        role: _inviteRole,
      );
      _inviteEmailCtrl.clear();
      if (mounted) context.showSuccess('Invitation envoyée.');
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);

    return AppShell(
      title: 'Paramètres organisation',
      currentRoute: '/organization-settings',
      body: orgAsync.when(
        loading: () => const Center(child: SkeletonLoader()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (org) {
          if (org == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.business,
                message: 'Aucune organisation trouvée.',
              ),
            );
          }

          // Populate fields on first load
          if (_nomCtrl.text.isEmpty) _populateFields(org);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Identité ──
                  SectionCard(
                    title: 'Identité',
                    child: Column(
                      children: [
                        // Logo + Nom
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar/Logo
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: org.primaryColor.withOpacity(0.1),
                              child: org.logoUrl != null
                                  ? ClipOval(
                                      child: Image.network(org.logoUrl!,
                                          width: 80, height: 80, fit: BoxFit.cover),
                                    )
                                  : Text(
                                      org.nom.isNotEmpty ? org.nom[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: org.primaryColor,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                children: [
                                  EabTextField(
                                    label: 'Nom de l\'organisation *',
                                    controller: _nomCtrl,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Requis' : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  EabTextField(
                                    label: 'Description',
                                    controller: _descCtrl,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // ── Thème & Couleurs ──
                  SectionCard(
                    title: 'Thème & Couleurs',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _colorField(
                                label: 'Couleur primaire',
                                controller: _couleurPrimaireCtrl,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.cardGap),
                            Expanded(
                              child: _colorField(
                                label: 'Couleur secondaire',
                                controller: _couleurSecondaireCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Aperçu
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                _parseColor(_couleurPrimaireCtrl.text, const Color(0xFF1B2A4A)),
                                _parseColor(_couleurSecondaireCtrl.text, const Color(0xFFD4A843)),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Aperçu du thème',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // ── Contact ──
                  SectionCard(
                    title: 'Contact',
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(child: EabTextField(label: 'Adresse', controller: _adresseCtrl)),
                          const SizedBox(width: AppSpacing.cardGap),
                          Expanded(child: EabTextField(label: 'Téléphone', controller: _telCtrl)),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        Row(children: [
                          Expanded(child: EabTextField(label: 'Email', controller: _emailCtrl)),
                          const SizedBox(width: AppSpacing.cardGap),
                          Expanded(child: EabTextField(label: 'Site web', controller: _siteCtrl)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),

                  // ── Bouton sauvegarder ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: EabButton(
                      label: 'Enregistrer',
                      variant: EabButtonVariant.primary,
                      isLoading: _saving,
                      onPressed: () => _save(org),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Invitations ──
                  SectionCard(
                    title: 'Inviter un utilisateur',
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 3,
                              child: EabTextField(
                                label: 'Email',
                                controller: _inviteEmailCtrl,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _inviteRole,
                                decoration: const InputDecoration(
                                  labelText: 'Rôle',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'adminNational', child: Text('Admin national')),
                                  DropdownMenuItem(value: 'responsableRegion', child: Text('Responsable région')),
                                  DropdownMenuItem(value: 'surintendantDistrict', child: Text('Surintendant district')),
                                  DropdownMenuItem(value: 'tresorierAssemblee', child: Text('Trésorier assemblée')),
                                ],
                                onChanged: (v) => setState(() => _inviteRole = v!),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            EabButton(
                              label: 'Inviter',
                              variant: EabButtonVariant.primary,
                              size: EabButtonSize.small,
                              isLoading: _inviting,
                              onPressed: () => _inviteUser(org.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _colorField({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _parseColor(controller.text, Colors.grey),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: EabTextField(
            label: label,
            controller: controller,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length != 6) return fallback;
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

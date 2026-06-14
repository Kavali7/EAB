/// Ecran des parametres de l'organisation.
///
/// Permet de modifier : nom, description, couleurs, logo, contact.
/// Accessible uniquement aux administrateurs nationaux.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/errors/error_handler.dart';
import 'package:eab/core/errors/app_exceptions.dart';
import 'package:eab/features/church_units/application/church_unit_scope_utils.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/organization/data/logo_file_picker.dart';
import 'package:eab/features/organization/data/picked_logo_file.dart';
import 'package:eab/ui/ui.dart';
import 'package:eab/widgets/app_shell.dart';
import 'package:eab/widgets/section_card.dart';

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
  final _sigleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _couleurPrimaireCtrl = TextEditingController();
  final _couleurSecondaireCtrl = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();
  String _inviteRole = 'tresorierAssemblee';
  String? _inviteChurchUnitId;
  bool _inviteCanManageChildren = false;
  bool _saving = false;
  bool _inviting = false;
  bool _uploadingLogo = false;

  bool get _inviteIsGlobalAdmin => _inviteRole == 'adminNational';

  static const _maxLogoBytes = 2 * 1024 * 1024;
  static const _allowedLogoExtensions = {'png', 'jpg', 'jpeg', 'webp', 'svg'};

  @override
  void dispose() {
    _nomCtrl.dispose();
    _sigleCtrl.dispose();
    _descCtrl.dispose();
    _logoUrlCtrl.dispose();
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
    _sigleCtrl.text = org.sigle ?? '';
    _descCtrl.text = org.description ?? '';
    _logoUrlCtrl.text = org.logoUrl ?? '';
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
        sigle: _sigleCtrl.text.trim().isEmpty ? null : _sigleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        logoUrl: _logoUrlCtrl.text.trim().isEmpty
            ? null
            : _logoUrlCtrl.text.trim(),
        couleurPrimaire: _couleurPrimaireCtrl.text.trim(),
        couleurSecondaire: _couleurSecondaireCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim().isEmpty
            ? null
            : _adresseCtrl.text.trim(),
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
      if (mounted) context.showSuccess('Organisation mise a jour.');
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _importLogo(Organization org) async {
    try {
      final picked = await pickLogoFile();
      if (picked == null) return;

      final extension = picked.extension;
      if (!_allowedLogoExtensions.contains(extension)) {
        if (mounted) {
          context.showError(
            const BusinessRuleException(
              'Formats acceptes : PNG, JPG, WEBP ou SVG.',
            ),
          );
        }
        return;
      }

      if (picked.bytes.lengthInBytes > _maxLogoBytes) {
        if (mounted) {
          context.showError(
            BusinessRuleException(
              'Le logo ne doit pas depasser ${_formatLogoSize(_maxLogoBytes)}.',
            ),
          );
        }
        return;
      }

      if (mounted) setState(() => _uploadingLogo = true);
      final repo = ref.read(organizationRepositoryProvider);
      final logoUrl = await repo.uploadOrganizationLogo(
        orgId: org.id,
        bytes: picked.bytes,
        extension: extension,
        contentType: _logoContentType(picked),
      );

      await repo.updateOrganizationLogo(orgId: org.id, logoUrl: logoUrl);
      _logoUrlCtrl.text = logoUrl;
      await ref.read(currentOrganizationProvider.notifier).refresh();

      if (mounted) context.showSuccess('Logo importe.');
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _removeLogo(Organization org) async {
    setState(() => _uploadingLogo = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.deleteOrganizationLogoFiles(orgId: org.id);
      await repo.updateOrganizationLogo(orgId: org.id, logoUrl: null);
      _logoUrlCtrl.clear();
      await ref.read(currentOrganizationProvider.notifier).refresh();
      if (mounted) context.showSuccess('Logo retire.');
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _inviteUser(String orgId) async {
    final email = _inviteEmailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      context.showError(
        const BusinessRuleException('Saisissez un email valide.'),
      );
      return;
    }

    final selectedUnitId = _inviteIsGlobalAdmin ? null : _inviteChurchUnitId;
    final canManageChildren = _inviteIsGlobalAdmin
        ? true
        : _inviteCanManageChildren;
    if (!_inviteIsGlobalAdmin && selectedUnitId == null) {
      context.showError(
        const BusinessRuleException(
          'Choisissez le perimetre de ce sous-compte.',
        ),
      );
      return;
    }
    setState(() => _inviting = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.inviteUser(
        orgId: orgId,
        email: email,
        role: _inviteRole,
        primaryChurchUnitId: selectedUnitId,
        canManageChildren: canManageChildren,
      );
      _inviteEmailCtrl.clear();
      if (mounted) {
        context.showSuccess(
          "Invitation enregistree. Le compte sera rattache a l'inscription.",
        );
      }
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final churchUnitsAsync = ref.watch(churchUnitsProvider);

    return AppShell(
      title: 'Parametres organisation',
      currentRoute: '/organization-settings',
      showBackButton: true,
      backRoute: '/',
      body: orgAsync.when(
        loading: () => const Center(child: SkeletonLoader()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (org) {
          if (org == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.business,
                message: 'Aucune organisation trouvee.',
              ),
            );
          }

          if (_nomCtrl.text.isEmpty) _populateFields(org);

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.lg : AppSpacing.pagePadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _identitySection(org, compact: compact),
                          const SizedBox(height: AppSpacing.cardGap),
                          _themeSection(compact: compact),
                          const SizedBox(height: AppSpacing.cardGap),
                          _contactSection(),
                          const SizedBox(height: AppSpacing.cardGap),
                          _saveActions(org, compact: compact),
                          const SizedBox(height: AppSpacing.xl),
                          _inviteSection(
                            compact: compact,
                            orgId: org.id,
                            churchUnits: churchUnitsAsync.value ?? const [],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _identitySection(Organization org, {required bool compact}) {
    final logoUrl = _logoUrlCtrl.text.trim();
    final fallbackLabel = _sigleCtrl.text.trim().isNotEmpty
        ? _sigleCtrl.text.trim()
        : org.nom;
    final logo = CircleAvatar(
      radius: compact ? 34 : 40,
      backgroundColor: org.primaryColor.withValues(alpha: 0.1),
      child: logoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                logoUrl,
                width: compact ? 68 : 80,
                height: compact ? 68 : 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.church,
                  size: compact ? 28 : 32,
                  color: org.primaryColor,
                ),
              ),
            )
          : Text(
              fallbackLabel.isNotEmpty ? fallbackLabel[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: compact ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: org.primaryColor,
              ),
            ),
    );

    final fields = Column(
      children: [
        ResponsiveFormRow(
          children: [
            EabTextField(
              label: 'Nom de l\'organisation *',
              controller: _nomCtrl,
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            EabTextField(
              label: 'Sigle affiche',
              controller: _sigleCtrl,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        EabTextField(
          label: 'Description',
          controller: _descCtrl,
          maxLines: compact ? 3 : 2,
        ),
        const SizedBox(height: AppSpacing.md),
        _logoImportPanel(org, compact: compact),
      ],
    );

    return SectionCard(
      title: 'Identite',
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: logo),
                const SizedBox(height: AppSpacing.lg),
                fields,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: fields),
              ],
            ),
    );
  }

  Widget _logoImportPanel(Organization org, {required bool compact}) {
    final logoUrl = _logoUrlCtrl.text.trim();
    final hasLogo = logoUrl.isNotEmpty;
    final preview = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: org.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.broken_image_outlined, color: org.primaryColor),
            )
          : Icon(Icons.image_outlined, color: org.primaryColor),
    );

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        EabButton(
          label: hasLogo ? 'Remplacer' : 'Importer',
          icon: Icons.upload_file_outlined,
          variant: EabButtonVariant.outline,
          size: EabButtonSize.small,
          isLoading: _uploadingLogo,
          onPressed: _uploadingLogo ? null : () => _importLogo(org),
        ),
        if (hasLogo)
          EabButton(
            label: 'Retirer',
            icon: Icons.delete_outline,
            variant: EabButtonVariant.ghost,
            size: EabButtonSize.small,
            onPressed: _uploadingLogo ? null : () => _removeLogo(org),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    preview,
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(child: _LogoImportCopy()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            )
          : Row(
              children: [
                preview,
                const SizedBox(width: AppSpacing.md),
                const Expanded(child: _LogoImportCopy()),
                const SizedBox(width: AppSpacing.md),
                actions,
              ],
            ),
    );
  }

  Widget _themeSection({required bool compact}) {
    return SectionCard(
      title: 'Theme & Couleurs',
      child: Column(
        children: [
          ResponsiveFormRow(
            children: [
              _colorField(
                label: 'Couleur primaire',
                controller: _couleurPrimaireCtrl,
              ),
              _colorField(
                label: 'Couleur secondaire',
                controller: _couleurSecondaireCtrl,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: compact ? 56 : 48,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  _parseColor(
                    _couleurPrimaireCtrl.text,
                    const Color(0xFF1B2A4A),
                  ),
                  _parseColor(
                    _couleurSecondaireCtrl.text,
                    const Color(0xFFD4A843),
                  ),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'Apercu du theme',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactSection() {
    return SectionCard(
      title: 'Contact',
      child: Column(
        children: [
          ResponsiveFormRow(
            children: [
              EabTextField(label: 'Adresse', controller: _adresseCtrl),
              EabTextField(label: 'Telephone', controller: _telCtrl),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(label: 'Email', controller: _emailCtrl),
              EabTextField(label: 'Site web', controller: _siteCtrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _saveActions(Organization org, {required bool compact}) {
    final button = EabButton(
      label: 'Enregistrer',
      variant: EabButtonVariant.primary,
      isLoading: _saving,
      onPressed: _uploadingLogo ? null : () => _save(org),
    );
    if (compact) return button;
    return Align(alignment: Alignment.centerRight, child: button);
  }

  Widget _inviteSection({
    required bool compact,
    required String orgId,
    required List<ChurchUnit> churchUnits,
  }) {
    final scopedUnits = userScopeUnits(churchUnits);
    if (_inviteIsGlobalAdmin && _inviteChurchUnitId != null) {
      _inviteChurchUnitId = null;
    }
    if (_inviteChurchUnitId != null &&
        !scopedUnits.any((unit) => unit.id == _inviteChurchUnitId)) {
      _inviteChurchUnitId = null;
    }

    final button = EabButton(
      label: 'Inviter',
      variant: EabButtonVariant.primary,
      size: compact ? EabButtonSize.medium : EabButtonSize.small,
      isLoading: _inviting,
      onPressed: () => _inviteUser(orgId),
    );

    return SectionCard(
      title: 'Inviter un utilisateur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Email',
                controller: _inviteEmailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              DropdownButtonFormField<String>(
                initialValue: _inviteRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'adminNational',
                    child: Text('Admin national'),
                  ),
                  DropdownMenuItem(
                    value: 'responsableRegion',
                    child: Text('Responsable region'),
                  ),
                  DropdownMenuItem(
                    value: 'surintendantDistrict',
                    child: Text('Surintendant district'),
                  ),
                  DropdownMenuItem(
                    value: 'tresorierAssemblee',
                    child: Text('Tresorier assemblee'),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _inviteRole = v!;
                  if (_inviteIsGlobalAdmin) {
                    _inviteChurchUnitId = null;
                    _inviteCanManageChildren = true;
                  } else {
                    _inviteCanManageChildren =
                        _inviteRole != 'tresorierAssemblee';
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              DropdownButtonFormField<String?>(
                key: ValueKey(
                  'invite-scope-${_inviteIsGlobalAdmin ? 'global' : 'scoped'}'
                  '-${_inviteChurchUnitId ?? 'none'}',
                ),
                initialValue: _inviteIsGlobalAdmin ? null : _inviteChurchUnitId,
                isExpanded: true,
                hint: Text(
                  _inviteIsGlobalAdmin
                      ? 'Toute l organisation'
                      : scopedUnits.isEmpty
                      ? 'Aucun perimetre disponible'
                      : 'Choisir un perimetre',
                ),
                decoration: InputDecoration(
                  labelText: 'Perimetre',
                  helperText: _inviteIsGlobalAdmin
                      ? 'Acces complet a l organisation.'
                      : 'Un sous-compte doit etre limite a un niveau.',
                  border: const OutlineInputBorder(),
                ),
                items: _inviteIsGlobalAdmin
                    ? const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Toute l organisation'),
                        ),
                      ]
                    : scopedUnits
                          .map(
                            (unit) => DropdownMenuItem<String?>(
                              value: unit.id,
                              child: Text(
                                '${unit.typeLabel} - ${churchUnitLabel(unit)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                onChanged: _inviteIsGlobalAdmin || scopedUnits.isEmpty
                    ? null
                    : (v) => setState(() => _inviteChurchUnitId = v),
              ),
              CheckboxListTile(
                value: _inviteCanManageChildren,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Autoriser les sous-niveaux'),
                subtitle: Text(
                  _inviteIsGlobalAdmin
                      ? 'Toujours actif pour un admin national.'
                      : 'Inclut les niveaux descendants du perimetre choisi.',
                ),
                onChanged: _inviteIsGlobalAdmin
                    ? null
                    : (v) =>
                          setState(() => _inviteCanManageChildren = v ?? false),
              ),
              compact
                  ? SizedBox(width: double.infinity, child: button)
                  : button,
            ],
          ),
        ],
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

  String _logoContentType(PickedLogoFile file) {
    final mimeType = file.mimeType.trim();
    if (mimeType.isNotEmpty) return mimeType;

    return switch (file.extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      _ => 'application/octet-stream',
    };
  }

  String _formatLogoSize(int bytes) {
    final megaBytes = bytes / (1024 * 1024);
    return '${megaBytes.toStringAsFixed(0)} Mo';
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

class _LogoImportCopy extends StatelessWidget {
  const _LogoImportCopy();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo de l organisation',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PNG, JPG, WEBP ou SVG. Taille maximale : 2 Mo.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

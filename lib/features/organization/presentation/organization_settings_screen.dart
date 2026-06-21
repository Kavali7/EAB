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
import 'package:eab/features/organization/data/hierarchy_permission_models.dart';
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
  final _fiscalIfuCtrl = TextEditingController();
  final _fiscalRegistreCtrl = TextEditingController();
  final _fiscalCentreImpotsCtrl = TextEditingController();
  final _fiscalCentreDepotCtrl = TextEditingController();
  final _fiscalPaysCtrl = TextEditingController();
  final _fiscalSiegeCtrl = TextEditingController();
  final _fiscalActiviteCtrl = TextEditingController();
  final _fiscalRepresentantNomCtrl = TextEditingController();
  final _fiscalRepresentantTitreCtrl = TextEditingController();
  final _fiscalRepresentantTelCtrl = TextEditingController();
  final _fiscalComptableNomCtrl = TextEditingController();
  final _fiscalComptableTitreCtrl = TextEditingController();
  final _fiscalComptableTelCtrl = TextEditingController();
  final _fiscalComptableEmailCtrl = TextEditingController();
  final _fiscalBanqueCtrl = TextEditingController();
  final _fiscalCompteBancaireCtrl = TextEditingController();
  final _fiscalCompteLibelleCtrl = TextEditingController();
  final _fiscalFormeJuridiqueCodeCtrl = TextEditingController();
  final _fiscalRegimeCodeCtrl = TextEditingController();
  final _fiscalPaysCodeCtrl = TextEditingController();
  final _fiscalEtablissementsPaysCtrl = TextEditingController();
  final _fiscalEtablissementsHorsPaysCtrl = TextEditingController();
  final _fiscalPremierExerciceCtrl = TextEditingController();
  final _fiscalCodeActiviteCtrl = TextEditingController();
  final _fiscalCaisseSocialeCtrl = TextEditingController();
  final _fiscalCodeImportateurCtrl = TextEditingController();
  final _fiscalRepresentantIfuCtrl = TextEditingController();
  final _fiscalDirigeantsCtrl = TextEditingController();
  final _fiscalConseilCtrl = TextEditingController();
  final _fiscalNotesApplicablesCtrl = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();
  String _inviteRole = 'tresorierAssemblee';
  String _fiscalControleCode = 'private_national';
  String? _inviteChurchUnitId;
  bool _inviteCanManageChildren = false;
  String? _permissionAncestorUnitId;
  String? _permissionDescendantUnitId;
  bool _permissionRequiresAcceptance = false;
  bool _loadingPermissions = false;
  bool _savingPermission = false;
  bool _respondingPermission = false;
  List<HierarchyPermission> _effectivePermissions = const [];
  List<UnitPermissionOverride> _permissionOverrides = const [];
  bool _saving = false;
  bool _inviting = false;
  bool _uploadingLogo = false;

  bool get _inviteIsGlobalAdmin => _inviteRole == 'adminNational';

  static const _maxLogoBytes = 2 * 1024 * 1024;
  static const _allowedLogoExtensions = {'png', 'jpg', 'jpeg', 'webp', 'svg'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPermissionOverrides();
    });
  }

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
    _fiscalIfuCtrl.dispose();
    _fiscalRegistreCtrl.dispose();
    _fiscalCentreImpotsCtrl.dispose();
    _fiscalCentreDepotCtrl.dispose();
    _fiscalPaysCtrl.dispose();
    _fiscalSiegeCtrl.dispose();
    _fiscalActiviteCtrl.dispose();
    _fiscalRepresentantNomCtrl.dispose();
    _fiscalRepresentantTitreCtrl.dispose();
    _fiscalRepresentantTelCtrl.dispose();
    _fiscalComptableNomCtrl.dispose();
    _fiscalComptableTitreCtrl.dispose();
    _fiscalComptableTelCtrl.dispose();
    _fiscalComptableEmailCtrl.dispose();
    _fiscalBanqueCtrl.dispose();
    _fiscalCompteBancaireCtrl.dispose();
    _fiscalCompteLibelleCtrl.dispose();
    _fiscalFormeJuridiqueCodeCtrl.dispose();
    _fiscalRegimeCodeCtrl.dispose();
    _fiscalPaysCodeCtrl.dispose();
    _fiscalEtablissementsPaysCtrl.dispose();
    _fiscalEtablissementsHorsPaysCtrl.dispose();
    _fiscalPremierExerciceCtrl.dispose();
    _fiscalCodeActiviteCtrl.dispose();
    _fiscalCaisseSocialeCtrl.dispose();
    _fiscalCodeImportateurCtrl.dispose();
    _fiscalRepresentantIfuCtrl.dispose();
    _fiscalDirigeantsCtrl.dispose();
    _fiscalConseilCtrl.dispose();
    _fiscalNotesApplicablesCtrl.dispose();
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
    final fiscal = org.fiscalProfile;
    _fiscalIfuCtrl.text = fiscal.ifu ?? '';
    _fiscalRegistreCtrl.text = fiscal.registrationNumber ?? '';
    _fiscalCentreImpotsCtrl.text = fiscal.taxCenter ?? '';
    _fiscalCentreDepotCtrl.text = fiscal.depositCenter ?? '';
    _fiscalPaysCtrl.text = fiscal.country ?? 'REPUBLIQUE DU BENIN';
    _fiscalSiegeCtrl.text = fiscal.headOfficeAddress ?? org.adresse ?? '';
    _fiscalActiviteCtrl.text = fiscal.activityDescription ?? '';
    _fiscalRepresentantNomCtrl.text = fiscal.legalRepresentativeName ?? '';
    _fiscalRepresentantTitreCtrl.text =
        fiscal.legalRepresentativeTitle ?? 'Representant legal';
    _fiscalRepresentantTelCtrl.text = fiscal.legalRepresentativePhone ?? '';
    _fiscalComptableNomCtrl.text = fiscal.accountantName ?? '';
    _fiscalComptableTitreCtrl.text =
        fiscal.accountantTitle ?? 'Comptable responsable';
    _fiscalComptableTelCtrl.text = fiscal.accountantPhone ?? '';
    _fiscalComptableEmailCtrl.text = fiscal.accountantEmail ?? '';
    _fiscalBanqueCtrl.text = fiscal.bankName ?? '';
    _fiscalCompteBancaireCtrl.text = fiscal.bankAccountNumber ?? '';
    _fiscalCompteLibelleCtrl.text = fiscal.bankAccountLabel ?? '';
    _fiscalFormeJuridiqueCodeCtrl.text = fiscal.legalFormCode ?? '07';
    _fiscalRegimeCodeCtrl.text = fiscal.taxRegimeCode ?? '01';
    _fiscalPaysCodeCtrl.text = fiscal.countryCode ?? '01';
    _fiscalEtablissementsPaysCtrl.text = fiscal.establishmentsInCountry ?? '01';
    _fiscalEtablissementsHorsPaysCtrl.text =
        fiscal.establishmentsOutsideCountry ?? '00';
    _fiscalPremierExerciceCtrl.text = fiscal.firstFiscalYear ?? '';
    _fiscalControleCode = fiscal.controlTypeCode ?? 'private_national';
    _fiscalCodeActiviteCtrl.text = fiscal.mainActivityCode ?? '';
    _fiscalCaisseSocialeCtrl.text = fiscal.socialSecurityNumber ?? '';
    _fiscalCodeImportateurCtrl.text = fiscal.importerCode ?? '';
    _fiscalRepresentantIfuCtrl.text = fiscal.legalRepresentativeFiscalId ?? '';
    _fiscalDirigeantsCtrl.text = fiscal.governanceLeaders ?? '';
    _fiscalConseilCtrl.text = fiscal.boardMembers ?? '';
    _fiscalNotesApplicablesCtrl.text =
        fiscal.applicableNotes ??
        OrganizationFiscalProfile.defaultApplicableNotes;
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
        parametres: OrganizationFiscalProfile.mergeIntoParametres(
          org.parametres,
          _fiscalProfileFromCurrentValues(),
        ),
        createdAt: org.createdAt,
      );
      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateOrganization(updated);
      await repo.completeOnboardingSteps(
        orgId: org.id,
        completedSteps: _completedOnboardingStepsFromCurrentValues(),
      );
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
      await repo.completeOnboardingSteps(
        orgId: org.id,
        completedSteps: const ['logo'],
      );
      _logoUrlCtrl.text = logoUrl;
      await ref.read(currentOrganizationProvider.notifier).refresh();

      if (mounted) context.showSuccess('Logo importe.');
    } catch (e) {
      if (mounted) context.showError(_logoImportError(e));
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

  Future<void> _loadHierarchyPermissions() async {
    final ancestorId = _permissionAncestorUnitId;
    final descendantId = _permissionDescendantUnitId;
    if (ancestorId == null || descendantId == null) {
      context.showError(
        const BusinessRuleException(
          'Choisissez une unite superieure et une unite inferieure.',
        ),
      );
      return;
    }

    setState(() => _loadingPermissions = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      final permissions = await repo.fetchEffectiveHierarchyPermissions(
        ancestorUnitId: ancestorId,
        descendantUnitId: descendantId,
      );
      final overrides = await repo.fetchUnitPermissionOverrides();
      if (mounted) {
        setState(() {
          _effectivePermissions = permissions;
          _permissionOverrides = overrides;
        });
      }
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _loadingPermissions = false);
    }
  }

  Future<void> _loadPermissionOverrides() async {
    setState(() => _loadingPermissions = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      final overrides = await repo.fetchUnitPermissionOverrides();
      if (mounted) setState(() => _permissionOverrides = overrides);
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _loadingPermissions = false);
    }
  }

  Future<void> _setHierarchyPermission(
    HierarchyPermission permission,
    bool allowed,
  ) async {
    final ancestorId = _permissionAncestorUnitId;
    final descendantId = _permissionDescendantUnitId;
    if (ancestorId == null || descendantId == null) return;

    setState(() => _savingPermission = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.setHierarchyPermissionOverride(
        ancestorUnitId: ancestorId,
        descendantUnitId: descendantId,
        domainCode: permission.domainCode,
        actionCode: permission.actionCode,
        allowed: allowed,
        requiresDescendantAcceptance: allowed && _permissionRequiresAcceptance,
        reason: _permissionRequiresAcceptance
            ? 'Accord demande depuis les parametres organisation.'
            : 'Autorisation configuree depuis les parametres organisation.',
      );
      await _loadHierarchyPermissions();
      if (mounted) {
        context.showSuccess(
          allowed ? 'Autorisation enregistree.' : 'Autorisation retiree.',
        );
      }
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _savingPermission = false);
    }
  }

  Future<void> _respondPermissionOverride(
    UnitPermissionOverride override,
    bool accept,
  ) async {
    setState(() => _respondingPermission = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.respondHierarchyPermissionOverride(
        overrideId: override.id,
        accept: accept,
        reason: accept
            ? 'Accord valide depuis les parametres organisation.'
            : 'Accord refuse depuis les parametres organisation.',
      );
      await _loadHierarchyPermissions();
      if (mounted) {
        context.showSuccess(accept ? 'Demande acceptee.' : 'Demande refusee.');
      }
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _respondingPermission = false);
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
                          if (org.hasPendingOnboardingSteps) ...[
                            _onboardingSection(org, compact: compact),
                            const SizedBox(height: AppSpacing.cardGap),
                          ],
                          _identitySection(org, compact: compact),
                          const SizedBox(height: AppSpacing.cardGap),
                          _themeSection(compact: compact),
                          const SizedBox(height: AppSpacing.cardGap),
                          _contactSection(),
                          const SizedBox(height: AppSpacing.cardGap),
                          _fiscalIdentitySection(compact: compact),
                          const SizedBox(height: AppSpacing.cardGap),
                          _saveActions(org, compact: compact),
                          const SizedBox(height: AppSpacing.xl),
                          _inviteSection(
                            compact: compact,
                            orgId: org.id,
                            churchUnits: churchUnitsAsync.value ?? const [],
                          ),
                          const SizedBox(height: AppSpacing.cardGap),
                          _hierarchyPermissionsSection(
                            compact: compact,
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

  Widget _onboardingSection(Organization org, {required bool compact}) {
    final pendingSteps = org.onboardingSkippedSteps;
    return SectionCard(
      title: 'Demarrage a terminer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ces points ont ete reportes pendant la creation. Ils seront marques comme termines quand les informations correspondantes seront enregistrees.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: pendingSteps
                .map(
                  (step) => _OnboardingStepCard(
                    step: step,
                    compact: compact,
                    onOpenStructure: step == 'hierarchy_details'
                        ? () => Navigator.of(context).pushNamed('/structure')
                        : null,
                  ),
                )
                .toList(),
          ),
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

  Widget _fiscalIdentitySection({required bool compact}) {
    return SectionCard(
      title: 'Identite fiscale & signataires',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ces informations remplacent toutes les donnees du modele dans le dossier fiscal Excel ou PDF.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Numero IFU',
                controller: _fiscalIfuCtrl,
                helper: 'Requis pour un dossier fiscal deposable.',
              ),
              EabTextField(
                label: 'Reference administrative',
                controller: _fiscalRegistreCtrl,
                helper: 'Registre, agrement ou identifiant reconnu.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Centre des impots',
                controller: _fiscalCentreImpotsCtrl,
              ),
              EabTextField(
                label: 'Centre de depot',
                controller: _fiscalCentreDepotCtrl,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(label: 'Pays', controller: _fiscalPaysCtrl),
              EabTextField(label: 'Siege fiscal', controller: _fiscalSiegeCtrl),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          EabTextField(
            label: 'Activite principale',
            controller: _fiscalActiviteCtrl,
            maxLines: compact ? 3 : 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          _subsectionTitle('Parametres SYSCEBNL'),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Code forme juridique',
                controller: _fiscalFormeJuridiqueCodeCtrl,
                helper: '07 = Association dans NOTE 36.',
                keyboardType: TextInputType.number,
              ),
              EabTextField(
                label: 'Code regime fiscal',
                controller: _fiscalRegimeCodeCtrl,
                helper: '01 = Reel normal.',
                keyboardType: TextInputType.number,
              ),
              EabTextField(
                label: 'Code pays siege',
                controller: _fiscalPaysCodeCtrl,
                helper: '01 = Benin.',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Etablissements pays',
                controller: _fiscalEtablissementsPaysCtrl,
                keyboardType: TextInputType.number,
              ),
              EabTextField(
                label: 'Etablissements hors pays',
                controller: _fiscalEtablissementsHorsPaysCtrl,
                keyboardType: TextInputType.number,
              ),
              EabTextField(
                label: 'Premier exercice',
                controller: _fiscalPremierExerciceCtrl,
                helper: 'Laisse vide = annee du dossier.',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              _fiscalControlDropdown(),
              EabTextField(
                label: 'Code activite',
                controller: _fiscalCodeActiviteCtrl,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'N caisse sociale',
                controller: _fiscalCaisseSocialeCtrl,
              ),
              EabTextField(
                label: 'Code importateur',
                controller: _fiscalCodeImportateurCtrl,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _subsectionTitle('Representant legal'),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Nom complet',
                controller: _fiscalRepresentantNomCtrl,
              ),
              EabTextField(
                label: 'Qualite',
                controller: _fiscalRepresentantTitreCtrl,
              ),
              EabTextField(
                label: 'Telephone',
                controller: _fiscalRepresentantTelCtrl,
                keyboardType: TextInputType.phone,
              ),
              EabTextField(
                label: 'IFU representant',
                controller: _fiscalRepresentantIfuCtrl,
                helper: 'Facultatif, repris sur FICHE R3.',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _subsectionTitle('Gouvernance fiscale'),
          const SizedBox(height: AppSpacing.sm),
          EabTextField(
            label: 'Dirigeants FICHE R3',
            controller: _fiscalDirigeantsCtrl,
            helper: 'Une ligne : Nom complet | Qualite courte | IFU | Adresse.',
            hint:
                'Georges GUIDAN | Representant legal | 3202600000099 | Cotonou',
            maxLines: compact ? 5 : 4,
          ),
          const SizedBox(height: AppSpacing.md),
          EabTextField(
            label: 'Conseil d administration FICHE R3',
            controller: _fiscalConseilCtrl,
            helper: 'Une ligne : Nom complet | Qualite courte | Adresse.',
            hint: 'Marie HOUNTON | Presidente du conseil | Porto-Novo',
            maxLines: compact ? 5 : 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          _subsectionTitle('Comptable responsable'),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Nom complet',
                controller: _fiscalComptableNomCtrl,
              ),
              EabTextField(
                label: 'Qualite',
                controller: _fiscalComptableTitreCtrl,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              EabTextField(
                label: 'Telephone comptable',
                controller: _fiscalComptableTelCtrl,
                keyboardType: TextInputType.phone,
              ),
              EabTextField(
                label: 'Email comptable',
                controller: _fiscalComptableEmailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _subsectionTitle('Banque de reference'),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveFormRow(
            children: [
              EabTextField(label: 'Banque', controller: _fiscalBanqueCtrl),
              EabTextField(
                label: 'Numero de compte',
                controller: _fiscalCompteBancaireCtrl,
              ),
              EabTextField(
                label: 'Intitule du compte',
                controller: _fiscalCompteLibelleCtrl,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _subsectionTitle('Notes annexes applicables'),
          const SizedBox(height: AppSpacing.sm),
          EabTextField(
            label: 'Notes applicables FICHE R4',
            controller: _fiscalNotesApplicablesCtrl,
            helper:
                'Separez par virgule ou retour a la ligne. Les autres notes seront marquees N/A.',
            hint: OrganizationFiscalProfile.defaultApplicableNotes,
            maxLines: compact ? 6 : 4,
          ),
        ],
      ),
    );
  }

  Widget _subsectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _fiscalControlDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _fiscalControleCode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Controle entite',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'public', child: Text('Controle public')),
        DropdownMenuItem(
          value: 'private_national',
          child: Text('Controle prive national'),
        ),
        DropdownMenuItem(
          value: 'private_foreign',
          child: Text('Controle prive etranger'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _fiscalControleCode = value);
      },
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

  Widget _hierarchyPermissionsSection({
    required bool compact,
    required List<ChurchUnit> churchUnits,
  }) {
    final activeUnits = userScopeUnits(churchUnits);
    final selectedAncestorId =
        _permissionAncestorUnitId != null &&
            activeUnits.any((unit) => unit.id == _permissionAncestorUnitId)
        ? _permissionAncestorUnitId
        : null;

    final descendantUnits = selectedAncestorId == null
        ? const <ChurchUnit>[]
        : _descendantUnitsOf(activeUnits, selectedAncestorId);

    final selectedDescendantId =
        _permissionDescendantUnitId != null &&
            descendantUnits.any(
              (unit) => unit.id == _permissionDescendantUnitId,
            )
        ? _permissionDescendantUnitId
        : null;

    final displayedPermissions = selectedDescendantId == null
        ? const <HierarchyPermission>[]
        : _effectivePermissions;
    final groupedPermissions = _groupPermissionsByDomain(displayedPermissions);

    return SectionCard(
      title: 'Autorisations hierarchiques',
      actions: [
        EabButton(
          label: 'Actualiser',
          icon: Icons.refresh,
          variant: EabButtonVariant.ghost,
          size: EabButtonSize.small,
          isLoading: _loadingPermissions,
          onPressed: _loadPermissionOverrides,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configurez ce que le niveau superieur peut voir ou faire chez un niveau inferieur.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFormRow(
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedAncestorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Niveau superieur',
                  border: OutlineInputBorder(),
                ),
                items: activeUnits
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit.id,
                        child: Text(
                          _unitDisplayLabel(unit),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: activeUnits.isEmpty
                    ? null
                    : (value) => setState(() {
                        _permissionAncestorUnitId = value;
                        _permissionDescendantUnitId = null;
                        _effectivePermissions = const [];
                      }),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'permission-descendant-${selectedAncestorId ?? 'none'}'
                  '-${selectedDescendantId ?? 'none'}',
                ),
                initialValue: selectedDescendantId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Niveau inferieur',
                  border: OutlineInputBorder(),
                ),
                hint: Text(
                  selectedAncestorId == null
                      ? 'Choisir un niveau superieur'
                      : descendantUnits.isEmpty
                      ? 'Aucun descendant'
                      : 'Choisir un niveau inferieur',
                ),
                items: descendantUnits
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit.id,
                        child: Text(
                          _unitDisplayLabel(unit),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: descendantUnits.isEmpty
                    ? null
                    : (value) => setState(() {
                        _permissionDescendantUnitId = value;
                        _effectivePermissions = const [];
                      }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? double.infinity : 340,
                child: SwitchListTile(
                  value: _permissionRequiresAcceptance,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Demander l accord du niveau inferieur'),
                  subtitle: const Text(
                    'Les droits ajoutes attendront une acceptation.',
                  ),
                  onChanged: (value) =>
                      setState(() => _permissionRequiresAcceptance = value),
                ),
              ),
              EabButton(
                label: 'Charger la matrice',
                icon: Icons.rule_outlined,
                variant: EabButtonVariant.primary,
                fullWidth: compact,
                isLoading: _loadingPermissions,
                onPressed:
                    selectedAncestorId == null || selectedDescendantId == null
                    ? null
                    : _loadHierarchyPermissions,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (displayedPermissions.isEmpty)
            _PermissionHint(compact: compact)
          else
            Column(
              children: [
                for (final entry in groupedPermissions.entries) ...[
                  _PermissionDomainBlock(
                    title: entry.key,
                    permissions: entry.value,
                    saving: _savingPermission,
                    onChanged: _setHierarchyPermission,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          if (_permissionOverrides.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _PermissionRequestsPanel(
              overrides: _permissionOverrides,
              unitLabelForId: (id) => _unitLabelById(activeUnits, id),
              responding: _respondingPermission,
              onAccept: (override) =>
                  _respondPermissionOverride(override, true),
              onReject: (override) =>
                  _respondPermissionOverride(override, false),
            ),
          ],
        ],
      ),
    );
  }

  List<ChurchUnit> _descendantUnitsOf(
    List<ChurchUnit> units,
    String ancestorId,
  ) {
    final byParent = <String?, List<ChurchUnit>>{};
    for (final unit in units) {
      byParent.putIfAbsent(unit.parentId, () => []).add(unit);
    }

    final result = <ChurchUnit>[];
    void collect(String parentId) {
      for (final child in byParent[parentId] ?? const <ChurchUnit>[]) {
        result.add(child);
        collect(child.id);
      }
    }

    collect(ancestorId);
    result.sort((a, b) {
      final level = a.levelOrder.compareTo(b.levelOrder);
      if (level != 0) return level;
      return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
    });
    return result;
  }

  Map<String, List<HierarchyPermission>> _groupPermissionsByDomain(
    List<HierarchyPermission> permissions,
  ) {
    final grouped = <String, List<HierarchyPermission>>{};
    for (final permission in permissions) {
      grouped
          .putIfAbsent(permission.domainLabel, () => <HierarchyPermission>[])
          .add(permission);
    }
    return grouped;
  }

  String _unitDisplayLabel(ChurchUnit unit) {
    return '${unit.typeLabel} - ${churchUnitLabel(unit)}';
  }

  String _unitLabelById(List<ChurchUnit> units, String unitId) {
    final matches = units.where((unit) => unit.id == unitId);
    if (matches.isEmpty) return 'Unite inconnue';
    return _unitDisplayLabel(matches.first);
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
            validator: _validateHexColor,
          ),
        ),
      ],
    );
  }

  List<String> _completedOnboardingStepsFromCurrentValues() {
    final steps = <String>[];
    if (_logoUrlCtrl.text.trim().isNotEmpty) {
      steps.add('logo');
    }
    if (_isValidHexColor(_couleurPrimaireCtrl.text) &&
        _isValidHexColor(_couleurSecondaireCtrl.text)) {
      steps.add('colors');
    }
    if ([
      _adresseCtrl.text,
      _telCtrl.text,
      _emailCtrl.text,
      _siteCtrl.text,
    ].any((value) => value.trim().isNotEmpty)) {
      steps.add('contact');
    }
    if ([
      _fiscalIfuCtrl.text,
      _fiscalCentreImpotsCtrl.text,
      _fiscalRepresentantNomCtrl.text,
      _fiscalComptableNomCtrl.text,
      _fiscalDirigeantsCtrl.text,
      _fiscalNotesApplicablesCtrl.text,
    ].any((value) => value.trim().isNotEmpty)) {
      steps.add('fiscal_identity');
    }
    return steps;
  }

  OrganizationFiscalProfile _fiscalProfileFromCurrentValues() {
    return OrganizationFiscalProfile(
      ifu: _nullIfBlank(_fiscalIfuCtrl.text),
      registrationNumber: _nullIfBlank(_fiscalRegistreCtrl.text),
      taxCenter: _nullIfBlank(_fiscalCentreImpotsCtrl.text),
      depositCenter: _nullIfBlank(_fiscalCentreDepotCtrl.text),
      country: _nullIfBlank(_fiscalPaysCtrl.text),
      headOfficeAddress: _nullIfBlank(_fiscalSiegeCtrl.text),
      activityDescription: _nullIfBlank(_fiscalActiviteCtrl.text),
      legalRepresentativeName: _nullIfBlank(_fiscalRepresentantNomCtrl.text),
      legalRepresentativeTitle: _nullIfBlank(_fiscalRepresentantTitreCtrl.text),
      legalRepresentativePhone: _nullIfBlank(_fiscalRepresentantTelCtrl.text),
      accountantName: _nullIfBlank(_fiscalComptableNomCtrl.text),
      accountantTitle: _nullIfBlank(_fiscalComptableTitreCtrl.text),
      accountantPhone: _nullIfBlank(_fiscalComptableTelCtrl.text),
      accountantEmail: _nullIfBlank(_fiscalComptableEmailCtrl.text),
      bankName: _nullIfBlank(_fiscalBanqueCtrl.text),
      bankAccountLabel: _nullIfBlank(_fiscalCompteLibelleCtrl.text),
      bankAccountNumber: _nullIfBlank(_fiscalCompteBancaireCtrl.text),
      legalFormCode: _nullIfBlank(_fiscalFormeJuridiqueCodeCtrl.text),
      taxRegimeCode: _nullIfBlank(_fiscalRegimeCodeCtrl.text),
      countryCode: _nullIfBlank(_fiscalPaysCodeCtrl.text),
      establishmentsInCountry: _nullIfBlank(_fiscalEtablissementsPaysCtrl.text),
      establishmentsOutsideCountry: _nullIfBlank(
        _fiscalEtablissementsHorsPaysCtrl.text,
      ),
      firstFiscalYear: _nullIfBlank(_fiscalPremierExerciceCtrl.text),
      controlTypeCode: _fiscalControleCode,
      mainActivityCode: _nullIfBlank(_fiscalCodeActiviteCtrl.text),
      socialSecurityNumber: _nullIfBlank(_fiscalCaisseSocialeCtrl.text),
      importerCode: _nullIfBlank(_fiscalCodeImportateurCtrl.text),
      legalRepresentativeFiscalId: _nullIfBlank(
        _fiscalRepresentantIfuCtrl.text,
      ),
      governanceLeaders: _nullIfBlank(_fiscalDirigeantsCtrl.text),
      boardMembers: _nullIfBlank(_fiscalConseilCtrl.text),
      applicableNotes: _nullIfBlank(_fiscalNotesApplicablesCtrl.text),
    );
  }

  String? _nullIfBlank(String value) {
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
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

  AppException _logoImportError(Object error) {
    final detail = error.toString();
    final message = detail.toLowerCase();

    if (message.contains('bucket') &&
        (message.contains('not found') ||
            message.contains('does not exist') ||
            message.contains('introuvable'))) {
      return const DataException(
        'Le bucket Storage organization-assets est introuvable. Appliquez la migration 00028 ou creez ce bucket public dans Supabase.',
      );
    }

    if (message.contains('row-level security') ||
        message.contains('rls') ||
        message.contains('unauthorized') ||
        message.contains('403') ||
        message.contains('permission denied')) {
      return PermissionException(
        'Import refuse par Supabase Storage. Verifiez que votre compte est admin national et que les politiques Storage sont appliquees.',
        detail,
      );
    }

    if (message.contains('payload too large') ||
        message.contains('file size') ||
        message.contains('too large')) {
      return BusinessRuleException(
        'Le logo ne doit pas depasser ${_formatLogoSize(_maxLogoBytes)}.',
        technicalDetail: detail,
      );
    }

    return UnknownException(
      'Le logo n a pas pu etre importe. Detail : ${_compactErrorDetail(detail)}',
      detail,
    );
  }

  String _compactErrorDetail(String detail) {
    final normalized = detail.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 110) return normalized;
    return '${normalized.substring(0, 107)}...';
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

  String? _validateHexColor(String? value) {
    if (_isValidHexColor(value)) return null;
    return 'Format attendu : #123ABC';
  }

  bool _isValidHexColor(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return false;
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(clean);
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({
    required this.step,
    required this.compact,
    this.onOpenStructure,
  });

  final String step;
  final bool compact;
  final VoidCallback? onOpenStructure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = compact ? double.infinity : 286.0;
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 106),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForStep(step), size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _titleForStep(step),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _descriptionForStep(step),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (onOpenStructure != null) ...[
              const SizedBox(height: AppSpacing.sm),
              EabButton(
                label: 'Ouvrir Structure',
                icon: Icons.account_tree_outlined,
                variant: EabButtonVariant.outline,
                size: EabButtonSize.small,
                onPressed: onOpenStructure,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForStep(String value) {
    return switch (value) {
      'logo' => Icons.image_outlined,
      'colors' => Icons.palette_outlined,
      'contact' => Icons.contact_mail_outlined,
      'hierarchy_details' => Icons.account_tree_outlined,
      _ => Icons.task_alt_outlined,
    };
  }

  String _titleForStep(String value) {
    return switch (value) {
      'logo' => 'Logo',
      'colors' => 'Couleurs',
      'contact' => 'Contact',
      'hierarchy_details' => 'Structure detaillee',
      _ => value,
    };
  }

  String _descriptionForStep(String value) {
    return switch (value) {
      'logo' => 'Importez le logo officiel depuis le bloc Identite.',
      'colors' => 'Choisissez les couleurs principales du site.',
      'contact' => 'Ajoutez adresse, telephone, email ou site web.',
      'hierarchy_details' =>
        'Ajoutez les niveaux et les unites depuis l ecran Structure.',
      _ => 'Completez cette information dans les parametres.',
    };
  }
}

class _PermissionHint extends StatelessWidget {
  const _PermissionHint({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              compact
                  ? 'Choisissez deux unites puis chargez la matrice.'
                  : 'Choisissez une unite superieure, une unite inferieure, puis chargez la matrice pour voir les droits disponibles.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDomainBlock extends StatelessWidget {
  const _PermissionDomainBlock({
    required this.title,
    required this.permissions,
    required this.saving,
    required this.onChanged,
  });

  final String title;
  final List<HierarchyPermission> permissions;
  final bool saving;
  final Future<void> Function(HierarchyPermission permission, bool allowed)
  onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.folder_copy_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: permissions
                .map(
                  (permission) => _PermissionActionTile(
                    permission: permission,
                    saving: saving,
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PermissionActionTile extends StatelessWidget {
  const _PermissionActionTile({
    required this.permission,
    required this.saving,
    required this.onChanged,
  });

  final HierarchyPermission permission;
  final bool saving;
  final Future<void> Function(HierarchyPermission permission, bool allowed)
  onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = permission.allowed
        ? Colors.green.shade700
        : colorScheme.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: permission.allowed
              ? Colors.green.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: permission.allowed
                ? Colors.green.withValues(alpha: 0.35)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    permission.actionLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _permissionStatusLabel(permission),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
            Switch(
              value: permission.allowed,
              onChanged: saving
                  ? null
                  : (value) => onChanged(permission, value),
            ),
          ],
        ),
      ),
    );
  }

  String _permissionStatusLabel(HierarchyPermission permission) {
    if (permission.isPending) return 'En attente d accord';
    if (permission.hasOverride) return 'Exception';
    if (permission.allowed) return 'Regle active';
    return 'Non autorise';
  }
}

class _PermissionRequestsPanel extends StatelessWidget {
  const _PermissionRequestsPanel({
    required this.overrides,
    required this.unitLabelForId,
    required this.responding,
    required this.onAccept,
    required this.onReject,
  });

  final List<UnitPermissionOverride> overrides;
  final String Function(String unitId) unitLabelForId;
  final bool responding;
  final Future<void> Function(UnitPermissionOverride override) onAccept;
  final Future<void> Function(UnitPermissionOverride override) onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Demandes d accord',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final override in overrides) ...[
            _PermissionRequestTile(
              permissionOverride: override,
              ancestorLabel: unitLabelForId(override.ancestorUnitId),
              descendantLabel: unitLabelForId(override.descendantUnitId),
              responding: responding,
              onAccept: onAccept,
              onReject: onReject,
            ),
            if (override != overrides.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PermissionRequestTile extends StatelessWidget {
  const _PermissionRequestTile({
    required this.permissionOverride,
    required this.ancestorLabel,
    required this.descendantLabel,
    required this.responding,
    required this.onAccept,
    required this.onReject,
  });

  final UnitPermissionOverride permissionOverride;
  final String ancestorLabel;
  final String descendantLabel;
  final bool responding;
  final Future<void> Function(UnitPermissionOverride override) onAccept;
  final Future<void> Function(UnitPermissionOverride override) onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = switch (permissionOverride.acceptanceStatus) {
      'accepted' => Colors.green.shade700,
      'rejected' => colorScheme.error,
      'revoked' => colorScheme.error,
      'pending' => Colors.orange.shade800,
      _ => colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${permissionOverride.domainLabel} - ${permissionOverride.actionLabel}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '$ancestorLabel vers $descendantLabel',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (permissionOverride.reason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              permissionOverride.reason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(
                  _overrideStatusLabel(permissionOverride.acceptanceStatus),
                ),
                labelStyle: TextStyle(color: statusColor),
                backgroundColor: statusColor.withValues(alpha: 0.08),
                side: BorderSide(color: statusColor.withValues(alpha: 0.28)),
              ),
              if (permissionOverride.isPending) ...[
                EabButton(
                  label: 'Accepter',
                  icon: Icons.check,
                  size: EabButtonSize.small,
                  variant: EabButtonVariant.outline,
                  isLoading: responding,
                  onPressed: responding
                      ? null
                      : () => onAccept(permissionOverride),
                ),
                EabButton(
                  label: 'Refuser',
                  icon: Icons.close,
                  size: EabButtonSize.small,
                  variant: EabButtonVariant.ghost,
                  onPressed: responding
                      ? null
                      : () => onReject(permissionOverride),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _overrideStatusLabel(String status) {
    return switch (status) {
      'pending' => 'En attente',
      'accepted' => 'Accepte',
      'rejected' => 'Refuse',
      'revoked' => 'Revoque',
      _ => 'Sans accord requis',
    };
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

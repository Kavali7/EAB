import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eab/core/errors/error_handler.dart';
import 'package:eab/core/theme.dart';
import 'package:eab/features/church_units/application/church_units_provider.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/providers/church_structure_providers.dart';
import 'package:eab/providers/user_profile_providers.dart';

class OrganizationOnboardingScreen extends ConsumerStatefulWidget {
  const OrganizationOnboardingScreen({super.key});

  @override
  ConsumerState<OrganizationOnboardingScreen> createState() =>
      _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState
    extends ConsumerState<OrganizationOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sigleCtrl = TextEditingController();
  final _rootUnitCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _structureModel = 'single';
  bool _skipLogo = true;
  bool _skipColors = true;
  bool _skipContact = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sigleCtrl.dispose();
    _rootUnitCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.createOrganizationOnboarding(
        name: _nameCtrl.text.trim(),
        sigle: _sigleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        structureModel: _structureModel,
        rootUnitName: _rootUnitCtrl.text.trim(),
        skipSteps: [
          if (_skipLogo) 'logo',
          if (_skipColors) 'colors',
          if (_skipContact) 'contact',
          if (_structureModel == 'multi_level') 'hierarchy_details',
        ],
      );

      ref.invalidate(profilsUtilisateursProvider);
      ref.invalidate(profilUtilisateurCourantProvider);
      ref.invalidate(assembleeActiveIdProvider);
      ref.invalidate(churchUnitActiveIdProvider);
      ref.invalidate(regionsProvider);
      ref.invalidate(districtsProvider);
      ref.invalidate(assembleesLocalesProvider);
      ref.invalidate(churchUnitsProvider);
      await ref.read(currentOrganizationProvider.notifier).refresh();

      if (!mounted) return;
      context.showSuccess('Eglise creee.');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 980;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) const Expanded(flex: 4, child: _OnboardingAside()),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 56 : 18,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isWide) ...[
                          const _MobileHeader(),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          'Configurer votre espace',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: isWide ? 30 : 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Renseignez le minimum pour commencer.',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        _OnboardingFormCard(
                          formKey: _formKey,
                          nameCtrl: _nameCtrl,
                          sigleCtrl: _sigleCtrl,
                          rootUnitCtrl: _rootUnitCtrl,
                          descriptionCtrl: _descriptionCtrl,
                          structureModel: _structureModel,
                          skipLogo: _skipLogo,
                          skipColors: _skipColors,
                          skipContact: _skipContact,
                          saving: _saving,
                          onStructureChanged: (value) =>
                              setState(() => _structureModel = value),
                          onSkipLogoChanged: (value) =>
                              setState(() => _skipLogo = value),
                          onSkipColorsChanged: (value) =>
                              setState(() => _skipColors = value),
                          onSkipContactChanged: (value) =>
                              setState(() => _skipContact = value),
                          onSubmit: _createOrganization,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => Supabase.instance.client.auth.signOut(),
                            icon: const Icon(Icons.logout),
                            label: const Text('Changer de compte'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingAside extends StatelessWidget {
  const _OnboardingAside();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(size: 58),
          const SizedBox(height: 44),
          Text(
            'Nouvelle eglise',
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Un espace autonome avec sa structure, ses sous-comptes et ses parametres.',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFD7E4EA),
              fontSize: 17,
              height: 1.55,
            ),
          ),
          const Spacer(),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AsideChip(icon: Icons.account_tree_outlined, label: 'Structure'),
              _AsideChip(icon: Icons.admin_panel_settings, label: 'Acces'),
              _AsideChip(icon: Icons.palette_outlined, label: 'Identite'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _BrandMark(size: 44),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Nouvelle eglise',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingFormCard extends StatelessWidget {
  const _OnboardingFormCard({
    required this.formKey,
    required this.nameCtrl,
    required this.sigleCtrl,
    required this.rootUnitCtrl,
    required this.descriptionCtrl,
    required this.structureModel,
    required this.skipLogo,
    required this.skipColors,
    required this.skipContact,
    required this.saving,
    required this.onStructureChanged,
    required this.onSkipLogoChanged,
    required this.onSkipColorsChanged,
    required this.onSkipContactChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController sigleCtrl;
  final TextEditingController rootUnitCtrl;
  final TextEditingController descriptionCtrl;
  final String structureModel;
  final bool skipLogo;
  final bool skipColors;
  final bool skipContact;
  final bool saving;
  final ValueChanged<String> onStructureChanged;
  final ValueChanged<bool> onSkipLogoChanged;
  final ValueChanged<bool> onSkipColorsChanged;
  final ValueChanged<bool> onSkipContactChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 520;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de l eglise',
                prefixIcon: Icon(Icons.church_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: sigleCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Sigle',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: rootUnitCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _rootUnitLabel(structureModel),
                      prefixIcon: const Icon(Icons.home_work_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descriptionCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Text('Mode de structure', style: AppTextStyles.subtitle),
            const SizedBox(height: 10),
            if (compact)
              _StructureOptionList(
                selected: structureModel,
                enabled: !saving,
                onChanged: onStructureChanged,
              )
            else
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'single',
                    icon: Icon(Icons.church_outlined),
                    label: Text('Unique'),
                  ),
                  ButtonSegment(
                    value: 'two_level',
                    icon: Icon(Icons.account_tree_outlined),
                    label: Text('Simple'),
                  ),
                  ButtonSegment(
                    value: 'multi_level',
                    icon: Icon(Icons.hub_outlined),
                    label: Text('Multi'),
                  ),
                ],
                selected: {structureModel},
                onSelectionChanged: saving
                    ? null
                    : (values) => onStructureChanged(values.first),
              ),
            const SizedBox(height: 18),
            Text(
              'A terminer depuis les parametres',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SkipChip(
                  icon: Icons.image_outlined,
                  label: 'Logo',
                  selected: skipLogo,
                  onSelected: saving ? null : onSkipLogoChanged,
                ),
                _SkipChip(
                  icon: Icons.palette_outlined,
                  label: 'Couleurs',
                  selected: skipColors,
                  onSelected: saving ? null : onSkipColorsChanged,
                ),
                _SkipChip(
                  icon: Icons.contact_mail_outlined,
                  label: 'Contact',
                  selected: skipContact,
                  onSelected: saving ? null : onSkipContactChanged,
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: saving ? null : onSubmit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rocket_launch_outlined),
                label: Text(saving ? 'Creation...' : 'Creer l espace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rootUnitLabel(String value) {
    return switch (value) {
      'two_level' => 'Assemblee de depart',
      'multi_level' => 'Nom du niveau racine',
      _ => 'Nom public',
    };
  }
}

class _StructureOptionList extends StatelessWidget {
  const _StructureOptionList({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StructureOption(
          value: 'single',
          selected: selected == 'single',
          enabled: enabled,
          icon: Icons.church_outlined,
          title: 'Eglise unique',
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _StructureOption(
          value: 'two_level',
          selected: selected == 'two_level',
          enabled: enabled,
          icon: Icons.account_tree_outlined,
          title: 'Siege + assemblee',
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _StructureOption(
          value: 'multi_level',
          selected: selected == 'multi_level',
          enabled: enabled,
          icon: Icons.hub_outlined,
          title: 'Multi-niveaux',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StructureOption extends StatelessWidget {
  const _StructureOption({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.onChanged,
  });

  final String value;
  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: AppRadius.mdAll,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryLight.withValues(alpha: 0.9)
              : AppColors.surfaceElevated,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SkipChip extends StatelessWidget {
  const _SkipChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.church,
        size: size * 0.56,
        color: AppColors.primaryDark,
      ),
    );
  }
}

class _AsideChip extends StatelessWidget {
  const _AsideChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondaryLight, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

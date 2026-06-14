import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/features/organization/application/organization_providers.dart';
import 'package:eab/features/organization/presentation/organization_onboarding_screen.dart';
import 'package:eab/ui/ui.dart';

class OrganizationGate extends ConsumerWidget {
  const OrganizationGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationAsync = ref.watch(currentOrganizationProvider);

    return organizationAsync.when(
      data: (organization) {
        if (organization == null) {
          return const OrganizationOnboardingScreen();
        }
        return child;
      },
      loading: () => const _GateScaffold(
        child: Center(child: SkeletonLoader(lineCount: 5, lineHeight: 22)),
      ),
      error: (error, _) => _GateScaffold(
        child: _GateErrorPanel(
          message: 'Impossible de charger l organisation courante.',
          onRetry: () =>
              ref.read(currentOrganizationProvider.notifier).refresh(),
          onSignOut: () => Supabase.instance.client.auth.signOut(),
        ),
      ),
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GateErrorPanel extends StatelessWidget {
  const _GateErrorPanel({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 34),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Se deconnecter'),
          ),
        ],
      ),
    );
  }
}

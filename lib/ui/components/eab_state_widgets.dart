/// Widgets d'état réutilisables : vide, erreur, chargement squelette.
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// ÉTAT VIDE
// ---------------------------------------------------------------------------

/// Affiche un état vide avec icône, message, et action optionnelle.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[350]),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ÉTAT D'ERREUR
// ---------------------------------------------------------------------------

/// Affiche un état d'erreur avec icône, message, et bouton "Réessayer".
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: colors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.error,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CHARGEMENT SQUELETTE
// ---------------------------------------------------------------------------

/// Placeholder animé pour simuler un chargement (shimmer basique).
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.lineCount = 5,
    this.lineHeight = 16,
  });

  final int lineCount;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lineCount, (i) {
          final widthFactor = i == 0 ? 0.6 : (i % 3 == 0 ? 0.4 : 0.9);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              alignment: Alignment.centerLeft,
              child: Container(
                height: lineHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

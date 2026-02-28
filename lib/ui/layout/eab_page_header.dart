/// En-tête de page standard EAB.
///
/// Remplace les en-têtes ad-hoc dans chaque écran par un composant
/// réutilisable avec titre, sous-titre, et actions.
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// En-tête de page réutilisable avec titre, sous-titre, et actions.
class EabPageHeader extends StatelessWidget {
  const EabPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineSmall),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: AppSpacing.md),
                ...actions!.expand(
                  (a) => [a, const SizedBox(width: AppSpacing.buttonGap)],
                ),
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.md),
            bottom!,
          ],
        ],
      ),
    );
  }
}

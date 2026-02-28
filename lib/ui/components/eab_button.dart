/// Composant bouton standard EAB.
///
/// Remplace les styles ad-hoc (ElevatedButton, TextButton, OutlinedButton)
/// par un composant unique avec variantes.
library;

import 'package:flutter/material.dart';

/// Variantes visuelles du bouton.
enum EabButtonVariant { primary, secondary, outline, danger, ghost }

/// Tailles du bouton.
enum EabButtonSize { small, medium, large }

/// Bouton réutilisable du design system EAB.
class EabButton extends StatelessWidget {
  const EabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = EabButtonVariant.primary,
    this.size = EabButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EabButtonVariant variant;
  final EabButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (bgColor, fgColor, borderColor) = switch (variant) {
      EabButtonVariant.primary => (colors.primary, Colors.white, Colors.transparent),
      EabButtonVariant.secondary => (colors.secondary, colors.onSecondary, Colors.transparent),
      EabButtonVariant.outline => (Colors.transparent, colors.primary, colors.primary),
      EabButtonVariant.danger => (colors.error, Colors.white, Colors.transparent),
      EabButtonVariant.ghost => (Colors.transparent, colors.primary, Colors.transparent),
    };

    final (paddingH, paddingV, fontSize, iconSize) = switch (size) {
      EabButtonSize.small => (12.0, 6.0, 13.0, 16.0),
      EabButtonSize.medium => (16.0, 10.0, 14.0, 18.0),
      EabButtonSize.large => (24.0, 14.0, 16.0, 20.0),
    };

    final effectiveOnPressed = isLoading ? null : onPressed;

    final buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}

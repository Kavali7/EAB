/// Dialog / Bottom sheet standard EAB.
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'eab_button.dart';

/// Dialog modal standard avec titre, contenu scrollable, et actions.
class EabDialog extends StatelessWidget {
  const EabDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.width = 520,
    this.scrollable = true,
  });

  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double width;
  final bool scrollable;

  /// Affiche le dialog de manière standard.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    double width = 520,
    bool scrollable = true,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => EabDialog(
        title: title,
        content: content,
        actions: actions,
        width: width,
        scrollable: scrollable,
      ),
    );
  }

  /// Helper rapide pour un dialog de confirmation.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool isDanger = false,
  }) {
    return show<bool>(
      context,
      title: title,
      content: Text(message),
      scrollable: false,
      actions: [
        EabButton(
          label: cancelLabel,
          variant: EabButtonVariant.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
        EabButton(
          label: confirmLabel,
          variant: isDanger
              ? EabButtonVariant.danger
              : EabButtonVariant.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 640;
    final effectiveWidth = compact ? media.size.width - 24 : width;
    final maxHeight = media.size.height - media.viewInsets.vertical - 32;
    final body = scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.lg : AppSpacing.dialogPadding,
              vertical: AppSpacing.lg,
            ),
            child: content,
          )
        : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.lg : AppSpacing.dialogPadding,
              vertical: AppSpacing.lg,
            ),
            child: content,
          );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.dialogRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: effectiveWidth.clamp(280, width).toDouble(),
          maxHeight: maxHeight.clamp(320, media.size.height).toDouble(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.dialogPadding,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const Divider(),
            // Contenu
            Flexible(child: body),
            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.md : AppSpacing.lg,
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children:
                            actions!
                                .expand(
                                  (action) => [
                                    SizedBox(
                                      width: double.infinity,
                                      child: action,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                )
                                .toList()
                              ..removeLast(),
                      )
                    : Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpacing.buttonGap,
                        runSpacing: AppSpacing.sm,
                        children: actions!,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

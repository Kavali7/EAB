/// Utilitaires responsive pour éviter les overflow sur mobile/tablette.
///
/// Breakpoints :
/// - < 600 : mobile (layout vertical)
/// - 600–1024 : tablet (2 colonnes max)
/// - > 1024 : desktop (Row libre)
library;

import 'package:flutter/material.dart';

/// Breakpoints officiels EAB.
class EabBreakpoints {
  EabBreakpoints._();
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Retourne le type de layout en fonction de la largeur.
enum EabLayoutType { mobile, tablet, desktop }

EabLayoutType layoutTypeOf(double width) {
  if (width < EabBreakpoints.mobile) return EabLayoutType.mobile;
  if (width < EabBreakpoints.tablet) return EabLayoutType.tablet;
  return EabLayoutType.desktop;
}

/// Widget responsive : affiche [mobile], [tablet] ou [desktop]
/// selon la largeur disponible.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = layoutTypeOf(constraints.maxWidth);
        switch (type) {
          case EabLayoutType.mobile:
            return mobile;
          case EabLayoutType.tablet:
            return tablet ?? desktop;
          case EabLayoutType.desktop:
            return desktop;
        }
      },
    );
  }
}

/// Row responsive pour les formulaires.
///
/// Sur desktop : affiche les enfants en Row (horizontal).
/// Sur mobile : affiche les enfants en Column (vertical).
/// Sur tablette : affiche 2 par ligne.
///
/// Chaque enfant est wrap dans un Expanded (desktop) ou full-width (mobile).
class ResponsiveFormRow extends StatelessWidget {
  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = layoutTypeOf(constraints.maxWidth);

        if (type == EabLayoutType.mobile) {
          // Tout en colonne
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        if (type == EabLayoutType.tablet) {
          // 2 par ligne
          final rows = <Widget>[];
          for (int i = 0; i < children.length; i += 2) {
            final hasSecond = i + 1 < children.length;
            rows.add(Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: children[i]),
                if (hasSecond) SizedBox(width: spacing),
                if (hasSecond)
                  Expanded(child: children[i + 1])
                else
                  const Expanded(child: SizedBox()),
              ],
            ));
            if (i + 2 < children.length) rows.add(SizedBox(height: runSpacing));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );
        }

        // Desktop — tout en Row
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

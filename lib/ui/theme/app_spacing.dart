/// Spacing constants utilisés dans toute l'application.
///
/// Tous les paddings, margins et gaps doivent utiliser ces constantes
/// au lieu de valeurs en dur pour garantir la cohérence visuelle.
library;

/// Constantes d'espacement pour la mise en page.
abstract final class AppSpacing {
  // Micro
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Page padding
  static const double pagePadding = 24;
  static const double pageHorizontal = 24;
  static const double pageVertical = 20;

  // Intercomposants
  static const double cardGap = 16;
  static const double sectionGap = 32;
  static const double fieldGap = 12;
  static const double buttonGap = 8;

  // Card
  static const double cardPadding = 16;
  static const double cardRadius = 12;

  // Input
  static const double inputRadius = 8;
  static const double inputPaddingH = 14;
  static const double inputPaddingV = 12;

  // Dialog / Sheet
  static const double dialogPadding = 24;
  static const double dialogRadius = 16;
}

/// Default product identity used before a church-specific brand is loaded.
library;

class ProductBranding {
  const ProductBranding._();

  static const appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Gestion Eglise',
  );

  static const appShortName = String.fromEnvironment(
    'APP_SHORT_NAME',
    defaultValue: 'GE',
  );

  static const appDescription =
      'Gestion d\'eglise, comptabilite et suivi administratif dans un seul espace.';
}

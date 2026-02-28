/// Utilitaires centralisés de conversion snake_case ↔ camelCase.
///
/// Utilisé par [SupabaseDataService] et les providers comptables pour
/// convertir les clés et valeurs entre PostgreSQL (snake_case) et Dart
/// (camelCase).
///
/// **Convention** :
/// - [snakeToCamel] / [camelToSnake] convertissent les **clés** JSON.
/// - [snakeValueToCamel] convertit une **valeur** enum snake_case.
/// - Les champs renommés (ex: fullName→nom, date_naissance→birthDate)
///   doivent être mappés manuellement dans chaque méthode get*().
library;

// ---------------------------------------------------------------------------
// CONVERSION DES CLÉS
// ---------------------------------------------------------------------------

/// Convertit les clés d'un [Map] de snake_case vers camelCase (récursif).
Map<String, dynamic> snakeToCamel(Map<String, dynamic> json) {
  return json.map((key, value) {
    final newKey = _snakeToCamelString(key);
    if (value is Map<String, dynamic>) {
      return MapEntry(newKey, snakeToCamel(value));
    } else if (value is List) {
      return MapEntry(
        newKey,
        value
            .map((e) => e is Map<String, dynamic> ? snakeToCamel(e) : e)
            .toList(),
      );
    }
    return MapEntry(newKey, value);
  });
}

/// Convertit les clés d'un [Map] de camelCase vers snake_case (récursif).
Map<String, dynamic> camelToSnake(Map<String, dynamic> json) {
  return json.map((key, value) {
    final newKey = _camelToSnakeString(key);
    if (value is Map<String, dynamic>) {
      return MapEntry(newKey, camelToSnake(value));
    } else if (value is List) {
      return MapEntry(
        newKey,
        value
            .map((e) => e is Map<String, dynamic> ? camelToSnake(e) : e)
            .toList(),
      );
    }
    return MapEntry(newKey, value);
  });
}

// ---------------------------------------------------------------------------
// CONVERSION DES VALEURS ENUM
// ---------------------------------------------------------------------------

/// Convertit une valeur enum snake_case vers camelCase.
///
/// Ex: `'evangelisation_masse'` → `'evangelisationMasse'`
///     `'admin_national'` → `'adminNational'`
String snakeValueToCamel(String input) {
  final parts = input.split('_');
  if (parts.length == 1) return input;
  return parts.first +
      parts.skip(1).map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1);
      }).join();
}

/// Mappe les valeurs françaises de `statut_matrimonial` vers les enums
/// anglais du modèle [Member] (`MaritalStatus: single, married, divorced,
/// widowed`).
String mapStatutMatrimonialToEnglish(String? statut) {
  switch (statut) {
    case 'celibataire':
      return 'single';
    case 'marie':
      return 'married';
    case 'divorce':
    case 'separe':
      return 'divorced';
    case 'veuf':
    case 'veuve':
      return 'widowed';
    default:
      return 'single';
  }
}

// ---------------------------------------------------------------------------
// HELPERS INTERNES
// ---------------------------------------------------------------------------

/// Convertit une chaîne snake_case vers camelCase.
String _snakeToCamelString(String input) {
  final parts = input.split('_');
  if (parts.length == 1) return input;
  return parts.first +
      parts.skip(1).map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1);
      }).join();
}

/// Convertit une chaîne camelCase vers snake_case.
String _camelToSnakeString(String input) {
  return input.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

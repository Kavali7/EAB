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
  // Noms de champs dont la valeur est un enum DB en snake_case
  const _enumFields = {
    'type', 'statut', 'nature', 'role', 'mode_paiement', 'modePaiement',
    'portee', 'statut_fidele', 'statutFidele', 'type_centre', 'typeCentre',
    'type_tiers', 'typeTiers', 'statut_exercice', 'statutExercice',
    'gender', 'marital_status', 'maritalStatus',
  };

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
    } else if (value is String &&
        value.contains('_') &&
        _enumFields.contains(key)) {
      // Convertir les valeurs enum snake_case du DB vers camelCase
      return MapEntry(newKey, _snakeToCamelString(value));
    }
    return MapEntry(newKey, value);
  });
}

/// Convertit les clés d'un [Map] de camelCase vers snake_case (récursif).
Map<String, dynamic> camelToSnake(Map<String, dynamic> json) {
  // Noms de champs (en camelCase) dont la valeur est un enum à convertir
  const _enumFields = {
    'type', 'statut', 'nature', 'role', 'modePaiement',
    'portee', 'statutFidele', 'typeCentre',
    'typeTiers', 'statutExercice', 'typeVisite',
    'gender', 'maritalStatus', 'statutMatrimonial',
  };

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
    } else if (value is String &&
        _enumFields.contains(key) &&
        RegExp(r'[A-Z]').hasMatch(value)) {
      // Convertir les valeurs enum camelCase → snake_case pour le DB
      return MapEntry(newKey, _camelToSnakeString(value));
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

/// Version publique de [_camelToSnakeString] pour les valeurs enum.
///
/// Ex: `'autreOfficier'` → `'autre_officier'`
///     `'troisiemeAge'` → `'troisieme_age'`
String camelValueToSnake(String input) => _camelToSnakeString(input);

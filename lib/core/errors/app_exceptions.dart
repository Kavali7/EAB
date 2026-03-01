/// Classes d'exception applicatives avec messages utilisateur lisibles.
///
/// Remplace les catch génériques `$e` par des messages clairs
/// pour les trésoriers non-techniques.
library;

/// Base des exceptions applicatives EAB.
sealed class AppException implements Exception {
  const AppException(this.userMessage, {this.technicalDetail});

  /// Message affiché à l'utilisateur (français, clair).
  final String userMessage;

  /// Détail technique (loggé, pas affiché).
  final String? technicalDetail;

  @override
  String toString() => userMessage;
}

/// Erreur de permission / autorisation.
class PermissionException extends AppException {
  const PermissionException([
    super.userMessage = 'Vous n\'avez pas les droits nécessaires.',
    String? detail,
  ]) : super(technicalDetail: detail);
}

/// Erreur métier (ex: exercice déjà ouvert, écriture non équilibrée).
class BusinessRuleException extends AppException {
  const BusinessRuleException(super.userMessage, {super.technicalDetail});
}

/// Erreur réseau / connexion.
class NetworkException extends AppException {
  const NetworkException([
    super.userMessage = 'Connexion au serveur impossible. Vérifiez votre connexion internet.',
    String? detail,
  ]) : super(technicalDetail: detail);
}

/// Erreur de données (parsing, format inattendu).
class DataException extends AppException {
  const DataException([
    super.userMessage = 'Erreur lors du traitement des données.',
    String? detail,
  ]) : super(technicalDetail: detail);
}

/// Erreur inconnue / non gérée.
class UnknownException extends AppException {
  const UnknownException([
    super.userMessage = 'Une erreur inattendue s\'est produite. Réessayez.',
    String? detail,
  ]) : super(technicalDetail: detail);
}

/// Convertit une exception Supabase/générique en AppException lisible.
AppException toAppException(Object error) {
  // Si c'est déjà une AppException, la retourner directement
  if (error is AppException) return error;

  final msg = error.toString().toLowerCase();

  // Erreurs réseau
  if (msg.contains('socketexception') ||
      msg.contains('connection refused') ||
      msg.contains('network') ||
      msg.contains('timeout')) {
    return NetworkException(
      'Connexion au serveur impossible. Vérifiez votre connexion internet.',
      error.toString(),
    );
  }

  // Erreurs RLS / permission Supabase
  if (msg.contains('rls') ||
      msg.contains('permission denied') ||
      msg.contains('policy') ||
      msg.contains('row-level security')) {
    return PermissionException(
      'Vous n\'avez pas les droits pour effectuer cette action.',
      error.toString(),
    );
  }

  // Contrainte UNIQUE (avant les mots-clés métier)
  if (msg.contains('duplicate key') || msg.contains('unique constraint')) {
    return const BusinessRuleException(
      'Cet enregistrement existe déjà (doublon).',
    );
  }

  // Contrainte CHECK (avant les mots-clés métier)
  if (msg.contains('check constraint') || msg.contains('violates check')) {
    return const BusinessRuleException(
      'Les données saisies ne respectent pas les règles de validation.',
    );
  }

  // FK violée (avant les mots-clés métier)
  if (msg.contains('foreign key') || msg.contains('violates foreign')) {
    return const BusinessRuleException(
      'Impossible de supprimer : cet élément est utilisé ailleurs.',
    );
  }

  // Erreurs métier Supabase (RAISE EXCEPTION dans les RPCs)
  if (msg.contains('administrateur national') ||
      msg.contains('exercice') ||
      msg.contains('brouillon') ||
      msg.contains('clôturé') ||
      msg.contains('equilibre') ||
      msg.contains('journal') ||
      msg.contains('compte de résultat')) {
    // Extraire le message de l'exception PostgreSQL
    final pgMsg = _extractPgMessage(error.toString());
    return BusinessRuleException(pgMsg ?? error.toString());
  }

  // Fallback
  return UnknownException(
    'Une erreur inattendue s\'est produite. Réessayez.',
    error.toString(),
  );
}

/// Tente d'extraire le message d'une exception PG/Supabase.
String? _extractPgMessage(String raw) {
  // Le format Supabase est souvent : "PostgrestException(message: '...', ...)"
  // On utilise .* (greedy) pour gérer les apostrophes français (l', d', s', etc.)
  final match = RegExp(r"message:\s*'(.+?)'(?:\s*[,)]|$)").firstMatch(raw);
  if (match != null) return match.group(1);
  // Fallback : chercher le contenu entre guillemets simples
  final fallback = RegExp(r"'(.{10,})'").firstMatch(raw);
  return fallback?.group(1);
}

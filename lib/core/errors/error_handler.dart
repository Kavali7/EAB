/// Extension SnackBar pour afficher les erreurs applicatives.
///
/// Usage dans un screen :
/// ```dart
/// try { ... } catch (e) { context.showError(e); }
/// // Avec bouton Réessayer :
/// try { ... } catch (e) { context.showError(e, onRetry: () => _load()); }
/// ```
library;

import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Extension pour afficher une erreur lisible dans un SnackBar.
extension ErrorSnackBar on BuildContext {
  /// Affiche un SnackBar d'erreur avec message utilisateur.
  ///
  /// Si [onRetry] est fourni, un bouton « Réessayer » est affiché.
  void showError(Object error, {VoidCallback? onRetry}) {
    final appError = error is AppException ? error : toAppException(error);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _iconForException(appError),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                appError.userMessage,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _colorForException(appError),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: onRetry != null ? 8 : 5),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white70,
                onPressed: () {},
              ),
      ),
    );
  }

  /// Affiche un SnackBar de succès.
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Affiche un SnackBar d'avertissement (jaune/orange).
  void showWarning(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Icône selon le type d'exception.
  IconData _iconForException(AppException e) => switch (e) {
        PermissionException() => Icons.lock_outline,
        NetworkException() => Icons.wifi_off,
        BusinessRuleException() => Icons.warning_amber_rounded,
        DataException() => Icons.storage_outlined,
        _ => Icons.error_outline,
      };

  /// Couleur selon le type d'exception.
  Color _colorForException(AppException e) => switch (e) {
        PermissionException() => Colors.deepPurple,
        NetworkException() => Colors.blueGrey.shade700,
        BusinessRuleException() => Colors.orange.shade800,
        DataException() => Colors.brown.shade700,
        _ => Colors.red.shade700,
      };
}

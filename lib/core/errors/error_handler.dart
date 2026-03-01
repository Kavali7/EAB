/// Extension SnackBar pour afficher les erreurs applicatives.
///
/// Usage dans un screen :
/// ```dart
/// try { ... } catch (e) { context.showError(e); }
/// ```
library;

import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Extension pour afficher une erreur lisible dans un SnackBar.
extension ErrorSnackBar on BuildContext {
  /// Affiche un SnackBar d'erreur avec message utilisateur.
  void showError(Object error) {
    final appError = error is AppException ? error : toAppException(error);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appError.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

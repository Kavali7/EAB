import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher un état d'erreur avec bouton Réessayer.
///
/// Utilisé sur tous les écrans qui chargent des données async.
/// Utilise [ListView] pour éviter le bottom overflow
/// quand le message d'erreur est long.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// Message d'erreur à afficher (inclure le vrai message d'exception).
  final String message;

  /// Callback de réessai (invalide les providers concernés).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24.0),
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ),
        ],
      ],
    );
  }
}

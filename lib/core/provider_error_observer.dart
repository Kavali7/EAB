import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Observer global qui logge tout provider passant en état d'erreur.
///
/// Ajouté au [ProviderScope] dans `main.dart` pour capturer
/// automatiquement les échecs de chargement de données.
base class ProviderErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    dev.log(
      '❌ PROVIDER ERREUR [${context.provider.name ?? context.provider.runtimeType}]: $error',
      error: error,
      stackTrace: stackTrace,
      name: 'ProviderErrorObserver',
    );
  }
}

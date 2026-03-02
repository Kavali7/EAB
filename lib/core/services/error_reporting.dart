/// Service d'observabilité (error reporting + logging).
///
/// Intégré avec Sentry + log console structuré.
/// - Capture des erreurs non gérées (Flutter + Zone)
/// - Métriques de performance RPC
/// - Breadcrumbs pour le contexte
library;

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Configuration du reporting d'erreurs.
class ErrorReporting {
  static bool _initialized = false;

  /// Initialise le système de reporting (à appeler dans main()).
  static void init() {
    if (_initialized) return;
    _initialized = true;

    // Capture les erreurs Flutter (widgets)
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      captureException(details.exception, stackTrace: details.stack);
    };

    // Erreurs non gérées (Zone)
    PlatformDispatcher.instance.onError = (error, stack) {
      captureException(error, stackTrace: stack);
      return true;
    };

    dev.log('🔍 ErrorReporting initialisé (mode ${kReleaseMode ? "PROD" : "DEV"})');
  }

  /// Capture une exception avec contexte optionnel.
  static void captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, String>? context,
  }) {
    // Envoyer vers Sentry
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: context != null
          ? (scope) {
              for (final entry in context.entries) {
                scope.setTag(entry.key, entry.value);
              }
            }
          : null,
    );

    // Log console structuré
    final ctx = context?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
    dev.log(
      '❌ ERROR: $exception${ctx.isNotEmpty ? " [$ctx]" : ""}',
      error: exception,
      stackTrace: stackTrace,
      name: 'ErrorReporting',
    );
  }

  /// Log un message avec niveau.
  static void log(
    String message, {
    String level = 'info',
    Map<String, String>? tags,
  }) {
    // Ajouter un breadcrumb Sentry
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      level: switch (level) {
        'warning' => SentryLevel.warning,
        'error' => SentryLevel.error,
        'debug' => SentryLevel.debug,
        _ => SentryLevel.info,
      },
      category: tags?['component'] ?? 'app',
      data: tags,
    ));

    final prefix = switch (level) {
      'warning' => '⚠️',
      'error' => '❌',
      'debug' => '🔧',
      _ => 'ℹ️',
    };

    dev.log(
      '$prefix $message',
      name: tags?['component'] ?? 'App',
    );
  }

  /// Identifie l'utilisateur courant pour Sentry.
  static void setUser({required String id, String? email, String? orgId}) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
      ));
      if (orgId != null) {
        scope.setTag('org_id', orgId);
      }
    });
  }

  /// Supprime l'utilisateur (déconnexion).
  static void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }
}

/// Wrapper pour mesurer les temps d'exécution RPC.
class RpcTimer {
  RpcTimer(this.rpcName) {
    _transaction = Sentry.startTransaction(
      'rpc.$rpcName',
      'rpc',
      bindToScope: true,
    );
  }
  final String rpcName;
  final _stopwatch = Stopwatch()..start();
  late final ISentrySpan _transaction;

  /// Stoppe le chrono et log la durée.
  Duration stop({String? orgId}) {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;

    // Terminer la transaction Sentry
    _transaction.status = duration.inSeconds >= 3
        ? const SpanStatus.deadlineExceeded()
        : const SpanStatus.ok();
    _transaction.finish();

    final tags = <String, String>{
      'rpc': rpcName,
      'duration_ms': duration.inMilliseconds.toString(),
    };
    if (orgId != null) tags['org_id'] = orgId;

    ErrorReporting.log(
      'RPC $rpcName → ${duration.inMilliseconds}ms',
      tags: tags,
    );

    // Alerter si > 3s
    if (duration.inSeconds >= 3) {
      ErrorReporting.log(
        'RPC LENTE: $rpcName a pris ${duration.inMilliseconds}ms',
        level: 'warning',
        tags: tags,
      );
    }

    return duration;
  }
}

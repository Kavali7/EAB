/// Service d'observabilité (error reporting + logging).
///
/// Wrapper prêt pour Sentry. En attendant activation :
/// - Log console structuré avec org_id, user_id, rpc_name, duration
/// - Capture des erreurs non gérées
/// - Métriques de performance RPC
library;

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Configuration du reporting d'erreurs.
class ErrorReporting {
  static bool _initialized = false;

  /// Initialise le système de reporting (à appeler dans main()).
  static Future<void> init({String? dsn}) async {
    if (_initialized) return;
    _initialized = true;

    // TODO(prod): Activer Sentry quand le DSN est disponible :
    // await SentryFlutter.init(
    //   (options) {
    //     options.dsn = dsn;
    //     options.tracesSampleRate = 0.2;
    //     options.environment = kReleaseMode ? 'production' : 'development';
    //   },
    //   appRunner: () => runApp(const ProviderScope(child: ChurchApp())),
    // );

    // En attendant : capture les erreurs Flutter
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
    // TODO(prod): Sentry.captureException(exception, stackTrace: stackTrace);

    // Log structuré
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
    // TODO(prod): Sentry.addBreadcrumb(Breadcrumb(message: message, ...));

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
}

/// Wrapper pour mesurer les temps d'exécution RPC.
class RpcTimer {
  RpcTimer(this.rpcName);
  final String rpcName;
  final _stopwatch = Stopwatch()..start();

  /// Stoppe le chrono et log la durée.
  Duration stop({String? orgId}) {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;

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

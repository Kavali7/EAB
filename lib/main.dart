import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/error_reporting.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: SupabaseConfig.debugMode,
  );

  // Initialiser Sentry + ErrorReporting
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '', // Vide = Sentry désactivé (dev local)
      );
      options.tracesSampleRate = 0.2;
      options.environment =
          const bool.fromEnvironment('dart.vm.product')
              ? 'production'
              : 'development';
      options.sendDefaultPii = false; // RGPD
      options.attachStacktrace = true;
    },
    appRunner: () {
      // Initialiser notre wrapper ErrorReporting
      ErrorReporting.init();

      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: const ProviderScope(child: ChurchApp()),
        ),
      );
    },
  );
}

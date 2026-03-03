import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/error_reporting.dart';

Future<void> main() async {
  // Sentry crée sa propre zone — il faut tout initialiser DEDANS
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue:
            'https://dc084a943cf1a5e5398c267bca007f83@o4510972141174784.ingest.de.sentry.io/4510972535177296',
      );
      options.tracesSampleRate = 0.2;
      options.environment =
          const bool.fromEnvironment('dart.vm.product')
              ? 'production'
              : 'development';
      options.sendDefaultPii = false; // RGPD
      options.attachStacktrace = true;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialiser Supabase
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: SupabaseConfig.debugMode,
      );

      // Initialiser notre wrapper ErrorReporting
      ErrorReporting.init();

      // Initialiser les données de locale pour intl (fr_FR)
      await initializeDateFormatting('fr_FR');

      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: const ProviderScope(child: ChurchApp()),
        ),
      );
    },
  );
}

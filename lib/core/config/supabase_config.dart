/// Configuration Supabase pour le projet EAB.
class SupabaseConfig {
  /// URL du projet Supabase.
  ///
  /// Peut etre surchargee au build avec:
  /// `--dart-define=SUPABASE_URL=https://votre-projet.supabase.co`
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ddyhwihcnmzqejjtwrbl.supabase.co',
  );

  /// Cle anonyme (anon key) pour l'acces public.
  ///
  /// Peut etre surchargee au build avec:
  /// `--dart-define=SUPABASE_ANON_KEY=...`
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWh3aWhjbm16cWVqanR3cmJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3ODIyOTAsImV4cCI6MjA4NzM1ODI5MH0.a6n7jdtadisoPky0XvywuDEUxo8-v-BzP4u4rv6pvcw',
  );

  /// Duree de timeout pour les requetes (en secondes).
  static const int requestTimeout = 30;

  /// Activer le mode debug (logs detailles).
  static const bool debugMode = true;

  /// Service de conversion Excel -> PDF pour les dossiers fiscaux officiels.
  ///
  /// A fournir au build avec :
  /// `--dart-define=FISCAL_PDF_CONVERTER_URL=https://votre-service`
  static const String fiscalPdfConverterUrl = String.fromEnvironment(
    'FISCAL_PDF_CONVERTER_URL',
    defaultValue: '',
  );
}

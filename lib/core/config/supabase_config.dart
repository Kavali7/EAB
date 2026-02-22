/// Configuration Supabase pour le projet EAB
class SupabaseConfig {
  /// URL du projet Supabase
  static const String supabaseUrl = 'https://ddyhwihcnmzqejjtwrbl.supabase.co';

  /// Clé anonyme (anon key) pour l'accès public
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWh3aWhjbm16cWVqanR3cmJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3ODIyOTAsImV4cCI6MjA4NzM1ODI5MH0.a6n7jdtadisoPky0XvywuDEUxo8-v-BzP4u4rv6pvcw';

  /// Durée de timeout pour les requêtes (en secondes)
  static const int requestTimeout = 30;

  /// Activer le mode debug (logs détaillés)
  static const bool debugMode = true;
}

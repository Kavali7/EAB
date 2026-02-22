# Guide d'installation - EAB

## 📋 Prérequis

### Développement
- **Flutter SDK** : Version 3.9.0 ou supérieure
- **Dart SDK** : Version 3.0.0 ou supérieure
- **Git** : Pour la gestion de version
- **IDE** : VS Code ou Android Studio (avec plugins Flutter/Dart)

### Backend
- **Compte Supabase** : [https://supabase.com](https://supabase.com)
- Projet Supabase créé

---

## 🚀 Installation

### 1. Cloner le projet

```bash
git clone <url-du-repository>
cd eab
```

### 2. Installer les dépendances Flutter

```bash
flutter pub get
```

### 3. Générer les fichiers Freezed

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## ⚙️ Configuration Supabase

### 1. Créer un projet Supabase

1. Connectez-vous à [supabase.com](https://supabase.com)
2. Cliquez sur "New Project"
3. Renseignez le nom : `eab`
4. Choisissez une région proche
5. Définissez un mot de passe pour la base de données
6. Attendez la création du projet

### 2. Récupérer les clés API

1. Dans le dashboard Supabase, allez dans **Settings** > **API**
2. Notez :
   - **Project URL** : `https://xxxxx.supabase.co`
   - **anon public key** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. Appliquer les migrations

#### Option A : Via le SQL Editor (recommandé pour débuter)

1. Dans Supabase, allez dans **SQL Editor**
2. Exécutez les fichiers dans l'ordre :
   - `supabase/migrations/00001_initial_schema.sql`
   - `supabase/migrations/00002_accounting_schema.sql`
   - `supabase/migrations/00003_rls_policies.sql`
   - `supabase/migrations/00004_functions_triggers.sql`
   - `supabase/migrations/00005_indexes.sql`
   - `supabase/migrations/00006_storage_buckets.sql`
   - `supabase/migrations/00007_improvements.sql`

3. Pour les données de démo :
   - `supabase/seed.sql`

#### Option B : Via Supabase CLI

```bash
# Installer Supabase CLI
npm install -g supabase

# Lier au projet
supabase link --project-ref <votre-project-ref>

# Appliquer les migrations
supabase db push
```

### 4. Créer les buckets Storage

Dans Supabase, allez dans **Storage** et créez :

1. **member-photos** (privé)
   - Pour les photos des membres

2. **documents** (privé)
   - Pour les pièces justificatives comptables

3. **organization-assets** (public)
   - Pour les logos et ressources publiques

### 5. Configurer l'authentification

Dans **Authentication** > **Providers** :

1. **Email** : Activé par défaut
   - Activer "Confirm email"

2. **Google** (optionnel) :
   - Créer des credentials dans Google Cloud Console
   - Renseigner Client ID et Client Secret

---

## 🔧 Configuration Flutter

### 1. Créer le fichier de configuration

Créez ou modifiez `lib/core/config/supabase_config.dart` :

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://votre-projet.supabase.co';
  static const String supabaseAnonKey = 'votre-anon-key';
}
```

### 2. Modifier le provider

Dans `lib/providers/data_service_provider.dart`, changez :

```dart
final dataServiceProvider = Provider<DataService>((ref) {
  // Utiliser Supabase au lieu de InMemory
  return SupabaseDataService();
});
```

---

## 🧪 Vérification

### Tester la connexion

```bash
flutter run -d chrome
```

### Tests unitaires

```bash
flutter test
```

### Analyse du code

```bash
flutter analyze
```

---

## 🔒 Sécurité

### En production

1. **Ne jamais exposer** les clés dans le code source public
2. Utiliser des **variables d'environnement**
3. Activer le **HTTPS** obligatoire
4. Configurer les **domaines autorisés** dans Supabase

### Variables d'environnement (production)

```bash
# .env (ne pas commiter !)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
```

---

## ❓ Dépannage

### Erreur "relation does not exist"
→ Les migrations n'ont pas été appliquées. Exécutez-les dans l'ordre.

### Erreur "permission denied"
→ Les politiques RLS bloquent l'accès. Vérifiez que l'utilisateur a un profil dans la table `profiles`.

### Erreur "Invalid JWT"
→ La clé anon est incorrecte. Vérifiez dans Supabase > Settings > API.

---

## 📞 Support

Pour toute question technique, consultez :
- [Documentation Flutter](https://docs.flutter.dev)
- [Documentation Supabase](https://supabase.com/docs)

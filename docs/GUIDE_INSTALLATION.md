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
   - `supabase/migrations/00008_exercices_v2.sql`
   - `supabase/migrations/00009_fix_handle_new_user.sql`
   - `supabase/migrations/00010_patch_post_revue.sql`
   - `supabase/migrations/00011_dashboard_finance.sql`
   - `supabase/migrations/00012_fiscal_tables.sql`
   - `supabase/migrations/00013_fiscal_rls.sql`
   - `supabase/migrations/00014_fiscal_rpcs.sql`
   - `supabase/migrations/00015_fiscal_import_balance.sql`
   - `supabase/migrations/00016_seed_syscebnl_template_v1.sql`
   - `supabase/migrations/00017_fix_user_id_rpcs.sql`
   - `supabase/migrations/00018_organization_branding.sql`
   - `supabase/migrations/00019_flexible_church_units.sql`
   - `supabase/migrations/00020_members_church_units.sql`
   - `supabase/migrations/00021_programs_church_units.sql`
   - `supabase/migrations/00022_monthly_reports_church_units.sql`
   - `supabase/migrations/00023_accounting_church_units.sql`
   - `supabase/migrations/00024_user_invitations.sql`
   - `supabase/migrations/00025_fix_user_invitation_legacy_scope.sql`
   - `supabase/migrations/00026_organization_onboarding.sql`
   - `supabase/migrations/00027_onboarding_completion_and_eab_demo.sql`
   - `supabase/migrations/00028_ensure_storage_buckets.sql`
   - `supabase/migrations/00029_church_unit_capabilities_financial_accounts.sql`
   - `supabase/migrations/00030_operational_financial_movements.sql`
   - `supabase/migrations/00031_hierarchical_permission_matrix.sql`
   - `supabase/migrations/00032_apply_hierarchy_permissions_members_programs.sql`
   - `supabase/migrations/00033_apply_hierarchy_permissions_finance_reports.sql`
   - `supabase/migrations/00034_apply_hierarchy_permissions_accounting_scopes.sql`
   - `supabase/migrations/00035_apply_hierarchy_permissions_fiscal_statements.sql`

   Les migrations `00018` a `00035` rendent l'application personnalisable par organisation, ajoutent la hierarchie flexible, rattachent progressivement les membres/familles/programmes/rapports mensuels/comptabilite operationnelle/dossiers fiscaux a `church_units`, activent les invitations de sous-comptes par organisation, ajoutent l'onboarding de creation d'une eglise autonome, permettent de finaliser les etapes ignorees depuis les parametres, creent les buckets Storage indispensables, ajoutent les capacites et moyens financiers configurables par unite, structurent les cotisations, promesses et mouvements financiers operationnels, ajoutent la matrice d'autorisations hierarchiques, puis l'appliquent aux membres/familles/programmes, finances operationnelles, rapports mensuels, perimetres comptables, dossiers fiscaux, imports de balance, rapports financiers et exports. Les donnees EAB existantes sont conservees comme compte de demonstration si `supabase/seed.sql` est execute.

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

### 4. Vérifier les buckets Storage

La migration `00028_ensure_storage_buckets.sql` cree automatiquement :

1. **member-photos** (privé)
   - Pour les photos des membres

2. **documents** (privé)
   - Pour les pièces justificatives comptables

3. **organization-assets** (public)
   - Pour les logos et ressources publiques

Si vous n'avez pas encore applique `00028`, creez ces buckets manuellement dans Supabase Storage avant de tester l'import de logo.

### 5. Configurer l'authentification

Dans **Authentication** > **Providers** :

1. **Email** : Activé par défaut
   - Activer "Confirm email"
   - En production, configurer un SMTP personnalise dans Supabase. Le service email integre est tres limite et peut retourner `email rate limit exceeded` pendant les inscriptions ou confirmations.
   - Ajuster ensuite **Authentication > Rate Limits** selon le volume attendu, notamment l'envoi d'emails.

2. **Google** (optionnel) :
   - Créer des credentials dans Google Cloud Console
   - Renseigner Client ID et Client Secret

### 6. Configurer le convertisseur PDF fiscal officiel

L'export PDF fiscal officiel ne doit pas etre un PDF reconstruit par l'application.
Il doit etre genere depuis le fichier Excel SYSCEBNL final afin de conserver les
feuilles, formules, zones d'impression et mises en page du dossier depose aux
impots.

Un service deployable est fourni ici :

`server/fiscal-pdf-converter`

Il utilise LibreOffice en mode headless. En production, deployez-le derriere HTTPS,
avec verification du token Supabase activee :

```bash
docker build -t eab-fiscal-pdf-converter server/fiscal-pdf-converter
docker run --rm -p 8088:8080 \
  -e ALLOWED_ORIGINS=https://votre-domaine-app \
  -e SUPABASE_URL=https://votre-projet.supabase.co \
  -e SUPABASE_ANON_KEY=votre-anon-key \
  eab-fiscal-pdf-converter
```

Puis compiler le frontend avec l'URL publique du service :

```bash
flutter build web --release \
  --dart-define=FISCAL_PDF_CONVERTER_URL=https://votre-convertisseur-pdf
```

Si `FISCAL_PDF_CONVERTER_URL` est absent, le bouton PDF affiche une erreur claire
et refuse l'export officiel. C'est voulu : cela evite de remettre en circulation
un PDF approximatif qui ne correspondrait pas exactement au classeur fiscal Excel.

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

### Tests SQL backend

Apres application des migrations, executer dans Supabase SQL Editor :

- `supabase/tests/test_user_invitations.sql`
- `supabase/tests/test_organization_onboarding.sql`
- `supabase/tests/test_operational_financial_movements.sql`
- `supabase/tests/test_hierarchical_permission_matrix.sql`
- `supabase/tests/test_hierarchy_permissions_members_programs.sql`
- `supabase/tests/test_hierarchy_permissions_finance_reports.sql`
- `supabase/tests/test_hierarchy_permissions_accounting_scopes.sql`
- `supabase/tests/test_hierarchy_permissions_fiscal_statements.sql`

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

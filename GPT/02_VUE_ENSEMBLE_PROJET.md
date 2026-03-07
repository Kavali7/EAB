# 📘 VUE D'ENSEMBLE DU PROJET EAB

## 1. Présentation

**EAB (Église–Administration–Budget)** est une application SaaS multi-tenant pour la gestion complète des églises évangéliques. Elle couvre :

- La gestion des fidèles/membres
- La structure ecclésiastique hiérarchique
- La comptabilité conforme SYCEBNL
- Les programmes et activités
- Les rapports mensuels et financiers
- La gestion budgétaire et des immobilisations

### Vision

Créer un produit **multi-églises** : pas uniquement EAB, mais utilisable par **n'importe quelle dénomination évangélique**. Chaque église a :

- Son propre logo et identité visuelle
- Sa propre organisation (régions, districts, assemblées)
- Ses propres membres, programmes, comptes
- Ses propres utilisateurs avec rôles spécifiques

## 2. Stack technique

| Composant | Technologie | Version |
| --- | --- | --- |
| **Frontend** | Flutter Web | SDK ^3.9.2 |
| **Backend** | Supabase (PostgreSQL) | supabase_flutter ^2.8.0 |
| **State Management** | Riverpod | flutter_riverpod ^3.0.3 |
| **Modèles de données** | Freezed + json_serializable | freezed ^3.2.3 |
| **Graphiques** | fl_chart | ^1.1.1 |
| **Responsive** | responsive_framework | ^1.5.1 |
| **Identifiants** | uuid | ^4.5.2 |
| **Formatage** | intl | ^0.20.2 |

**Plateforme cible** : Web (desktop et tablette principalement), potentiellement mobile plus tard.

## 3. Architecture de l'application

### Pattern architectural

```
lib/
├── main.dart                    # Point d'entrée (Supabase.initialize)
├── app/                         # Point d'entrée MaterialApp
│   └── app.dart                 # MaterialApp + Routes + Theme
├── core/
│   ├── config/
│   │   └── supabase_config.dart # URL + anon key
│   ├── services/
│   │   ├── data_service.dart         # Interface abstraite (contrat)
│   │   ├── in_memory_data_service.dart # Mock data (87KB, dev)
│   │   ├── supabase_data_service.dart  # Impl Supabase réelle
│   │   └── supabase_service.dart       # Client singleton
│   ├── utils/
│   │   └── case_converters.dart  # Helpers snake_case ↔ camelCase centralisés
│   ├── theme.dart              # AppColors, AppTextStyles, buildAppTheme()
│   └── constants.dart          # Enums, labels, formatters, catégories
├── models/                     # 18 modèles Freezed (x3 fichiers chacun)
│   ├── member.dart + .freezed.dart + .g.dart
│   ├── ecriture_comptable.dart + ...
│   ├── compte_comptable.dart + ...
│   └── ... (18 entités total)
├── providers/                  # 9 fichiers Riverpod
│   ├── data_service_provider.dart
│   ├── members_provider.dart
│   ├── programs_provider.dart
│   ├── accounting_providers.dart (19KB — le plus gros)
│   ├── church_structure_providers.dart
│   ├── user_profile_providers.dart
│   ├── families_provider.dart
│   └── rapport_mensuel_eab_providers.dart (11KB)
├── screens/                    # 7 modules d'écrans (existants, migration progressive)
│   ├── auth/         (3 écrans : login, signup, forgot password)
│   ├── dashboard/    (1 écran : tableau de bord)
│   ├── members/      (1 écran : gestion des fidèles)
│   ├── programs/     (1 écran : programmes/activités)
│   ├── church_structure/ (1 écran : régions/districts/assemblées)
│   ├── accounting/   (9 écrans + 1 sous-dossier widgets/)
│   └── reports/      (2 écrans : rapport mensuel + impression)
├── widgets/                    # 5 widgets réutilisables (existants)
│   ├── app_shell.dart          # Layout principal (AppBar + Sidebar + Body)
│   ├── side_navigation.dart    # Menu latéral (12 items)
│   ├── context_header.dart     # En-tête contextuel
│   ├── info_card.dart          # Carte statistique
│   └── section_card.dart       # Carte de section
├── ui/                         # 🆕 Design system (Étape 2)
│   ├── theme/                  # Tokens, typographie, thème v2
│   ├── components/             # EabButton, EabField, EabTable, etc.
│   └── layout/                 # AppShell v2, PageHeader, responsive
└── features/                   # 🆕 Modules métier isolés (Étape 3+)
    ├── amortissements/          # Calcul et tableau d'amortissement
    ├── dashboard/               # Dashboard V2 (KPIs, alertes, actions rapides)
    ├── dashboard_finance/       # Dashboard financier avancé (3 RPCs)
    ├── etats_financiers/        # Balance, résultat, bilan, grand livre
    ├── exercices/               # Gestion exercices (brouillon→ouvert→clôturé)
    ├── members/                 # Membres V2 (formulaire, filtres, UI Kit)
    ├── organization/            # Paramètres organisation (multi-tenant)
    ├── programs/                # Programmes V2 (UI Kit)
    ├── fiscal_dossier/          # Dossier fiscal SYSCEBNL (wizard, PDF, import CSV)
    └── search/                  # Recherche globale (trigrammes pg_trgm)
```

### Couche de données

L'app utilise le **pattern Strategy** pour les données :

```
DataService (abstract)
├── InMemoryDataService  ← Pour le dev/démo (données mockées)
└── SupabaseDataService  ← Pour la prod (vraie BDD)
```

Le choix du service est fait via le provider `dataServiceProvider`. Les helpers de conversion snake_case ↔ camelCase sont centralisés dans `core/utils/case_converters.dart` (partagés entre SupabaseDataService et les providers comptables).

## 4. Routes de l'application (16 routes)

| Route | Écran | Module |
| --- | --- | --- |
| `/login` | LoginScreen | Auth |
| `/signup` | SignupScreen | Auth |
| `/forgot-password` | ForgotPasswordScreen | Auth |
| `/` | DashboardScreen | Dashboard |
| `/members` | MembersScreen | Membres |
| `/programs` | ProgramsScreen | Programmes |
| `/structure` | ChurchStructureScreen | Structure |
| `/accounting` | AccountingScreen | Comptabilité |
| `/accounting-settings` | AccountingSettingsScreen | Paramétrage comptable |
| `/accounting-budgets` | AccountingBudgetsScreen | Budgets |
| `/accounting-immobilisations` | AccountingImmobilisationsScreen | Immobilisations |
| `/accounting-treasury` | AccountingTreasuryScreen | Trésorerie |
| `/accounting-reconciliation` | AccountingReconciliationScreen | Rapprochement bancaire |
| `/accounting-reports` | AccountingReportsScreen | États & exports |
| `/reports-rapport-mensuel` | RapportMensuelEabScreen | Rapport mensuel EAB |
| `/fiscal-dossiers` | FiscalDossiersScreen | Dossier fiscal (liste) |
| `/fiscal-dossier/:id` | FiscalWizardScreen | Dossier fiscal (wizard) |
| `/fiscal-import-balance` | FiscalImportScreen | Import balance CSV |

### Navigation latérale (15 items)

1. Tableau de bord
2. Fidèles
3. Programmes
4. Structure de l'Église
5. Comptabilité
6. Trésorerie
7. Rapprochement bancaire
8. États & exports
9. Rapport mensuel EAB
10. Dossier fiscal
11. Budgets
12. Immobilisations
13. Paramétrage comptable
14. Exercices comptables
15. États financiers

## 5. Modèles de données (27+ entités)

| Modèle | Table Supabase | Champs clés |
| --- | --- | --- |
| `Member` | `membres` | fullName, gender, birthDate, phone, email, statut, role, vulnerabilites |
| `ProfilUtilisateur` | `profiles` | id, nom, role, organizationId, idRegion, idDistrict, idAssembleeLocale |
| `RegionEglise` | `regions_eglise` | id, nom, code, organizationId |
| `DistrictEglise` | `districts_eglise` | id, nom, code, idRegion |
| `AssembleeLocale` | `assemblees_locales` | id, nom, code, ville, idDistrict, idPasteur |
| `Famille` | `familles` | id, nom, idEpoux, idEpouse, idAssembleeLocale |
| `Program` | `programmes` | id, type, date, location, participant stats, conversion stats |
| `CompteComptable` | `comptes_comptables` | id, numero, intitule, nature, niveau, idParent |
| `JournalComptable` | `journaux_comptables` | id, code, intitule, type |
| `CentreAnalytique` | `centres_analytiques` | id, code, nom, type |
| `Tiers` | `tiers` | id, nom, type, telephone, email |
| `EcritureComptable` | `ecritures_comptables` | id, date, libelle, statut, idJournal, lignes[] |
| `LigneEcriture` | `lignes_ecritures` | id, idCompte, debit, credit, modePaiement |
| `BudgetComptable` | `budgets_comptables` | id, exercice, libelle, estVerrouille |
| `LigneBudgetComptable` | `lignes_budgets` | id, idBudget, idCompte, montantPrevu, montantRevu |
| `ImmobilisationComptable` | `immobilisations_comptables` | id, type, dateAcquisition, valeurAcquisition, dureeUtilite |
| `RapportMensuelEab` | `rapports_mensuels_eab` | id, annee, mois, statsMembres, statsActivites, statsFinances |
| `ReleveBancaire` | `releves_bancaires` | id, dateReleve, soldeInitial, soldeFinal |
| `FiscalTemplate` | `fiscal_templates` | id, code, label, version, isActive |
| `FiscalTemplatePage` | `fiscal_template_pages` | id, templateId, code, title, pageOrder |
| `FiscalTemplateField` | `fiscal_template_fields` | id, pageId, fieldKey, label, fieldType, section |
| `FiscalDossier` | `fiscal_dossiers` | id, organizationId, templateId, status, label |
| `FiscalDossierValue` | `fiscal_dossier_values` | id, dossierId, fieldKey, value, source |
| `FiscalValidationResult` | (RPC result) | ok, errorCount, errors[] |
| `ImportedTrialBalance` | `imported_trial_balances` | id, organizationId, exerciceLabel, totals |
| `ImportedTrialBalanceLine` | `imported_trial_balance_lines` | id, accountNumber, debit, credit |
| `CsvImportResult` | (local) | lines[], totalDebit, totalCredit, isBalanced |

## 6. Système de rôles (4 niveaux)

| Rôle | Périmètre | Peut changer d'assemblée ? |
| --- | --- | --- |
| `admin_national` | Toute l'organisation | ✅ Oui (toutes) |
| `responsable_region` | Sa région (ses districts + assemblées) | ✅ Oui (sa région) |
| `surintendant_district` | Son district (ses assemblées) | ✅ Oui (son district) |
| `tresorier_assemblee` | Son assemblée locale uniquement | ❌ Non |

La sélection de l'assemblée active se fait dans l'AppBar. Le rôle détermine aussi les droits CRUD via les politiques RLS côté Supabase.

## 7. Dépendances backend (Supabase)

- **17 fichiers de migration** SQL (00001 → 00016)
- **Seed data** : `seed.sql` (30KB) + `reset_demo_data.sql` (4KB)
- **30 tables** avec RLS activé sur toutes
- **30+ fonctions PostgreSQL** (RPCs : exercices, états financiers, dashboard finance, recherche globale, dossier fiscal)
- **5 triggers métier** + 22 triggers `updated_at`
- **~80 index** pour la performance
- **4 vues** (membres_actifs, ecritures_actives, soldes_comptes, tableau_bord_financier)
- **3 storage buckets** (member-photos, documents, organization-assets)
- **2 extensions** (uuid-ossp, pg_trgm)

## 8. État d'avancement actuel

### ✅ Fonctionnel

- Authentification (login, signup, mot de passe oublié)
- Structure ecclésiastique (CRUD régions, districts, assemblées)
- Gestion des membres (CRUD complet)
- Programmes/activités (CRUD complet)
- Plan comptable (paramétrage)
- Journaux comptables (paramétrage)
- Saisie d'écritures comptables avec lignes débit/crédit
- Budgets prévisionnels
- Immobilisations
- Rapport mensuel EAB
- Tableau de bord avec graphiques (fl_chart)
- Navigation responsive (sidebar desktop, drawer mobile)

- Gestion des exercices comptables (création, ouverture, clôture avec à-nouveaux) ✅
- Tableau de bord financier avancé (KPIs, évolution 12 mois, répartition camembert) ✅
- Recherche globale (Ctrl+K, trigrammes pg_trgm, membres/programmes/écritures) ✅
- États financiers SYCEBNL (balance générale, compte de résultat, bilan, grand livre) ✅
- Amortissements (tableau linéaire, calcul dotation, génération écriture) ✅
- Export PDF (balance, grand livre, rapport mensuel) ✅
- Export CSV (écritures, membres, programmes) ✅
- Dashboard V2 (KPIs riches, alertes, actions rapides) ✅
- Paramètres organisation (multi-tenant) ✅
- Dossier fiscal SYSCEBNL (wizard multi-pages, 5 pages template, pré-remplissage, validation, verrouillage) ✅
- Import balance CSV (paste, prévisualisation, contrôle D=C) ✅
- Export PDF dossier fiscal (COVER, IDENTITY, BILAN_ACTIF, BILAN_PASSIF, RESULTAT) ✅
- Fix RLS : injection `organization_id` depuis `profiles` (pas `appMetadata`) dans toutes les insertions comptables ✅
- Fix RPCs `open_exercice` / `cloturer_exercice` : correction `m.user_id` → `profiles.id = auth.uid()` ✅
- Fix DataTable overflow dans paramétrage comptable ✅
- Error handling : `try/catch` + `SnackBar` sur les formulaires d'insertion comptable ✅

### ⚠️ Partiel / À améliorer

- Trésorerie (vue simplifiée)
- Rapprochement bancaire (basique)
- Gestion des familles (peu exploitée)
- Designs de certains écrans legacy (structures)

### ❌ Non implémenté

- Personnalisation visuelle par église (logo, couleurs dynamiques)
- Onboarding première connexion
- Template PDF personnalisable par organisation
- Sortie d'immobilisation (cession, mise au rebut)
- Notifications / alertes configurables
- Mode hors-ligne
- Multi-langue
- Journal d'audit (UI — le backend existe)
- Comparaison inter-périodes / inter-assemblées

## 9. Catégories financières

L'application contient **190+ catégories de recettes** et **180+ catégories de dépenses** pré-définies dans `constants.dart`, couvrant la quasi-totalité des opérations financières d'une église évangélique africaine (dîmes, offrandes, collectes, locations, construction, aides sociales, missions, etc.).

## 10. Documents de référence disponibles

| Document | Emplacement | Contenu |
| --- | --- | --- |
| `BACKEND_REFERENCE.md` | `docs/` | Référence complète backend (tables, RLS, fonctions, triggers) |
| `GUIDE_UTILISATEUR.md` | `docs/` | Guide utilisateur de l'application |
| `GUIDE_INSTALLATION.md` | `docs/` | Guide d'installation et configuration |
| `SYSCEBNL2.pdf` | racine | Référentiel SYCEBNL complet (17MB) |
| `FICHIER EAW.pdf` | racine | Document de référence EAW (4MB) |
| `EAB pdf.pdf` | racine | Présentation EAB (58KB) |

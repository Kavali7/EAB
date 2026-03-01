# 📱 INVENTAIRE DES ÉCRANS ET NAVIGATION — EAB

## 1. Module Authentification (`screens/auth/`)

### 1.1 `LoginScreen` — Écran de connexion

- **Route** : `/login`
- **Fichier** : `login_screen.dart` (289 lignes)
- **Composants** : Formulaire email + mot de passe, bouton connexion, liens vers inscription et mot de passe oublié
- **Provider** : Supabase Auth direct
- **Fonctionnalités** :
  - Validation du formulaire
  - Appel `Supabase.instance.client.auth.signInWithPassword()`
  - Traduction des erreurs auth en français (`_translateAuthError()`)
  - Redirection vers `/` après connexion
- **Design actuel** : Fond coloré (AppColors.primary), formulaire centré, logo `EAB`
- **État** : ✅ Fonctionnel
- **À améliorer** :
  - Design basique, pas de branding multi-tenant (logo organisation)
  - Pas d'animation de chargement sophistiquée
  - Pas de "Remember me"

### 1.2 `SignupScreen` — Inscription

- **Route** : `/signup`
- **Fichier** : `signup_screen.dart`
- **Fonctionnalités** : Création de compte avec email + mot de passe
- **État** : ✅ Fonctionnel
- **À améliorer** : Pas de choix d'organisation, pas de champs profil

### 1.3 `ForgotPasswordScreen` — Mot de passe oublié

- **Route** : `/forgot-password`
- **Fichier** : `forgot_password_screen.dart`
- **Fonctionnalités** : Envoi de lien de réinitialisation par email
- **État** : ✅ Fonctionnel

---

## 2. Module Tableau de Bord (`screens/dashboard/`)

### 2.1 `DashboardScreen` — Tableau de bord principal

- **Route** : `/`
- **Fichier** : `dashboard_screen.dart` (517 lignes)
- **Providers** : `membersProvider`, `programsProvider`, `ecrituresComptablesProvider`, `profilUtilisateurCourantProvider`
- **Widgets utilisés** : `AppShell`, `InfoCard`, `ContextHeader`
- **Données affichées** :
  - Cards statistiques : total membres, programmes du mois, total recettes, total dépenses
  - Graphique en barres : distribution des programmes par type (`_programBarChart`)
  - Graphique en lignes : flux de trésorerie mensuel recettes vs dépenses (`_cashflowLineChart`)
  - Graphique camembert : distribution matrimoniale des membres (`_maritalDistribution`)
- **Graphiques** : `fl_chart` (PieChart, BarChart, LineChart)
- **État** : ⚠️ Partiel
- **À améliorer** :
  - Design peu attractif — cartes simples sans icônes ni couleurs distinctes
  - Données limitées (pas de comparaison mois précédent)
  - Pas de KPIs avancés (taux de présence, évolution, alertes)
  - Pas de widget d'actions rapides
  - Pas personnalisable par rôle

---

## 3. Module Membres/Fidèles (`screens/members/`)

### 3.1 `MembersScreen` — Liste et gestion des fidèles

- **Route** : `/members`
- **Fichier** : `members_screen.dart` (1269 lignes — LE PLUS GROS ÉCRAN)
- **Providers** : `membersProvider`, `familiesProvider`, `assembleesLocalesProvider`, `districtsProvider`, `regionsProvider`, `profilUtilisateurCourantProvider`
- **Composants principaux** :
  - `_MembersScreenState` : Vue liste avec filtres (région, district, assemblée, recherche texte) et `PaginatedDataTable`
  - `_MembersDataSource` : DataSource pour le tableau paginé avec colonnes (nom, rôle, statut, famille, assemblée, vulnérabilités)
  - `MemberFormDialog` : Formulaire modal complet pour ajout/modification
  - `_DateField` : Widget de sélection de date réutilisable
- **Fonctionnalités** :
  - Filtrage par hiérarchie (région → district → assemblée)
  - Recherche par nom (fullName)
  - CRUD complet (ajout, modification, suppression avec confirmation)
  - Calcul automatique des enfants (`_isChild` : < 16 ans)
  - Dérivation automatique du statut matrimonial
  - Validation des dates croisées (conversion < baptême < main d'association)
  - Scope automatique selon le rôle utilisateur (`_applyProfileScope`)
  - Verrouillage des filtres selon le rôle
- **Formulaire** : 20+ champs organisés en sections (Identité, Contact, Vie spirituelle, Statut, Vulnérabilités)
- **État** : ✅ Fonctionnel
- **À améliorer** :
  - Tableau basique (PaginatedDataTable standard)
  - Pas de fiche détaillée individuelle
  - Pas de photo du fidèle
  - Pas d'historique de présence
  - Formulaire dans un Dialog (pas un écran dédié)
  - Pas d'import/export Excel

---

## 4. Module Programmes (`screens/programs/`)

### 4.1 `ProgramsScreen` — Activités et cultes

- **Route** : `/programs`
- **Fichier** : `programs_screen.dart` (1183 lignes)
- **Providers** : `programsProvider`, `assembleesLocalesProvider`, `districtsProvider`, `regionsProvider`, `profilUtilisateurCourantProvider`
- **Composants** :
  - `_ProgramsScreenState` : Vue liste avec filtres (région, district, assemblée, type, dates) et `PaginatedDataTable`
  - `ProgramFormDialog` : Formulaire modal (type, date, lieu, participants, conversions, statistics spécifiques selon le type)
  - `_DateField`, `_DateFilterField` : Widgets date
- **Fonctionnalités** :
  - CRUD complet des programmes/activités
  - 12 types de programmes avec champs contextuels :
    - Culte : fréquentation H/F/G/F
    - Évangélisation : conversions, lieux visités
    - Baptêmes : nombre de baptisés
    - École dimanche : enfants, moniteurs
    - Visite : type de visite, personnes visitées
  - Vue détaillée en dialog
  - Filtrage par type, période, assemblée
  - Scope par rôle
- **État** : ✅ Fonctionnel
- **À améliorer** :
  - Design du tableau basique
  - Pas de calendrier visuel
  - Pas de statistiques de tendance
  - Pas de rappels/planification

---

## 5. Module Structure Ecclésiastique (`screens/church_structure/`)

### 5.1 `ChurchStructureScreen` — Régions, Districts, Assemblées

- **Route** : `/structure`
- **Fichier** : `church_structure_screen.dart`
- **Fonctionnalités** :
  - Vue et gestion de la hiérarchie : Régions → Districts → Assemblées
  - CRUD pour chaque niveau
- **État** : ✅ Fonctionnel
- **À améliorer** :
  - Pas de vue en arbre (TreeView)
  - Pas de carte géographique
  - Pas de statistiques par niveau

---

## 6. Module Comptabilité (`screens/accounting/`) — 9 écrans

### 6.1 `AccountingScreen` — Saisie comptable (écran principal)

- **Route** : `/accounting`
- **Fichier** : `accounting_screen.dart` (1165 lignes)
- **Providers** : `ecrituresComptablesProvider`, `comptesComptablesProvider`, `journauxComptablesProvider`, `centresAnalytiquesProvider`, `tiersProvider`, `assembleesLocalesProvider`, `profilUtilisateurCourantProvider`
- **Tabs** : 4 onglets
  1. **Journal** : Liste des écritures du journal sélectionné (filtre par journal)
  2. **Toutes les écritures** : Vue consolidée avec recherche
  3. **Synthèse** : Vue financière avec graphiques (revenus, charges, résultat, top comptes) et chart résultat par mois
  4. **Nouvelle écriture** : Formulaire de saisie via `EcritureComptableForm`
- **Fonctionnalités** :
  - Saisie d'écritures comptables multilignes (débit/crédit)
  - Filtrage par journal (caisse, banque, OD), par portée (assemblée, district, région, national)
  - Vue détails d'une écriture (`_showEcritureDetails`)
  - Calcul synthèse financière (total produits, total charges, résultat)
  - Top 5 comptes débiteurs et créditeurs
  - Graphique d'évolution du résultat mensuel
  - Contrôle d'accès par rôle
- **État** : ✅ Fonctionnel mais à améliorer
- **À améliorer** :
  - Design du tableau d'écritures basique
  - Validation de l'équilibre dans le formulaire pourrait être plus visible
  - Pas d'impression / export
  - La synthèse manque de détails

### 6.2 `AccountingSettingsScreen` — Paramétrage comptable

- **Route** : `/accounting-settings`
- **Fichier** : `accounting_settings_screen.dart` (31KB)
- **Tabs** : Plan comptable, Journaux, Centres analytiques, Tiers
- **CRUD** : Complet pour les 4 entités de paramétrage
- **État** : ✅ Fonctionnel

### 6.3 `AccountingBudgetsScreen` — Budgets prévisionnels

- **Route** : `/accounting-budgets`
- **Fichier** : `accounting_budgets_screen.dart` (28KB)
- **Fonctionnalités** : CRUD budgets, lignes budgétaires par compte, verrouillage
- **État** : ✅ Fonctionnel
- **À améliorer** : Pas de comparaison budget vs réalisé visuel

### 6.4 `AccountingImmobilisationsScreen` — Immobilisations

- **Route** : `/accounting-immobilisations`
- **Fichier** : `accounting_immobilisations_screen.dart` (23KB)
- **Fonctionnalités** : CRUD immobilisations, types, calcul amortissement
- **État** : ✅ Fonctionnel
- **À améliorer** : Pas de tableau d'amortissement détaillé

### 6.5 `AccountingTreasuryScreen` — Trésorerie

- **Route** : `/accounting-treasury`
- **Fichier** : `accounting_treasury_screen.dart` (11KB)
- **Fonctionnalités** : Vue des soldes de trésorerie (caisse, banque)
- **État** : ⚠️ Partiel — vue simplifiée

### 6.6 `AccountingReconciliationScreen` — Rapprochement bancaire

- **Route** : `/accounting-reconciliation`
- **Fichier** : `accounting_reconciliation_screen.dart` (12KB)
- **Fonctionnalités** : Lignes de relevé bancaire, pointage
- **État** : ⚠️ Partiel

### 6.7 `AccountingReportsScreen` — États & exports

- **Route** : `/accounting-reports`
- **Fichier** : `accounting_reports_screen.dart` (18KB)
- **Rapports disponibles** :
  - Balance des comptes
  - Grand livre
  - Journal centralisé
- **État** : ⚠️ Partiel — affichage écran uniquement, pas d'export PDF/Excel

### 6.8 `AccountingBalancePrintScreen` — Impression balance

- **Fichier** : `accounting_balance_print_screen.dart` (5KB)
- **Fonctionnalité** : Vue d'impression de la balance
- **État** : ⚠️ Basique

### 6.9 `AccountingLedgerPrintScreen` — Impression grand livre

- **Fichier** : `accounting_ledger_print_screen.dart` (4KB)
- **Fonctionnalité** : Vue d'impression du grand livre
- **État** : ⚠️ Basique

---

## 7. Module Rapports (`screens/reports/`)

### 7.1 `RapportMensuelEabScreen` — Rapport mensuel

- **Route** : `/reports-rapport-mensuel`
- **Fichier** : `rapport_mensuel_eab_screen.dart` (22KB)
- **Provider** : `rapportMensuelEabProviders` (11KB)
- **Fonctionnalités** :
  - Sélection année/mois/assemblée
  - Affichage du rapport avec 3 sections :
    - Statistiques Membres (effectifs, conversions, baptêmes, décès)
    - Statistiques Activités (cultes, évangélisations, etc.)
    - Statistiques Financières (produits, charges, résultat)
  - Calcul automatisé à partir des données de membres, programmes et écritures
- **État** : ✅ Fonctionnel
- **À améliorer** :
  - Pas d'export PDF
  - Design du rapport pas assez esthétique/professionnel
  - Pas de comparaison avec le mois précédent

### 7.2 `RapportMensuelEabPrintScreen` — Impression rapport

- **Fichier** : `rapport_mensuel_eab_print_screen.dart` (9KB)
- **Fonctionnalité** : Vue optimisée pour impression navigateur
- **État** : ⚠️ Basique

---

## 8. Modules Feature (`features/`) — 9 modules, 30 fichiers

### 8.1 Dashboard V2 (`features/dashboard/`)

- **Fichier** : `presentation/dashboard_screen_v2.dart`
- **Fonctionnalités** : KPIs riches, alertes, activité récente, actions rapides, résumé par rôle
- **État** : ✅ Fonctionnel

### 8.2 Dashboard Finance (`features/dashboard_finance/`)

- **Fichiers** : `dashboard_finance_screen.dart`, `dashboard_finance_providers.dart`
- **RPCs backend** : `dashboard_finance_kpis`, `dashboard_finance_evolution`, `dashboard_finance_repartition`
- **Fonctionnalités** : KPIs financiers, évolution 12 mois (LineChart), répartition produits/charges (PieChart)
- **État** : ✅ Fonctionnel

### 8.3 États Financiers (`features/etats_financiers/`)

- **Fichiers** : `presentation/etats_financiers_screen.dart`, `application/reports_providers.dart`, `data/reports_repository.dart`, `services/export_service.dart`
- **RPCs backend** : `report_balance_generale`, `report_compte_resultat`, `report_bilan`, `report_grand_livre`
- **Fonctionnalités** : Balance générale, compte de résultat SYCEBNL, bilan simplifié, grand livre avec solde cumulé, export PDF/CSV
- **État** : ✅ Fonctionnel

### 8.4 Exercices Comptables (`features/exercices/`)

- **Fichiers** : `presentation/exercices_screen.dart`, `presentation/exercice_form_dialog.dart`, `application/exercices_providers.dart`, `data/exercices_repository.dart`
- **RPCs backend** : `open_exercice`, `get_exercice_ouvert`, `can_post_in_exercice`, `cloturer_exercice`
- **Cycle** : Brouillon → Ouvert → Clôturé (avec écriture de résultat + à-nouveaux)
- **État** : ✅ Fonctionnel

### 8.5 Amortissements (`features/amortissements/`)

- **Fichiers** : `application/amortissement_providers.dart`, `presentation/tableau_amortissement_dialog.dart`, `services/amortissement_service.dart`
- **RPC backend** : `calculate_amortissement`
- **Fonctionnalités** : Tableau d'amortissement linéaire, calcul dotation annuelle, génération écriture 68x/28x
- **État** : ✅ Fonctionnel

### 8.6 Recherche Globale (`features/search/`)

- **Fichiers** : `presentation/global_search_dialog.dart`, `application/search_providers.dart`, `data/search_repository.dart`
- **RPC backend** : `global_search` (trigrammes pg_trgm, min 2 chars, limit 30, cap 50)
- **Fonctionnalités** : Ctrl+K, recherche membres/programmes/écritures, résultats groupés par catégorie
- **État** : ✅ Fonctionnel

### 8.7 Membres V2 (`features/members/`)

- **Fichiers** : `presentation/members_screen_v2.dart`, `presentation/member_form_dialog.dart`, `application/members_providers.dart`, `data/members_repository.dart`
- **Fonctionnalités** : Version migrée vers le UI Kit (`EabTable`, `EabHierarchyFilter`, etc.)
- **État** : ✅ Fonctionnel

### 8.8 Programmes V2 (`features/programs/`)

- **Fichiers** : `presentation/programs_screen_v2.dart`, `presentation/program_form_dialog.dart`, `application/programs_providers.dart`, `data/programs_repository.dart`
- **Fonctionnalités** : Version migrée vers le UI Kit
- **État** : ✅ Fonctionnel

### 8.9 Organisation (`features/organization/`)

- **Fichiers** : `presentation/organization_settings_screen.dart`, `application/organization_providers.dart`, `data/organization_repository.dart`, `data/organization_model.dart`
- **Fonctionnalités** : Paramètres d'organisation, branding multi-tenant
- **État** : ✅ Fonctionnel

---

## 9. Widgets partagés (`widgets/`)

| Widget | Fichier | Taille | Rôle |
| --- | --- | --- | --- |
| `AppShell` | `app_shell.dart` | 8KB | Layout principal : AppBar + Sidebar (desktop) / Drawer (mobile) + Body. Gère la sélection du profil utilisateur et de l'assemblée active dans l'AppBar. |
| `SideNavigation` | `side_navigation.dart` | 4KB | Menu latéral avec 12 items de navigation + bouton déconnexion. |
| `ContextHeader` | `context_header.dart` | 5KB | En-tête contextuel affichant l'assemblée active avec ses informations hiérarchiques. |
| `InfoCard` | `info_card.dart` | 2KB | Carte statistique avec titre, valeur et couleur. |
| `SectionCard` | `section_card.dart` | 1KB | Carte de section avec titre et contenu. |

---

## 10. Layout et responsive

- **Breakpoints** (via `responsive_framework`) :
  - Mobile : 0–599px
  - Tablette : 600–1023px
  - Desktop : 1024–1440px
  - XL : 1441px+
- **Desktop** (≥1000px) : Sidebar fixe (240px max) + contenu principal
- **Mobile** (<1000px) : Drawer latéral via hamburger menu

---

## 11. Résumé des tailles des écrans (indicateur de complexité)

| Écran | Lignes | Taille | Complexité |
| --- | --- | --- | --- |
| `members_screen.dart` | 1269 | 50KB | 🔴 Très élevée |
| `programs_screen.dart` | 1183 | 48KB | 🔴 Très élevée |
| `accounting_screen.dart` | 1165 | 48KB | 🔴 Très élevée |
| `accounting_settings_screen.dart` | — | 31KB | 🟠 Élevée |
| `accounting_budgets_screen.dart` | — | 28KB | 🟠 Élevée |
| `accounting_immobilisations_screen.dart` | — | 23KB | 🟠 Élevée |
| `rapport_mensuel_eab_screen.dart` | — | 22KB | 🟠 Élevée |
| `dashboard_screen_v2.dart` | — | — | 🟡 Moyenne |
| `dashboard_finance_screen.dart` | — | — | 🟡 Moyenne |
| `etats_financiers_screen.dart` | — | — | 🟡 Moyenne |
| `exercices_screen.dart` | — | — | 🟡 Moyenne |
| `accounting_reports_screen.dart` | — | 18KB | 🟡 Moyenne |
| `supabase_data_service.dart` | 446 | 14KB | 🟡 Moyenne |
| `accounting_reconciliation_screen.dart` | — | 12KB | 🟡 Moyenne |
| `login_screen.dart` | 289 | 11KB | 🟢 Modérée |

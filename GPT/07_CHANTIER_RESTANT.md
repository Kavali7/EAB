# 🚧 CHANTIER RESTANT — Fonctionnalités à Implémenter

## Vue d'ensemble

Le projet EAB dispose d'une **base fonctionnelle solide** avec les phases critiques (C1-C4), haute priorité (H1-H5), et **moyenne (M1-M6) terminées**. Le chantier restant se concentre sur : (1) les items résiduels des phases 1-2, (2) les fonctionnalités de phase 4 retenues pour la V1.

> **Dernière mise à jour** : 2026-03-02

---

## 🔴 PRIORITÉ CRITIQUE (à faire en premier)

### C1. Refonte du Design Global ✅

**Pourquoi** : Le design actuel est fonctionnel mais n'est pas à la hauteur d'un produit SaaS commercial. Les tableaux sont bruts (PaginatedDataTable par défaut), les formulaires sont des Dialog trop petits, et il n'y a pas de micro-animations.

**Travail** :

- [x] UI Kit centralisé créé (`lib/ui/`) — 13 composants réutilisables ✅
- [x] Google Fonts Inter appliqué globalement + JetBrains Mono (code) ✅
- [x] Refondre le composant de tableau → `EabTable` (en-têtes, tri, pagination, états) ✅
- [x] Transformer les formulaires Dialog → `EabDialog` + `EabButton` ✅
- [x] Ajouter des skeleton loading → `SkeletonLoader` ✅
- [x] Créer des empty states → `EmptyState` + `ErrorState` ✅
- [x] Material 3 activé, tokens finalisés (AppRadius, AppElevation, AppAnimation, AppAccessibility) ✅
- [x] Couleurs enrichies : 18 tokens, ombres, dégradés ✅
- [x] Features Membres et Programmes migrées vers `features/` avec UI Kit ✅

### C2. Refonte du Tableau de Bord ✅

**Pourquoi** : Le dashboard est l'écran d'accueil — il doit impressionner et informer.

**Travail** :

- [x] Cartes KPI riches avec icônes, couleurs, tendance ↑↓ et pourcentage vs mois précédent
- [x] Résumé financier du mois : Recettes / Dépenses / Résultat avec mini-graphes sparkline
- [x] Alertes et rappels (écritures en brouillon, exercice non ouvert, nouveaux convertis)
- [x] Activité récente (dernières écritures, derniers membres)
- [x] Raccourcis d'actions rapides (nouvelle écriture, nouveau membre, rapport du mois)
- [x] Résumé par rôle : admin voit toutes les assemblées, trésorier voit son assemblée

### C3. Multi-Tenant Complet ✅

**Pourquoi** : L'app doit fonctionner pour n'importe quelle église, pas seulement EAB.

**Travail** :

- [x] Onboarding : écran de création d'organisation (nom, logo, couleurs)
- [x] Thème dynamique par organisation (couleur primaire, logo dans le sidebar)
- [x] Nom de l'organisation dans l'AppBar au lieu de "EAB"
- [x] Plan comptable modèle fourni lors de la création d'une organisation
- [x] Catégories de recettes/dépenses paramétrables par organisation (parametres JSON)
- [x] Invitation d'utilisateurs dans une organisation existante

### C4. Export PDF / Excel ✅

**Pourquoi** : Les trésoriers ont besoin d'imprimer et partager les rapports.

**Travail** :

- [x] Export du rapport mensuel EAB en PDF professionnel (mise en page esthétique avec logo)
- [x] Export de la balance des comptes en PDF
- [x] Export du grand livre en PDF
- [x] Export des listes (membres, programmes) en Excel/CSV
- [x] Export des écritures comptables en CSV
- [ ] Template PDF personnalisable par organisation

---

## 🟠 PRIORITÉ HAUTE (phase 2)

### H1. Gestion des Exercices Comptables ✅

**Travail** :

- [x] Écran de gestion des exercices : création, ouverture, clôture
- [x] Clôture d'exercice : vérifier que toutes les écritures sont validées
- [x] Génération automatique de l'écriture de résultat
- [x] Écriture d'ouverture du nouvel exercice (à-nouveaux)
- [x] Interdire la saisie hors période de l'exercice ouvert

### H2. Amortissements Automatiques ✅

**Travail** :

- [x] Tableau d'amortissement par immobilisation (linéaire) ✅
- [x] Calcul automatique de la dotation annuelle ✅
- [x] Génération de l'écriture d'amortissement (débit 68x / crédit 28x) ✅
- [x] Dialog de visualisation du tableau d'amortissement ✅
- [ ] Sortie d'immobilisation (cession, mise au rebut)

### H3. Rapports Financiers Avancés ✅

**Travail** :

- [x] Compte de résultat (charges vs produits, par nature)
- [x] Bilan simplifié (actif circulant / immo vs passif / fonds propres)
- [x] Balance générale (vérification D=C)
- [x] Grand livre avec solde cumulé
- [ ] Tableau des flux de trésorerie
- [ ] Rapport budget vs réalisé (par compte, par mois)
- [ ] Comparaison inter-périodes (M vs M-1, A vs A-1)
- [ ] Ratios financiers clés (autonomie, couverture…)

### H4. Tableau de Bord Financier Avancé ✅

**Travail** :

- [x] Graphique d'évolution 12 mois des produits / charges / solde net (fl_chart) ✅
- [x] Répartition des charges par nature (camembert PieChart) ✅
- [x] Répartition des produits par nature (camembert PieChart) ✅
- [x] KPIs financiers (trésorerie, résultat, variation, nb écritures) ✅
- [x] 3 RPCs backend : dashboard_finance_kpis, evolution, repartition ✅
- [ ] Suivi budgétaire visuel (jauges de progression)
- [ ] Comparaison inter-assemblées (admin national)

### H5. Recherche Globale ✅

**Travail** :

- [x] Barre de recherche dans l'AppBar + bouton loupe
- [x] Recherche sur membres, programmes, écritures (trigrammes pg_trgm)
- [x] Résultats groupés par catégorie avec icônes colorées
- [x] Raccourci clavier Ctrl+K + navigation ↑↓ Enter Esc

---

## 🟡 PRIORITÉ MOYENNE (phase 3)

### M1. Journal d'Audit (Frontend) ✅

**Travail** :

- [x] Écran de consultation du journal d'audit (`audit_log_screen.dart`)
- [x] Filtres : par action (INSERT/UPDATE/DELETE/VALIDATION/CLOTURE), table, utilisateur
- [x] Vue chronologique timeline avec icônes colorées par action
- [x] Détail bottom sheet : métadonnées + changements JSONB
- [x] Provider filtrable (`audit_providers.dart`)
- [x] Route `/audit-log` + entrée sidebar

### M2. Fiches Individuelles ✅

**Travail** :

- [x] Fiche membre détaillée (`member_detail_screen.dart`) : profil complet, parcours spirituel, vulnérabilités
- [x] Fiche compte comptable (`compte_detail_screen.dart`) : mouvements récents, solde cumulé, DataTable
- [x] Navigation tap sur ligne tableau → fiche détaillée
- [x] Flèche retour ← sur chaque fiche

### M3. Notifications et Alertes ✅

**Travail** :

- [x] Système de notifications in-app (`notifications_provider.dart`)
- [x] 3 règles métier : écritures brouillon, exercice absent, exercice expirant (< 30j)
- [x] 🔔 Cloche avec badge rouge dans l'AppBar
- [x] Panneau popup avec priorités colorées (urgent/warning/info)
- [x] Navigation vers l'écran concerné au tap

### M4. Gestion des Familles (enrichie) ✅

**Travail** :

- [x] Vue famille (`famille_detail_screen.dart`) avec liens époux/épouse/enfants
- [x] Navigation vers fiche membre depuis la famille
- [x] Statistiques familiales (nb membres, officiers)

### M5. Calendrier des Activités ✅

**Travail** :

- [x] Vue calendrier mensuelle (`calendar_screen.dart`)
- [x] Points colorés par type de programme (culte, baptême, visite...)
- [x] Navigation mois précédent/suivant + bouton "Aujourd'hui"
- [x] Détail du jour en bottom sheet
- [x] Liste des activités du mois en dessous
- [x] Route `/calendar` + entrée sidebar

### M6. Gestion des Tiers Enrichie ✅

**Travail** :

- [x] Fiche tiers (`tiers_detail_screen.dart`) avec coordonnées
- [x] Historique des opérations (écritures liées au tiers)
- [x] Balance par tiers (Débit / Crédit / Solde)

---

## 🟢 PRIORITÉ BASSE (phase 4 — différenciation V1)

### B1. Analytics Avancées

- [ ] Dashboard de BI avec graphiques interactifs
- [ ] Tendances de croissance (membres, finances) sur 12 mois
- [ ] Benchmarking entre assemblées (admin national)

### B2. Mobile App Native

- [ ] Adapter l'app Flutter pour Android/iOS
- [ ] Mode hors-ligne avec synchronisation
- [ ] Notifications push

### B3. Multi-Langue (EN uniquement pour V1)

- [ ] Support français / anglais
- [ ] Système de localisation `intl`

### B6. Mode Avancé Comptable

- [ ] Lettrage des comptes de tiers
- [ ] Import d'écritures depuis fichier Excel/CSV
- [ ] Import automatique de relevé bancaire (OFX/QIF)

> **Note**: B4 (Intégrations Mobile Money/WhatsApp) et B5 (Communication/Messagerie) sont reportés à la V2.

---

## 🔧 INFRASTRUCTURE (Pipeline Release)

### R1. Sentry — Error Monitoring ✅

- [x] `sentry_flutter` intégré dans `pubspec.yaml`
- [x] DSN configuré via `--dart-define` (prod) avec fallback vide (dev)
- [x] `ErrorReporting` : capture exceptions, breadcrumbs, user context, RPC timing

### R2. Audit SQL ✅

- [x] Script `test/e2e/audit_post_merge.sql` — 10 tests
- [x] RLS : 22 tables protégées, 12 policies storage
- [x] Performance : toutes tables indexées (3-11 index chacune)
- [x] Backups : automatiques Supabase (7 jours rétention)

---

## 📋 Résumé par phase

| Phase | Items | Impact | Statut |
| --- | --- | --- | --- |
| **Phase 1 — Critique** | C1-C4 (Design, Dashboard, Multi-tenant, Export) | ✅ Terminé | Complet |
| **Phase 2 — Haute** | H1-H5 (Exercices, Amortissements, Rapports, Dashboard financier, Recherche) | ✅ Terminé | Complet (sauf flux trésorerie, ratios) |
| **Phase 3 — Moyenne** | M1-M6 (Audit, Fiches, Notifications, Familles, Calendrier, Tiers) | ✅ Terminé | **Complet** |
| **Phase 4 — Basse** | B1, B2, B3, B6 (Analytics, Mobile, EN, Comptable avancé) | 🟢 Différenciation | ~3-4 semaines |
| **Infrastructure** | R1-R2 (Sentry, Audit SQL) | ✅ Terminé | Complet |

---

## 🏁 Critères de réussite du produit final

1. **Un trésorier d'église sans formation informatique** doit pouvoir saisir ses écritures, générer son rapport mensuel et l'exporter en PDF — en moins de 15 minutes.
2. **Un administrateur national** doit pouvoir avoir une vue consolidée instantanée de toutes ses assemblées.
3. **Le design** doit rivaliser avec les applications SaaS modernes (Stripe, Linear, Notion) tout en restant simple.
4. **Chaque église** doit avoir son espace personnalisé avec son logo et ses couleurs.
5. **Les rapports financiers** doivent être conformes au SYCEBNL et imprimables immédiatement.

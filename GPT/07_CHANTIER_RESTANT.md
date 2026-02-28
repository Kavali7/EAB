# 🚧 CHANTIER RESTANT — Fonctionnalités à Implémenter

## Vue d'ensemble

Le projet EAB dispose d'une **base fonctionnelle solide** (CRUD sur toutes les entités, comptabilité, rapports, rôles). Le chantier restant se concentre sur : (1) le polissage du design, (2) les fonctionnalités manquantes, (3) le multi-tenant complet, et (4) la compétitivité.

---

## 🔴 PRIORITÉ CRITIQUE (à faire en premier)

### C1. Refonte du Design Global

**Pourquoi** : Le design actuel est fonctionnel mais n'est pas à la hauteur d'un produit SaaS commercial. Les tableaux sont bruts (PaginatedDataTable par défaut), les formulaires sont des Dialog trop petits, et il n'y a pas de micro-animations.

**Travail** :

- [x] UI Kit centralisé créé (`lib/ui/`) — 13 composants réutilisables ✅
- [ ] Adopter une police Google Fonts (Inter ou Poppins)
- [x] Refondre le composant de tableau → `EabTable` (en-têtes, tri, pagination, états) ✅
- [x] Transformer les formulaires Dialog → `EabDialog` + `EabButton` ✅
- [x] Ajouter des skeleton loading → `SkeletonLoader` ✅
- [x] Créer des empty states → `EmptyState` + `ErrorState` ✅
- [ ] Ajouter des micro-animations (transitions de page, hover effects, feedback tactile)
- [ ] Repenser les couleurs : garder navy/doré mais ajouter richesse (dégradés, ombres)
- [x] Features Membres et Programmes migrées vers `features/` avec UI Kit ✅

### C2. Refonte du Tableau de Bord

**Pourquoi** : Le dashboard est l'écran d'accueil — il doit impressionner et informer.

**Travail** :

- [ ] Cartes KPI riches avec icônes, couleurs, tendance ↑↓ et pourcentage vs mois précédent
- [ ] Résumé financier du mois : Recettes / Dépenses / Résultat avec mini-graphes sparkline
- [ ] Alertes et rappels (écritures en brouillon, budget dépassé, rapport en retard)
- [ ] Activité récente (dernières écritures, derniers membres)
- [ ] Raccourcis d'actions rapides (nouvelle écriture, nouveau membre, rapport du mois)
- [ ] Résumé par rôle : admin voit toutes les assemblées, trésorier voit son assemblée

### C3. Multi-Tenant Complet

**Pourquoi** : L'app doit fonctionner pour n'importe quelle église, pas seulement EAB.

**Travail** :

- [ ] Onboarding : écran de création d'organisation (nom, logo, couleurs)
- [ ] Thème dynamique par organisation (couleur primaire, logo dans le sidebar)
- [ ] Nom de l'organisation dans l'AppBar au lieu de "EAB"
- [ ] Plan comptable modèle fourni lors de la création d'une organisation
- [ ] Catégories de recettes/dépenses paramétrables par organisation (sortir de `constants.dart`)
- [ ] Invitation d'utilisateurs dans une organisation existante

### C4. Export PDF / Excel

**Pourquoi** : Les trésoriers ont besoin d'imprimer et partager les rapports.

**Travail** :

- [ ] Export du rapport mensuel EAB en PDF professionnel (mise en page esthétique avec logo)
- [ ] Export de la balance des comptes en PDF
- [ ] Export du grand livre en PDF
- [ ] Export des listes (membres, programmes) en Excel
- [ ] Export des écritures comptables en Excel
- [ ] Template PDF personnalisable par organisation

---

## 🟠 PRIORITÉ HAUTE (phase 2)

### H1. Gestion des Exercices Comptables

**Travail** :

- [ ] Écran de gestion des exercices : création, ouverture, clôture
- [ ] Clôture d'exercice : vérifier que toutes les écritures sont validées
- [ ] Génération automatique de l'écriture de résultat
- [ ] Écriture d'ouverture du nouvel exercice (à-nouveaux)
- [ ] Interdire la saisie hors période de l'exercice ouvert

### H2. Amortissements Automatiques

**Travail** :

- [ ] Tableau d'amortissement par immobilisation (linéaire / dégressif)
- [ ] Calcul automatique de la dotation annuelle
- [ ] Génération de l'écriture d'amortissement en fin d'exercice
- [ ] Vue consolidée des amortissements de l'exercice
- [ ] Sortie d'immobilisation (cession, mise au rebut)

### H3. Rapports Financiers Avancés

**Travail** :

- [ ] Compte de résultat (charges vs produits, par nature)
- [ ] Bilan simplifié (actif circulant / immo vs passif / fonds propres)
- [ ] Tableau des flux de trésorerie
- [ ] Rapport budget vs réalisé (par compte, par mois)
- [ ] Comparaison inter-périodes (M vs M-1, A vs A-1)
- [ ] Ratios financiers clés (autonomie, couverture…)

### H4. Tableau de Bord Financier Avancé

**Travail** :

- [ ] Graphique d'évolution annuelle des recettes / dépenses
- [ ] Répartition des charges par nature (camembert)
- [ ] Répartition des produits par nature
- [ ] Suivi budgétaire visuel (jauges de progression)
- [ ] Alerte de dépassement budgétaire
- [ ] Comparaison inter-assemblées (admin national)

### H5. Recherche Globale

**Travail** :

- [ ] Barre de recherche dans l'AppBar
- [ ] Recherche sur membres, programmes, écritures
- [ ] Résultats groupés par catégorie
- [ ] Raccourci clavier (Ctrl+K ou /)

---

## 🟡 PRIORITÉ MOYENNE (phase 3)

### M1. Journal d'Audit (Frontend)

**Travail** :

- [ ] Écran de consultation du journal d'audit (`audit_log`)
- [ ] Filtres : par action, date, utilisateur, table, enregistrement
- [ ] Vue chronologique des modifications d'une entité

### M2. Fiches Individuelles

**Travail** :

- [ ] Fiche membre détaillée (profil complet, historique, famille, timeline)
- [ ] Fiche assemblée (statistiques, membres, programmes, finances)
- [ ] Fiche compte comptable (mouvements, solde, graphique)

### M3. Notifications et Alertes

**Travail** :

- [ ] Système de notifications in-app
- [ ] Alertes configurables : budget dépassé, rapport en retard, écriture en attente
- [ ] Badge de notification sur l'icône dans le sidebar

### M4. Gestion des Familles (enrichie)

**Travail** :

- [ ] Vue famille avec arbre généalogique simplifié
- [ ] Lien automatique des enfants aux parents
- [ ] Statistiques familiales

### M5. Calendrier des Activités

**Travail** :

- [ ] Vue calendrier mensuelle/hebdomadaire des programmes
- [ ] Planification d'activités futures
- [ ] Rappels avant événement

### M6. Gestion des Tiers Enrichie

**Travail** :

- [ ] Fiche tiers avec historique des opérations
- [ ] Balance par tiers (dû par les tiers / dû aux tiers)
- [ ] Relances automatiques

---

## 🟢 PRIORITÉ BASSE (phase 4 — différenciation)

### B1. Analytics Avancées

- [ ] Dashboard de BI avec graphiques interactifs
- [ ] Tendances de croissance (membres, finances) sur 12 mois
- [ ] Benchmarking entre assemblées (admin national)
- [ ] Prédictions ML simples (tendance des recettes)

### B2. Mobile App Native

- [ ] Adapter l'app Flutter pour Android/iOS
- [ ] Mode hors-ligne avec synchronisation
- [ ] Notifications push

### B3. Multi-Langue

- [ ] Support français / anglais / portugais / espagnol
- [ ] Système de localisation `intl`

### B4. Intégrations

- [ ] Intégration Mobile Money (MTN MoMo, Orange Money) pour les offrandes en ligne
- [ ] Intégration SMS pour rappels aux fidèles
- [ ] Intégration WhatsApp Business API
- [ ] Connexion avec des plateformes de paiement (Stripe, PayPal)

### B5. Communication

- [ ] Messagerie interne
- [ ] Annuaire des fidèles (avec consentement RGPD)
- [ ] Envoi de SMS/email groupés

### B6. Mode Avancé Comptable

- [ ] Lettrage des comptes de tiers
- [ ] Import d'écritures depuis fichier Excel/CSV
- [ ] Import automatique de relevé bancaire (OFX/QIF)
- [ ] Multi-devises (pour les organisations internationales)

---

## 📋 Résumé par phase

| Phase | Items | Impact | Effort |
| --- | --- | --- | --- |
| **Phase 1 — Critique** | C1-C4 (Design, Dashboard, Multi-tenant, Export) | 🔴 Maximal | ~3-4 semaines |
| **Phase 2 — Haute** | H1-H5 (Exercices, Amortissements, Rapports, Dashboard financier, Recherche) | 🟠 Élevé | ~2-3 semaines |
| **Phase 3 — Moyenne** | M1-M6 (Audit, Fiches, Notifications, Familles, Calendrier, Tiers) | 🟡 Moyen | ~2-3 semaines |
| **Phase 4 — Basse** | B1-B6 (Analytics, Mobile, Multi-langue, Intégrations, Communication, Comptable avancé) | 🟢 Différenciation | ~4-6 semaines |

---

## 🏁 Critères de réussite du produit final

1. **Un trésorier d'église sans formation informatique** doit pouvoir saisir ses écritures, générer son rapport mensuel et l'exporter en PDF — en moins de 15 minutes.
2. **Un administrateur national** doit pouvoir avoir une vue consolidée instantanée de toutes ses assemblées.
3. **Le design** doit rivaliser avec les applications SaaS modernes (Stripe, Linear, Notion) tout en restant simple.
4. **Chaque église** doit avoir son espace personnalisé avec son logo et ses couleurs.
5. **Les rapports financiers** doivent être conformes au SYCEBNL et imprimables immédiatement.

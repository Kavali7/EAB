# 📘 BACKEND_REFERENCE.md — Référence Complète du Backend EAB

> [!CAUTION]
> ## ⚠️ LECTURE ET MISE À JOUR OBLIGATOIRES
> Ce fichier est la **source de vérité unique** pour le backend Supabase du projet EAB.
> **Toute modification du backend** (tables, colonnes, RLS, fonctions, triggers, index, storage)
> **DOIT être reflétée ici AVANT de commiter.**
> Ne JAMAIS se fier uniquement aux fichiers de migration — ce document reflète l'état RÉEL.

- **Projet** : EAB (Église–Administration–Budget)
- **Backend** : Supabase (PostgreSQL)
- **Dernière mise à jour** : 2026-02-22
- **Fichiers de migration** : `supabase/migrations/00001` → `00007`

---

## Table des matières

1. [Types / Enums](#1-types--enums)
2. [Tables — Structure ecclésiastique](#2-tables--structure-ecclésiastique)
3. [Tables — Comptabilité (SYCEBNL)](#3-tables--comptabilité-sycebnl)
4. [Tables — Améliorations (exercices, audit, séquences)](#4-tables--améliorations)
5. [Clés primaires et étrangères](#5-clés-primaires-et-étrangères)
6. [Contraintes](#6-contraintes)
7. [Politiques RLS](#7-politiques-rls)
8. [Fonctions PostgreSQL](#8-fonctions-postgresql)
9. [Triggers](#9-triggers)
10. [Index](#10-index)
11. [Vues](#11-vues)
12. [Storage Buckets](#12-storage-buckets)
13. [Extensions](#13-extensions)
14. [Diagramme de dépendances](#14-diagramme-de-dépendances)
15. [Journal des modifications](#15-journal-des-modifications)

---

## 1. Types / Enums

| Nom | Valeurs | Source |
|-----|---------|--------|
| `gender` | `male`, `female` | 00001 |
| `statut_matrimonial` | `celibataire`, `marie`, `veuf`, `veuve`, `divorce`, `separe` | 00001 |
| `statut_fidele` | `actif`, `inactif`, `parti`, `decede`, `transfere` | 00001 |
| `role_fidele` | `membre`, `pasteur`, `ancien`, `diacre`, `diaconesse`, `evangeliste`, `autre_officier` | 00001 |
| `vulnerabilite_fidele` | `orphelin`, `veuf`, `veuve`, `handicape`, `troisieme_age`, `autre` | 00001 |
| `type_programme` | `culte`, `evangelisation_masse`, `evangelisation_porte_a_porte`, `baptemes`, `mains_association`, `sainte_cene`, `reunion_priere`, `mariage`, `discipline`, `visite`, `ecole_du_dimanche`, `autre` | 00001 |
| `type_visite` | `fidele`, `autorite`, `partenaire`, `autre_assemblee`, `autre` | 00001 |
| `role_utilisateur` | `admin_national`, `responsable_region`, `surintendant_district`, `tresorier_assemblee` | 00001 |
| `nature_compte` | `actif`, `passif`, `charge`, `produit`, `hors_activite_ordinaire`, `engagement`, `autre` | 00002 |
| `type_journal_comptable` | `caisse`, `banque`, `operations_diverses` | 00002 |
| `type_tiers` | `membre`, `fournisseur`, `bailleur`, `employe`, `partenaire`, `autre` | 00002 |
| `type_centre_analytique` | `assemblee_locale`, `projet`, `activite`, `departement`, `autre` | 00002 |
| `mode_paiement` | `especes`, `cheque`, `virement_bancaire`, `mobile_money`, `microfinance`, `autre` | 00002 |
| `type_immobilisation` | `terrain`, `batiment`, `mobilier`, `materiel_informatique`, `materiel_sono`, `vehicule`, `autre` | 00002 |
| `statut_ecriture` | `brouillon`, `validee`, `cloturee` | 00002 |
| `action_audit` | `INSERT`, `UPDATE`, `DELETE`, `SOFT_DELETE`, `LOGIN`, `LOGOUT`, `VALIDATION`, `CLOTURE` | 00007 |

---

## 2. Tables — Structure ecclésiastique

### 2.1 `organizations`
> Multi-tenancy. Chaque église/organisation a son espace isolé.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `name` | TEXT | NON | — | Nom de l'organisation |
| `code` | TEXT | OUI | — | Code unique (UNIQUE) |
| `description` | TEXT | OUI | — | Description |
| `logo_url` | TEXT | OUI | — | URL du logo |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | Date de création |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | Dernière modification |

**RLS** : ✅ activé — **UNIQUE** : `code`

---

### 2.2 `profiles`
> Profil utilisateur avec rôle et périmètre d'accès. Lié à `auth.users`.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | — | PK, FK → `auth.users(id)` ON DELETE CASCADE |
| `organization_id` | UUID | OUI | — | FK → `organizations(id)` ON DELETE SET NULL |
| `full_name` | TEXT | NON | — | Nom complet |
| `role` | `role_utilisateur` | NON | `'tresorier_assemblee'` | Rôle utilisateur |
| `id_region` | UUID | OUI | — | FK → `regions_eglise(id)` ON DELETE SET NULL |
| `id_district` | UUID | OUI | — | FK → `districts_eglise(id)` ON DELETE SET NULL |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` ON DELETE SET NULL |
| `avatar_url` | TEXT | OUI | — | URL de l'avatar |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ activé

---

### 2.3 `regions_eglise`
> Régions ecclésiastiques au niveau national.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` ON DELETE CASCADE |
| `nom` | TEXT | NON | — | Nom de la région |
| `code` | TEXT | OUI | — | Code région |
| `description` | TEXT | OUI | — | — |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, code)`

---

### 2.4 `districts_eglise`
> Districts au sein d'une région.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` ON DELETE CASCADE |
| `id_region` | UUID | NON | — | FK → `regions_eglise(id)` ON DELETE CASCADE |
| `nom` | TEXT | NON | — | Nom du district |
| `code` | TEXT | OUI | — | Code district |
| `description` | TEXT | OUI | — | — |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, code)`

---

### 2.5 `assemblees_locales`
> Assemblées locales (églises locales).

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` ON DELETE CASCADE |
| `id_district` | UUID | NON | — | FK → `districts_eglise(id)` ON DELETE CASCADE |
| `nom` | TEXT | NON | — | Nom de l'assemblée |
| `code` | TEXT | OUI | — | Code assemblée |
| `ville` | TEXT | OUI | — | Ville |
| `quartier` | TEXT | OUI | — | Quartier |
| `adresse_postale` | TEXT | OUI | — | Adresse postale |
| `telephone` | TEXT | OUI | — | Téléphone |
| `email` | TEXT | OUI | — | Email |
| `id_fidele_pasteur_responsable` | UUID | OUI | — | FK → `membres(id)` ON DELETE SET NULL |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, code)`

---

### 2.6 `familles`
> Familles de fidèles pour le suivi familial.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` ON DELETE CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` ON DELETE SET NULL |
| `nom` | TEXT | NON | — | Nom de famille |
| `id_epoux` | UUID | OUI | — | FK → `membres(id)` ON DELETE SET NULL |
| `id_epouse` | UUID | OUI | — | FK → `membres(id)` ON DELETE SET NULL |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

---

### 2.7 `membres`
> Membres/fidèles de l'église avec toutes leurs informations.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` ON DELETE CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` ON DELETE SET NULL |
| `id_famille` | UUID | OUI | — | FK → `familles(id)` ON DELETE SET NULL |
| `full_name` | TEXT | NON | — | Nom complet |
| `gender` | `gender` | NON | — | Genre |
| `date_naissance` | DATE | OUI | — | Date de naissance |
| `phone` | TEXT | OUI | — | Téléphone |
| `email` | TEXT | OUI | — | Email |
| `address` | TEXT | OUI | — | Adresse |
| `statut_matrimonial` | `statut_matrimonial` | OUI | — | Statut matrimonial |
| `date_conversion` | DATE | OUI | — | Date de conversion |
| `date_bapteme` | DATE | OUI | — | Date de baptême |
| `date_main_association` | DATE | OUI | — | Date main d'association |
| `statut` | `statut_fidele` | NON | `'actif'` | Statut du fidèle |
| `role` | `role_fidele` | NON | `'membre'` | Rôle dans l'église |
| `date_entree` | DATE | OUI | — | Date d'entrée |
| `date_sortie` | DATE | OUI | — | Date de sortie |
| `motif_sortie` | TEXT | OUI | — | Motif de sortie |
| `date_deces` | DATE | OUI | — | Date de décès |
| `vulnerabilites` | JSONB | OUI | `'[]'` | Liste des vulnérabilités |
| `photo_url` | TEXT | OUI | — | URL de la photo |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

---

### 2.8 `programmes`
> Activités et programmes de l'église (cultes, évangélisations, etc.).

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` ON DELETE CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` ON DELETE SET NULL |
| `type` | `type_programme` | NON | — | Type de programme |
| `date` | DATE | NON | — | Date du programme |
| `location` | TEXT | NON | — | Lieu |
| `description` | TEXT | OUI | — | Description |
| `observations` | TEXT | OUI | — | Observations |
| `participant_ids` | JSONB | OUI | `'[]'` | IDs des participants |
| `type_visite` | `type_visite` | OUI | — | Type de visite |
| `compte_rendu_visite` | TEXT | OUI | — | Compte rendu |
| `nombre_hommes` | INTEGER | OUI | `0` | Nb hommes présents |
| `nombre_femmes` | INTEGER | OUI | `0` | Nb femmes présentes |
| `nombre_garcons` | INTEGER | OUI | `0` | Nb garçons présents |
| `nombre_filles` | INTEGER | OUI | `0` | Nb filles présentes |
| `conversions_hommes` | INTEGER | OUI | `0` | Conversions hommes |
| `conversions_femmes` | INTEGER | OUI | `0` | Conversions femmes |
| `conversions_garcons` | INTEGER | OUI | `0` | Conversions garçons |
| `conversions_filles` | INTEGER | OUI | `0` | Conversions filles |
| `nombre_classes_ecole_dimanche` | INTEGER | OUI | `0` | Nb classes école dimanche |
| `nombre_moniteurs_hommes` | INTEGER | OUI | `0` | Nb moniteurs hommes |
| `nombre_monitrices_femmes` | INTEGER | OUI | `0` | Nb monitrices femmes |
| `derniere_lecon_ecole_dimanche` | TEXT | OUI | — | Dernière leçon |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` | TIMESTAMPTZ | NON | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

---

## 3. Tables — Comptabilité (SYCEBNL)

### 3.1 `comptes_comptables`
> Plan comptable conforme SYCEBNL.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` CASCADE |
| `numero` | TEXT | NON | — | Numéro du compte (ex: "5121") |
| `intitule` | TEXT | NON | — | Libellé du compte |
| `nature` | `nature_compte` | NON | — | Nature comptable |
| `niveau` | INTEGER | OUI | `1` | 1=classe, 2=compte, 3=sous-compte |
| `id_compte_parent` | UUID | OUI | — | FK → `comptes_comptables(id)` SET NULL |
| `actif` | BOOLEAN | NON | `TRUE` | Compte actif |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, numero)`

---

### 3.2 `journaux_comptables`
> Journaux comptables (caisse, banque, OD).

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` CASCADE |
| `code` | TEXT | NON | — | Code journal (ex: "CAI", "BAN") |
| `intitule` | TEXT | NON | — | Libellé |
| `type` | `type_journal_comptable` | NON | — | Type de journal |
| `actif` | BOOLEAN | NON | `TRUE` | Journal actif |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, code)`

---

### 3.3 `centres_analytiques`
> Centres analytiques pour la comptabilité analytique.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` SET NULL |
| `code` | TEXT | NON | — | Code centre |
| `nom` | TEXT | NON | — | Nom |
| `type` | `type_centre_analytique` | NON | — | Type |
| `description` | TEXT | OUI | — | — |
| `actif` | BOOLEAN | NON | `TRUE` | Centre actif |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, code)`

---

### 3.4 `tiers`
> Fournisseurs, bailleurs, partenaires et autres tiers.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` SET NULL |
| `id_fidele_lie` | UUID | OUI | — | FK → `membres(id)` SET NULL |
| `nom` | TEXT | NON | — | Nom du tiers |
| `type` | `type_tiers` | NON | — | Type de tiers |
| `telephone` / `email` / `adresse` | TEXT | OUI | — | Contact |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

---

### 3.5 `ecritures_comptables`
> En-têtes des écritures comptables.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` SET NULL |
| `id_journal` | UUID | NON | — | FK → `journaux_comptables(id)` **RESTRICT** |
| `id_centre_analytique_principal` | UUID | OUI | — | FK → `centres_analytiques(id)` SET NULL |
| `date` | DATE | NON | — | Date de l'écriture |
| `reference_piece` | TEXT | OUI | — | Réf. pièce justificative |
| `libelle` | TEXT | NON | — | Libellé |
| `statut` | `statut_ecriture` | NON | `'brouillon'` | Statut |
| `piece_justificative_url` | TEXT | OUI | — | URL vers Storage |
| `created_by` | UUID | OUI | — | FK → `profiles(id)` SET NULL |
| `validated_by` | UUID | OUI | — | FK → `profiles(id)` SET NULL |
| `validated_at` | TIMESTAMPTZ | OUI | — | Date validation |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

---

### 3.6 `lignes_ecritures`
> Lignes débit/crédit des écritures comptables.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `id_ecriture` | UUID | NON | — | FK → `ecritures_comptables(id)` CASCADE |
| `id_compte_comptable` | UUID | NON | — | FK → `comptes_comptables(id)` **RESTRICT** |
| `id_centre_analytique` | UUID | OUI | — | FK → `centres_analytiques(id)` SET NULL |
| `id_tiers` | UUID | OUI | — | FK → `tiers(id)` SET NULL |
| `libelle` | TEXT | OUI | — | Libellé de la ligne |
| `debit` | DECIMAL(15,2) | OUI | `0` | Montant débit |
| `credit` | DECIMAL(15,2) | OUI | `0` | Montant crédit |
| `mode_paiement` | `mode_paiement` | OUI | — | Mode de paiement |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **CHECK** : `(debit>0 AND credit=0) OR (debit=0 AND credit>0) OR (debit=0 AND credit=0)`

---

### 3.7 `budgets_comptables`
> Budgets par exercice et périmètre.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK → `organizations(id)` CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK → `assemblees_locales(id)` SET NULL |
| `id_centre_analytique` | UUID | OUI | — | FK → `centres_analytiques(id)` SET NULL |
| `id_tiers_bailleur` | UUID | OUI | — | FK → `tiers(id)` SET NULL |
| `exercice` | INTEGER | NON | — | Année budgétaire |
| `libelle` | TEXT | OUI | — | Libellé |
| `est_verrouille` | BOOLEAN | NON | `FALSE` | Budget verrouillé |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, exercice, id_assemblee_locale, id_centre_analytique)`

---

### 3.8 `lignes_budgets`
> Détail des lignes budgétaires par compte.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `id_budget` | UUID | NON | — | FK → `budgets_comptables(id)` CASCADE |
| `id_compte_comptable` | UUID | NON | — | FK → `comptes_comptables(id)` **RESTRICT** |
| `montant_prevu` | DECIMAL(15,2) | NON | `0` | Montant prévu |
| `montant_revu` | DECIMAL(15,2) | OUI | — | Montant révisé |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(id_budget, id_compte_comptable)`

---

### 3.9 `immobilisations_comptables`
> Actifs immobilisés avec suivi des amortissements.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK SET NULL |
| `id_centre_analytique` | UUID | OUI | — | FK SET NULL |
| `libelle` | TEXT | NON | — | Libellé |
| `type` | `type_immobilisation` | NON | — | Type |
| `date_acquisition` | DATE | NON | — | Date d'acquisition |
| `valeur_acquisition` | DECIMAL(15,2) | NON | — | Valeur d'acquisition |
| `valeur_residuelle` | DECIMAL(15,2) | OUI | — | Valeur résiduelle |
| `duree_utilite_en_annees` | INTEGER | NON | — | Durée d'utilité |
| `id_compte_immobilisation` | UUID | OUI | — | FK → `comptes_comptables` **RESTRICT** |
| `id_compte_amortissement` | UUID | OUI | — | FK → `comptes_comptables` SET NULL |
| `id_compte_dotation` | UUID | OUI | — | FK → `comptes_comptables` SET NULL |
| `est_sortie` | BOOLEAN | NON | `FALSE` | Bien sorti |
| `date_sortie` | DATE | OUI | — | Date de sortie |
| `valeur_cession` | DECIMAL(15,2) | OUI | — | Valeur de cession |
| `deleted_at` | TIMESTAMPTZ | OUI | — | Soft delete (00007) |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

---

### 3.10 `rapports_mensuels_eab`
> Rapports mensuels consolidés par assemblée.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK CASCADE |
| `id_assemblee_locale` | UUID | NON | — | FK CASCADE |
| `annee` | INTEGER | NON | — | Année |
| `mois` | INTEGER | NON | — | Mois (CHECK 1-12) |
| `stats_membres` | JSONB | NON | `'{}'` | Stats membres |
| `stats_activites` | JSONB | NON | `'{}'` | Stats activités |
| `stats_finances` | JSONB | NON | `'{}'` | Stats finances |
| `resume_activites` | TEXT | OUI | — | Résumé |
| `projets_realisations` | TEXT | OUI | — | Projets réalisés |
| `projets_mois_suivant` | TEXT | OUI | — | Projets à venir |
| `observations` | TEXT | OUI | — | Observations |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅ — **UNIQUE** : `(organization_id, id_assemblee_locale, annee, mois)` — **CHECK** : `mois >= 1 AND mois <= 12`

---

### 3.11 `releves_bancaires`
> Relevés bancaires pour rapprochement.

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NON | `uuid_generate_v4()` | PK |
| `organization_id` | UUID | NON | — | FK CASCADE |
| `id_assemblee_locale` | UUID | OUI | — | FK SET NULL |
| `id_journal_banque` | UUID | OUI | — | FK → `journaux_comptables(id)` **RESTRICT** |
| `date_releve` | DATE | NON | — | Date du relevé |
| `solde_initial` | DECIMAL(15,2) | NON | `0` | Solde initial |
| `solde_final` | DECIMAL(15,2) | NON | `0` | Solde final |
| `fichier_url` | TEXT | OUI | — | URL du fichier |
| `created_at` / `updated_at` | TIMESTAMPTZ | NON | `NOW()` | — |

**RLS** : ✅

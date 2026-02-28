# ⚙️ LOGIQUE MÉTIER — Règles Comptables et Fonctionnelles

## 1. Norme comptable : SYCEBNL (OHADA)

### 1.1 Plan comptable

Le Système Comptable des Entités à But Non Lucratif (SYCEBNL) est le cadre comptable applicable aux associations, fondations et organismes à but non lucratif dans l'espace OHADA (17 pays d'Afrique).

**Classes de comptes utilisées :**

| Classe | Nature | Exemples dans une église |
| --- | --- | --- |
| 1 | Fonds propres | Fonds associatifs, résultats antérieurs |
| 2 | Immobilisations | Terrains, bâtiments, mobilier, sono, véhicules |
| 3 | Stocks | Bibles, brochures, matériel (rarement utilisé) |
| 4 | Tiers | Fournisseurs, membres débiteurs, avances |
| 5 | Trésorerie | Caisse (espèces), Banque (compte bancaire) |
| 6 | Charges | Loyers, transports, aides sociales, primes, travaux |
| 7 | Produits | Dîmes, offrandes, cotisations, dons, ventes |
| 8 | Hors activité ordinaire | Subventions exceptionnelles, héritages |

### 1.2 Journaux comptables

| Code | Type | Usage |
| --- | --- | --- |
| `CAI` | Caisse | Opérations en espèces |
| `BAN` | Banque | Virements, chèques, mobile money |
| `OD` | Opérations diverses | Écritures de régularisation, amortissements |

### 1.3 Principes comptables appliqués

- **Partie double** : Chaque écriture a obligatoirement Total Débit = Total Crédit
- **Exercice comptable** : Du 1er janvier au 31 décembre
- **Monnaie** : FCFA (0 décimales)
- **Numérotation** : Séquence automatique par journal et exercice (ex: `CAI-2026-0001`)

---

## 2. Workflow des écritures comptables

### 2.1 Cycle de vie d'une écriture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  BROUILLON  │ ──> │   VALIDÉE    │ ──> │   CLÔTURÉE   │
│ (modifiable │     │ (non modif.) │     │ (archivée)   │
│  saisie)    │     │  approuvée)  │     │ exercice     │
└─────────────┘     └──────────────┘     │ fermé)       │
                                          └──────────────┘
```

| Statut | Modifiable ? | Supprimable ? | Qui ? |
| --- | --- | --- | --- |
| `brouillon` | ✅ Oui | ✅ Oui | Auteur |
| `validee` | ❌ Non | ❌ Non | Superviseur |
| `cloturee` | ❌ Non | ❌ Non | Système (fin d'exercice) |

### 2.2 Saisie d'une écriture

1. L'utilisateur choisit le journal (CAI/BAN/OD)
2. Il entre la date et le libellé
3. Il ajoute les lignes :
   - Chaque ligne : compte + montant au débit OU au crédit + tiers (optionnel) + centre analytique (optionnel) + mode de paiement
4. Le système vérifie que `Σ Débit = Σ Crédit`
5. Enregistrement en statut `brouillon`
6. Un supérieur peut valider → statut `validee`

### 2.3 Contraintes de validation

- Une écriture doit avoir au minimum 2 lignes
- Le total débit doit être égal au total crédit (tolérance : 0 FCFA)
- La date doit être dans l'exercice en cours (contrainte non encore implémentée)
- Le journal doit exister
- Les comptes doivent exister et être de niveau détail (pas un compte de regroupement)

---

## 3. États financiers

### 3.1 Balance des comptes

Pour chaque compte, affiche :
- Solde débiteur initial
- Somme des mouvements débiteurs
- Somme des mouvements créditeurs
- Solde final (débiteur ou créditeur)

### 3.2 Grand Livre

Journal détaillé de toutes les écritures passées sur un compte, avec :
- Date, libellé, débit, crédit, solde progressif

### 3.3 Rapport mensuel EAB

Le rapport mensuel est un document officiel de l'église, consolidant sur un mois donné :

**Section Membres :**
- Effectifs actifs (hommes / femmes / enfants)
- Nouvelles conversions du mois
- Nouveaux baptisés du mois
- Décès du mois
- Transferts entrants/sortants

**Section Activités :**
- Nombre de cultes tenus
- Nombre d'évangélisations (masse + porte-à-porte)
- Nombre de baptêmes
- Nombre de mariages
- Nombre de mains d'association (intégration de nouveaux membres)
- Sainte Cène célébrées
- Réunions de prière
- Visites pastorales

**Section Finances :**
- Total des produits (classe 7) du mois
- Total des charges (classe 6) du mois
- Résultat du mois (Produits - Charges)
- Comparaison avec budget prévisionnel (non implémenté)

---

## 4. Système de rôles et permissions

### 4.1 Hiérarchie

```
admin_national
  └── responsable_region
        └── surintendant_district
              └── tresorier_assemblee
```

### 4.2 Règles d'accès

| Action | Admin National | Resp. Région | Surint. District | Trésorier |
| --- | --- | --- | --- | --- |
| Voir membres | Tous | Sa région | Son district | Son assemblée |
| Ajouter membre | ✅ (partout) | ✅ (sa région) | ✅ (son district) | ✅ (son assemblée) |
| Voir écritures | Toutes | Sa région | Son district | Son assemblée |
| Saisir écriture | ✅ (partout) | ✅ (sa région) | ✅ (son district) | ✅ (son assemblée) |
| Paramétrage comptable | ✅ | ✅ | ❌ | ❌ |
| Créer exercice | ✅ | ❌ | ❌ | ❌ |
| Clôturer exercice | ✅ | ❌ | ❌ | ❌ |

### 4.3 Implémentation côté Flutter

Le scope est appliqué via `_applyProfileScope()` dans chaque écran :
- Le profil courant détermine les assemblées autorisées (`_assembleesAutorisees`)
- Les filtres hiérarchiques (région/district/assemblée) sont pré-remplis et verrouillés selon le rôle

### 4.4 Implémentation côté Supabase (RLS)

Toutes les tables sont protégées par des politiques RLS qui filtrent par `organization_id`. La logique de hiérarchie (région → district → assemblée) n'est pas encore pleinement appliquée côté backend — elle est principalement côté client.

---

## 5. Multi-tenancy

### 5.1 Architecture

Chaque rangée de données est isolée par `organization_id` :

```
organizations (id, name, logo_url, ...)
  ├── regions_eglise (organization_id = org.id)
  │     └── districts_eglise (organization_id = org.id)
  │           └── assemblees_locales (organization_id = org.id)
  │                 └── membres (organization_id = org.id)
  ├── comptes_comptables (organization_id = org.id)
  ├── journaux_comptables (organization_id = org.id)
  └── ... (toutes les tables)
```

### 5.2 RLS

Les politiques RLS s'assurent qu'un utilisateur ne peut voir/modifier que les données de son organisation, en vérifiant :
```sql
organization_id IN (
  SELECT organization_id FROM profiles WHERE id = auth.uid()
)
```

### 5.3 Ce qui manque pour le vrai multi-tenant

- ❌ Personnalisation visuelle par organisation (logo, couleurs, nom dans l'AppBar)
- ❌ Paramètres spécifiques par organisation (devise, format de date)
- ❌ Onboarding : création d'une nouvelle organisation avec configuration initiale
- ❌ Plan comptable modèle à copier lors de la création d'une organisation

---

## 6. Gestion budgétaire

### 6.1 Structure

- Un budget est lié à un exercice comptable
- Il contient des lignes budgétaires, chacune associée à un compte comptable
- Chaque ligne a : montant prévu, montant révisé
- Un budget peut être verrouillé (`est_verrouille`)

### 6.2 Ce qui est implémenté

- CRUD des budgets et lignes budgétaires
- Association budget → exercice

### 6.3 Ce qui manque

- ❌ Comparaison budget vs réalisé (données existent mais pas le visuel)
- ❌ Alertes de dépassement budgétaire
- ❌ Rapports de suivi budgétaire

---

## 7. Immobilisations

### 7.1 Types

`terrain`, `batiment`, `mobilier`, `materiel_informatique`, `materiel_sono`, `vehicule`, `autre`

### 7.2 Données collectées

- Description, type, date d'acquisition, valeur d'acquisition
- Durée d'utilité (en années), méthode d'amortissement

### 7.3 Ce qui manque

- ❌ Calcul automatique des dotations aux amortissements
- ❌ Tableau d'amortissement linéaire/dégressif
- ❌ Écriture d'amortissement automatique en fin d'exercice
- ❌ Sortie d'immobilisation (cession, mise au rebut)

---

## 8. Centres analytiques

Les centres analytiques permettent un suivi des coûts par dimension :

| Type | Exemple |
| --- | --- |
| `assemblee_locale` | Assemblée de Cotonou Centre |
| `projet` | Construction nouveau temple |
| `activite` | Croisade d'évangélisation 2026 |
| `departement` | Département Jeunesse |
| `autre` | Autre |

Chaque ligne d'écriture peut être associée à un centre analytique pour l'analyse des coûts par dimension.

---

## 9. Catégories financières (constantes)

L'application pré-définit **190 catégories de recettes** et **183 catégories de dépenses** dans `constants.dart`. Ces catégories couvrent :

**Recettes** : Dîmes, offrandes (10+ types), cotisations, collectes (15+ types), ventes (10+ types), revenus d'activités, dons (diaspora, partenaires, sponsors), financements participatifs, etc.

**Dépenses** : Loyers, achats d'équipement (30+ types), factures, impression (10+ types), primes et indemnités, transport, hébergement, événements (15+ types), aides sociales, construction (20+ types), communication (10+ types), secrétariat, frais bancaires, etc.

> **Note** : Ces catégories sont actuellement dans le code Dart en dur. Elles devraient à terme être dans la base de données pour être paramétrables par organisation.

---

## 10. Audit et traçabilité

### 10.1 Ce qui existe (backend)

- Table `audit_log` avec : `action`, `table_name`, `record_id`, `old_data`, `new_data`, `performed_by`, `performed_at`
- Types d'action : INSERT, UPDATE, DELETE, SOFT_DELETE, LOGIN, LOGOUT, VALIDATION, CLOTURE
- Trigger `trg_audit_ecritures` qui enregistre tout changement sur les écritures

### 10.2 Ce qui manque (frontend)

- ❌ Écran de consultation du journal d'audit
- ❌ Filtres par action, date, utilisateur, table
- ❌ Visualisation de l'historique d'une entité (« qui a modifié quoi, quand »)

---

## 11. Modes de paiement

| Code | Label |
| --- | --- |
| `especes` | Espèces |
| `cheque` | Chèque |
| `virement_bancaire` | Virement bancaire |
| `mobile_money` | Mobile Money |
| `microfinance` | Microfinance |
| `autre` | Autre |

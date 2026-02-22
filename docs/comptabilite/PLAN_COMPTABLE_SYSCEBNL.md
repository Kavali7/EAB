# Plan Comptable SYSCEBNL - EAB

## 📋 Introduction

Le **SYSCEBNL** (Système Comptable des Entités à But Non Lucratif) est le référentiel comptable applicable aux organisations sans but lucratif dans l'espace OHADA. Ce guide présente le plan comptable utilisé dans l'application EAB.

---

## 🏗️ Structure du plan comptable

Le plan comptable est organisé en **classes** numérotées de 1 à 9 :

| Classe | Intitulé | Nature |
|--------|----------|--------|
| 1 | Ressources durables | Passif |
| 2 | Actif immobilisé | Actif |
| 3 | Stocks | Actif |
| 4 | Tiers | Actif/Passif |
| 5 | Trésorerie | Actif |
| 6 | Charges | Charge |
| 7 | Produits | Produit |
| 8 | Hors activité ordinaire | HAO |
| 9 | Engagements | Engagement |

---

## 💰 Comptes utilisés dans EAB

### Classe 2 - Immobilisations

| Numéro | Intitulé | Description |
|--------|----------|-------------|
| 21 | Terrains | Terrains propriété de l'église |
| 213 | Bâtiments | Temples, salles, presbytères |
| 2183 | Mobilier | Bancs, chaises, tables |
| 2184 | Matériel de sonorisation | Sono, micros, enceintes |
| 2813 | Amortissement bâtiments | Cumul amortissement bâtiments |
| 28183 | Amortissement mobilier | Cumul amortissement mobilier |
| 28184 | Amortissement matériel sono | Cumul amortissement sono |

### Classe 4 - Tiers

| Numéro | Intitulé | Description |
|--------|----------|-------------|
| 401 | Fournisseurs | Dettes envers fournisseurs |
| 411 | Membres / Adhérents | Créances sur membres |

### Classe 5 - Trésorerie

| Numéro | Intitulé | Description |
|--------|----------|-------------|
| 531 | Caisse | Espèces en caisse |
| 5121 | Banque - Compte principal | Compte bancaire courant |

### Classe 6 - Charges

| Numéro | Intitulé | Description |
|--------|----------|-------------|
| 613 | Loyers et locations | Loyers de salles |
| 615 | Entretien et réparations | Maintenance, réparations |
| 624 | Transports | Déplacements, carburant |
| 645 | Indemnités et aides | Aides aux membres vulnérables |
| 6811 | Dotations aux amortissements | Amortissement annuel |

### Classe 7 - Produits

| Numéro | Intitulé | Description |
|--------|----------|-------------|
| 701 | Dîmes | Contributions des membres (10%) |
| 702 | Offrandes de culte | Collectes pendant les cultes |
| 706 | Dons et libéralités | Dons exceptionnels |
| 758 | Autres produits de gestion | Produits divers |

---

## 📓 Journaux comptables

L'application utilise trois journaux principaux :

| Code | Intitulé | Utilisation |
|------|----------|-------------|
| **CAI** | Journal de caisse | Mouvements en espèces |
| **BAN** | Journal de banque | Virements, chèques, prélèvements |
| **OD** | Opérations diverses | Régularisations, amortissements |

---

## ✍️ Exemples d'écritures

### 1. Enregistrement des offrandes de culte (espèces)

| Compte | Libellé | Débit | Crédit |
|--------|---------|-------|--------|
| 531 | Caisse | 150 000 | |
| 702 | Offrandes de culte | | 150 000 |

*Journal : CAI - Pièce : REC-2025-03-02-001*

### 2. Paiement facture fournisseur (virement bancaire)

| Compte | Libellé | Débit | Crédit |
|--------|---------|-------|--------|
| 613 | Loyers et locations | 80 000 | |
| 5121 | Banque | | 80 000 |

*Journal : BAN - Pièce : FAC-LOYER-2025-03*

### 3. Aide sociale à un membre vulnérable

| Compte | Libellé | Débit | Crédit |
|--------|---------|-------|--------|
| 645 | Indemnités et aides | 30 000 | |
| 531 | Caisse | | 30 000 |

*Journal : CAI - Pièce : AIDE-SOC-2025-03-10*

### 4. Dotation aux amortissements (fin d'exercice)

| Compte | Libellé | Débit | Crédit |
|--------|---------|-------|--------|
| 6811 | Dotations aux amortissements | 450 000 | |
| 2813 | Amortissement bâtiments | | 450 000 |

*Journal : OD - Pièce : AMORT-2025*

---

## 📊 Centres analytiques

Les centres analytiques permettent d'affecter les charges et produits à :

### Par assemblée locale
- ASS-COT-CENTRE (Assemblée Cotonou Centre)
- ASS-AGLA (Assemblée Agla)
- ASS-FIDJROSSE (Assemblée Fidjrossè)

### Par projet
- PROJ-CONSTR-COT (Projet construction temple)
- PROJ-EV-2025 (Projet évangélisation 2025)

---

## 📅 Exercice comptable

L'exercice comptable correspond à l'année civile (1er janvier - 31 décembre).

### États de l'exercice

| État | Description | Actions possibles |
|------|-------------|-------------------|
| **Ouvert** | Exercice en cours | Saisie, validation |
| **Clôturé** | Exercice terminé | Consultation seule |

### Clôture de l'exercice

1. Valider toutes les écritures en brouillon
2. Passer les écritures d'amortissement
3. Générer les états financiers
4. Clôturer l'exercice (action irréversible)

---

## 📈 États financiers

### Bilan
- **Actif** : Immobilisations, créances, trésorerie
- **Passif** : Fonds propres, dettes

### Compte de résultat
- **Produits** : Dîmes, offrandes, dons
- **Charges** : Fonctionnement, personnel, amortissements
- **Résultat** : Excédent ou déficit

### Tableau de trésorerie
- Recettes encaissées
- Dépenses décaissées
- Variation de trésorerie

---

## ❓ Règles importantes

1. **Équilibre** : Chaque écriture doit être équilibrée (Total Débit = Total Crédit)

2. **Pièce justificative** : Toute écriture doit avoir une pièce (facture, reçu, etc.)

3. **Validation** : Une écriture validée ne peut plus être modifiée

4. **Clôture** : Les écritures d'un exercice clôturé sont verrouillées

5. **Soft delete** : Les suppressions sont logiques (récupérables par admin)

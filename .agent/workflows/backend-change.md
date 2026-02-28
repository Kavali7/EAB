---
description: Processus obligatoire pour toute modification du backend Supabase
---

# Workflow : Modification du Backend

Ce workflow s'applique à **toute** modification touchant le backend Supabase du projet EAB.

## Étapes obligatoires

### 1. Lire la documentation backend
- Ouvrir et lire `docs/BACKEND_REFERENCE.md`
- Identifier les tables, fonctions, triggers, RLS et index concernés par la modification

### 2. Effectuer les modifications
- Créer ou modifier les fichiers de migration dans `supabase/migrations/`
- Respecter la nomenclature : `00XXX_description.sql`
- Suivre les conventions existantes (multi-tenancy via `organization_id`, RLS via fonctions helper)

### 3. Mettre à jour BACKEND_REFERENCE.md
// turbo
- Ouvrir `docs/BACKEND_REFERENCE.md`
- Mettre à jour les sections concernées (tables, colonnes, FK, RLS, fonctions, triggers, index, etc.)
- Ajouter une entrée au journal des modifications (section 15)
- Mettre à jour la date de dernière mise à jour dans l'en-tête

### 4. Vérifier la cohérence
- S'assurer que `BACKEND_REFERENCE.md` reflète exactement l'état réel du backend
- En cas de doute, exécuter les scripts d'introspection de `docs/scripts_introspection.md`

### 5. Commiter
- Inclure `docs/BACKEND_REFERENCE.md` dans le même commit que les modifications SQL

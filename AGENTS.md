# AGENTS.md — Instructions pour les agents IA

> Ce fichier est destiné aux **agents IA / assistants de code** travaillant sur ce projet.

## Règle n°1 : BACKEND_REFERENCE.md

Avant toute modification touchant le backend (base de données, RLS, fonctions, triggers, storage, migrations SQL), vous **DEVEZ** :

1. **Lire** `docs/BACKEND_REFERENCE.md` pour comprendre l'état actuel du backend
2. **Effectuer** vos modifications
3. **Mettre à jour** `docs/BACKEND_REFERENCE.md` pour refléter les changements
4. **Ajouter** une entrée au journal des modifications (section 15 du fichier)

### Fichiers backend à surveiller

Toute modification dans ces chemins déclenche l'obligation de mise à jour :

- `supabase/migrations/*.sql`
- `supabase/functions/**`
- `lib/core/services/supabase_*.dart`
- `lib/core/config/supabase_config.dart`

### Exemple d'entrée au journal

```markdown
| 2026-XX-XX | Agent IA | Ajout de la colonne `xyz` sur `table_abc`, nouvelle politique RLS |
```

## Fichiers de référence importants

| Fichier | Description |
|---------|-------------|
| `docs/BACKEND_REFERENCE.md` | Source de vérité unique pour le backend |
| `docs/scripts_introspection.md` | Scripts SQL pour introspecter la DB en cas de doute |
| `supabase/migrations/` | Fichiers de migration SQL ordonnés (00001-00007) |

## Règle n°2 : Commits obligatoires avec détails en français

Tout commit touchant le backend **DOIT** :

1. **Inclure** `docs/BACKEND_REFERENCE.md` dans le commit (`git add docs/BACKEND_REFERENCE.md`)
2. **Avoir un message de commit détaillé en français** décrivant exactement :
   - Quelles tables, colonnes, fonctions, triggers ou politiques RLS ont été modifiées
   - La nature du changement (ajout, modification, suppression)
   - L'impact sur les autres composants

### Format de message de commit

```
feat(backend): [description courte]

Détails :
- Table `xxx` : ajout de la colonne `yyy` (TYPE, nullable/non-nullable)
- Fonction `zzz` : modification de la logique pour [raison]
- RLS : nouvelle politique sur `table_abc` pour [rôle]
- Index : ajout de `idx_xxx` sur `table.colonne`

Mise à jour de docs/BACKEND_REFERENCE.md sections : X, Y, Z
```

> ⚠️ Un hook pre-commit **bloquera** le commit si `docs/BACKEND_REFERENCE.md` n'est pas inclus.

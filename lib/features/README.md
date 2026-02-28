# lib/features/

Modules métier isolés. Chaque feature suit la structure :

```
features/
  <module>/
    data/           # Repositories (wrappers DataService, appels Supabase)
    domain/         # Entités, validateurs, règles métier pures
    application/    # Providers Riverpod, state notifiers
    presentation/   # Screens, widgets, formulaires
```

## Features prévues

- `members/` — Gestion des fidèles
- `programs/` — Programmes et activités
- `accounting/` — Comptabilité SYCEBNL
- `dashboard/` — Tableau de bord et KPIs
- `auth/` — Authentification et profil utilisateur
- `church_structure/` — Structure ecclésiastique (régions/districts/assemblées)
- `reports/` — Rapports et états financiers

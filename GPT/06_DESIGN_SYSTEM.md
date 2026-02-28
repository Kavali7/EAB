# 🎨 DESIGN SYSTEM — Thème et Composants UI

## 1. Palette de couleurs actuelle

### Couleurs définies dans `AppColors` (`core/theme.dart`)

```dart
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF0B2E4B);    // Navy foncé
  static const Color secondary = Color(0xFFF2C94C);  // Doré/Jaune

  // Neutres
  static const Color background = Color(0xFFF5F7FA); // Gris très clair
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2933); // Charbon foncé
  static const Color textSecondary = Color(0xFF6B7280); // Gris moyen

  // États
  static const Color success = Color(0xFF16A34A);    // Vert
  static const Color warning = Color(0xFFEAB308);    // Jaune
  static const Color error = Color(0xFFDC2626);      // Rouge
  static const Color info = Color(0xFF2563EB);       // Bleu

  // Séparateurs
  static const Color divider = Color(0xFFE5E7EB);   // Gris clair
}
```

### Évaluation

| Aspect | Score | Commentaire |
| --- | --- | --- |
| Cohérence | 🟢 7/10 | Palette bien définie, peu de couleurs hors système |
| Modernité | 🟡 5/10 | Palette sobre mais peu dynamique, pas de dégradés |
| Identité | 🔴 3/10 | Pas de branding multi-tenant, couleurs fixes |
| Accessibilité | 🟡 6/10 | Contraste correct mais pas vérifié WCAG |

---

## 2. Typographie

### Styles via `AppTextStyles`

```dart
class AppTextStyles {
  static const TextStyle title = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const TextStyle subtitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontSize: 14);
  static const TextStyle secondary = TextStyle(fontSize: 13, color: AppColors.textSecondary);
}
```

### Évaluation

- ❌ Pas de police personnalisée (utilise la police système Flutter par défaut)
- ❌ Hiérarchie typographique limitée (seulement 5 styles)
- ❌ Pas de `headline`, `display`, `label`, `caption`

### Recommandation

Ajouter Google Fonts (Inter ou Poppins) et une échelle typographique complète.

---

## 3. Thème Material (`buildAppTheme()`)

### Configuration actuelle

```dart
ThemeData buildAppTheme() {
  return ThemeData.light().copyWith(
    // AppBar : fond navy, texte blanc
    appBarTheme: AppBarTheme(backgroundColor: primary, foregroundColor: white),

    // Boutons : fond navy, texte blanc, coins arrondis 8px
    elevatedButtonTheme: ...,

    // Inputs : bordure arrondie 6px, focus navy, padding 12x10
    inputDecorationTheme: ...,

    // Cards : fond blanc, elevation 1, coins arrondis 8px
    cardTheme: ...,

    // TabBar : label blanc, indicateur doré
    tabBarTheme: ...,

    // DataTable : en-tête bold, lignes hauteur 36px
    dataTableTheme: ...,

    // Scrollbar : navy semi-transparent
    scrollbarTheme: ...,
  );
}
```

### Évaluation

| Aspect | Score | Commentaire |
| --- | --- | --- |
| Couverture | 🟢 7/10 | Couvre AppBar, boutons, inputs, cards, tabs, tables |
| Homogénéité | 🟡 5/10 | Certains widgets n'utilisent pas le thème (styles en dur) |
| Personnalisation | 🔴 2/10 | Thème unique, pas dynamique par organisation |

---

## 4. Composants UI réutilisables

### 4.1 `AppShell` — Layout principal (248 lignes)

**Rôle** : Layout wrapper pour tous les écrans principaux de l'app.

**Structure** :

```
┌────────────────────────────────────────────────────┐
│ AppBar [Titre] [Profil ▼] [Assemblée active ▼]     │
├──────────┬─────────────────────────────────────────┤
│          │                                         │
│  Side    │                                         │
│  Nav     │           Body (contenu)                │
│  (240px) │                                         │
│          │                                         │
│          │                                         │
├──────────┴─────────────────────────────────────────┤
│ (optionnel: FAB)                                   │
└────────────────────────────────────────────────────┘
```

**Props** :

- `title` : Titre de la page
- `body` : Widget du contenu principal
- `currentRoute` : Route active pour la navigation
- `floatingActionButton` : FAB optionnel
- `actions` : Actions supplémentaires dans l'AppBar
- `bottom` : Widget sous l'AppBar (TabBar)

**Logique intégrée** :

- Chargement du profil utilisateur courant
- Calcul des assemblées autorisées selon le rôle
- Sélection d'assemblée active dans l'AppBar
- Responsive : sidebar fixe ≥1000px, drawer <1000px

### 4.2 `SideNavigation` — Menu latéral (125 lignes)

**Structure** :

```
┌──────────────────────┐
│ EAB                  │  ← Titre (navy, bold, 20px)
├──────────────────────┤
│ 📊 Tableau de bord   │  ← ListTile avec icône
│ 👥 Fidèles           │     (sélectionné = doré)
│ 📅 Programmes        │
│ 🏛️ Structure         │
│ 💰 Comptabilité      │
│ 🏦 Trésorerie        │
│ ↔️ Rapprochement     │
│ 📈 États & exports   │
│ 📄 Rapport mensuel   │
│ 📊 Budgets           │
│ 🏗️ Immobilisations   │
│ ⚙️ Paramétrage       │
├──────────────────────┤
│ 🚪 Déconnexion       │  ← Rouge
└──────────────────────┘
```

### 4.3 `ContextHeader` — En-tête contextuel (5KB)

Affiche les informations de l'assemblée active : nom, district, région, avec un style en bandeau.

### 4.4 `InfoCard` — Carte statistique (2KB)

Carte simple avec titre + valeur numérique + couleur. Utilisée sur le dashboard.

### 4.5 `SectionCard` — Carte de section (1KB)

Container avec titre et contenu enfant, utilisé pour regrouper visuellement des sections.

### 4.6 🆕 UI Kit (`lib/ui/`) — Design System Centralisé

Nouveau design system introduit pour remplacer les composants ad-hoc dupliqués dans chaque écran.

**Import unique** : `import 'package:eab/ui/ui.dart';`

| Composant | Fichier | Description |
| --- | --- | --- |
| `EabButton` | `ui/components/eab_button.dart` | 5 variantes (primary/secondary/outline/danger/ghost), 3 tailles, loading state |
| `EabTextField` | `ui/components/eab_text_field.dart` | Champ texte avec label, validation, prefix/suffix |
| `EabNumberField` | `ui/components/eab_text_field.dart` | Champ numérique avec formatage et filtrage |
| `EabSelectField<T>` | `ui/components/eab_select_field.dart` | Dropdown générique avec label et validation |
| `EabDateField` | `ui/components/eab_date_field.dart` | Sélecteur de date (date picker Material, format JJ/MM/AAAA) |
| `EabTable<T>` | `ui/components/eab_table.dart` | Tableau paginé avec tri, empty/loading/error states intégrés |
| `EabDialog` | `ui/components/eab_dialog.dart` | Dialog modal avec `show()` et `confirm()` statiques |
| `EabHierarchyFilter` | `ui/components/eab_hierarchy_filter.dart` | Filtres cascade Région→District→Assemblée |
| `EmptyState` | `ui/components/eab_state_widgets.dart` | État vide avec icône, message, action |
| `ErrorState` | `ui/components/eab_state_widgets.dart` | État erreur avec bouton "Réessayer" |
| `SkeletonLoader` | `ui/components/eab_state_widgets.dart` | Placeholder de chargement |
| `EabPageHeader` | `ui/layout/eab_page_header.dart` | En-tête de page (titre, sous-titre, icône, actions) |
| `AppSpacing` | `ui/theme/app_spacing.dart` | Constantes d'espacement (xs→xxxl, page, card, input, dialog) |

---

## 5. Patterns UI récurrents

### 5.1 Pattern des écrans de liste

Quasiment tous les écrans de liste (Membres, Programmes, Comptabilité) suivent le même pattern :

```
AppShell(
  title: 'Titre',
  body: Column(
    children: [
      // Filtres en haut (dropdowns, recherche)
      Row([DropdownRegion, DropdownDistrict, DropdownAssemblee, Search]),

      // Tableau paginé
      PaginatedDataTable(
        columns: [...],
        source: _CustomDataSource(...),
        rowsPerPage: 15,
      ),
    ],
  ),
  floatingActionButton: FAB(onPressed: _openForm),
)
```

### 5.2 Pattern des formulaires

Tous les formulaires utilisent un `Dialog` modal :

```dart
showDialog(
  context: context,
  builder: (_) => EntityFormDialog(existing: entity),
);
```

**Problèmes avec ce pattern** :

- Le dialog est trop petit pour les formulaires complexes (20+ champs pour les membres)
- Pas de sauvegarde du brouillon
- Difficile à utiliser sur mobile

### 5.3 Pattern des filtres hiérarchiques

Les filtres Région → District → Assemblée sont un pattern clé :

- Le changement de région réinitialise district et assemblée
- Le changement de district réinitialise l'assemblée
- Le rôle utilisateur verrouille certains filtres

---

## 6. Responsive actuel

| Largeur | Comportement |
| --- | --- |
| ≥ 1000px | Sidebar fixe 240px + contenu |
| < 1000px | Drawer (hamburger menu) |
| Breakpoints | mobile (0-599), tablet (600-1023), desktop (1024-1440), XL (1441+) |

**Problèmes** :

- Les tableaux `PaginatedDataTable` ne sont pas responsive (trop de colonnes sur mobile)
- Les filtres ne s'adaptent pas (toujours en Row, pas de wrap)
- Les formulaires Dialog ne s'adaptent pas à la taille de l'écran

---

## 7. Points critiques du design actuel

### Ce qui fonctionne ✅

- La palette navy/doré est distinctive et professionnelle
- La sidebar est claire et bien organisée
- Le système AppShell assure une cohérence de layout
- Les breakpoints responsive_framework sont bien définis

### Ce qui doit être amélioré 🔴

| Problème | Impact | Priorité | Statut |
| --- | --- | --- | --- |
| Pas de police personnalisée | Look générique | 🟠 Haute | ❌ À faire |
| Pas de micro-animations | Interface statique | 🟡 Moyenne | ❌ À faire |
| Tableaux PaginatedDataTable bruts | UX basique | 🔴 Critique | ✅ Résolu (`EabTable`) |
| Formulaires en Dialog | Inconfort sur mobile | 🔴 Critique | ✅ Résolu (`EabDialog`) |
| Pas de Dark Mode | Fonctionnalité attendue | 🟡 Moyenne | ❌ À faire |
| Cards du dashboard sans icônes | Peu attractif | 🟠 Haute | ✅ Résolu (`KpiCard`) |
| Pas de skeleton loading | Écrans vides | 🟠 Haute | ✅ Résolu (`SkeletonLoader`) |
| Pas d'illustrations / empty states | Data vides basiques | 🟡 Moyenne | ✅ Résolu (`EmptyState`) |
| Navigation ne montre pas la position | Pas de breadcrumb | 🟡 Moyenne | ❌ À faire |
| Pas de thème par organisation | Multi-tenant incomplet | 🔴 Critique | 🔶 Fondation posée (`OrganisationBranding`) |

---

## 8. UI Kit — Composants créés (`lib/ui/`)

Import unique : `import 'package:eab/ui/ui.dart';`

| Composant | Fichier | Description |
| --- | --- | --- |
| `AppSpacing` | `theme/app_spacing.dart` | Constantes d'espacement |
| `OrganisationBranding` | `theme/organisation_branding.dart` | Config multi-tenant |
| `EabButton` | `components/eab_button.dart` | 5 variantes, 3 tailles, loading |
| `EabTextField` | `components/eab_text_field.dart` | Champs texte + `EabNumberField` |
| `EabSelectField` | `components/eab_select_field.dart` | Dropdown générique |
| `EabDateField` | `components/eab_date_field.dart` | Sélecteur de date |
| `EabTable` | `components/eab_table.dart` | Tableau paginé, triable, états |
| `EabDialog` | `components/eab_dialog.dart` | Dialog + `show()` + `confirm()` |
| `EabHierarchyFilter` | `components/eab_hierarchy_filter.dart` | Filtres Région→District→Assemblée |
| `EmptyState` | `components/eab_state_widgets.dart` | État vide avec icône |
| `ErrorState` | `components/eab_state_widgets.dart` | État erreur avec retry |
| `SkeletonLoader` | `components/eab_state_widgets.dart` | Chargement animé |
| `KpiCard` | `components/kpi_card.dart` | Carte KPI avec tendance ↑↓ |
| `QuickActionCard` | `components/kpi_card.dart` | Raccourci d'action rapide |
| `EabPageHeader` | `layout/eab_page_header.dart` | En-tête de page réutilisable |

---

## 9. Recommandations restantes

1. **Adopter Google Fonts** (Inter ou Poppins) pour un look premium
2. **Ajouter des animations** : page transitions, micro-feedback
3. **Implémenter le thème dynamique par organisation** : alimentation depuis Supabase `organisations`
4. **Ajouter un mode sombre** professionnel
5. **Migrer les écrans restants** (Comptabilité, Structure église) vers le UI Kit

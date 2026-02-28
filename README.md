> [!CAUTION]
> **⚠️ BACKEND : Avant toute modification de la base de données, des fonctions, du RLS ou du Storage Supabase,
> consultez et mettez à jour [`docs/BACKEND_REFERENCE.md`](docs/BACKEND_REFERENCE.md).**
> C'est la source de vérité unique du backend. Voir aussi [`AGENTS.md`](AGENTS.md).

# EAB - Gestion d'Église et Comptabilité SYSCEBNL

## 📋 Présentation

**EAB** (Église - Administration - Budget) est une application de gestion complète destinée aux organisations ecclésiastiques. Elle permet de gérer :

- 🏛️ **Structure ecclésiastique** : Régions, Districts, Assemblées locales
- 👥 **Membres / Fidèles** : Informations personnelles, vie spirituelle, familles
- 📅 **Programmes / Activités** : Cultes, évangélisations, baptêmes, etc.
- 💰 **Comptabilité SYSCEBNL** : Conforme au Système Comptable des Entités à But Non Lucratif
- 📊 **Rapports mensuels** : Statistiques consolidées par assemblée

## 🏗️ Architecture technique

### Frontend
- **Framework** : Flutter (Dart)
- **State Management** : Riverpod
- **Modèles** : Freezed + JSON Serializable

### Backend
- **Base de données** : Supabase (PostgreSQL)
- **Authentification** : Supabase Auth (Email/Password + OAuth)
- **Stockage fichiers** : Supabase Storage
- **Sécurité** : Row Level Security (RLS) basée sur les rôles

## 👥 Rôles utilisateurs

| Rôle | Périmètre d'accès |
|------|-------------------|
| **Admin National** | Toutes les données de l'organisation |
| **Responsable Région** | Toutes les données de sa région |
| **Surintendant District** | Toutes les données de son district |
| **Trésorier Assemblée** | Données de son assemblée uniquement |

## 📁 Structure du projet

```
eab/
├── lib/
│   ├── core/           # Configuration, thème, services
│   ├── models/         # Modèles de données (Freezed)
│   ├── providers/      # State management (Riverpod)
│   ├── screens/        # Écrans de l'application
│   └── widgets/        # Widgets réutilisables
├── supabase/
│   └── migrations/     # Fichiers SQL de migration
├── docs/               # Documentation
├── test/               # Tests unitaires
└── web/                # Configuration web
```

## 🚀 Démarrage rapide

### Prérequis
- Flutter SDK 3.9+
- Compte Supabase

### Installation

```bash
# Cloner le projet
git clone <repository>

# Installer les dépendances
cd eab
flutter pub get

# Générer les fichiers Freezed
flutter pub run build_runner build

# Lancer l'application
flutter run
```

### Configuration Supabase

1. Créer un projet Supabase
2. Exécuter les migrations SQL (dans `supabase/migrations/`)
3. Configurer les variables d'environnement :
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

## 📚 Documentation

- [**📘 Référence Backend (OBLIGATOIRE)**](docs/BACKEND_REFERENCE.md)
- [Guide d'installation](docs/GUIDE_INSTALLATION.md)
- [Guide utilisateur](docs/GUIDE_UTILISATEUR.md)
- [Comptabilité SYSCEBNL](docs/comptabilite/PLAN_COMPTABLE_SYSCEBNL.md)
- [Structure ecclésiastique](docs/structure_eglise/ASSEMBLEES.md)

## 📄 Licence

Projet privé - Tous droits réservés.

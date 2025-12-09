-- ============================================================================
-- EAB Backend - 00001 Initial Schema
-- ============================================================================
-- Multi-tenancy + Structure ecclésiastique + Membres + Programmes
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Genre
CREATE TYPE gender AS ENUM ('male', 'female');

-- Statut matrimonial
CREATE TYPE statut_matrimonial AS ENUM (
    'celibataire', 'marie', 'veuf', 'veuve', 'divorce', 'separe'
);

-- Statut du fidèle
CREATE TYPE statut_fidele AS ENUM (
    'actif', 'inactif', 'parti', 'decede', 'transfere'
);

-- Rôle du fidèle dans l'église
CREATE TYPE role_fidele AS ENUM (
    'membre', 'pasteur', 'ancien', 'diacre', 'diaconesse', 
    'evangeliste', 'autre_officier'
);

-- Vulnérabilité
CREATE TYPE vulnerabilite_fidele AS ENUM (
    'orphelin', 'veuf', 'veuve', 'handicape', 'troisieme_age', 'autre'
);

-- Type de programme
CREATE TYPE type_programme AS ENUM (
    'culte', 'evangelisation_masse', 'evangelisation_porte_a_porte',
    'baptemes', 'mains_association', 'sainte_cene', 'reunion_priere',
    'mariage', 'discipline', 'visite', 'ecole_du_dimanche', 'autre'
);

-- Type de visite
CREATE TYPE type_visite AS ENUM (
    'fidele', 'autorite', 'partenaire', 'autre_assemblee', 'autre'
);

-- Rôle utilisateur
CREATE TYPE role_utilisateur AS ENUM (
    'admin_national', 'responsable_region', 'surintendant_district', 
    'tresorier_assemblee'
);

-- ============================================================================
-- ORGANIZATIONS (Multi-tenancy)
-- ============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    code TEXT UNIQUE,
    description TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE organizations IS 'Table principale pour le multi-tenancy. Chaque église/organisation a son espace isolé.';

-- ============================================================================
-- PROFILES (Linked to auth.users)
-- ============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    role role_utilisateur NOT NULL DEFAULT 'tresorier_assemblee',
    id_region UUID,
    id_district UUID,
    id_assemblee_locale UUID,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE profiles IS 'Profil utilisateur avec rôle et périmètre d''accès.';

-- ============================================================================
-- STRUCTURE EGLISE
-- ============================================================================

-- Régions
CREATE TABLE regions_eglise (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    nom TEXT NOT NULL,
    code TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(organization_id, code)
);

COMMENT ON TABLE regions_eglise IS 'Régions ecclésiastiques au niveau national.';

-- Districts
CREATE TABLE districts_eglise (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_region UUID NOT NULL REFERENCES regions_eglise(id) ON DELETE CASCADE,
    nom TEXT NOT NULL,
    code TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(organization_id, code)
);

COMMENT ON TABLE districts_eglise IS 'Districts au sein d''une région.';

-- Assemblées locales
CREATE TABLE assemblees_locales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_district UUID NOT NULL REFERENCES districts_eglise(id) ON DELETE CASCADE,
    nom TEXT NOT NULL,
    code TEXT,
    ville TEXT,
    quartier TEXT,
    adresse_postale TEXT,
    telephone TEXT,
    email TEXT,
    id_fidele_pasteur_responsable UUID, -- Will be FK after membres table is created
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(organization_id, code)
);

COMMENT ON TABLE assemblees_locales IS 'Assemblées locales (églises locales).';

-- ============================================================================
-- FAMILLES & MEMBRES
-- ============================================================================

-- Familles
CREATE TABLE familles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    nom TEXT NOT NULL,
    id_epoux UUID, -- Will be FK after membres table
    id_epouse UUID, -- Will be FK after membres table
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE familles IS 'Familles de fidèles pour le suivi familial.';

-- Membres
CREATE TABLE membres (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    id_famille UUID REFERENCES familles(id) ON DELETE SET NULL,
    
    -- Identité
    full_name TEXT NOT NULL,
    gender gender NOT NULL,
    date_naissance DATE,
    
    -- Contact
    phone TEXT,
    email TEXT,
    address TEXT,
    
    -- Vie spirituelle
    statut_matrimonial statut_matrimonial,
    date_conversion DATE,
    date_bapteme DATE,
    date_main_association DATE,
    
    -- Statut dans l'église
    statut statut_fidele NOT NULL DEFAULT 'actif',
    role role_fidele NOT NULL DEFAULT 'membre',
    date_entree DATE,
    date_sortie DATE,
    motif_sortie TEXT,
    date_deces DATE,
    
    -- Vulnérabilités (stockées en JSON pour flexibilité)
    vulnerabilites JSONB DEFAULT '[]'::jsonb,
    
    -- Photo
    photo_url TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE membres IS 'Membres/fidèles de l''église avec toutes leurs informations.';

-- Add foreign keys for circular references
ALTER TABLE assemblees_locales 
    ADD CONSTRAINT fk_assemblees_pasteur 
    FOREIGN KEY (id_fidele_pasteur_responsable) 
    REFERENCES membres(id) ON DELETE SET NULL;

ALTER TABLE familles 
    ADD CONSTRAINT fk_familles_epoux 
    FOREIGN KEY (id_epoux) REFERENCES membres(id) ON DELETE SET NULL;

ALTER TABLE familles 
    ADD CONSTRAINT fk_familles_epouse 
    FOREIGN KEY (id_epouse) REFERENCES membres(id) ON DELETE SET NULL;

-- Add foreign keys for profiles to reference structure
ALTER TABLE profiles
    ADD CONSTRAINT fk_profiles_region
    FOREIGN KEY (id_region) REFERENCES regions_eglise(id) ON DELETE SET NULL;

ALTER TABLE profiles
    ADD CONSTRAINT fk_profiles_district
    FOREIGN KEY (id_district) REFERENCES districts_eglise(id) ON DELETE SET NULL;

ALTER TABLE profiles
    ADD CONSTRAINT fk_profiles_assemblee
    FOREIGN KEY (id_assemblee_locale) REFERENCES assemblees_locales(id) ON DELETE SET NULL;

-- ============================================================================
-- PROGRAMMES / ACTIVITES
-- ============================================================================

CREATE TABLE programmes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    
    -- Informations de base
    type type_programme NOT NULL,
    date DATE NOT NULL,
    location TEXT NOT NULL,
    description TEXT,
    observations TEXT,
    
    -- Participants (IDs stockés en JSON)
    participant_ids JSONB DEFAULT '[]'::jsonb,
    
    -- Pour les visites
    type_visite type_visite,
    compte_rendu_visite TEXT,
    
    -- Statistiques de fréquentation
    nombre_hommes INTEGER DEFAULT 0,
    nombre_femmes INTEGER DEFAULT 0,
    nombre_garcons INTEGER DEFAULT 0,
    nombre_filles INTEGER DEFAULT 0,
    
    -- Conversions
    conversions_hommes INTEGER DEFAULT 0,
    conversions_femmes INTEGER DEFAULT 0,
    conversions_garcons INTEGER DEFAULT 0,
    conversions_filles INTEGER DEFAULT 0,
    
    -- École du dimanche
    nombre_classes_ecole_dimanche INTEGER DEFAULT 0,
    nombre_moniteurs_hommes INTEGER DEFAULT 0,
    nombre_monitrices_femmes INTEGER DEFAULT 0,
    derniere_lecon_ecole_dimanche TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE programmes IS 'Activités et programmes de l''église (cultes, évangélisations, etc.).';

-- ============================================================================
-- Enable RLS on all tables
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions_eglise ENABLE ROW LEVEL SECURITY;
ALTER TABLE districts_eglise ENABLE ROW LEVEL SECURITY;
ALTER TABLE assemblees_locales ENABLE ROW LEVEL SECURITY;
ALTER TABLE familles ENABLE ROW LEVEL SECURITY;
ALTER TABLE membres ENABLE ROW LEVEL SECURITY;
ALTER TABLE programmes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Grant permissions to authenticated users
-- ============================================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

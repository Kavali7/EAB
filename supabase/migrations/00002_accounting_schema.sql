-- ============================================================================
-- EAB Backend - 00002 Accounting Schema (SYCEBNL)
-- ============================================================================
-- Comptabilité conforme au Système Comptable des Entités à But Non Lucratif
-- ============================================================================

-- ============================================================================
-- ENUMS COMPTABLES
-- ============================================================================

-- Nature des comptes comptables
CREATE TYPE nature_compte AS ENUM (
    'actif', 'passif', 'charge', 'produit', 
    'hors_activite_ordinaire', 'engagement', 'autre'
);

-- Type de journal comptable
CREATE TYPE type_journal_comptable AS ENUM (
    'caisse', 'banque', 'operations_diverses'
);

-- Type de tiers
CREATE TYPE type_tiers AS ENUM (
    'membre', 'fournisseur', 'bailleur', 'employe', 'partenaire', 'autre'
);

-- Type de centre analytique
CREATE TYPE type_centre_analytique AS ENUM (
    'assemblee_locale', 'projet', 'activite', 'departement', 'autre'
);

-- Mode de paiement
CREATE TYPE mode_paiement AS ENUM (
    'especes', 'cheque', 'virement_bancaire', 'mobile_money', 'microfinance', 'autre'
);

-- Type d'immobilisation
CREATE TYPE type_immobilisation AS ENUM (
    'terrain', 'batiment', 'mobilier', 'materiel_informatique',
    'materiel_sono', 'vehicule', 'autre'
);

-- Statut d'écriture comptable
CREATE TYPE statut_ecriture AS ENUM (
    'brouillon', 'validee', 'cloturee'
);

-- ============================================================================
-- PLAN COMPTABLE
-- ============================================================================

CREATE TABLE comptes_comptables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    numero TEXT NOT NULL, -- Numéro du compte (ex: "5121", "701")
    intitule TEXT NOT NULL, -- Libellé du compte
    nature nature_compte NOT NULL,
    niveau INTEGER DEFAULT 1, -- 1=classe, 2=compte, 3=sous-compte
    id_compte_parent UUID REFERENCES comptes_comptables(id) ON DELETE SET NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, numero)
);

COMMENT ON TABLE comptes_comptables IS 'Plan comptable conforme SYCEBNL.';

-- ============================================================================
-- JOURNAUX COMPTABLES
-- ============================================================================

CREATE TABLE journaux_comptables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    code TEXT NOT NULL, -- ex: "CAI", "BAN", "OD"
    intitule TEXT NOT NULL, -- ex: "Journal de caisse"
    type type_journal_comptable NOT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, code)
);

COMMENT ON TABLE journaux_comptables IS 'Journaux comptables (caisse, banque, OD).';

-- ============================================================================
-- CENTRES ANALYTIQUES
-- ============================================================================

CREATE TABLE centres_analytiques (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    
    code TEXT NOT NULL, -- ex: "ASS-COT-CENTRE", "PROJ-EV-2025"
    nom TEXT NOT NULL,
    type type_centre_analytique NOT NULL,
    description TEXT,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, code)
);

COMMENT ON TABLE centres_analytiques IS 'Centres analytiques pour la comptabilité analytique.';

-- ============================================================================
-- TIERS
-- ============================================================================

CREATE TABLE tiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    id_fidele_lie UUID REFERENCES membres(id) ON DELETE SET NULL,
    
    nom TEXT NOT NULL,
    type type_tiers NOT NULL,
    telephone TEXT,
    email TEXT,
    adresse TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE tiers IS 'Fournisseurs, bailleurs, partenaires et autres tiers.';

-- ============================================================================
-- ECRITURES COMPTABLES
-- ============================================================================

CREATE TABLE ecritures_comptables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    id_journal UUID NOT NULL REFERENCES journaux_comptables(id) ON DELETE RESTRICT,
    id_centre_analytique_principal UUID REFERENCES centres_analytiques(id) ON DELETE SET NULL,
    
    date DATE NOT NULL,
    reference_piece TEXT, -- Référence de la pièce justificative
    libelle TEXT NOT NULL,
    statut statut_ecriture NOT NULL DEFAULT 'brouillon',
    
    -- Pièce justificative (URL vers Storage)
    piece_justificative_url TEXT,
    
    -- Auteur
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    validated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    validated_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ecritures_comptables IS 'En-têtes des écritures comptables.';

-- ============================================================================
-- LIGNES D'ECRITURES COMPTABLES
-- ============================================================================

CREATE TABLE lignes_ecritures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_ecriture UUID NOT NULL REFERENCES ecritures_comptables(id) ON DELETE CASCADE,
    id_compte_comptable UUID NOT NULL REFERENCES comptes_comptables(id) ON DELETE RESTRICT,
    id_centre_analytique UUID REFERENCES centres_analytiques(id) ON DELETE SET NULL,
    id_tiers UUID REFERENCES tiers(id) ON DELETE SET NULL,
    
    libelle TEXT,
    debit DECIMAL(15,2) DEFAULT 0,
    credit DECIMAL(15,2) DEFAULT 0,
    mode_paiement mode_paiement,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Contrainte: soit débit, soit crédit, pas les deux
    CONSTRAINT check_debit_ou_credit CHECK (
        (debit > 0 AND credit = 0) OR (debit = 0 AND credit > 0) OR (debit = 0 AND credit = 0)
    )
);

COMMENT ON TABLE lignes_ecritures IS 'Lignes débit/crédit des écritures comptables.';

-- ============================================================================
-- BUDGETS
-- ============================================================================

CREATE TABLE budgets_comptables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    id_centre_analytique UUID REFERENCES centres_analytiques(id) ON DELETE SET NULL,
    id_tiers_bailleur UUID REFERENCES tiers(id) ON DELETE SET NULL,
    
    exercice INTEGER NOT NULL, -- Année budgétaire
    libelle TEXT,
    est_verrouille BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, exercice, id_assemblee_locale, id_centre_analytique)
);

COMMENT ON TABLE budgets_comptables IS 'Budgets par exercice et périmètre.';

-- Lignes de budget
CREATE TABLE lignes_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_budget UUID NOT NULL REFERENCES budgets_comptables(id) ON DELETE CASCADE,
    id_compte_comptable UUID NOT NULL REFERENCES comptes_comptables(id) ON DELETE RESTRICT,
    
    montant_prevu DECIMAL(15,2) NOT NULL DEFAULT 0,
    montant_revu DECIMAL(15,2),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(id_budget, id_compte_comptable)
);

COMMENT ON TABLE lignes_budgets IS 'Détail des lignes budgétaires par compte.';

-- ============================================================================
-- IMMOBILISATIONS
-- ============================================================================

CREATE TABLE immobilisations_comptables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    id_centre_analytique UUID REFERENCES centres_analytiques(id) ON DELETE SET NULL,
    
    libelle TEXT NOT NULL,
    type type_immobilisation NOT NULL,
    date_acquisition DATE NOT NULL,
    valeur_acquisition DECIMAL(15,2) NOT NULL,
    valeur_residuelle DECIMAL(15,2),
    duree_utilite_en_annees INTEGER NOT NULL,
    
    -- Comptes liés
    id_compte_immobilisation UUID REFERENCES comptes_comptables(id) ON DELETE RESTRICT,
    id_compte_amortissement UUID REFERENCES comptes_comptables(id) ON DELETE SET NULL,
    id_compte_dotation UUID REFERENCES comptes_comptables(id) ON DELETE SET NULL,
    
    -- Sortie
    est_sortie BOOLEAN NOT NULL DEFAULT FALSE,
    date_sortie DATE,
    valeur_cession DECIMAL(15,2),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE immobilisations_comptables IS 'Actifs immobilisés avec suivi des amortissements.';

-- ============================================================================
-- RAPPORTS MENSUELS EAB
-- ============================================================================

CREATE TABLE rapports_mensuels_eab (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID NOT NULL REFERENCES assemblees_locales(id) ON DELETE CASCADE,
    
    annee INTEGER NOT NULL,
    mois INTEGER NOT NULL CHECK (mois >= 1 AND mois <= 12),
    
    -- Statistiques membres (JSONB pour flexibilité)
    stats_membres JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Statistiques activités (JSONB)
    stats_activites JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Statistiques financières (JSONB)
    stats_finances JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Champs texte
    resume_activites TEXT,
    projets_realisations TEXT,
    projets_mois_suivant TEXT,
    observations TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, id_assemblee_locale, annee, mois)
);

COMMENT ON TABLE rapports_mensuels_eab IS 'Rapports mensuels consolidés par assemblée.';

-- ============================================================================
-- RELEVES BANCAIRES (pour rapprochement)
-- ============================================================================

CREATE TABLE releves_bancaires (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
    id_journal_banque UUID REFERENCES journaux_comptables(id) ON DELETE RESTRICT,
    
    date_releve DATE NOT NULL,
    solde_initial DECIMAL(15,2) NOT NULL DEFAULT 0,
    solde_final DECIMAL(15,2) NOT NULL DEFAULT 0,
    fichier_url TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE releves_bancaires IS 'Relevés bancaires pour rapprochement.';

-- ============================================================================
-- Enable RLS on all accounting tables
-- ============================================================================

ALTER TABLE comptes_comptables ENABLE ROW LEVEL SECURITY;
ALTER TABLE journaux_comptables ENABLE ROW LEVEL SECURITY;
ALTER TABLE centres_analytiques ENABLE ROW LEVEL SECURITY;
ALTER TABLE tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecritures_comptables ENABLE ROW LEVEL SECURITY;
ALTER TABLE lignes_ecritures ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets_comptables ENABLE ROW LEVEL SECURITY;
ALTER TABLE lignes_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE immobilisations_comptables ENABLE ROW LEVEL SECURITY;
ALTER TABLE rapports_mensuels_eab ENABLE ROW LEVEL SECURITY;
ALTER TABLE releves_bancaires ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Grant permissions
-- ============================================================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

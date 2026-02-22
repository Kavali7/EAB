-- ============================================================================
-- EAB Backend - 00005 Indexes
-- ============================================================================
-- Indexes pour optimiser les performances des requêtes
-- ============================================================================

-- ============================================================================
-- ORGANIZATIONS
-- ============================================================================
CREATE INDEX idx_organizations_code ON organizations(code);

-- ============================================================================
-- PROFILES
-- ============================================================================
CREATE INDEX idx_profiles_organization ON profiles(organization_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_region ON profiles(id_region);
CREATE INDEX idx_profiles_district ON profiles(id_district);
CREATE INDEX idx_profiles_assemblee ON profiles(id_assemblee_locale);

-- ============================================================================
-- REGIONS
-- ============================================================================
CREATE INDEX idx_regions_organization ON regions_eglise(organization_id);
CREATE INDEX idx_regions_code ON regions_eglise(organization_id, code);

-- ============================================================================
-- DISTRICTS
-- ============================================================================
CREATE INDEX idx_districts_organization ON districts_eglise(organization_id);
CREATE INDEX idx_districts_region ON districts_eglise(id_region);
CREATE INDEX idx_districts_code ON districts_eglise(organization_id, code);

-- ============================================================================
-- ASSEMBLEES LOCALES
-- ============================================================================
CREATE INDEX idx_assemblees_organization ON assemblees_locales(organization_id);
CREATE INDEX idx_assemblees_district ON assemblees_locales(id_district);
CREATE INDEX idx_assemblees_code ON assemblees_locales(organization_id, code);
CREATE INDEX idx_assemblees_pasteur ON assemblees_locales(id_fidele_pasteur_responsable);

-- ============================================================================
-- FAMILLES
-- ============================================================================
CREATE INDEX idx_familles_organization ON familles(organization_id);
CREATE INDEX idx_familles_assemblee ON familles(id_assemblee_locale);

-- ============================================================================
-- MEMBRES
-- ============================================================================
CREATE INDEX idx_membres_organization ON membres(organization_id);
CREATE INDEX idx_membres_assemblee ON membres(id_assemblee_locale);
CREATE INDEX idx_membres_famille ON membres(id_famille);
CREATE INDEX idx_membres_statut ON membres(statut);
CREATE INDEX idx_membres_role ON membres(role);
CREATE INDEX idx_membres_full_name ON membres(full_name);
CREATE INDEX idx_membres_phone ON membres(phone);
CREATE INDEX idx_membres_email ON membres(email);
-- Enable pg_trgm extension for fuzzy search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Full text search on name
CREATE INDEX idx_membres_full_name_trgm ON membres USING gin (full_name gin_trgm_ops);

-- ============================================================================
-- PROGRAMMES
-- ============================================================================
CREATE INDEX idx_programmes_organization ON programmes(organization_id);
CREATE INDEX idx_programmes_assemblee ON programmes(id_assemblee_locale);
CREATE INDEX idx_programmes_type ON programmes(type);
CREATE INDEX idx_programmes_date ON programmes(date);
CREATE INDEX idx_programmes_assemblee_date ON programmes(id_assemblee_locale, date);

-- ============================================================================
-- COMPTES COMPTABLES
-- ============================================================================
CREATE INDEX idx_comptes_organization ON comptes_comptables(organization_id);
CREATE INDEX idx_comptes_numero ON comptes_comptables(organization_id, numero);
CREATE INDEX idx_comptes_nature ON comptes_comptables(nature);
CREATE INDEX idx_comptes_parent ON comptes_comptables(id_compte_parent);
CREATE INDEX idx_comptes_actif ON comptes_comptables(actif);

-- ============================================================================
-- JOURNAUX COMPTABLES
-- ============================================================================
CREATE INDEX idx_journaux_organization ON journaux_comptables(organization_id);
CREATE INDEX idx_journaux_code ON journaux_comptables(organization_id, code);
CREATE INDEX idx_journaux_type ON journaux_comptables(type);

-- ============================================================================
-- CENTRES ANALYTIQUES
-- ============================================================================
CREATE INDEX idx_centres_organization ON centres_analytiques(organization_id);
CREATE INDEX idx_centres_assemblee ON centres_analytiques(id_assemblee_locale);
CREATE INDEX idx_centres_code ON centres_analytiques(organization_id, code);
CREATE INDEX idx_centres_type ON centres_analytiques(type);

-- ============================================================================
-- TIERS
-- ============================================================================
CREATE INDEX idx_tiers_organization ON tiers(organization_id);
CREATE INDEX idx_tiers_assemblee ON tiers(id_assemblee_locale);
CREATE INDEX idx_tiers_type ON tiers(type);
CREATE INDEX idx_tiers_fidele ON tiers(id_fidele_lie);

-- ============================================================================
-- ECRITURES COMPTABLES
-- ============================================================================
CREATE INDEX idx_ecritures_organization ON ecritures_comptables(organization_id);
CREATE INDEX idx_ecritures_assemblee ON ecritures_comptables(id_assemblee_locale);
CREATE INDEX idx_ecritures_journal ON ecritures_comptables(id_journal);
CREATE INDEX idx_ecritures_date ON ecritures_comptables(date);
CREATE INDEX idx_ecritures_statut ON ecritures_comptables(statut);
CREATE INDEX idx_ecritures_assemblee_date ON ecritures_comptables(id_assemblee_locale, date);
CREATE INDEX idx_ecritures_created_by ON ecritures_comptables(created_by);

-- ============================================================================
-- LIGNES ECRITURES
-- ============================================================================
CREATE INDEX idx_lignes_ecriture ON lignes_ecritures(id_ecriture);
CREATE INDEX idx_lignes_compte ON lignes_ecritures(id_compte_comptable);
CREATE INDEX idx_lignes_centre ON lignes_ecritures(id_centre_analytique);
CREATE INDEX idx_lignes_tiers ON lignes_ecritures(id_tiers);

-- ============================================================================
-- BUDGETS
-- ============================================================================
CREATE INDEX idx_budgets_organization ON budgets_comptables(organization_id);
CREATE INDEX idx_budgets_assemblee ON budgets_comptables(id_assemblee_locale);
CREATE INDEX idx_budgets_exercice ON budgets_comptables(exercice);
CREATE INDEX idx_budgets_centre ON budgets_comptables(id_centre_analytique);

-- ============================================================================
-- LIGNES BUDGETS
-- ============================================================================
CREATE INDEX idx_lignes_budgets_budget ON lignes_budgets(id_budget);
CREATE INDEX idx_lignes_budgets_compte ON lignes_budgets(id_compte_comptable);

-- ============================================================================
-- IMMOBILISATIONS
-- ============================================================================
CREATE INDEX idx_immobilisations_organization ON immobilisations_comptables(organization_id);
CREATE INDEX idx_immobilisations_assemblee ON immobilisations_comptables(id_assemblee_locale);
CREATE INDEX idx_immobilisations_type ON immobilisations_comptables(type);
CREATE INDEX idx_immobilisations_date_acquisition ON immobilisations_comptables(date_acquisition);
CREATE INDEX idx_immobilisations_sortie ON immobilisations_comptables(est_sortie);

-- ============================================================================
-- RAPPORTS MENSUELS
-- ============================================================================
CREATE INDEX idx_rapports_organization ON rapports_mensuels_eab(organization_id);
CREATE INDEX idx_rapports_assemblee ON rapports_mensuels_eab(id_assemblee_locale);
CREATE INDEX idx_rapports_periode ON rapports_mensuels_eab(annee, mois);
CREATE INDEX idx_rapports_assemblee_periode ON rapports_mensuels_eab(id_assemblee_locale, annee, mois);

-- ============================================================================
-- RELEVES BANCAIRES
-- ============================================================================
CREATE INDEX idx_releves_organization ON releves_bancaires(organization_id);
CREATE INDEX idx_releves_assemblee ON releves_bancaires(id_assemblee_locale);
CREATE INDEX idx_releves_date ON releves_bancaires(date_releve);
CREATE INDEX idx_releves_journal ON releves_bancaires(id_journal_banque);

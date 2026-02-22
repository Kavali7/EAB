-- ============================================================================
-- EAB Backend - Reset Demo Data
-- ============================================================================
-- Script pour réinitialiser la base de données après une démonstration client
-- Supprime toutes les données de démo mais garde la structure et l'admin
-- ============================================================================

-- ============================================================================
-- ATTENTION : CE SCRIPT SUPPRIME TOUTES LES DONNÉES !
-- À utiliser uniquement après validation du client
-- ============================================================================

BEGIN;

-- Désactiver temporairement les triggers d'audit pour éviter la surcharge
ALTER TABLE membres DISABLE TRIGGER audit_membres_trigger;
ALTER TABLE ecritures_comptables DISABLE TRIGGER audit_ecritures_trigger;

-- ============================================================================
-- SUPPRESSION DES DONNÉES (dans l'ordre des dépendances)
-- ============================================================================

-- Audit logs (vider l'historique)
TRUNCATE TABLE audit_logs RESTART IDENTITY CASCADE;

-- Comptabilité - Détails
TRUNCATE TABLE lignes_ecritures RESTART IDENTITY CASCADE;
TRUNCATE TABLE lignes_budgets RESTART IDENTITY CASCADE;
TRUNCATE TABLE lignes_releves_bancaires RESTART IDENTITY CASCADE;

-- Comptabilité - En-têtes
TRUNCATE TABLE ecritures_comptables RESTART IDENTITY CASCADE;
TRUNCATE TABLE budgets_comptables RESTART IDENTITY CASCADE;
TRUNCATE TABLE immobilisations_comptables RESTART IDENTITY CASCADE;
TRUNCATE TABLE releves_bancaires RESTART IDENTITY CASCADE;
TRUNCATE TABLE rapports_mensuels_eab RESTART IDENTITY CASCADE;

-- Séquences
TRUNCATE TABLE sequences_pieces RESTART IDENTITY CASCADE;

-- Tiers
TRUNCATE TABLE tiers RESTART IDENTITY CASCADE;

-- Programmes
TRUNCATE TABLE programmes RESTART IDENTITY CASCADE;

-- Membres et familles
TRUNCATE TABLE membres RESTART IDENTITY CASCADE;
TRUNCATE TABLE familles RESTART IDENTITY CASCADE;

-- Note: On garde la structure (régions, districts, assemblées)
-- et les référentiels (comptes, journaux, centres analytiques)

-- Réinitialiser les exercices comptables
UPDATE exercices_comptables SET est_cloture = FALSE, est_ouvert = TRUE, cloture_par = NULL, cloture_at = NULL;

-- ============================================================================
-- RÉACTIVER LES TRIGGERS
-- ============================================================================

ALTER TABLE membres ENABLE TRIGGER audit_membres_trigger;
ALTER TABLE ecritures_comptables ENABLE TRIGGER audit_ecritures_trigger;

COMMIT;

-- ============================================================================
-- MESSAGE DE CONFIRMATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Réinitialisation terminée avec succès !';
    RAISE NOTICE '📋 Les éléments suivants ont été conservés :';
    RAISE NOTICE '   - Organisation';
    RAISE NOTICE '   - Structure ecclésiastique (régions, districts, assemblées)';
    RAISE NOTICE '   - Plan comptable';
    RAISE NOTICE '   - Journaux comptables';
    RAISE NOTICE '   - Centres analytiques';
    RAISE NOTICE '   - Exercices comptables (réouverts)';
    RAISE NOTICE '   - Profils utilisateurs';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Les éléments suivants ont été supprimés :';
    RAISE NOTICE '   - Membres / Fidèles';
    RAISE NOTICE '   - Familles';
    RAISE NOTICE '   - Programmes / Activités';
    RAISE NOTICE '   - Écritures comptables';
    RAISE NOTICE '   - Budgets et lignes';
    RAISE NOTICE '   - Immobilisations';
    RAISE NOTICE '   - Tiers';
    RAISE NOTICE '   - Logs d''audit';
END $$;

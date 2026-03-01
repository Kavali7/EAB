-- ============================================================================
-- TEST RLS MULTI-TENANT : isolation inter-organisations
-- ============================================================================
-- Ce script vérifie que les politiques RLS empêchent un utilisateur d'une
-- organisation d'accéder aux données d'une autre organisation.
--
-- À exécuter manuellement dans le SQL Editor Supabase.
-- Créez 2 organisations et 2 utilisateurs de test si nécessaire.
-- ============================================================================

-- 1. Vérifier que TOUTES les tables métier ont RLS activé
SELECT
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'membres', 'familles', 'programmes',
    'comptes_comptables', 'journaux_comptables',
    'ecritures_comptables', 'lignes_ecritures',
    'exercices_comptables', 'budgets_comptables',
    'immobilisations_comptables', 'tiers',
    'releves_bancaires', 'rapports_mensuels_eab',
    'audit_logs'
  )
ORDER BY tablename;
-- ATTENDU : rowsecurity = true pour TOUTES les lignes

-- 2. Lister les policies par table
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 3. Compter les policies par table (chaque table doit en avoir >= 1)
SELECT
  tablename,
  COUNT(*) AS nb_policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY nb_policies ASC;
-- ⚠️ ALERTE : si une table a 0 policy → fuite potentielle

-- 4. Vérifier l'isolation des données (à adapter avec vos IDs réels)
-- Remplacez les UUIDs par ceux de vos organisations de test

-- Test avec l'utilisateur de l'org A :
-- SET LOCAL request.jwt.claims = '{"sub":"<user_a_id>", "role":"authenticated"}';
-- SELECT COUNT(*) FROM membres WHERE organization_id = '<org_b_id>';
-- ATTENDU : 0 (l'utilisateur A ne voit pas les membres de l'org B)

-- 5. Vérifier que les RPCs respectent aussi l'isolation
-- L'utilisateur A ne devrait pas pouvoir appeler :
-- SELECT * FROM get_exercice_ouvert('<org_b_id>');
-- ATTENDU : aucun résultat (SECURITY DEFINER mais filtré par org_id)

-- 6. Récapitulatif des tables SANS RLS (devrait être vide pour les tables métier)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT IN ('schema_migrations')
  AND tablename NOT IN (
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true
  )
ORDER BY tablename;
-- ATTENDU : seules tables techniques (migrations, etc.)

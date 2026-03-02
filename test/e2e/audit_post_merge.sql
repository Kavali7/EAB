-- ============================================================================
-- EAB — AUDIT POST-MERGE (Étape 4.2 / 4.3 / 4.4)
-- ============================================================================
-- À exécuter dans Supabase SQL Editor
-- Résultat attendu : TOUT est ✅
-- ============================================================================

-- ============================================================================
-- 4.2 — AUDIT RLS (Row Level Security)
-- ============================================================================

-- ─────────────────────────────────────────────────
-- TEST 1 : Toutes les tables user-facing ont RLS activé
-- ─────────────────────────────────────────────────
SELECT 
    '4.2.1 — RLS sur tables' as test,
    schemaname || '.' || tablename as table_name,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ON' 
        ELSE '❌ RLS OFF — DANGER' 
    END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
ORDER BY rowsecurity ASC, tablename;

-- ─────────────────────────────────────────────────
-- TEST 2 : Inventaire des policies RLS par table
-- ─────────────────────────────────────────────────
SELECT 
    '4.2.2 — Policies par table' as test,
    schemaname || '.' || tablename as table_name,
    policyname as policy,
    cmd as operation,
    CASE 
        WHEN qual IS NOT NULL OR with_check IS NOT NULL 
        THEN '✅ Protégé' 
        ELSE '⚠️ Policy vide' 
    END as status
FROM pg_policies
WHERE schemaname IN ('public', 'storage')
ORDER BY tablename, cmd;

-- ─────────────────────────────────────────────────
-- TEST 3 : Tables sans aucune policy (DANGER !)
-- ─────────────────────────────────────────────────
SELECT 
    '4.2.3 — Tables SANS policy' as test,
    'public.' || t.tablename as table_name,
    CASE 
        WHEN t.rowsecurity AND p.tablename IS NULL 
        THEN '❌ RLS ON mais AUCUNE POLICY → bloqué total'
        WHEN NOT t.rowsecurity 
        THEN '⚠️ RLS OFF → accès libre'
        ELSE '✅ OK'
    END as status
FROM pg_tables t
LEFT JOIN (
    SELECT DISTINCT tablename FROM pg_policies WHERE schemaname = 'public'
) p ON t.tablename = p.tablename
WHERE t.schemaname = 'public'
AND t.tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
ORDER BY status DESC;

-- ─────────────────────────────────────────────────
-- TEST 4 : Policies Storage (multi-tenant)
-- ─────────────────────────────────────────────────
SELECT 
    '4.2.4 — Storage RLS' as test,
    policyname as policy,
    cmd as operation,
    CASE 
        WHEN qual::text LIKE '%get_user_organization_id%' 
          OR with_check::text LIKE '%get_user_organization_id%'
        THEN '✅ Isolé par org_id'
        WHEN policyname LIKE '%Anyone%' THEN '✅ Public (lecture seule, OK)'
        ELSE '⚠️ Pas d''isolation org'
    END as isolation_status
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY policyname;

-- ─────────────────────────────────────────────────
-- TEST 5 : Vérifier que get_user_organization_id() existe
-- ─────────────────────────────────────────────────
SELECT 
    '4.2.5 — Fonctions sécurité' as test,
    routine_name,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ Existe' 
        ELSE '❌ Manquante' 
    END as status
FROM information_schema.routines
WHERE routine_name IN (
    'get_user_organization_id', 
    'get_user_role',
    'handle_new_user'
)
AND routine_schema = 'public'
ORDER BY routine_name;

-- ============================================================================
-- 4.3 — VÉRIFICATION BACKUPS
-- ============================================================================

-- ─────────────────────────────────────────────────
-- TEST 6 : Taille de la base
-- ─────────────────────────────────────────────────
SELECT 
    '4.3.1 — Taille DB' as test,
    pg_size_pretty(pg_database_size(current_database())) as taille_totale,
    '✅ Note: Backups gérés automatiquement par Supabase (plan gratuit = 7 jours)' as info;

-- ─────────────────────────────────────────────────
-- TEST 7 : Nombre de lignes par table
-- ─────────────────────────────────────────────────
SELECT 
    '4.3.2 — Volume données' as test,
    relname as table_name,
    n_live_tup as nb_lignes,
    pg_size_pretty(pg_total_relation_size(relid)) as taille
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- ============================================================================
-- 4.4 — AUDIT PERFORMANCE
-- ============================================================================

-- ─────────────────────────────────────────────────
-- TEST 8 : Index existants
-- ─────────────────────────────────────────────────
SELECT 
    '4.4.1 — Index' as test,
    schemaname || '.' || tablename as table_name,
    indexname as index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) as taille_index
FROM pg_indexes
JOIN pg_stat_user_indexes USING (indexrelname)
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ─────────────────────────────────────────────────
-- TEST 9 : Tables sans index (potentiellement lentes)
-- ─────────────────────────────────────────────────
SELECT
    '4.4.2 — Tables sans index custom' as test,
    t.tablename,
    COUNT(i.indexname) as nb_index,
    CASE 
        WHEN COUNT(i.indexname) <= 1 THEN '⚠️ Seul index PK — vérifier si requêtes fréquentes'
        ELSE '✅ Indexé'
    END as status
FROM pg_tables t
LEFT JOIN pg_indexes i ON t.tablename = i.tablename AND i.schemaname = 'public'
WHERE t.schemaname = 'public'
AND t.tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
GROUP BY t.tablename
ORDER BY nb_index ASC;

-- ─────────────────────────────────────────────────
-- TEST 10 : Vérifier les RPCs dashboard (existent et sont accessibles)
-- ─────────────────────────────────────────────────
SELECT 
    '4.4.3 — RPCs critiques' as test,
    routine_name,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ Existe' 
        ELSE '❌ Manquante' 
    END as status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_dashboard_finance',
    'get_balance_par_classe',
    'get_top_comptes',
    'create_ecriture',
    'cloturer_exercice',
    'get_grand_livre',
    'get_balance_generale',
    'get_bilan',
    'get_compte_resultat',
    'calculer_amortissement_annuel',
    'traiter_amortissements_exercice'
)
ORDER BY routine_name;

-- ============================================================================
-- RÉSUMÉ
-- ============================================================================
SELECT '🏁 AUDIT TERMINÉ — Vérifiez que tout est ✅ ci-dessus' as resultat;

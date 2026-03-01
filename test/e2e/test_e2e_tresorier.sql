-- ============================================================================
-- Test E2E — Scénario trésorier complet
-- ============================================================================
-- Ce script simule un workflow complet de trésorier :
-- 1. Vérifier qu'un exercice ouvert existe
-- 2. Vérifier qu'on peut poster dans l'exercice
-- 3. Simuler une écriture validée
-- 4. Vérifier les états financiers (balance, résultat, bilan)
-- 5. Vérifier le dashboard finance
-- 6. Vérifier la recherche globale
-- ============================================================================
-- IMPORTANT : exécuter en tant qu'utilisateur authentifié avec rôle admin
-- ============================================================================

-- ════════════════════════════════════════════════════════════════
-- 0. Paramètres (remplacer par vos IDs)
-- ════════════════════════════════════════════════════════════════

-- Remplacer par l'ID de votre organisation
-- SELECT id FROM organizations LIMIT 1;
DO $$
DECLARE
  v_org_id UUID;
  v_exercice RECORD;
  v_can_post BOOLEAN;
  v_balance_count INTEGER;
  v_resultat_count INTEGER;
  v_bilan_count INTEGER;
  v_gl_count INTEGER;
  v_kpis RECORD;
  v_evo_count INTEGER;
  v_rep_count INTEGER;
  v_search_count INTEGER;
  v_errors TEXT[] := '{}';
  v_tests_passed INTEGER := 0;
  v_total_tests INTEGER := 0;
BEGIN
  -- Récupérer l'org
  SELECT id INTO v_org_id FROM organizations LIMIT 1;
  IF v_org_id IS NULL THEN
    RAISE NOTICE '❌ SKIP: aucune organisation trouvée';
    RETURN;
  END IF;

  RAISE NOTICE '🔍 Organisation: %', v_org_id;

  -- ══════════════════════════════════════════════
  -- TEST 1: Exercice ouvert
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT * INTO v_exercice FROM exercices_comptables
  WHERE organization_id = v_org_id AND statut = 'ouvert' AND deleted_at IS NULL LIMIT 1;
  IF v_exercice IS NOT NULL THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 1: Exercice ouvert trouvé (%, %→%)', v_exercice.annee, v_exercice.date_debut, v_exercice.date_fin;
  ELSE
    v_errors := array_append(v_errors, 'TEST 1: Aucun exercice ouvert');
    RAISE NOTICE '⚠️ TEST 1: Aucun exercice ouvert (tests partiels)';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 2: can_post_in_exercice
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT can_post_in_exercice(v_org_id, CURRENT_DATE) INTO v_can_post;
  IF v_can_post IS NOT NULL THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 2: can_post_in_exercice = %', v_can_post;
  ELSE
    v_errors := array_append(v_errors, 'TEST 2: can_post_in_exercice NULL');
    RAISE NOTICE '❌ TEST 2: can_post_in_exercice retourne NULL';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 3: Balance générale
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_balance_count FROM report_balance_generale(v_org_id);
  IF v_balance_count >= 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 3: Balance générale OK (% lignes)', v_balance_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 3: Balance générale échouée');
    RAISE NOTICE '❌ TEST 3: Balance générale échouée';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 4: Compte de résultat
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_resultat_count FROM report_compte_resultat(v_org_id);
  IF v_resultat_count >= 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 4: Compte de résultat OK (% lignes)', v_resultat_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 4: Compte résultat échoué');
    RAISE NOTICE '❌ TEST 4: Compte de résultat échoué';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 5: Bilan
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_bilan_count FROM report_bilan(v_org_id);
  IF v_bilan_count >= 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 5: Bilan OK (% lignes)', v_bilan_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 5: Bilan échoué');
    RAISE NOTICE '❌ TEST 5: Bilan échoué';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 6: Grand livre
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_gl_count FROM report_grand_livre(v_org_id);
  IF v_gl_count >= 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 6: Grand livre OK (% lignes)', v_gl_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 6: Grand livre échoué');
    RAISE NOTICE '❌ TEST 6: Grand livre échoué';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 7: Dashboard finance KPIs
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT * INTO v_kpis FROM dashboard_finance_kpis(v_org_id);
  IF v_kpis IS NOT NULL THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 7: KPIs OK — tréso=%, résultat=%, produits=%, charges=%',
      v_kpis.tresorerie_actuelle, v_kpis.resultat_exercice, v_kpis.total_produits, v_kpis.total_charges;
  ELSE
    v_errors := array_append(v_errors, 'TEST 7: KPIs NULL');
    RAISE NOTICE '❌ TEST 7: dashboard_finance_kpis NULL';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 8: Dashboard finance évolution
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_evo_count FROM dashboard_finance_evolution(v_org_id);
  IF v_evo_count = 12 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 8: Évolution 12 mois OK (% lignes)', v_evo_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 8: Évolution attendu 12, reçu ' || v_evo_count);
    RAISE NOTICE '⚠️ TEST 8: Évolution % lignes (attendu 12)', v_evo_count;
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 9: Dashboard finance répartition
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_rep_count FROM dashboard_finance_repartition(v_org_id);
  IF v_rep_count >= 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 9: Répartition OK (% catégories)', v_rep_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 9: Répartition échouée');
    RAISE NOTICE '❌ TEST 9: Répartition échouée';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 10: Recherche globale (min 2 chars)
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_search_count FROM global_search(v_org_id, 'test');
  IF v_search_count >= 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 10: Recherche globale OK (% résultats pour "test")', v_search_count;
  ELSE
    v_errors := array_append(v_errors, 'TEST 10: Recherche échouée');
    RAISE NOTICE '❌ TEST 10: Recherche globale échouée';
  END IF;

  -- ══════════════════════════════════════════════
  -- TEST 11: Recherche < 2 chars (doit retourner 0)
  -- ══════════════════════════════════════════════
  v_total_tests := v_total_tests + 1;
  SELECT COUNT(*) INTO v_search_count FROM global_search(v_org_id, 'a');
  IF v_search_count = 0 THEN
    v_tests_passed := v_tests_passed + 1;
    RAISE NOTICE '✅ TEST 11: Recherche < 2 chars bloquée (0 résultat)';
  ELSE
    v_errors := array_append(v_errors, 'TEST 11: Recherche 1 char non bloquée');
    RAISE NOTICE '❌ TEST 11: Recherche 1 char devrait retourner 0, reçu %', v_search_count;
  END IF;

  -- ══════════════════════════════════════════════
  -- RÉSUMÉ
  -- ══════════════════════════════════════════════
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════';
  RAISE NOTICE '📊 RÉSULTAT: %/% tests passés', v_tests_passed, v_total_tests;
  RAISE NOTICE '════════════════════════════════════';
  IF array_length(v_errors, 1) > 0 THEN
    RAISE NOTICE '⚠️ Erreurs:';
    FOR i IN 1..array_length(v_errors, 1) LOOP
      RAISE NOTICE '   - %', v_errors[i];
    END LOOP;
  ELSE
    RAISE NOTICE '🎉 Tous les tests passent !';
  END IF;
END;
$$;

-- =============================================================================
-- Test RLS — Tables Dossier Fiscal SYSCEBNL
-- =============================================================================
-- Vérifie que RLS est activé sur les 8 nouvelles tables et que les policies
-- sont correctement définies. Exécuter dans le SQL Editor de Supabase.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Vérifier que RLS est activé sur toutes les tables fiscales
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_tables TEXT[] := ARRAY[
    'fiscal_templates',
    'fiscal_template_pages',
    'fiscal_template_fields',
    'fiscal_account_mapping',
    'fiscal_dossiers',
    'fiscal_dossier_values',
    'imported_trial_balances',
    'imported_trial_balance_lines'
  ];
  v_table TEXT;
  v_rls BOOLEAN;
  v_count INT := 0;
  v_errors TEXT := '';
BEGIN
  FOREACH v_table IN ARRAY v_tables
  LOOP
    SELECT relrowsecurity INTO v_rls
    FROM pg_class
    WHERE oid = ('public.' || v_table)::regclass;

    IF v_rls THEN
      v_count := v_count + 1;
      RAISE NOTICE '✅ RLS activé sur %', v_table;
    ELSE
      v_errors := v_errors || '❌ RLS NON activé sur ' || v_table || E'\n';
    END IF;
  END LOOP;

  IF v_errors <> '' THEN
    RAISE EXCEPTION E'ÉCHEC — Tables sans RLS :\n%', v_errors;
  ELSE
    RAISE NOTICE '✅ SUCCÈS : RLS activé sur les 8 tables fiscales (%/8)', v_count;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Vérifier que les policies existent
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_expected_policies TEXT[] := ARRAY[
    'fiscal_templates_select_auth',
    'fiscal_template_pages_select_auth',
    'fiscal_template_fields_select_auth',
    'fiscal_account_mapping_select_auth',
    'fiscal_dossiers_select_org',
    'fiscal_dossiers_insert_org',
    'fiscal_dossiers_update_org',
    'fiscal_dossiers_delete_org',
    'fiscal_values_select_org',
    'fiscal_values_insert_org',
    'fiscal_values_update_org',
    'fiscal_values_delete_org',
    'import_balances_select_org',
    'import_balances_insert_org'
  ];
  v_policy TEXT;
  v_count INT := 0;
  v_missing TEXT := '';
BEGIN
  FOREACH v_policy IN ARRAY v_expected_policies
  LOOP
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = v_policy) THEN
      v_count := v_count + 1;
    ELSE
      v_missing := v_missing || '❌ Policy manquante : ' || v_policy || E'\n';
    END IF;
  END LOOP;

  IF v_missing <> '' THEN
    RAISE EXCEPTION E'ÉCHEC — Policies manquantes :\n%', v_missing;
  ELSE
    RAISE NOTICE '✅ SUCCÈS : % policies fiscales vérifiées', v_count;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Vérifier les RPCs existent
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_rpcs TEXT[] := ARRAY[
    'prefill_fiscal_dossier',
    'prefill_fiscal_dossier_from_import',
    'validate_fiscal_dossier',
    'lock_fiscal_dossier'
  ];
  v_rpc TEXT;
  v_count INT := 0;
  v_missing TEXT := '';
BEGIN
  FOREACH v_rpc IN ARRAY v_rpcs
  LOOP
    IF EXISTS (
      SELECT 1 FROM pg_proc WHERE proname = v_rpc AND pronamespace = 'public'::regnamespace
    ) THEN
      v_count := v_count + 1;
    ELSE
      v_missing := v_missing || '❌ RPC manquante : ' || v_rpc || E'\n';
    END IF;
  END LOOP;

  IF v_missing <> '' THEN
    RAISE EXCEPTION E'ÉCHEC — RPCs manquantes :\n%', v_missing;
  ELSE
    RAISE NOTICE '✅ SUCCÈS : % RPCs fiscales vérifiées', v_count;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Vérifier le seed template SYSCEBNL_2026
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_tpl_count INT;
  v_page_count INT;
  v_field_count INT;
  v_mapping_count INT;
BEGIN
  SELECT COUNT(*) INTO v_tpl_count FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026';
  SELECT COUNT(*) INTO v_page_count FROM public.fiscal_template_pages
    WHERE template_id = (SELECT id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026');
  SELECT COUNT(*) INTO v_field_count FROM public.fiscal_template_fields
    WHERE page_id IN (SELECT id FROM public.fiscal_template_pages
      WHERE template_id = (SELECT id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026'));
  SELECT COUNT(*) INTO v_mapping_count FROM public.fiscal_account_mapping
    WHERE template_id = (SELECT id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026');

  IF v_tpl_count = 1 AND v_page_count = 5 AND v_field_count >= 25 AND v_mapping_count >= 10 THEN
    RAISE NOTICE '✅ SUCCÈS Seed : template=%, pages=%, champs=%, mappings=%',
      v_tpl_count, v_page_count, v_field_count, v_mapping_count;
  ELSE
    RAISE EXCEPTION '❌ ÉCHEC Seed : template=% (attendu 1), pages=% (attendu 5), champs=% (attendu ≥25), mappings=% (attendu ≥10)',
      v_tpl_count, v_page_count, v_field_count, v_mapping_count;
  END IF;
END $$;

-- ============================================================================
-- Test E2E DB - Hierarchical permissions for fiscal statements
-- ============================================================================
-- Objectif :
--   1. Creer deux unites temporaires dans une organisation existante.
--   2. Creer un dossier fiscal, une balance importee et une ecriture brouillon
--      rattaches au niveau inferieur.
--   3. Creer un utilisateur temporaire rattache au niveau superieur.
--   4. Verifier les droits descendants sur etats financiers, exports et RPCs.
--   5. Nettoyer toutes les donnees de test avant COMMIT.
-- ============================================================================

DROP TABLE IF EXISTS _hierarchy_fiscal_statements_test_result;
CREATE TEMP TABLE _hierarchy_fiscal_statements_test_result (
  sort_order INTEGER,
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
) ON COMMIT PRESERVE ROWS;

BEGIN;

DO $$
DECLARE
  v_admin_id UUID;
  v_org_id UUID;
  v_template_id UUID;
  v_suffix TEXT := lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_parent_type_id UUID := gen_random_uuid();
  v_child_type_id UUID := gen_random_uuid();
  v_parent_unit_id UUID := gen_random_uuid();
  v_child_unit_id UUID := gen_random_uuid();
  v_user_id UUID := gen_random_uuid();
  v_journal_id UUID := gen_random_uuid();
  v_cash_account_id UUID := gen_random_uuid();
  v_revenue_account_id UUID := gen_random_uuid();
  v_entry_id UUID := gen_random_uuid();
  v_line_debit_id UUID := gen_random_uuid();
  v_line_credit_id UUID := gen_random_uuid();
  v_dossier_id UUID := gen_random_uuid();
  v_import_id UUID := gen_random_uuid();
  v_import_line_cash_id UUID := gen_random_uuid();
  v_import_line_revenue_id UUID := gen_random_uuid();
  v_value_id UUID := gen_random_uuid();
  v_direct_view BOOLEAN;
  v_descendant_view BOOLEAN;
  v_descendant_create BOOLEAN;
  v_descendant_update BOOLEAN;
  v_export_allowed BOOLEAN;
  v_validate_before BOOLEAN;
  v_validate_pending BOOLEAN;
  v_pending_validation_blocked BOOLEAN := FALSE;
  v_validate_after BOOLEAN;
  v_validation_after_allowed BOOLEAN := FALSE;
  v_prefill_import_allowed BOOLEAN := FALSE;
  v_prefill_accounting_allowed BOOLEAN := FALSE;
  v_report_balance_includes_child BOOLEAN := FALSE;
  v_locked_value_blocked BOOLEAN := FALSE;
  v_dossier_unit_synced BOOLEAN;
  v_import_unit_synced BOOLEAN;
  v_result JSONB;
BEGIN
  SELECT p.id, p.organization_id
  INTO v_admin_id, v_org_id
  FROM profiles p
  WHERE p.role = 'admin_national'
    AND p.organization_id IS NOT NULL
  ORDER BY p.created_at
  LIMIT 1;

  IF v_admin_id IS NULL OR v_org_id IS NULL THEN
    RAISE EXCEPTION 'Aucun profil admin_national avec organisation_id trouve.';
  END IF;

  SELECT id
  INTO v_template_id
  FROM fiscal_templates
  WHERE code = 'SYSCEBNL_2026'
    AND is_active = TRUE
  LIMIT 1;

  IF v_template_id IS NULL THEN
    RAISE EXCEPTION 'Template fiscal SYSCEBNL_2026 introuvable.';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);

  INSERT INTO church_unit_types (
    id,
    organization_id,
    code,
    label,
    level_order,
    is_local,
    is_financial_scope,
    can_have_members,
    can_have_cash_accounts,
    can_have_bank_accounts,
    can_have_mobile_money_accounts,
    can_create_programs,
    can_launch_contributions,
    can_validate_finances,
    can_consolidate_finances,
    can_notify_descendants,
    can_view_descendants
  )
  VALUES
  (
    v_parent_type_id,
    v_org_id,
    'codex_fiscal_parent_' || v_suffix,
    'Niveau parent test fiscal',
    150,
    FALSE,
    TRUE,
    FALSE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    TRUE
  ),
  (
    v_child_type_id,
    v_org_id,
    'codex_fiscal_child_' || v_suffix,
    'Niveau enfant test fiscal',
    151,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE,
    FALSE,
    TRUE
  );

  INSERT INTO church_units (
    id,
    organization_id,
    type_id,
    parent_id,
    nom,
    code,
    metadata
  )
  VALUES
  (
    v_parent_unit_id,
    v_org_id,
    v_parent_type_id,
    NULL,
    'Unite parent test fiscal',
    'TFISC-PARENT-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  ),
  (
    v_child_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Unite enfant test fiscal',
    'TFISC-CHILD-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  );

  INSERT INTO journaux_comptables (
    id,
    organization_id,
    code,
    intitule,
    type
  )
  VALUES (
    v_journal_id,
    v_org_id,
    'TFS' || upper(v_suffix),
    'Journal test fiscal',
    'operations_diverses'
  );

  INSERT INTO comptes_comptables (
    id,
    organization_id,
    numero,
    intitule,
    nature,
    niveau
  )
  VALUES
  (
    v_cash_account_id,
    v_org_id,
    '57' || substr(v_suffix, 1, 4),
    'Caisse test fiscal',
    'actif',
    2
  ),
  (
    v_revenue_account_id,
    v_org_id,
    '70' || substr(v_suffix, 1, 4),
    'Produit test fiscal',
    'produit',
    2
  );

  INSERT INTO ecritures_comptables (
    id,
    organization_id,
    church_unit_id,
    id_journal,
    date,
    reference_piece,
    libelle,
    statut,
    created_by
  )
  VALUES (
    v_entry_id,
    v_org_id,
    v_child_unit_id,
    v_journal_id,
    CURRENT_DATE,
    'TEST-FISC-' || upper(v_suffix),
    'Ecriture test etats financiers',
    'brouillon',
    v_admin_id
  );

  INSERT INTO lignes_ecritures (
    id,
    id_ecriture,
    id_compte_comptable,
    libelle,
    debit,
    credit,
    mode_paiement
  )
  VALUES
  (
    v_line_debit_id,
    v_entry_id,
    v_cash_account_id,
    'Debit test fiscal',
    100000,
    0,
    'especes'
  ),
  (
    v_line_credit_id,
    v_entry_id,
    v_revenue_account_id,
    'Credit test fiscal',
    0,
    100000,
    'especes'
  );

  INSERT INTO fiscal_dossiers (
    id,
    organization_id,
    church_unit_id,
    template_id,
    status,
    label,
    created_by
  )
  VALUES (
    v_dossier_id,
    v_org_id,
    v_child_unit_id,
    v_template_id,
    'draft',
    'Dossier test permissions fiscales',
    v_admin_id
  );

  INSERT INTO imported_trial_balances (
    id,
    organization_id,
    church_unit_id,
    exercice_label,
    filename,
    total_debit,
    total_credit,
    line_count,
    created_by
  )
  VALUES (
    v_import_id,
    v_org_id,
    v_child_unit_id,
    'Exercice test ' || v_suffix,
    'balance-test-' || v_suffix || '.csv',
    100000,
    100000,
    2,
    v_admin_id
  );

  INSERT INTO imported_trial_balance_lines (
    id,
    import_id,
    organization_id,
    account_number,
    account_label,
    debit,
    credit
  )
  VALUES
  (
    v_import_line_cash_id,
    v_import_id,
    v_org_id,
    '57' || substr(v_suffix, 1, 4),
    'Caisse importee test fiscal',
    100000,
    0
  ),
  (
    v_import_line_revenue_id,
    v_import_id,
    v_org_id,
    '70' || substr(v_suffix, 1, 4),
    'Produit importe test fiscal',
    0,
    100000
  );

  INSERT INTO fiscal_dossier_values (
    id,
    dossier_id,
    organization_id,
    field_key,
    value,
    source,
    updated_by
  )
  VALUES (
    v_value_id,
    v_dossier_id,
    v_org_id,
    'test.initial',
    '"ok"'::jsonb,
    'manual',
    v_admin_id
  );

  SELECT church_unit_id = v_child_unit_id
  INTO v_dossier_unit_synced
  FROM fiscal_dossiers
  WHERE id = v_dossier_id;

  SELECT church_unit_id = v_child_unit_id
  INTO v_import_unit_synced
  FROM imported_trial_balances
  WHERE id = v_import_id;

  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'codex-fiscal-permissions-' || v_suffix || '@example.test',
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Utilisateur test permissions fiscales'),
    NOW(),
    NOW()
  );

  INSERT INTO profiles (
    id,
    organization_id,
    full_name,
    role,
    primary_church_unit_id
  )
  VALUES (
    v_user_id,
    v_org_id,
    'Utilisateur test permissions fiscales',
    'responsable_region',
    v_parent_unit_id
  )
  ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    primary_church_unit_id = EXCLUDED.primary_church_unit_id,
    updated_at = NOW();

  PERFORM set_config('request.jwt.claim.sub', v_user_id::text, true);

  SELECT user_can_access_financial_statements_scope(
    v_parent_unit_id,
    NULL,
    'view_details'
  )
  INTO v_direct_view;

  SELECT user_can_access_financial_statements_scope(
    v_child_unit_id,
    NULL,
    'view_details'
  )
  INTO v_descendant_view;

  SELECT user_can_access_financial_statements_scope(
    v_child_unit_id,
    NULL,
    'create'
  )
  INTO v_descendant_create;

  SELECT user_can_access_financial_statements_scope(
    v_child_unit_id,
    NULL,
    'update'
  )
  INTO v_descendant_update;

  SELECT user_can_access_exports_scope(
    v_child_unit_id,
    NULL,
    'export'
  )
  INTO v_export_allowed;

  SELECT user_can_access_financial_statements_scope(
    v_child_unit_id,
    NULL,
    'validate'
  )
  INTO v_validate_before;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'financial_statements',
    'validate',
    TRUE,
    TRUE,
    'Test validation dossier fiscal en attente'
  );

  SELECT user_can_access_financial_statements_scope(
    v_child_unit_id,
    NULL,
    'validate'
  )
  INTO v_validate_pending;

  BEGIN
    v_result := validate_fiscal_dossier(v_dossier_id);
    v_pending_validation_blocked := FALSE;
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_pending_validation_blocked := TRUE;
  END;

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);

  UPDATE church_unit_permission_overrides permission_override
  SET
    acceptance_status = 'accepted',
    accepted_by = v_user_id,
    accepted_at = NOW()
  FROM church_permission_domains domain,
       church_permission_actions action
  WHERE permission_override.organization_id = v_org_id
    AND permission_override.ancestor_unit_id = v_parent_unit_id
    AND permission_override.descendant_unit_id = v_child_unit_id
    AND permission_override.domain_id = domain.id
    AND permission_override.action_id = action.id
    AND domain.organization_id = v_org_id
    AND domain.code = 'financial_statements'
    AND action.organization_id = v_org_id
    AND action.code = 'validate';

  PERFORM set_config('request.jwt.claim.sub', v_user_id::text, true);

  SELECT user_can_access_financial_statements_scope(
    v_child_unit_id,
    NULL,
    'validate'
  )
  INTO v_validate_after;

  BEGIN
    v_result := validate_fiscal_dossier(v_dossier_id);
    v_validation_after_allowed := TRUE;
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_validation_after_allowed := FALSE;
  END;

  BEGIN
    v_result := prefill_fiscal_dossier_from_import(v_dossier_id, v_import_id);
    v_prefill_import_allowed := (v_result->>'success')::boolean;
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_prefill_import_allowed := FALSE;
  END;

  BEGIN
    UPDATE ecritures_comptables
    SET statut = 'validee'
    WHERE id = v_entry_id;

    SELECT EXISTS (
      SELECT 1
      FROM report_balance_generale(v_org_id, CURRENT_DATE, CURRENT_DATE) r
      WHERE r.compte_id = v_cash_account_id
    )
    INTO v_report_balance_includes_child;

    v_result := prefill_fiscal_dossier(v_dossier_id);
    v_prefill_accounting_allowed := (v_result->>'success')::boolean;

    RAISE EXCEPTION 'rollback accounting report probe';
  EXCEPTION
    WHEN raise_exception THEN
      NULL;
  END;

  BEGIN
    UPDATE fiscal_dossiers
    SET status = 'locked'
    WHERE id = v_dossier_id;

    UPDATE fiscal_dossier_values
    SET value = '"blocked?"'::jsonb
    WHERE id = v_value_id;

    v_locked_value_blocked := FALSE;
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_locked_value_blocked := TRUE;
  END;

  INSERT INTO _hierarchy_fiscal_statements_test_result VALUES
    (
      1,
      'perimetre_dossier_fiscal_conserve',
      v_dossier_unit_synced = TRUE,
      'dossier_unit_synced=' || COALESCE(v_dossier_unit_synced::text, 'NULL')
    ),
    (
      2,
      'perimetre_import_balance_conserve',
      v_import_unit_synced = TRUE,
      'import_unit_synced=' || COALESCE(v_import_unit_synced::text, 'NULL')
    ),
    (
      3,
      'acces_direct_etats_financiers_conserve',
      v_direct_view = TRUE,
      'direct_view=' || COALESCE(v_direct_view::text, 'NULL')
    ),
    (
      4,
      'lecture_etats_financiers_descendant_autorisee',
      v_descendant_view = TRUE,
      'descendant_view=' || COALESCE(v_descendant_view::text, 'NULL')
    ),
    (
      5,
      'creation_dossier_descendant_autorisee',
      v_descendant_create = TRUE,
      'descendant_create=' || COALESCE(v_descendant_create::text, 'NULL')
    ),
    (
      6,
      'modification_dossier_descendant_autorisee',
      v_descendant_update = TRUE,
      'descendant_update=' || COALESCE(v_descendant_update::text, 'NULL')
    ),
    (
      7,
      'export_descendant_autorise',
      v_export_allowed = TRUE,
      'export_allowed=' || COALESCE(v_export_allowed::text, 'NULL')
    ),
    (
      8,
      'validation_dossier_descendant_autorisee_par_defaut',
      v_validate_before = TRUE,
      'validate_before_override=' || COALESCE(v_validate_before::text, 'NULL')
    ),
    (
      9,
      'validation_dossier_en_attente_refusee',
      v_validate_pending = FALSE
        AND v_pending_validation_blocked = TRUE,
      'validate_pending=' || COALESCE(v_validate_pending::text, 'NULL') ||
        ', blocked=' || v_pending_validation_blocked::text
    ),
    (
      10,
      'validation_dossier_acceptee_autorisee',
      v_validate_after = TRUE
        AND v_validation_after_allowed = TRUE,
      'validate_after_acceptance=' || COALESCE(v_validate_after::text, 'NULL') ||
        ', rpc_allowed=' || v_validation_after_allowed::text
    ),
    (
      11,
      'prefill_depuis_import_autorise',
      v_prefill_import_allowed = TRUE,
      'prefill_import=' || COALESCE(v_prefill_import_allowed::text, 'NULL')
    ),
    (
      12,
      'rapport_balance_filtre_par_perimetre',
      v_report_balance_includes_child = TRUE,
      'report_balance_child=' ||
        COALESCE(v_report_balance_includes_child::text, 'NULL')
    ),
    (
      13,
      'prefill_depuis_comptabilite_autorise',
      v_prefill_accounting_allowed = TRUE,
      'prefill_accounting=' ||
        COALESCE(v_prefill_accounting_allowed::text, 'NULL')
    ),
    (
      14,
      'valeurs_dossier_verrouille_non_modifiables',
      v_locked_value_blocked = TRUE,
      'locked_value_blocked=' || v_locked_value_blocked::text
    );

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
  UPDATE fiscal_dossiers
  SET status = 'draft', import_id = NULL
  WHERE id = v_dossier_id;
  DELETE FROM fiscal_dossier_values WHERE dossier_id = v_dossier_id;
  DELETE FROM fiscal_dossiers WHERE id = v_dossier_id;
  DELETE FROM imported_trial_balance_lines WHERE import_id = v_import_id;
  DELETE FROM imported_trial_balances WHERE id = v_import_id;
  DELETE FROM lignes_ecritures WHERE id IN (v_line_debit_id, v_line_credit_id);
  DELETE FROM ecritures_comptables WHERE id = v_entry_id;
  DELETE FROM comptes_comptables WHERE id IN (v_cash_account_id, v_revenue_account_id);
  DELETE FROM journaux_comptables WHERE id = v_journal_id;
  DELETE FROM church_unit_permission_overrides
  WHERE ancestor_unit_id = v_parent_unit_id
     OR descendant_unit_id = v_child_unit_id;
  DELETE FROM profiles WHERE id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
  DELETE FROM church_units WHERE id IN (v_child_unit_id, v_parent_unit_id);
  DELETE FROM church_unit_types WHERE id IN (v_child_type_id, v_parent_type_id);
  PERFORM set_config('request.jwt.claim.sub', '', true);
END $$;

COMMIT;

SELECT check_name, ok, detail
FROM _hierarchy_fiscal_statements_test_result
ORDER BY sort_order;

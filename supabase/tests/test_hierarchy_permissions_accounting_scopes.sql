-- ============================================================================
-- Test E2E DB - Hierarchical permissions for accounting scopes
-- ============================================================================
-- Objectif :
--   1. Creer deux unites temporaires dans une organisation existante.
--   2. Creer des objets comptables rattaches au niveau inferieur.
--   3. Creer un utilisateur temporaire rattache au niveau superieur.
--   4. Verifier les droits descendants comptables par domaine.
--   5. Verifier qu'une validation d'ecriture en attente d'accord est bloquee.
--   6. Nettoyer toutes les donnees de test avant COMMIT.
-- ============================================================================

DROP TABLE IF EXISTS _hierarchy_accounting_scopes_test_result;
CREATE TEMP TABLE _hierarchy_accounting_scopes_test_result (
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
  v_suffix TEXT := lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_parent_type_id UUID := gen_random_uuid();
  v_child_type_id UUID := gen_random_uuid();
  v_parent_unit_id UUID := gen_random_uuid();
  v_child_unit_id UUID := gen_random_uuid();
  v_user_id UUID := gen_random_uuid();
  v_journal_id UUID := gen_random_uuid();
  v_bank_journal_id UUID := gen_random_uuid();
  v_cash_account_id UUID := gen_random_uuid();
  v_revenue_account_id UUID := gen_random_uuid();
  v_asset_account_id UUID := gen_random_uuid();
  v_depreciation_account_id UUID := gen_random_uuid();
  v_expense_account_id UUID := gen_random_uuid();
  v_center_id UUID := gen_random_uuid();
  v_global_center_id UUID := gen_random_uuid();
  v_tiers_id UUID := gen_random_uuid();
  v_entry_id UUID := gen_random_uuid();
  v_line_debit_id UUID := gen_random_uuid();
  v_line_credit_id UUID := gen_random_uuid();
  v_budget_id UUID := gen_random_uuid();
  v_budget_line_id UUID := gen_random_uuid();
  v_asset_id UUID := gen_random_uuid();
  v_statement_id UUID := gen_random_uuid();
  v_direct_entry_view BOOLEAN;
  v_child_entry_view BOOLEAN;
  v_child_entry_create BOOLEAN;
  v_child_entry_validate_before BOOLEAN;
  v_child_entry_validate_pending BOOLEAN;
  v_pending_validation_blocked BOOLEAN := FALSE;
  v_child_entry_validate_after BOOLEAN;
  v_accepted_validation_allowed BOOLEAN := FALSE;
  v_entry_status_after_probe TEXT;
  v_budget_create_before BOOLEAN;
  v_budget_create_after BOOLEAN;
  v_asset_create BOOLEAN;
  v_bank_update BOOLEAN;
  v_global_reference_view BOOLEAN;
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
    'codex_acc_parent_' || v_suffix,
    'Niveau parent test comptabilite',
    140,
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
    'codex_acc_child_' || v_suffix,
    'Niveau enfant test comptabilite',
    141,
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
    'Unite parent test comptabilite',
    'TACC-PARENT-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  ),
  (
    v_child_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Unite enfant test comptabilite',
    'TACC-CHILD-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  );

  INSERT INTO journaux_comptables (
    id,
    organization_id,
    code,
    intitule,
    type
  )
  VALUES
  (
    v_journal_id,
    v_org_id,
    'TAC' || upper(v_suffix),
    'Journal test comptabilite',
    'operations_diverses'
  ),
  (
    v_bank_journal_id,
    v_org_id,
    'TBQ' || upper(v_suffix),
    'Journal banque test comptabilite',
    'banque'
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
    'Caisse test comptabilite',
    'actif',
    2
  ),
  (
    v_revenue_account_id,
    v_org_id,
    '70' || substr(v_suffix, 1, 4),
    'Produit test comptabilite',
    'produit',
    2
  ),
  (
    v_asset_account_id,
    v_org_id,
    '24' || substr(v_suffix, 1, 4),
    'Immobilisation test comptabilite',
    'actif',
    2
  ),
  (
    v_depreciation_account_id,
    v_org_id,
    '28' || substr(v_suffix, 1, 4),
    'Amortissement test comptabilite',
    'actif',
    2
  ),
  (
    v_expense_account_id,
    v_org_id,
    '68' || substr(v_suffix, 1, 4),
    'Dotation test comptabilite',
    'charge',
    2
  );

  INSERT INTO centres_analytiques (
    id,
    organization_id,
    church_unit_id,
    code,
    nom,
    type
  )
  VALUES
  (
    v_center_id,
    v_org_id,
    v_child_unit_id,
    'CTR-' || upper(v_suffix),
    'Centre test comptabilite',
    'activite'
  ),
  (
    v_global_center_id,
    v_org_id,
    NULL,
    'GCTR-' || upper(v_suffix),
    'Centre global test comptabilite',
    'autre'
  );

  INSERT INTO tiers (
    id,
    organization_id,
    church_unit_id,
    nom,
    type
  )
  VALUES (
    v_tiers_id,
    v_org_id,
    v_child_unit_id,
    'Tiers test comptabilite',
    'fournisseur'
  );

  INSERT INTO ecritures_comptables (
    id,
    organization_id,
    church_unit_id,
    id_journal,
    id_centre_analytique_principal,
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
    v_center_id,
    CURRENT_DATE,
    'TEST-' || upper(v_suffix),
    'Ecriture test permissions comptables',
    'brouillon',
    v_admin_id
  );

  INSERT INTO lignes_ecritures (
    id,
    id_ecriture,
    id_compte_comptable,
    id_centre_analytique,
    id_tiers,
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
    v_center_id,
    v_tiers_id,
    'Debit test permissions',
    50000,
    0,
    'especes'
  ),
  (
    v_line_credit_id,
    v_entry_id,
    v_revenue_account_id,
    v_center_id,
    v_tiers_id,
    'Credit test permissions',
    0,
    50000,
    'especes'
  );

  INSERT INTO budgets_comptables (
    id,
    organization_id,
    church_unit_id,
    id_centre_analytique,
    id_tiers_bailleur,
    exercice,
    libelle
  )
  VALUES (
    v_budget_id,
    v_org_id,
    v_child_unit_id,
    v_center_id,
    v_tiers_id,
    2099,
    'Budget test permissions comptables'
  );

  INSERT INTO lignes_budgets (
    id,
    id_budget,
    id_compte_comptable,
    montant_prevu,
    montant_revu
  )
  VALUES (
    v_budget_line_id,
    v_budget_id,
    v_expense_account_id,
    75000,
    80000
  );

  INSERT INTO immobilisations_comptables (
    id,
    organization_id,
    church_unit_id,
    id_centre_analytique,
    libelle,
    type,
    date_acquisition,
    valeur_acquisition,
    valeur_residuelle,
    duree_utilite_en_annees,
    id_compte_immobilisation,
    id_compte_amortissement,
    id_compte_dotation
  )
  VALUES (
    v_asset_id,
    v_org_id,
    v_child_unit_id,
    v_center_id,
    'Immobilisation test permissions',
    'materiel_informatique',
    CURRENT_DATE,
    150000,
    0,
    3,
    v_asset_account_id,
    v_depreciation_account_id,
    v_expense_account_id
  );

  INSERT INTO releves_bancaires (
    id,
    organization_id,
    church_unit_id,
    id_journal_banque,
    date_releve,
    solde_initial,
    solde_final
  )
  VALUES (
    v_statement_id,
    v_org_id,
    v_child_unit_id,
    v_bank_journal_id,
    CURRENT_DATE,
    100000,
    125000
  );

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
    'codex-accounting-permissions-' || v_suffix || '@example.test',
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Utilisateur test permissions comptables'),
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
    'Utilisateur test permissions comptables',
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

  SELECT user_can_access_accounting_entries_scope(
    v_parent_unit_id,
    NULL,
    'view_details'
  )
  INTO v_direct_entry_view;

  SELECT user_can_access_accounting_entries_scope(
    v_child_unit_id,
    NULL,
    'view_details'
  )
  INTO v_child_entry_view;

  SELECT user_can_access_accounting_entries_scope(
    v_child_unit_id,
    NULL,
    'create'
  )
  INTO v_child_entry_create;

  SELECT user_can_access_accounting_entries_scope(
    v_child_unit_id,
    NULL,
    'validate'
  )
  INTO v_child_entry_validate_before;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'accounting_entries',
    'validate',
    TRUE,
    TRUE,
    'Test validation ecriture en attente'
  );

  SELECT user_can_access_accounting_entries_scope(
    v_child_unit_id,
    NULL,
    'validate'
  )
  INTO v_child_entry_validate_pending;

  BEGIN
    UPDATE ecritures_comptables
    SET statut = 'validee'
    WHERE id = v_entry_id;

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
    AND domain.code = 'accounting_entries'
    AND action.organization_id = v_org_id
    AND action.code = 'validate';

  PERFORM set_config('request.jwt.claim.sub', v_user_id::text, true);

  SELECT user_can_access_accounting_entries_scope(
    v_child_unit_id,
    NULL,
    'validate'
  )
  INTO v_child_entry_validate_after;

  BEGIN
    UPDATE ecritures_comptables
    SET statut = 'validee'
    WHERE id = v_entry_id;

    RAISE EXCEPTION 'rollback accepted validation probe';
  EXCEPTION
    WHEN raise_exception THEN
      v_accepted_validation_allowed := TRUE;
  END;

  SELECT statut::text
  INTO v_entry_status_after_probe
  FROM ecritures_comptables
  WHERE id = v_entry_id;

  SELECT user_can_access_accounting_budgets_scope(
    v_child_unit_id,
    NULL,
    'create'
  )
  INTO v_budget_create_before;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'accounting_budgets',
    'create',
    TRUE,
    FALSE,
    'Test creation budget autorisee'
  );

  SELECT user_can_access_accounting_budgets_scope(
    v_child_unit_id,
    NULL,
    'create'
  )
  INTO v_budget_create_after;

  SELECT user_can_access_accounting_assets_scope(
    v_child_unit_id,
    NULL,
    'create'
  )
  INTO v_asset_create;

  SELECT user_can_access_bank_reconciliation_scope(
    v_child_unit_id,
    NULL,
    'update'
  )
  INTO v_bank_update;

  SELECT user_can_access_accounting_references_scope(
    NULL,
    NULL,
    'view_details'
  )
  INTO v_global_reference_view;

  INSERT INTO _hierarchy_accounting_scopes_test_result VALUES
    (
      1,
      'acces_direct_ecritures_conserve',
      v_direct_entry_view = TRUE,
      'direct_entry_view=' || COALESCE(v_direct_entry_view::text, 'NULL')
    ),
    (
      2,
      'lecture_ecritures_descendant_autorisee_par_defaut',
      v_child_entry_view = TRUE,
      'entry_view_descendant=' || COALESCE(v_child_entry_view::text, 'NULL')
    ),
    (
      3,
      'creation_ecritures_descendant_refusee_par_defaut',
      v_child_entry_create = FALSE,
      'entry_create_descendant=' || COALESCE(v_child_entry_create::text, 'NULL')
    ),
    (
      4,
      'validation_ecritures_descendant_autorisee_par_defaut',
      v_child_entry_validate_before = TRUE,
      'entry_validate_before_override=' ||
        COALESCE(v_child_entry_validate_before::text, 'NULL')
    ),
    (
      5,
      'validation_ecritures_en_attente_refusee',
      v_child_entry_validate_pending = FALSE
        AND v_pending_validation_blocked = TRUE,
      'entry_validate_pending=' ||
        COALESCE(v_child_entry_validate_pending::text, 'NULL') ||
        ', blocked=' || v_pending_validation_blocked::text
    ),
    (
      6,
      'validation_ecritures_acceptee_autorisee',
      v_child_entry_validate_after = TRUE
        AND v_accepted_validation_allowed = TRUE
        AND v_entry_status_after_probe = 'brouillon',
      'entry_validate_after_acceptance=' ||
        COALESCE(v_child_entry_validate_after::text, 'NULL') ||
        ', update_allowed=' || v_accepted_validation_allowed::text ||
        ', statut_after_probe=' || COALESCE(v_entry_status_after_probe, 'NULL')
    ),
    (
      7,
      'creation_budgets_descendant_refusee_par_defaut',
      v_budget_create_before = FALSE,
      'budget_create_before_override=' ||
        COALESCE(v_budget_create_before::text, 'NULL')
    ),
    (
      8,
      'creation_budgets_descendant_autorisee_par_exception',
      v_budget_create_after = TRUE,
      'budget_create_after_override=' ||
        COALESCE(v_budget_create_after::text, 'NULL')
    ),
    (
      9,
      'creation_immobilisations_descendant_refusee_par_defaut',
      v_asset_create = FALSE,
      'asset_create=' || COALESCE(v_asset_create::text, 'NULL')
    ),
    (
      10,
      'modification_releves_descendant_refusee_par_defaut',
      v_bank_update = FALSE,
      'bank_statement_update=' || COALESCE(v_bank_update::text, 'NULL')
    ),
    (
      11,
      'lecture_references_globales_conservee',
      v_global_reference_view = TRUE,
      'global_reference_view=' ||
        COALESCE(v_global_reference_view::text, 'NULL')
    );

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
  DELETE FROM lignes_budgets WHERE id = v_budget_line_id;
  DELETE FROM budgets_comptables WHERE id = v_budget_id;
  DELETE FROM lignes_ecritures WHERE id IN (v_line_debit_id, v_line_credit_id);
  DELETE FROM ecritures_comptables WHERE id = v_entry_id;
  DELETE FROM immobilisations_comptables WHERE id = v_asset_id;
  DELETE FROM releves_bancaires WHERE id = v_statement_id;
  DELETE FROM tiers WHERE id = v_tiers_id;
  DELETE FROM centres_analytiques WHERE id IN (v_center_id, v_global_center_id);
  DELETE FROM comptes_comptables
  WHERE id IN (
    v_cash_account_id,
    v_revenue_account_id,
    v_asset_account_id,
    v_depreciation_account_id,
    v_expense_account_id
  );
  DELETE FROM journaux_comptables WHERE id IN (v_journal_id, v_bank_journal_id);
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
FROM _hierarchy_accounting_scopes_test_result
ORDER BY sort_order;

-- ============================================================================
-- Test E2E DB - Hierarchical permissions for finance and monthly reports
-- ============================================================================
-- Objectif :
--   1. Creer deux unites temporaires dans une organisation existante.
--   2. Creer un utilisateur temporaire rattache au niveau superieur.
--   3. Verifier les droits descendants finances et rapports mensuels.
--   4. Verifier qu'une validation de mouvement en attente d'accord est bloquee.
--   5. Nettoyer toutes les donnees de test avant COMMIT.
-- ============================================================================

DROP TABLE IF EXISTS _hierarchy_finance_reports_test_result;
CREATE TEMP TABLE _hierarchy_finance_reports_test_result (
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
  v_account_id UUID := gen_random_uuid();
  v_campaign_id UUID := gen_random_uuid();
  v_movement_id UUID := gen_random_uuid();
  v_direct_campaign_view BOOLEAN;
  v_child_campaign_create_before BOOLEAN;
  v_child_campaign_create_after BOOLEAN;
  v_child_pledge_create BOOLEAN;
  v_child_movement_validate_before BOOLEAN;
  v_child_movement_validate_pending BOOLEAN;
  v_pending_validation_blocked BOOLEAN := FALSE;
  v_child_movement_validate_after BOOLEAN;
  v_movement_status_after TEXT;
  v_monthly_report_consolidate BOOLEAN;
  v_monthly_report_create BOOLEAN;
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
    'codex_fin_parent_' || v_suffix,
    'Niveau parent test finances',
    130,
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
    'codex_fin_child_' || v_suffix,
    'Niveau enfant test finances',
    131,
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
    'Unite parent test finances',
    'TFIN-PARENT-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  ),
  (
    v_child_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Unite enfant test finances',
    'TFIN-CHILD-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  );

  INSERT INTO church_unit_financial_accounts (
    id,
    organization_id,
    church_unit_id,
    type,
    label,
    currency
  )
  VALUES (
    v_account_id,
    v_org_id,
    v_child_unit_id,
    'cash',
    'Caisse test permissions ' || v_suffix,
    'FCFA'
  );

  INSERT INTO campagnes_financieres (
    id,
    organization_id,
    church_unit_id,
    titre,
    type,
    objectif_montant,
    statut,
    created_by
  )
  VALUES (
    v_campaign_id,
    v_org_id,
    v_child_unit_id,
    'Campagne test permissions finances',
    'cotisation',
    100000,
    'active',
    v_admin_id
  );

  INSERT INTO mouvements_financiers (
    id,
    organization_id,
    church_unit_id,
    financial_account_id,
    campagne_id,
    contributeur_nom,
    type,
    montant,
    libelle,
    mode_paiement,
    statut,
    submitted_by
  )
  VALUES (
    v_movement_id,
    v_org_id,
    v_child_unit_id,
    v_account_id,
    v_campaign_id,
    'Contributeur test permissions',
    'encaissement',
    25000,
    'Mouvement test permissions',
    'especes',
    'soumis',
    v_admin_id
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
    'codex-finance-permissions-' || v_suffix || '@example.test',
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Utilisateur test permissions finances'),
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
    'Utilisateur test permissions finances',
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

  SELECT user_can_access_financial_campaigns_scope(
    v_parent_unit_id,
    'view_details'
  )
  INTO v_direct_campaign_view;

  SELECT user_can_access_financial_campaigns_scope(
    v_child_unit_id,
    'create'
  )
  INTO v_child_campaign_create_before;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'financial_campaigns',
    'create',
    FALSE,
    FALSE,
    'Test refus creation campagne'
  );

  SELECT user_can_access_financial_campaigns_scope(
    v_child_unit_id,
    'create'
  )
  INTO v_child_campaign_create_after;

  SELECT user_can_access_financial_pledges_scope(
    v_child_unit_id,
    'create'
  )
  INTO v_child_pledge_create;

  SELECT user_can_access_financial_movements_scope(
    v_child_unit_id,
    'validate'
  )
  INTO v_child_movement_validate_before;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'financial_movements',
    'validate',
    TRUE,
    TRUE,
    'Test validation mouvement en attente'
  );

  SELECT user_can_access_financial_movements_scope(
    v_child_unit_id,
    'validate'
  )
  INTO v_child_movement_validate_pending;

  BEGIN
    UPDATE mouvements_financiers
    SET statut = 'valide'
    WHERE id = v_movement_id;

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
    AND domain.code = 'financial_movements'
    AND action.organization_id = v_org_id
    AND action.code = 'validate';

  PERFORM set_config('request.jwt.claim.sub', v_user_id::text, true);

  SELECT user_can_access_financial_movements_scope(
    v_child_unit_id,
    'validate'
  )
  INTO v_child_movement_validate_after;

  UPDATE mouvements_financiers
  SET statut = 'valide'
  WHERE id = v_movement_id;

  SELECT statut
  INTO v_movement_status_after
  FROM mouvements_financiers
  WHERE id = v_movement_id;

  SELECT user_can_access_monthly_reports_scope(
    v_child_unit_id,
    NULL,
    'consolidate'
  )
  INTO v_monthly_report_consolidate;

  SELECT user_can_access_monthly_reports_scope(
    v_child_unit_id,
    NULL,
    'create'
  )
  INTO v_monthly_report_create;

  INSERT INTO _hierarchy_finance_reports_test_result VALUES
    (
      1,
      'acces_direct_campagnes_conserve',
      v_direct_campaign_view = TRUE,
      'direct_campaign_view=' || COALESCE(v_direct_campaign_view::text, 'NULL')
    ),
    (
      2,
      'creation_campagnes_descendant_autorisee_par_defaut',
      v_child_campaign_create_before = TRUE,
      'campaign_create_before_override=' ||
        COALESCE(v_child_campaign_create_before::text, 'NULL')
    ),
    (
      3,
      'creation_campagnes_descendant_refusee_par_exception',
      v_child_campaign_create_after = FALSE,
      'campaign_create_after_override=' ||
        COALESCE(v_child_campaign_create_after::text, 'NULL')
    ),
    (
      4,
      'creation_promesses_descendant_autorisee_par_defaut',
      v_child_pledge_create = TRUE,
      'pledge_create=' || COALESCE(v_child_pledge_create::text, 'NULL')
    ),
    (
      5,
      'validation_mouvements_descendant_autorisee_par_defaut',
      v_child_movement_validate_before = TRUE,
      'movement_validate_before_override=' ||
        COALESCE(v_child_movement_validate_before::text, 'NULL')
    ),
    (
      6,
      'validation_mouvements_en_attente_refusee',
      v_child_movement_validate_pending = FALSE
        AND v_pending_validation_blocked = TRUE,
      'movement_validate_pending=' ||
        COALESCE(v_child_movement_validate_pending::text, 'NULL') ||
        ', blocked=' || v_pending_validation_blocked::text
    ),
    (
      7,
      'validation_mouvements_acceptee_autorisee',
      v_child_movement_validate_after = TRUE
        AND v_movement_status_after = 'valide',
      'movement_validate_after_acceptance=' ||
        COALESCE(v_child_movement_validate_after::text, 'NULL') ||
        ', statut=' || COALESCE(v_movement_status_after, 'NULL')
    ),
    (
      8,
      'consolidation_rapports_mensuels_autorisee',
      v_monthly_report_consolidate = TRUE,
      'monthly_report_consolidate=' ||
        COALESCE(v_monthly_report_consolidate::text, 'NULL')
    ),
    (
      9,
      'creation_rapports_mensuels_non_autorisee_par_defaut',
      v_monthly_report_create = FALSE,
      'monthly_report_create=' ||
        COALESCE(v_monthly_report_create::text, 'NULL')
    );

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
  DELETE FROM mouvements_financiers WHERE id = v_movement_id;
  DELETE FROM campagnes_financieres WHERE id = v_campaign_id;
  DELETE FROM church_unit_financial_accounts WHERE id = v_account_id;
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
FROM _hierarchy_finance_reports_test_result
ORDER BY sort_order;

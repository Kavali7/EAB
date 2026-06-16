-- ============================================================================
-- Test E2E DB - Hierarchical permissions applied to members and programs
-- ============================================================================
-- Objectif :
--   1. Creer deux unites temporaires dans une organisation existante.
--   2. Creer un utilisateur temporaire rattache au niveau superieur.
--   3. Verifier que l'acces direct a son niveau reste ouvert.
--   4. Verifier que l'acces descendant depend de la matrice members/programs.
--   5. Nettoyer toutes les donnees de test avant COMMIT.
-- ============================================================================

DROP TABLE IF EXISTS _hierarchy_members_programs_test_result;
CREATE TEMP TABLE _hierarchy_members_programs_test_result (
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
  v_direct_member_view BOOLEAN;
  v_child_member_view_before BOOLEAN;
  v_child_member_view_after BOOLEAN;
  v_child_member_create BOOLEAN;
  v_child_program_create BOOLEAN;
  v_child_program_update_before BOOLEAN;
  v_child_program_update_after BOOLEAN;
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
    'codex_perm_parent_' || v_suffix,
    'Niveau parent test permissions',
    120,
    FALSE,
    TRUE,
    FALSE,
    TRUE,
    FALSE,
    FALSE,
    FALSE,
    FALSE,
    TRUE
  ),
  (
    v_child_type_id,
    v_org_id,
    'codex_perm_child_' || v_suffix,
    'Niveau enfant test permissions',
    121,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
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
    'Unite parent test permissions',
    'TPARENT-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  ),
  (
    v_child_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Unite enfant test permissions',
    'TCHILD-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
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
    'codex-permissions-' || v_suffix || '@example.test',
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Utilisateur test permissions'),
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
    'Utilisateur test permissions',
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

  SELECT user_can_access_members_scope(v_parent_unit_id, NULL, 'view_details')
  INTO v_direct_member_view;

  SELECT user_can_access_members_scope(v_child_unit_id, NULL, 'view_details')
  INTO v_child_member_view_before;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'members',
    'view_details',
    FALSE,
    FALSE,
    'Test refus lecture membres'
  );

  SELECT user_can_access_members_scope(v_child_unit_id, NULL, 'view_details')
  INTO v_child_member_view_after;

  SELECT user_can_access_members_scope(v_child_unit_id, NULL, 'create')
  INTO v_child_member_create;

  SELECT user_can_access_programs_scope(v_child_unit_id, NULL, 'create')
  INTO v_child_program_create;

  PERFORM set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'programs',
    'update',
    TRUE,
    TRUE,
    'Test update programme en attente'
  );

  SELECT user_can_access_programs_scope(v_child_unit_id, NULL, 'update')
  INTO v_child_program_update_before;

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
    AND domain.code = 'programs'
    AND action.organization_id = v_org_id
    AND action.code = 'update';

  SELECT user_can_access_programs_scope(v_child_unit_id, NULL, 'update')
  INTO v_child_program_update_after;

  INSERT INTO _hierarchy_members_programs_test_result VALUES
    (
      1,
      'acces_direct_conserve',
      v_direct_member_view = TRUE,
      'direct_member_view=' || COALESCE(v_direct_member_view::text, 'NULL')
    ),
    (
      2,
      'lecture_membres_descendant_autorisee_par_defaut',
      v_child_member_view_before = TRUE,
      'member_view_before_override=' ||
        COALESCE(v_child_member_view_before::text, 'NULL')
    ),
    (
      3,
      'lecture_membres_descendant_refusee_par_exception',
      v_child_member_view_after = FALSE,
      'member_view_after_override=' ||
        COALESCE(v_child_member_view_after::text, 'NULL')
    ),
    (
      4,
      'creation_membres_descendant_refusee_si_non_autorisee',
      v_child_member_create = FALSE,
      'member_create=' || COALESCE(v_child_member_create::text, 'NULL')
    ),
    (
      5,
      'creation_programmes_descendant_autorisee_par_capacite',
      v_child_program_create = TRUE,
      'program_create=' || COALESCE(v_child_program_create::text, 'NULL')
    ),
    (
      6,
      'modification_programmes_en_attente_refusee',
      v_child_program_update_before = FALSE,
      'program_update_before_acceptance=' ||
        COALESCE(v_child_program_update_before::text, 'NULL')
    ),
    (
      7,
      'modification_programmes_acceptee_autorisee',
      v_child_program_update_after = TRUE,
      'program_update_after_acceptance=' ||
        COALESCE(v_child_program_update_after::text, 'NULL')
    );

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);
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
FROM _hierarchy_members_programs_test_result
ORDER BY sort_order;

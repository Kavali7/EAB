-- ============================================================================
-- Test E2E DB - Onboarding organisation
-- ============================================================================
-- Objectif :
--   1. Simuler un nouvel utilisateur authentifie sans organisation.
--   2. Creer une organisation autonome via create_organization_onboarding().
--   3. Verifier la structure minimale et le rattachement admin.
--   4. Nettoyer les donnees de test avant COMMIT.
--
-- Ce script ne laisse pas de donnees de test persistantes.
-- ============================================================================

DROP TABLE IF EXISTS _organization_onboarding_test_result;
CREATE TEMP TABLE _organization_onboarding_test_result (
  sort_order INTEGER,
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
) ON COMMIT PRESERVE ROWS;

BEGIN;

DO $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_email TEXT := 'codex-onboarding-test-' ||
    replace(gen_random_uuid()::text, '-', '') || '@example.test';
  v_result JSONB;
  v_org_id UUID;
  v_primary_unit_id UUID;
  v_profile profiles%ROWTYPE;
  v_org organizations%ROWTYPE;
  v_unit_count INTEGER;
  v_type_count INTEGER;
  v_local_type_count INTEGER;
BEGIN
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
    v_email,
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Admin onboarding test'),
    NOW(),
    NOW()
  );

  PERFORM set_config('request.jwt.claim.sub', v_user_id::text, true);

  SELECT create_organization_onboarding(
    p_name := 'Eglise Test Onboarding',
    p_sigle := 'ETO',
    p_description := 'Organisation creee par test automatise',
    p_structure_model := 'single',
    p_root_unit_name := 'Assemblee Test',
    p_skip_steps := '["logo","colors","contact"]'::jsonb
  )
  INTO v_result;

  v_org_id := (v_result->>'organization_id')::UUID;
  v_primary_unit_id := (v_result->>'primary_unit_id')::UUID;

  SELECT *
  INTO v_org
  FROM organizations
  WHERE id = v_org_id;

  SELECT *
  INTO v_profile
  FROM profiles
  WHERE id = v_user_id;

  SELECT COUNT(*)
  INTO v_type_count
  FROM church_unit_types
  WHERE organization_id = v_org_id;

  SELECT COUNT(*)
  INTO v_local_type_count
  FROM church_unit_types
  WHERE organization_id = v_org_id
    AND code = 'local_church'
    AND is_local = TRUE
    AND can_have_members = TRUE;

  SELECT COUNT(*)
  INTO v_unit_count
  FROM church_units
  WHERE organization_id = v_org_id
    AND id = v_primary_unit_id
    AND nom = 'Assemblee Test'
    AND active = TRUE;

  INSERT INTO _organization_onboarding_test_result VALUES
    (
      1,
      'organisation_creee',
      v_org.id = v_org_id AND v_org.name = 'Eglise Test Onboarding',
      'organization_id=' || COALESCE(v_org_id::text, 'NULL')
    ),
    (
      2,
      'code_unique_genere',
      v_org.code LIKE 'ETO-%',
      'code=' || COALESCE(v_org.code, 'NULL')
    ),
    (
      3,
      'etapes_ignorees_conservees',
      (v_org.parametres #> '{onboarding,skipped_steps}') = '["logo","colors","contact"]'::jsonb,
      'skipped_steps=' || COALESCE((v_org.parametres #> '{onboarding,skipped_steps}')::text, 'NULL')
    ),
    (
      4,
      'profil_admin_rattache',
      v_profile.organization_id = v_org_id
        AND v_profile.role = 'admin_national'
        AND v_profile.primary_church_unit_id = v_primary_unit_id,
      'profile_org=' || COALESCE(v_profile.organization_id::text, 'NULL') ||
        ', role=' || COALESCE(v_profile.role::text, 'NULL') ||
        ', primary_unit=' || COALESCE(v_profile.primary_church_unit_id::text, 'NULL')
    ),
    (
      5,
      'type_local_cree',
      v_type_count = 1 AND v_local_type_count = 1,
      'type_count=' || v_type_count::text ||
        ', local_type_count=' || v_local_type_count::text
    ),
    (
      6,
      'unite_principale_creee',
      v_unit_count = 1,
      'primary_unit_id=' || COALESCE(v_primary_unit_id::text, 'NULL') ||
        ', unit_count=' || v_unit_count::text
    );

  DELETE FROM organizations WHERE id = v_org_id;
  DELETE FROM profiles WHERE id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
  PERFORM set_config('request.jwt.claim.sub', '', true);
END $$;

COMMIT;

SELECT check_name, ok, detail
FROM _organization_onboarding_test_result
ORDER BY sort_order;

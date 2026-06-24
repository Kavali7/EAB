-- ============================================================================
-- Test DB - Platform owner console RPCs
-- ============================================================================
-- Objectif :
--   1. Refuser les RPC console a un utilisateur non proprietaire plateforme.
--   2. Autoriser la liste et la modification mobile avec app_metadata owner.
--   3. Restaurer la politique mobile initiale de l'organisation cible.
-- ============================================================================

DROP TABLE IF EXISTS _platform_console_test_result;
CREATE TEMP TABLE _platform_console_test_result (
  sort_order INTEGER,
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
) ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _platform_console_context;
CREATE TEMP TABLE _platform_console_context (
  user_id UUID NOT NULL,
  org_id UUID NOT NULL,
  original_parametres JSONB NOT NULL
) ON COMMIT DROP;

GRANT SELECT, INSERT, UPDATE, DELETE ON _platform_console_test_result TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON _platform_console_context TO authenticated;

BEGIN;

INSERT INTO _platform_console_context (
  user_id,
  org_id,
  original_parametres
)
SELECT
  p.id,
  o.id,
  coalesce(o.parametres, '{}'::jsonb)
FROM organizations o
JOIN profiles p ON p.organization_id = o.id
WHERE p.role = 'admin_national'
ORDER BY o.created_at, p.created_at
LIMIT 1;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM _platform_console_context) THEN
    RAISE EXCEPTION 'Aucune organisation avec profil admin_national trouvee.';
  END IF;
END $$;

SET LOCAL ROLE authenticated;

SELECT
  set_config('request.jwt.claim.sub', user_id::text, true),
  set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub',
      user_id,
      'role',
      'authenticated',
      'app_metadata',
      jsonb_build_object('role', 'authenticated')
    )::text,
    true
  )
FROM _platform_console_context;

DO $$
DECLARE
  v_blocked BOOLEAN := FALSE;
BEGIN
  BEGIN
    PERFORM platform_list_organizations();
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_blocked := TRUE;
    WHEN OTHERS THEN
      IF SQLSTATE = '42501' THEN
        v_blocked := TRUE;
      ELSE
        RAISE;
      END IF;
  END;

  INSERT INTO _platform_console_test_result
  VALUES (
    1,
    'non_proprietaire_refuse',
    v_blocked,
    'blocked=' || v_blocked
  );
END $$;

RESET ROLE;

DO $$
DECLARE
  v_user_id UUID;
  v_org_id UUID;
  v_unit_id UUID;
  v_original_app_meta JSONB;
  v_profile_blocked BOOLEAN := FALSE;
  v_scope_blocked BOOLEAN := FALSE;
BEGIN
  SELECT user_id, org_id
  INTO v_user_id, v_org_id
  FROM _platform_console_context
  LIMIT 1;

  SELECT coalesce(
    p.primary_church_unit_id,
    (
      SELECT cu.id
      FROM church_units cu
      WHERE cu.organization_id = v_org_id
      ORDER BY cu.created_at, cu.id
      LIMIT 1
    )
  )
  INTO v_unit_id
  FROM profiles p
  WHERE p.id = v_user_id;

  SELECT raw_app_meta_data INTO v_original_app_meta
  FROM auth.users
  WHERE id = v_user_id;

  UPDATE auth.users
  SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('platform_owner', TRUE, 'role', 'platform_owner')
  WHERE id = v_user_id;

  BEGIN
    UPDATE profiles
    SET full_name = full_name
    WHERE id = v_user_id;
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_profile_blocked := TRUE;
    WHEN OTHERS THEN
      IF SQLSTATE = '42501' THEN
        v_profile_blocked := TRUE;
      ELSE
        RAISE;
      END IF;
  END;

  BEGIN
    INSERT INTO church_unit_user_scopes (
      id,
      organization_id,
      user_id,
      unit_id,
      role,
      can_manage_children
    )
    VALUES (
      gen_random_uuid(),
      v_org_id,
      v_user_id,
      v_unit_id,
      'admin_national',
      TRUE
    );
  EXCEPTION
    WHEN insufficient_privilege THEN
      v_scope_blocked := TRUE;
    WHEN OTHERS THEN
      IF SQLSTATE = '42501' THEN
        v_scope_blocked := TRUE;
      ELSE
        RAISE;
      END IF;
  END;

  UPDATE auth.users
  SET raw_app_meta_data = v_original_app_meta
  WHERE id = v_user_id;

  INSERT INTO _platform_console_test_result
  VALUES (
    3,
    'profil_eglise_refuse_pour_proprietaire',
    v_profile_blocked,
    'blocked=' || v_profile_blocked
  );

  INSERT INTO _platform_console_test_result
  VALUES (
    4,
    'perimetre_eglise_refuse_pour_proprietaire',
    v_scope_blocked,
    'blocked=' || v_scope_blocked
  );
END $$;

SET LOCAL ROLE authenticated;

SELECT set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',
    user_id,
    'role',
    'authenticated',
    'app_metadata',
    jsonb_build_object('platform_owner', TRUE)
  )::text,
  true
)
FROM _platform_console_context;

DO $$
DECLARE
  v_count INTEGER := 0;
  v_user_id UUID;
BEGIN
  PERFORM set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000099999',
    TRUE
  );
  PERFORM set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub',
      '00000000-0000-0000-0000-000000099999',
      'role',
      'authenticated',
      'app_metadata',
      jsonb_build_object('platform_owner', TRUE)
    )::TEXT,
    TRUE
  );

  SELECT COUNT(*) INTO v_count
  FROM organizations;

  INSERT INTO _platform_console_test_result
  VALUES (
    2,
    'proprietaire_sans_profil_ne_lit_pas_organisations_directement',
    v_count = 0,
    'direct_org_count=' || v_count
  );

  SELECT user_id INTO v_user_id
  FROM _platform_console_context
  LIMIT 1;

  PERFORM set_config('request.jwt.claim.sub', v_user_id::TEXT, TRUE);
  PERFORM set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub',
      v_user_id,
      'role',
      'authenticated',
      'app_metadata',
      jsonb_build_object('platform_owner', TRUE)
    )::TEXT,
    TRUE
  );

  SELECT COUNT(*) INTO v_count
  FROM platform_list_organizations();

  INSERT INTO _platform_console_test_result
  VALUES (
    5,
    'proprietaire_liste_organisations',
    v_count > 0,
    'org_count=' || v_count
  );
END $$;

DO $$
DECLARE
  v_org_id UUID;
  v_policy JSONB;
  v_stored JSONB;
BEGIN
  SELECT org_id INTO v_org_id FROM _platform_console_context LIMIT 1;

  SELECT platform_update_organization_mobile_access(
    v_org_id,
    'restricted',
    ARRAY['/', '/members', '/programs']::TEXT[]
  )
  INTO v_policy;

  SELECT parametres -> 'mobile_access'
  INTO v_stored
  FROM organizations
  WHERE id = v_org_id;

  INSERT INTO _platform_console_test_result
  VALUES (
    6,
    'proprietaire_modifie_mobile_access',
    v_policy = v_stored
      AND v_stored ->> 'mode' = 'restricted'
      AND v_stored -> 'allowed_routes' ? '/members',
    'policy=' || v_stored::TEXT
  );
END $$;

RESET ROLE;

UPDATE organizations o
SET parametres = c.original_parametres
FROM _platform_console_context c
WHERE o.id = c.org_id;

COMMIT;

SELECT check_name, ok, detail
FROM _platform_console_test_result
ORDER BY sort_order;

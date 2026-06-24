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
    3,
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
    4,
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

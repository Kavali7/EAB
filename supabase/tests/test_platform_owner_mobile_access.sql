-- ============================================================================
-- Test DB - Platform owner protection for mobile access policy
-- ============================================================================
-- Objectif :
--   1. Simuler un admin national d'eglise non proprietaire plateforme.
--   2. Verifier que mobile_access est bloque.
--   3. Simuler le meme compte avec app_metadata.platform_owner = true.
--   4. Verifier que mobile_access est autorise.
-- ============================================================================

DROP TABLE IF EXISTS _platform_mobile_access_test_result;
CREATE TEMP TABLE _platform_mobile_access_test_result (
  sort_order INTEGER,
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
) ON COMMIT PRESERVE ROWS;

DROP TABLE IF EXISTS _platform_mobile_access_context;
CREATE TEMP TABLE _platform_mobile_access_context (
  user_id UUID NOT NULL,
  org_id UUID NOT NULL,
  original_parametres JSONB NOT NULL
) ON COMMIT DROP;

GRANT SELECT, INSERT, UPDATE, DELETE ON _platform_mobile_access_test_result TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON _platform_mobile_access_context TO authenticated;

BEGIN;

INSERT INTO _platform_mobile_access_context (
  user_id,
  org_id,
  original_parametres
)
SELECT
  p.id,
  p.organization_id,
  coalesce(o.parametres, '{}'::jsonb)
FROM profiles p
JOIN organizations o ON o.id = p.organization_id
WHERE p.role = 'admin_national'
  AND p.organization_id IS NOT NULL
ORDER BY p.created_at
LIMIT 1;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM _platform_mobile_access_context) THEN
    RAISE EXCEPTION 'Aucun profil admin_national avec organisation_id trouve.';
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
FROM _platform_mobile_access_context;

DO $$
DECLARE
  v_org_id UUID;
  v_blocked BOOLEAN := FALSE;
BEGIN
  SELECT org_id INTO v_org_id FROM _platform_mobile_access_context LIMIT 1;

  BEGIN
    UPDATE organizations
    SET parametres = jsonb_set(
      coalesce(parametres, '{}'::jsonb),
      '{mobile_access}',
      '{"mode":"restricted","allowed_routes":["/"]}'::jsonb,
      TRUE
    )
    WHERE id = v_org_id;
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

  INSERT INTO _platform_mobile_access_test_result
  VALUES (
    1,
    'admin_eglise_non_proprietaire_bloque',
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
FROM _platform_mobile_access_context;

DO $$
DECLARE
  v_org_id UUID;
  v_allowed BOOLEAN := TRUE;
BEGIN
  SELECT org_id INTO v_org_id FROM _platform_mobile_access_context LIMIT 1;

  BEGIN
    UPDATE organizations
    SET parametres = jsonb_set(
      coalesce(parametres, '{}'::jsonb),
      '{mobile_access}',
      '{"mode":"restricted","allowed_routes":["/","/members"]}'::jsonb,
      TRUE
    )
    WHERE id = v_org_id;
  EXCEPTION
    WHEN OTHERS THEN
      v_allowed := FALSE;
  END;

  INSERT INTO _platform_mobile_access_test_result
  VALUES (
    2,
    'proprietaire_plateforme_autorise',
    v_allowed,
    'allowed=' || v_allowed
  );
END $$;

RESET ROLE;

UPDATE organizations o
SET parametres = c.original_parametres
FROM _platform_mobile_access_context c
WHERE o.id = c.org_id;

COMMIT;

SELECT check_name, ok, detail
FROM _platform_mobile_access_test_result
ORDER BY sort_order;

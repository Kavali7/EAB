-- ============================================================================
-- Platform-owner console RPCs
-- ============================================================================
-- The SaaS/platform owner can supervise organizations without receiving broad
-- direct table rights in the frontend. These RPCs are deliberately narrow:
--   1. list organization identity and mobile policy data;
--   2. update only organizations.parametres.mobile_access.

CREATE OR REPLACE FUNCTION platform_owner_jwt_claim_grants_access()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  SELECT
    lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '')) IN (
      'platform_owner',
      'platform_admin',
      'owner'
    )
    OR lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'app_role', '')) IN (
      'platform_owner',
      'platform_admin',
      'owner'
    )
    OR lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'platform_owner', 'false')) IN (
      'true',
      '1',
      'yes',
      'on'
    )
    OR lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'is_platform_owner', 'false')) IN (
      'true',
      '1',
      'yes',
      'on'
    );
$$;

COMMENT ON FUNCTION platform_owner_jwt_claim_grants_access() IS
  'JWT-only platform-owner check for SECURITY DEFINER RPCs. It intentionally ignores SQL technical roles.';

CREATE OR REPLACE FUNCTION platform_list_organizations()
RETURNS TABLE (
  id UUID,
  name TEXT,
  sigle TEXT,
  code TEXT,
  description TEXT,
  logo_url TEXT,
  couleur_primaire TEXT,
  couleur_secondaire TEXT,
  adresse TEXT,
  telephone TEXT,
  email TEXT,
  site_web TEXT,
  devise TEXT,
  parametres JSONB,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT platform_owner_jwt_claim_grants_access() THEN
    RAISE EXCEPTION 'Acces reserve au proprietaire plateforme.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    o.id,
    o.name,
    o.sigle,
    o.code,
    o.description,
    o.logo_url,
    o.couleur_primaire,
    o.couleur_secondaire,
    o.adresse,
    o.telephone,
    o.email,
    o.site_web,
    o.devise,
    coalesce(o.parametres, '{}'::jsonb) AS parametres,
    o.created_at
  FROM organizations o
  ORDER BY lower(coalesce(o.name, o.sigle, o.code, o.id::text));
END;
$$;

COMMENT ON FUNCTION platform_list_organizations() IS
  'Lists organizations for the SaaS/platform owner console. Requires is_platform_owner().';

CREATE OR REPLACE FUNCTION platform_update_organization_mobile_access(
  p_org_id UUID,
  p_mode TEXT,
  p_allowed_routes TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_routes TEXT[];
  v_policy JSONB;
  v_updated JSONB;
BEGIN
  IF NOT platform_owner_jwt_claim_grants_access() THEN
    RAISE EXCEPTION 'Acces reserve au proprietaire plateforme.'
      USING ERRCODE = '42501';
  END IF;

  IF p_mode NOT IN ('full', 'restricted') THEN
    RAISE EXCEPTION 'Mode mobile invalide : %', p_mode
      USING ERRCODE = '22023';
  END IF;

  v_routes := coalesce(
    p_allowed_routes,
    ARRAY[
      '/',
      '/members',
      '/programs',
      '/calendar',
      '/reports-rapport-mensuel',
      '/financial-campaigns',
      '/accounting',
      '/accounting-treasury',
      '/structure',
      '/organization-settings'
    ]::TEXT[]
  );

  IF array_length(v_routes, 1) IS NULL THEN
    v_routes := ARRAY['/']::TEXT[];
  END IF;

  IF NOT '/' = ANY(v_routes) THEN
    v_routes := array_prepend('/', v_routes);
  END IF;

  SELECT array_agg(DISTINCT route ORDER BY route)
  INTO v_routes
  FROM unnest(v_routes) AS allowed_route(route)
  WHERE btrim(route) <> '';

  v_policy := jsonb_build_object(
    'mode',
    p_mode,
    'allowed_routes',
    to_jsonb(v_routes)
  );

  UPDATE organizations
  SET
    parametres = jsonb_set(
      coalesce(parametres, '{}'::jsonb),
      '{mobile_access}',
      v_policy,
      TRUE
    ),
    updated_at = NOW()
  WHERE id = p_org_id
  RETURNING parametres -> 'mobile_access'
  INTO v_updated;

  IF v_updated IS NULL THEN
    RAISE EXCEPTION 'Organisation introuvable : %', p_org_id
      USING ERRCODE = 'P0002';
  END IF;

  RETURN v_updated;
END;
$$;

COMMENT ON FUNCTION platform_update_organization_mobile_access(UUID, TEXT, TEXT[]) IS
  'Updates only organizations.parametres.mobile_access for a target organization. Requires is_platform_owner().';

ALTER FUNCTION platform_list_organizations() OWNER TO postgres;
ALTER FUNCTION platform_update_organization_mobile_access(UUID, TEXT, TEXT[]) OWNER TO postgres;
ALTER FUNCTION platform_owner_jwt_claim_grants_access() OWNER TO postgres;

GRANT EXECUTE ON FUNCTION platform_list_organizations() TO authenticated;
GRANT EXECUTE ON FUNCTION platform_update_organization_mobile_access(UUID, TEXT, TEXT[]) TO authenticated;

-- ============================================================================
-- Platform-owner protection for organization mobile access policy
-- ============================================================================
-- The mobile UX restriction is a SaaS/platform administration feature.
-- Church-level roles, including admin_national, can still update normal
-- organization identity, branding, contact and fiscal settings, but cannot
-- change organizations.parametres.mobile_access.

CREATE OR REPLACE FUNCTION is_platform_owner()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  SELECT
    current_user IN ('postgres', 'service_role', 'supabase_admin')
    OR lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '')) IN (
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

COMMENT ON FUNCTION is_platform_owner() IS
  'Returns true only for platform/SaaS owner accounts marked in Supabase Auth app_metadata, or technical SQL/service roles.';

CREATE OR REPLACE FUNCTION prevent_mobile_access_update_without_platform_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF coalesce(OLD.parametres -> 'mobile_access', 'null'::jsonb)
      IS DISTINCT FROM coalesce(NEW.parametres -> 'mobile_access', 'null'::jsonb)
     AND NOT is_platform_owner() THEN
    RAISE EXCEPTION
      'Seul un proprietaire plateforme peut modifier la politique mobile d une organisation.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION prevent_mobile_access_update_without_platform_owner() IS
  'Blocks updates to organizations.parametres.mobile_access unless the caller is a platform owner.';

DROP TRIGGER IF EXISTS protect_organization_mobile_access ON organizations;

CREATE TRIGGER protect_organization_mobile_access
  BEFORE UPDATE OF parametres ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION prevent_mobile_access_update_without_platform_owner();

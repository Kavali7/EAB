-- ============================================================================
-- Platform-owner tenant isolation
-- ============================================================================
-- A platform owner administers the SaaS console through dedicated RPCs.
-- It must not become an ordinary church user by receiving a tenant profile or
-- a church-unit scope, otherwise it would see one church's business data.

CREATE OR REPLACE FUNCTION auth_user_has_platform_owner_claim(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    lower(coalesce(u.raw_app_meta_data ->> 'role', '')) IN (
      'platform_owner',
      'platform_admin',
      'owner'
    )
    OR lower(coalesce(u.raw_app_meta_data ->> 'app_role', '')) IN (
      'platform_owner',
      'platform_admin',
      'owner'
    )
    OR lower(coalesce(u.raw_app_meta_data ->> 'platform_owner', 'false')) IN (
      'true',
      '1',
      'yes',
      'on'
    )
    OR lower(coalesce(u.raw_app_meta_data ->> 'is_platform_owner', 'false')) IN (
      'true',
      '1',
      'yes',
      'on'
    )
  FROM auth.users u
  WHERE u.id = p_user_id;
$$;

COMMENT ON FUNCTION auth_user_has_platform_owner_claim(UUID) IS
  'Checks Supabase Auth app_metadata for platform-owner accounts without relying on the current JWT.';

CREATE OR REPLACE FUNCTION prevent_platform_owner_profile_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth_user_has_platform_owner_claim(NEW.id)
     AND (
       NEW.organization_id IS NOT NULL
       OR NEW.primary_church_unit_id IS NOT NULL
     ) THEN
    RAISE EXCEPTION
      'Un proprietaire plateforme ne peut pas etre rattache a une organisation cliente.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION prevent_platform_owner_profile_assignment() IS
  'Prevents platform-owner Auth users from receiving ordinary tenant profile scope.';

DROP TRIGGER IF EXISTS protect_platform_owner_profile_assignment ON profiles;

CREATE TRIGGER protect_platform_owner_profile_assignment
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION prevent_platform_owner_profile_assignment();

CREATE OR REPLACE FUNCTION prevent_platform_owner_unit_scope_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth_user_has_platform_owner_claim(NEW.user_id) THEN
    RAISE EXCEPTION
      'Un proprietaire plateforme ne peut pas recevoir un perimetre d eglise cliente.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION prevent_platform_owner_unit_scope_assignment() IS
  'Prevents platform-owner Auth users from receiving church-unit scopes.';

DROP TRIGGER IF EXISTS protect_platform_owner_unit_scope_assignment
  ON church_unit_user_scopes;

CREATE TRIGGER protect_platform_owner_unit_scope_assignment
  BEFORE INSERT OR UPDATE ON church_unit_user_scopes
  FOR EACH ROW
  EXECUTE FUNCTION prevent_platform_owner_unit_scope_assignment();

ALTER FUNCTION auth_user_has_platform_owner_claim(UUID) OWNER TO postgres;
ALTER FUNCTION prevent_platform_owner_profile_assignment() OWNER TO postgres;
ALTER FUNCTION prevent_platform_owner_unit_scope_assignment() OWNER TO postgres;

-- ============================================================================
-- Apply hierarchical permissions to members and programs
-- ============================================================================
-- The flexible hierarchy gives a user a structural scope; the permission matrix
-- decides what that scope can do on a descendant unit for each business domain.
--
-- This migration keeps direct access unchanged:
--   - admin_national keeps full tenant access;
--   - users keep direct access to their primary unit and explicit scopes;
--   - legacy assemblee access remains a fallback only for rows not yet linked
--     to a flexible church unit.
--
-- Descendant access is now controlled by the point-by-point matrix for:
--   - members;
--   - families;
--   - programs.

CREATE OR REPLACE FUNCTION user_has_direct_church_unit_access(
  target_unit_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_user_role role_utilisateur;
  v_user_org_id UUID;
  v_primary_unit_id UUID;
  v_target_org_id UUID;
BEGIN
  IF v_user_id IS NULL OR target_unit_id IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT role, organization_id, primary_church_unit_id
  INTO v_user_role, v_user_org_id, v_primary_unit_id
  FROM profiles
  WHERE id = v_user_id;

  IF v_user_org_id IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT organization_id
  INTO v_target_org_id
  FROM church_units
  WHERE id = target_unit_id
    AND active = TRUE;

  IF v_target_org_id IS DISTINCT FROM v_user_org_id THEN
    RETURN FALSE;
  END IF;

  IF v_user_role = 'admin_national' THEN
    RETURN TRUE;
  END IF;

  IF v_primary_unit_id = target_unit_id THEN
    RETURN TRUE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM church_unit_user_scopes scope
    WHERE scope.user_id = v_user_id
      AND scope.organization_id = v_user_org_id
      AND scope.unit_id = target_unit_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION user_has_church_unit_action_permission(
  target_unit_id UUID,
  p_domain_code TEXT,
  p_action_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_user_role role_utilisateur;
  v_user_org_id UUID;
  v_primary_unit_id UUID;
BEGIN
  IF v_user_id IS NULL
     OR target_unit_id IS NULL
     OR NULLIF(trim(p_domain_code), '') IS NULL
     OR NULLIF(trim(p_action_code), '') IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT role, organization_id, primary_church_unit_id
  INTO v_user_role, v_user_org_id, v_primary_unit_id
  FROM profiles
  WHERE id = v_user_id;

  IF v_user_org_id IS NULL THEN
    RETURN FALSE;
  END IF;

  IF v_user_role = 'admin_national' THEN
    RETURN TRUE;
  END IF;

  IF user_has_direct_church_unit_access(target_unit_id) THEN
    RETURN TRUE;
  END IF;

  IF v_primary_unit_id IS NOT NULL
     AND is_church_unit_ancestor(v_primary_unit_id, target_unit_id)
     AND get_church_hierarchy_permission(
       v_primary_unit_id,
       target_unit_id,
       p_domain_code,
       p_action_code
     ) THEN
    RETURN TRUE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM church_unit_user_scopes scope
    WHERE scope.user_id = v_user_id
      AND scope.organization_id = v_user_org_id
      AND scope.can_manage_children = TRUE
      AND is_church_unit_ancestor(scope.unit_id, target_unit_id)
      AND get_church_hierarchy_permission(
        scope.unit_id,
        target_unit_id,
        p_domain_code,
        p_action_code
      )
  );
END;
$$;

CREATE OR REPLACE FUNCTION user_can_access_members_scope(
  p_church_unit_id UUID,
  p_assemblee_id UUID,
  p_action_code TEXT
)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    get_user_role() = 'admin_national'
    OR (
      p_church_unit_id IS NOT NULL
      AND user_has_church_unit_action_permission(
        p_church_unit_id,
        'members',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_families_scope(
  p_church_unit_id UUID,
  p_assemblee_id UUID,
  p_action_code TEXT
)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    get_user_role() = 'admin_national'
    OR (
      p_church_unit_id IS NOT NULL
      AND user_has_church_unit_action_permission(
        p_church_unit_id,
        'families',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_programs_scope(
  p_church_unit_id UUID,
  p_assemblee_id UUID,
  p_action_code TEXT
)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    get_user_role() = 'admin_national'
    OR (
      p_church_unit_id IS NOT NULL
      AND user_has_church_unit_action_permission(
        p_church_unit_id,
        'programs',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

DROP POLICY IF EXISTS "Users can view membres based on access" ON membres;
DROP POLICY IF EXISTS "Users can manage membres based on access" ON membres;
DROP POLICY IF EXISTS "Users can view familles based on access" ON familles;
DROP POLICY IF EXISTS "Users can manage familles based on access" ON familles;
DROP POLICY IF EXISTS "Users can view programmes based on access" ON programmes;
DROP POLICY IF EXISTS "Users can manage programmes based on access" ON programmes;

DROP POLICY IF EXISTS "Users can view membres based on hierarchy permissions"
  ON membres;
DROP POLICY IF EXISTS "Users can create membres based on hierarchy permissions"
  ON membres;
DROP POLICY IF EXISTS "Users can update membres based on hierarchy permissions"
  ON membres;
DROP POLICY IF EXISTS "Users can delete membres based on hierarchy permissions"
  ON membres;

DROP POLICY IF EXISTS "Users can view familles based on hierarchy permissions"
  ON familles;
DROP POLICY IF EXISTS "Users can create familles based on hierarchy permissions"
  ON familles;
DROP POLICY IF EXISTS "Users can update familles based on hierarchy permissions"
  ON familles;
DROP POLICY IF EXISTS "Users can delete familles based on hierarchy permissions"
  ON familles;

DROP POLICY IF EXISTS "Users can view programmes based on hierarchy permissions"
  ON programmes;
DROP POLICY IF EXISTS "Users can create programmes based on hierarchy permissions"
  ON programmes;
DROP POLICY IF EXISTS "Users can update programmes based on hierarchy permissions"
  ON programmes;
DROP POLICY IF EXISTS "Users can delete programmes based on hierarchy permissions"
  ON programmes;

CREATE POLICY "Users can view membres based on hierarchy permissions"
  ON membres FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_members_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create membres based on hierarchy permissions"
  ON membres FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_members_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update membres based on hierarchy permissions"
  ON membres FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_members_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_members_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete membres based on hierarchy permissions"
  ON membres FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_members_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view familles based on hierarchy permissions"
  ON familles FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_families_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create familles based on hierarchy permissions"
  ON familles FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_families_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update familles based on hierarchy permissions"
  ON familles FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_families_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_families_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete familles based on hierarchy permissions"
  ON familles FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_families_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view programmes based on hierarchy permissions"
  ON programmes FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_programs_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create programmes based on hierarchy permissions"
  ON programmes FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_programs_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update programmes based on hierarchy permissions"
  ON programmes FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_programs_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_programs_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete programmes based on hierarchy permissions"
  ON programmes FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_programs_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

GRANT EXECUTE ON FUNCTION user_has_direct_church_unit_access(UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_has_church_unit_action_permission(UUID, TEXT, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_members_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_families_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_programs_scope(UUID, UUID, TEXT)
  TO authenticated;

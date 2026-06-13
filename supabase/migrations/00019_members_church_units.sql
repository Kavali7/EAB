-- ============================================================================
-- EAB Backend - 00019 Members linked to flexible church units
-- ============================================================================
-- Connects the members module to the generic church_units hierarchy while
-- preserving legacy assemblee references during the progressive migration.

ALTER TABLE membres
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE familles
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_membres_church_unit
  ON membres(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_familles_church_unit
  ON familles(church_unit_id);

COMMENT ON COLUMN membres.church_unit_id IS
  'Flexible church unit that owns this member. Kept in sync with id_assemblee_locale during migration.';
COMMENT ON COLUMN familles.church_unit_id IS
  'Flexible church unit that owns this family. Kept in sync with id_assemblee_locale during migration.';

UPDATE membres m
SET church_unit_id = cu.id
FROM church_units cu
WHERE m.church_unit_id IS NULL
  AND m.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = m.id_assemblee_locale
  AND cu.organization_id = m.organization_id;

UPDATE familles f
SET church_unit_id = cu.id
FROM church_units cu
WHERE f.church_unit_id IS NULL
  AND f.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = f.id_assemblee_locale
  AND cu.organization_id = f.organization_id;

CREATE OR REPLACE FUNCTION sync_member_church_unit_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_legacy_assemblee_id UUID;
  v_church_unit_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    NEW.organization_id := get_user_organization_id();
  END IF;

  IF NEW.church_unit_id IS NULL AND NEW.id_assemblee_locale IS NOT NULL THEN
    SELECT id INTO v_church_unit_id
    FROM church_units
    WHERE organization_id = NEW.organization_id
      AND legacy_assemblee_id = NEW.id_assemblee_locale
    LIMIT 1;

    NEW.church_unit_id := v_church_unit_id;
  END IF;

  IF NEW.id_assemblee_locale IS NULL AND NEW.church_unit_id IS NOT NULL THEN
    SELECT legacy_assemblee_id INTO v_legacy_assemblee_id
    FROM church_units
    WHERE id = NEW.church_unit_id
      AND organization_id = NEW.organization_id;

    NEW.id_assemblee_locale := v_legacy_assemblee_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION sync_family_church_unit_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_legacy_assemblee_id UUID;
  v_church_unit_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    NEW.organization_id := get_user_organization_id();
  END IF;

  IF NEW.church_unit_id IS NULL AND NEW.id_assemblee_locale IS NOT NULL THEN
    SELECT id INTO v_church_unit_id
    FROM church_units
    WHERE organization_id = NEW.organization_id
      AND legacy_assemblee_id = NEW.id_assemblee_locale
    LIMIT 1;

    NEW.church_unit_id := v_church_unit_id;
  END IF;

  IF NEW.id_assemblee_locale IS NULL AND NEW.church_unit_id IS NOT NULL THEN
    SELECT legacy_assemblee_id INTO v_legacy_assemblee_id
    FROM church_units
    WHERE id = NEW.church_unit_id
      AND organization_id = NEW.organization_id;

    NEW.id_assemblee_locale := v_legacy_assemblee_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_member_church_unit_scope_trigger ON membres;
CREATE TRIGGER sync_member_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON membres
  FOR EACH ROW EXECUTE FUNCTION sync_member_church_unit_scope();

DROP TRIGGER IF EXISTS sync_family_church_unit_scope_trigger ON familles;
CREATE TRIGGER sync_family_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON familles
  FOR EACH ROW EXECUTE FUNCTION sync_family_church_unit_scope();

CREATE OR REPLACE FUNCTION user_has_church_unit_access(target_unit_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  user_role role_utilisateur;
  primary_unit_id UUID;
BEGIN
  IF target_unit_id IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT role, primary_church_unit_id
  INTO user_role, primary_unit_id
  FROM profiles
  WHERE id = auth.uid();

  IF user_role = 'admin_national' THEN
    RETURN TRUE;
  END IF;

  IF primary_unit_id IS NOT NULL
     AND target_unit_id IN (
       SELECT unit_id FROM get_church_unit_descendants(primary_unit_id)
     ) THEN
    RETURN TRUE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM church_unit_user_scopes scope
    WHERE scope.user_id = auth.uid()
      AND scope.organization_id = get_user_organization_id()
      AND (
        scope.unit_id = target_unit_id
        OR (
          scope.can_manage_children
          AND target_unit_id IN (
            SELECT unit_id FROM get_church_unit_descendants(scope.unit_id)
          )
        )
      )
  );
END;
$$;

DROP POLICY IF EXISTS "Users can view membres based on access" ON membres;
DROP POLICY IF EXISTS "Users can manage membres based on access" ON membres;
DROP POLICY IF EXISTS "Users can view familles based on access" ON familles;
DROP POLICY IF EXISTS "Users can manage familles based on access" ON familles;

CREATE POLICY "Users can view membres based on access"
  ON membres FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage membres based on access"
  ON membres FOR ALL
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can view familles based on access"
  ON familles FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage familles based on access"
  ON familles FOR ALL
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

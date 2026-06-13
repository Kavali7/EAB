-- ============================================================================
-- EAB Backend - 00020 Programs linked to flexible church units
-- ============================================================================
-- Connects programmes to the generic church_units hierarchy while preserving
-- legacy assemblee references during the progressive migration.

ALTER TABLE programmes
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_programmes_church_unit
  ON programmes(church_unit_id);

COMMENT ON COLUMN programmes.church_unit_id IS
  'Flexible church unit that owns this programme. Kept in sync with id_assemblee_locale during migration.';

UPDATE programmes p
SET church_unit_id = cu.id
FROM church_units cu
WHERE p.church_unit_id IS NULL
  AND p.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = p.id_assemblee_locale
  AND cu.organization_id = p.organization_id;

CREATE OR REPLACE FUNCTION sync_program_church_unit_scope()
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

DROP TRIGGER IF EXISTS sync_program_church_unit_scope_trigger ON programmes;
CREATE TRIGGER sync_program_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON programmes
  FOR EACH ROW EXECUTE FUNCTION sync_program_church_unit_scope();

DROP POLICY IF EXISTS "Users can view programmes based on access" ON programmes;
DROP POLICY IF EXISTS "Users can manage programmes based on access" ON programmes;

CREATE POLICY "Users can view programmes based on access"
  ON programmes FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage programmes based on access"
  ON programmes FOR ALL
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

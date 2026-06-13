-- ============================================================================
-- EAB Backend - 00021 Monthly reports linked to flexible church units
-- ============================================================================
-- Connects monthly reports to the generic church_units hierarchy while keeping
-- the legacy local church reference for existing EAB demo data.

ALTER TABLE rapports_mensuels_eab
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE rapports_mensuels_eab
  ALTER COLUMN id_assemblee_locale DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rapports_church_unit
  ON rapports_mensuels_eab(church_unit_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_rapports_church_unit_periode
  ON rapports_mensuels_eab(organization_id, church_unit_id, annee, mois)
  WHERE church_unit_id IS NOT NULL;

COMMENT ON COLUMN rapports_mensuels_eab.church_unit_id IS
  'Flexible church unit/perimeter for this monthly report. Kept in sync with id_assemblee_locale during migration.';

UPDATE rapports_mensuels_eab r
SET church_unit_id = cu.id
FROM church_units cu
WHERE r.church_unit_id IS NULL
  AND r.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = r.id_assemblee_locale
  AND cu.organization_id = r.organization_id;

CREATE OR REPLACE FUNCTION sync_monthly_report_church_unit_scope()
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

DROP TRIGGER IF EXISTS sync_monthly_report_church_unit_scope_trigger
  ON rapports_mensuels_eab;
CREATE TRIGGER sync_monthly_report_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON rapports_mensuels_eab
  FOR EACH ROW EXECUTE FUNCTION sync_monthly_report_church_unit_scope();

DROP POLICY IF EXISTS "Users can view rapports based on access"
  ON rapports_mensuels_eab;
DROP POLICY IF EXISTS "Users can manage rapports based on access"
  ON rapports_mensuels_eab;

CREATE POLICY "Users can view rapports based on access"
  ON rapports_mensuels_eab FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage rapports based on access"
  ON rapports_mensuels_eab FOR ALL
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

-- ============================================================================
-- EAB Backend - 00023 Accounting scopes linked to flexible church units
-- ============================================================================
-- Extends the flexible church hierarchy to operational accounting tables while
-- keeping legacy assemblee references during the progressive migration.

ALTER TABLE centres_analytiques
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE tiers
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE ecritures_comptables
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE budgets_comptables
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE immobilisations_comptables
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE releves_bancaires
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_centres_church_unit
  ON centres_analytiques(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_tiers_church_unit
  ON tiers(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_ecritures_church_unit
  ON ecritures_comptables(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_budgets_church_unit
  ON budgets_comptables(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_immobilisations_church_unit
  ON immobilisations_comptables(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_releves_church_unit
  ON releves_bancaires(church_unit_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_budgets_church_unit_scope
  ON budgets_comptables(organization_id, exercice, church_unit_id, id_centre_analytique)
  WHERE church_unit_id IS NOT NULL;

COMMENT ON COLUMN centres_analytiques.church_unit_id IS
  'Flexible church unit/perimeter for this analytical center. Kept in sync with id_assemblee_locale during migration.';
COMMENT ON COLUMN tiers.church_unit_id IS
  'Flexible church unit/perimeter for this third party. Kept in sync with id_assemblee_locale during migration.';
COMMENT ON COLUMN ecritures_comptables.church_unit_id IS
  'Flexible church unit/perimeter for this accounting entry. Kept in sync with id_assemblee_locale during migration.';
COMMENT ON COLUMN budgets_comptables.church_unit_id IS
  'Flexible church unit/perimeter for this budget. Kept in sync with id_assemblee_locale during migration.';
COMMENT ON COLUMN immobilisations_comptables.church_unit_id IS
  'Flexible church unit/perimeter for this fixed asset. Kept in sync with id_assemblee_locale during migration.';
COMMENT ON COLUMN releves_bancaires.church_unit_id IS
  'Flexible church unit/perimeter for this bank statement. Kept in sync with id_assemblee_locale during migration.';

UPDATE centres_analytiques c
SET church_unit_id = cu.id
FROM church_units cu
WHERE c.church_unit_id IS NULL
  AND c.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = c.id_assemblee_locale
  AND cu.organization_id = c.organization_id;

UPDATE tiers t
SET church_unit_id = cu.id
FROM church_units cu
WHERE t.church_unit_id IS NULL
  AND t.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = t.id_assemblee_locale
  AND cu.organization_id = t.organization_id;

UPDATE ecritures_comptables e
SET church_unit_id = cu.id
FROM church_units cu
WHERE e.church_unit_id IS NULL
  AND e.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = e.id_assemblee_locale
  AND cu.organization_id = e.organization_id;

UPDATE budgets_comptables b
SET church_unit_id = cu.id
FROM church_units cu
WHERE b.church_unit_id IS NULL
  AND b.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = b.id_assemblee_locale
  AND cu.organization_id = b.organization_id;

UPDATE immobilisations_comptables i
SET church_unit_id = cu.id
FROM church_units cu
WHERE i.church_unit_id IS NULL
  AND i.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = i.id_assemblee_locale
  AND cu.organization_id = i.organization_id;

UPDATE releves_bancaires r
SET church_unit_id = cu.id
FROM church_units cu
WHERE r.church_unit_id IS NULL
  AND r.id_assemblee_locale IS NOT NULL
  AND cu.legacy_assemblee_id = r.id_assemblee_locale
  AND cu.organization_id = r.organization_id;

CREATE OR REPLACE FUNCTION sync_accounting_church_unit_scope()
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

DROP TRIGGER IF EXISTS sync_centre_church_unit_scope_trigger
  ON centres_analytiques;
CREATE TRIGGER sync_centre_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON centres_analytiques
  FOR EACH ROW EXECUTE FUNCTION sync_accounting_church_unit_scope();

DROP TRIGGER IF EXISTS sync_tiers_church_unit_scope_trigger
  ON tiers;
CREATE TRIGGER sync_tiers_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON tiers
  FOR EACH ROW EXECUTE FUNCTION sync_accounting_church_unit_scope();

DROP TRIGGER IF EXISTS sync_ecriture_church_unit_scope_trigger
  ON ecritures_comptables;
CREATE TRIGGER sync_ecriture_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON ecritures_comptables
  FOR EACH ROW EXECUTE FUNCTION sync_accounting_church_unit_scope();

DROP TRIGGER IF EXISTS sync_budget_church_unit_scope_trigger
  ON budgets_comptables;
CREATE TRIGGER sync_budget_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON budgets_comptables
  FOR EACH ROW EXECUTE FUNCTION sync_accounting_church_unit_scope();

DROP TRIGGER IF EXISTS sync_immobilisation_church_unit_scope_trigger
  ON immobilisations_comptables;
CREATE TRIGGER sync_immobilisation_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON immobilisations_comptables
  FOR EACH ROW EXECUTE FUNCTION sync_accounting_church_unit_scope();

DROP TRIGGER IF EXISTS sync_releve_church_unit_scope_trigger
  ON releves_bancaires;
CREATE TRIGGER sync_releve_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, id_assemblee_locale, church_unit_id
  ON releves_bancaires
  FOR EACH ROW EXECUTE FUNCTION sync_accounting_church_unit_scope();

DROP POLICY IF EXISTS "Users can view tiers based on access" ON tiers;
DROP POLICY IF EXISTS "Users can manage tiers based on access" ON tiers;
DROP POLICY IF EXISTS "Users can view ecritures based on access" ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can manage ecritures based on access" ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can view lignes via ecriture" ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can manage lignes via ecriture" ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can view budgets based on access" ON budgets_comptables;
DROP POLICY IF EXISTS "Users can manage budgets based on access" ON budgets_comptables;
DROP POLICY IF EXISTS "Users can view lignes budget via budget" ON lignes_budgets;
DROP POLICY IF EXISTS "Users can manage lignes budget via budget" ON lignes_budgets;
DROP POLICY IF EXISTS "Users can view immobilisations based on access" ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can manage immobilisations based on access" ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can view releves based on access" ON releves_bancaires;
DROP POLICY IF EXISTS "Users can manage releves based on access" ON releves_bancaires;

CREATE POLICY "Users can view tiers based on access"
  ON tiers FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
      OR (church_unit_id IS NULL AND id_assemblee_locale IS NULL)
    )
  );

CREATE POLICY "Users can manage tiers based on access"
  ON tiers FOR ALL
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

CREATE POLICY "Users can view ecritures based on access"
  ON ecritures_comptables FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage ecritures based on access"
  ON ecritures_comptables FOR ALL
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

CREATE POLICY "Users can view lignes via ecriture"
  ON lignes_ecritures FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND (
          get_user_role() = 'admin_national'
          OR user_has_church_unit_access(e.church_unit_id)
          OR user_has_assemblee_access(e.id_assemblee_locale)
        )
    )
  );

CREATE POLICY "Users can manage lignes via ecriture"
  ON lignes_ecritures FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND (
          get_user_role() = 'admin_national'
          OR user_has_church_unit_access(e.church_unit_id)
          OR user_has_assemblee_access(e.id_assemblee_locale)
        )
    )
  );

CREATE POLICY "Users can view budgets based on access"
  ON budgets_comptables FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage budgets based on access"
  ON budgets_comptables FOR ALL
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

CREATE POLICY "Users can view lignes budget via budget"
  ON lignes_budgets FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND (
          get_user_role() = 'admin_national'
          OR user_has_church_unit_access(b.church_unit_id)
          OR user_has_assemblee_access(b.id_assemblee_locale)
        )
    )
  );

CREATE POLICY "Users can manage lignes budget via budget"
  ON lignes_budgets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND (
          get_user_role() = 'admin_national'
          OR user_has_church_unit_access(b.church_unit_id)
          OR user_has_assemblee_access(b.id_assemblee_locale)
        )
    )
  );

CREATE POLICY "Users can view immobilisations based on access"
  ON immobilisations_comptables FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage immobilisations based on access"
  ON immobilisations_comptables FOR ALL
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

CREATE POLICY "Users can view releves based on access"
  ON releves_bancaires FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
      OR user_has_assemblee_access(id_assemblee_locale)
    )
  );

CREATE POLICY "Users can manage releves based on access"
  ON releves_bancaires FOR ALL
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

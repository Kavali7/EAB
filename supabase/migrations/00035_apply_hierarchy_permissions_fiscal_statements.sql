-- ============================================================================
-- Apply hierarchical permissions to fiscal dossiers and financial statements
-- ============================================================================
-- Extends the permission rollout to:
--   - fiscal_dossiers;
--   - fiscal_dossier_values;
--   - imported_trial_balances;
--   - imported_trial_balance_lines;
--   - financial statement report RPCs.
--
-- Existing UI calls remain compatible. When a screen does not yet provide an
-- explicit church_unit_id, the database assigns the current user's primary
-- church unit, then falls back to the organization root.

ALTER TABLE fiscal_dossiers
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

ALTER TABLE imported_trial_balances
  ADD COLUMN IF NOT EXISTS church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_fiscal_dossiers_church_unit
  ON fiscal_dossiers(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_import_balances_church_unit
  ON imported_trial_balances(church_unit_id);

COMMENT ON COLUMN fiscal_dossiers.church_unit_id IS
  'Flexible church unit/perimeter for this fiscal dossier.';
COMMENT ON COLUMN imported_trial_balances.church_unit_id IS
  'Flexible church unit/perimeter for this imported trial balance.';

UPDATE fiscal_dossiers d
SET church_unit_id = COALESCE(
  creator.primary_church_unit_id,
  root.id
)
FROM church_units root
LEFT JOIN profiles creator
  ON creator.id = d.created_by
 AND creator.organization_id = d.organization_id
WHERE d.church_unit_id IS NULL
  AND root.organization_id = d.organization_id
  AND root.parent_id IS NULL;

UPDATE imported_trial_balances i
SET church_unit_id = COALESCE(
  creator.primary_church_unit_id,
  root.id
)
FROM church_units root
LEFT JOIN profiles creator
  ON creator.id = i.created_by
 AND creator.organization_id = i.organization_id
WHERE i.church_unit_id IS NULL
  AND root.organization_id = i.organization_id
  AND root.parent_id IS NULL;

CREATE OR REPLACE FUNCTION fiscal_scope_contains_unit(
  p_scope_unit_id UUID,
  p_target_unit_id UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  SELECT
    p_scope_unit_id IS NOT NULL
    AND p_target_unit_id IS NOT NULL
    AND (
      p_scope_unit_id = p_target_unit_id
      OR is_church_unit_ancestor(p_scope_unit_id, p_target_unit_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_financial_statements_scope(
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
        'financial_statements',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_exports_scope(
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
        'exports',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION ensure_fiscal_statement_permission_rules(
  p_org_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'organization_id obligatoire.'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO church_hierarchy_permission_rules (
    organization_id,
    ancestor_type_id,
    descendant_type_id,
    domain_id,
    action_id,
    allowed,
    requires_descendant_acceptance,
    inherited,
    metadata
  )
  SELECT
    ancestor.organization_id,
    ancestor.id,
    descendant.id,
    domain.id,
    action.id,
    TRUE,
    FALSE,
    TRUE,
    jsonb_build_object('seeded_from', '00035_fiscal_statement_permissions')
  FROM church_unit_types ancestor
  JOIN church_unit_types descendant
    ON descendant.organization_id = ancestor.organization_id
   AND descendant.level_order > ancestor.level_order
  JOIN church_permission_domains domain
    ON domain.organization_id = ancestor.organization_id
   AND domain.code IN ('financial_statements', 'exports')
  JOIN church_permission_actions action
    ON action.organization_id = ancestor.organization_id
  WHERE ancestor.organization_id = p_org_id
    AND ancestor.can_view_descendants = TRUE
    AND (
      (
        domain.code = 'financial_statements'
        AND ancestor.can_consolidate_finances = TRUE
        AND action.code IN ('create', 'update', 'consolidate', 'export')
      )
      OR (
        domain.code = 'financial_statements'
        AND ancestor.can_validate_finances = TRUE
        AND action.code IN ('validate', 'reject')
      )
      OR (
        domain.code = 'exports'
        AND ancestor.can_consolidate_finances = TRUE
        AND action.code IN ('export', 'consolidate')
      )
    )
  ON CONFLICT (
    organization_id,
    ancestor_type_id,
    descendant_type_id,
    domain_id,
    action_id
  ) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION seed_church_permissions_after_type_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM ensure_default_church_permission_catalog(NEW.organization_id);
  PERFORM ensure_extended_church_permission_rules(NEW.organization_id);
  PERFORM ensure_fiscal_statement_permission_rules(NEW.organization_id);
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  v_org_id UUID;
BEGIN
  FOR v_org_id IN SELECT id FROM organizations
  LOOP
    PERFORM ensure_fiscal_statement_permission_rules(v_org_id);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION sync_fiscal_dossier_church_unit_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_church_unit_id UUID;
  v_unit_org_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    NEW.organization_id := get_user_organization_id();
  END IF;

  IF NEW.church_unit_id IS NULL THEN
    SELECT primary_church_unit_id
    INTO v_church_unit_id
    FROM profiles
    WHERE id = COALESCE(NEW.created_by, auth.uid())
      AND organization_id = NEW.organization_id;

    IF v_church_unit_id IS NULL THEN
      SELECT id
      INTO v_church_unit_id
      FROM church_units
      WHERE organization_id = NEW.organization_id
        AND parent_id IS NULL
        AND active = TRUE
      ORDER BY created_at
      LIMIT 1;
    END IF;

    NEW.church_unit_id := v_church_unit_id;
  END IF;

  IF NEW.church_unit_id IS NOT NULL THEN
    SELECT organization_id
    INTO v_unit_org_id
    FROM church_units
    WHERE id = NEW.church_unit_id
      AND active = TRUE;

    IF v_unit_org_id IS DISTINCT FROM NEW.organization_id THEN
      RAISE EXCEPTION 'Le perimetre du dossier fiscal doit appartenir a la meme organisation.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION sync_imported_trial_balance_church_unit_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_church_unit_id UUID;
  v_unit_org_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    NEW.organization_id := get_user_organization_id();
  END IF;

  IF NEW.church_unit_id IS NULL THEN
    SELECT primary_church_unit_id
    INTO v_church_unit_id
    FROM profiles
    WHERE id = COALESCE(NEW.created_by, auth.uid())
      AND organization_id = NEW.organization_id;

    IF v_church_unit_id IS NULL THEN
      SELECT id
      INTO v_church_unit_id
      FROM church_units
      WHERE organization_id = NEW.organization_id
        AND parent_id IS NULL
        AND active = TRUE
      ORDER BY created_at
      LIMIT 1;
    END IF;

    NEW.church_unit_id := v_church_unit_id;
  END IF;

  IF NEW.church_unit_id IS NOT NULL THEN
    SELECT organization_id
    INTO v_unit_org_id
    FROM church_units
    WHERE id = NEW.church_unit_id
      AND active = TRUE;

    IF v_unit_org_id IS DISTINCT FROM NEW.organization_id THEN
      RAISE EXCEPTION 'Le perimetre de la balance importee doit appartenir a la meme organisation.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION sync_fiscal_dossier_value_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_status fiscal_dossier_status;
BEGIN
  SELECT organization_id, status
  INTO v_org_id, v_status
  FROM fiscal_dossiers
  WHERE id = NEW.dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable pour la valeur.'
      USING ERRCODE = '23503';
  END IF;

  IF v_status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Impossible de modifier les valeurs d''un dossier fiscal verrouille ou soumis.'
      USING ERRCODE = '42501';
  END IF;

  NEW.organization_id := v_org_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION sync_imported_trial_balance_line_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
BEGIN
  SELECT organization_id
  INTO v_org_id
  FROM imported_trial_balances
  WHERE id = NEW.import_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Balance importee introuvable pour la ligne.'
      USING ERRCODE = '23503';
  END IF;

  NEW.organization_id := v_org_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_fiscal_dossier_church_unit_scope_trigger
  ON fiscal_dossiers;
CREATE TRIGGER sync_fiscal_dossier_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, created_by, church_unit_id
  ON fiscal_dossiers
  FOR EACH ROW
  EXECUTE FUNCTION sync_fiscal_dossier_church_unit_scope();

DROP TRIGGER IF EXISTS sync_imported_trial_balance_church_unit_scope_trigger
  ON imported_trial_balances;
CREATE TRIGGER sync_imported_trial_balance_church_unit_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, created_by, church_unit_id
  ON imported_trial_balances
  FOR EACH ROW
  EXECUTE FUNCTION sync_imported_trial_balance_church_unit_scope();

DROP TRIGGER IF EXISTS sync_fiscal_dossier_value_scope_trigger
  ON fiscal_dossier_values;
CREATE TRIGGER sync_fiscal_dossier_value_scope_trigger
  BEFORE INSERT OR UPDATE OF dossier_id, organization_id, value, source
  ON fiscal_dossier_values
  FOR EACH ROW
  EXECUTE FUNCTION sync_fiscal_dossier_value_scope();

DROP TRIGGER IF EXISTS sync_imported_trial_balance_line_scope_trigger
  ON imported_trial_balance_lines;
CREATE TRIGGER sync_imported_trial_balance_line_scope_trigger
  BEFORE INSERT OR UPDATE OF import_id, organization_id
  ON imported_trial_balance_lines
  FOR EACH ROW
  EXECUTE FUNCTION sync_imported_trial_balance_line_scope();

CREATE OR REPLACE FUNCTION enforce_fiscal_dossier_workflow_permission()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_required_action TEXT := 'update';
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.status <> 'draft' THEN
      RAISE EXCEPTION 'Seul un dossier fiscal brouillon peut etre supprime.'
        USING ERRCODE = '42501';
    END IF;

    IF NOT user_can_access_financial_statements_scope(
      OLD.church_unit_id,
      NULL,
      'update'
    ) THEN
      RAISE EXCEPTION 'Droit insuffisant pour supprimer ce dossier fiscal.'
        USING ERRCODE = '42501';
    END IF;

    RETURN OLD;
  END IF;

  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF OLD.status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Impossible de modifier un dossier fiscal verrouille ou soumis.'
      USING ERRCODE = '42501';
  END IF;

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    IF NEW.status = 'ready' THEN
      v_required_action := 'validate';
    ELSIF NEW.status IN ('locked', 'submitted') THEN
      v_required_action := 'consolidate';
    ELSE
      v_required_action := 'update';
    END IF;
  END IF;

  IF NOT user_can_access_financial_statements_scope(
    NEW.church_unit_id,
    NULL,
    v_required_action
  ) THEN
    RAISE EXCEPTION
      'Droit insuffisant pour l''action % sur ce dossier fiscal.',
      v_required_action
      USING ERRCODE = '42501';
  END IF;

  IF OLD.church_unit_id IS DISTINCT FROM NEW.church_unit_id
     AND NOT user_can_access_financial_statements_scope(
       OLD.church_unit_id,
       NULL,
       'update'
     ) THEN
    RAISE EXCEPTION 'Droit insuffisant pour deplacer ce dossier fiscal.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_fiscal_dossier_workflow_permission_trigger
  ON fiscal_dossiers;
CREATE TRIGGER enforce_fiscal_dossier_workflow_permission_trigger
  BEFORE UPDATE OR DELETE ON fiscal_dossiers
  FOR EACH ROW
  EXECUTE FUNCTION enforce_fiscal_dossier_workflow_permission();

DROP POLICY IF EXISTS "fiscal_dossiers_select_org"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "fiscal_dossiers_insert_org"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "fiscal_dossiers_update_org"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "fiscal_dossiers_delete_org"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "fiscal_values_select_org"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "fiscal_values_insert_org"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "fiscal_values_update_org"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "fiscal_values_delete_org"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "import_balances_select_org"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "import_balances_insert_org"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "import_balances_delete_org"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "import_balance_lines_select_org"
  ON imported_trial_balance_lines;
DROP POLICY IF EXISTS "import_balance_lines_insert_org"
  ON imported_trial_balance_lines;
DROP POLICY IF EXISTS "import_balance_lines_delete_org"
  ON imported_trial_balance_lines;

DROP POLICY IF EXISTS "Users can view fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "Users can create fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "Users can update fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "Users can delete fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers;
DROP POLICY IF EXISTS "Users can view fiscal values by dossier permissions"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "Users can create fiscal values by dossier permissions"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "Users can update fiscal values by dossier permissions"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "Users can delete fiscal values by dossier permissions"
  ON fiscal_dossier_values;
DROP POLICY IF EXISTS "Users can view imported balances by hierarchy permissions"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "Users can create imported balances by hierarchy permissions"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "Users can update imported balances by hierarchy permissions"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "Users can delete imported balances by hierarchy permissions"
  ON imported_trial_balances;
DROP POLICY IF EXISTS "Users can view imported balance lines by import permissions"
  ON imported_trial_balance_lines;
DROP POLICY IF EXISTS "Users can create imported balance lines by import permissions"
  ON imported_trial_balance_lines;
DROP POLICY IF EXISTS "Users can delete imported balance lines by import permissions"
  ON imported_trial_balance_lines;

CREATE POLICY "Users can view fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'view_details'
    )
  );

CREATE POLICY "Users can create fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'create'
    )
  );

CREATE POLICY "Users can update fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND status NOT IN ('locked', 'submitted')
    AND (
      user_can_access_financial_statements_scope(church_unit_id, NULL, 'update')
      OR user_can_access_financial_statements_scope(church_unit_id, NULL, 'validate')
      OR user_can_access_financial_statements_scope(church_unit_id, NULL, 'consolidate')
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      user_can_access_financial_statements_scope(church_unit_id, NULL, 'update')
      OR user_can_access_financial_statements_scope(church_unit_id, NULL, 'validate')
      OR user_can_access_financial_statements_scope(church_unit_id, NULL, 'consolidate')
    )
  );

CREATE POLICY "Users can delete fiscal dossiers by hierarchy permissions"
  ON fiscal_dossiers FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND status = 'draft'
    AND user_can_access_financial_statements_scope(church_unit_id, NULL, 'update')
  );

CREATE POLICY "Users can view fiscal values by dossier permissions"
  ON fiscal_dossier_values FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM fiscal_dossiers d
      WHERE d.id = fiscal_dossier_values.dossier_id
        AND d.organization_id = get_user_organization_id()
        AND user_can_access_financial_statements_scope(
          d.church_unit_id,
          NULL,
          'view_details'
        )
    )
  );

CREATE POLICY "Users can create fiscal values by dossier permissions"
  ON fiscal_dossier_values FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM fiscal_dossiers d
      WHERE d.id = fiscal_dossier_values.dossier_id
        AND d.organization_id = get_user_organization_id()
        AND d.status NOT IN ('locked', 'submitted')
        AND user_can_access_financial_statements_scope(
          d.church_unit_id,
          NULL,
          'update'
        )
    )
  );

CREATE POLICY "Users can update fiscal values by dossier permissions"
  ON fiscal_dossier_values FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM fiscal_dossiers d
      WHERE d.id = fiscal_dossier_values.dossier_id
        AND d.organization_id = get_user_organization_id()
        AND d.status NOT IN ('locked', 'submitted')
        AND user_can_access_financial_statements_scope(
          d.church_unit_id,
          NULL,
          'update'
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM fiscal_dossiers d
      WHERE d.id = fiscal_dossier_values.dossier_id
        AND d.organization_id = get_user_organization_id()
        AND d.status NOT IN ('locked', 'submitted')
        AND user_can_access_financial_statements_scope(
          d.church_unit_id,
          NULL,
          'update'
        )
    )
  );

CREATE POLICY "Users can delete fiscal values by dossier permissions"
  ON fiscal_dossier_values FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM fiscal_dossiers d
      WHERE d.id = fiscal_dossier_values.dossier_id
        AND d.organization_id = get_user_organization_id()
        AND d.status NOT IN ('locked', 'submitted')
        AND user_can_access_financial_statements_scope(
          d.church_unit_id,
          NULL,
          'update'
        )
    )
  );

CREATE POLICY "Users can view imported balances by hierarchy permissions"
  ON imported_trial_balances FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'view_details'
    )
  );

CREATE POLICY "Users can create imported balances by hierarchy permissions"
  ON imported_trial_balances FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'create'
    )
  );

CREATE POLICY "Users can update imported balances by hierarchy permissions"
  ON imported_trial_balances FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'update'
    )
  );

CREATE POLICY "Users can delete imported balances by hierarchy permissions"
  ON imported_trial_balances FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_statements_scope(
      church_unit_id,
      NULL,
      'update'
    )
  );

CREATE POLICY "Users can view imported balance lines by import permissions"
  ON imported_trial_balance_lines FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM imported_trial_balances i
      WHERE i.id = imported_trial_balance_lines.import_id
        AND i.organization_id = get_user_organization_id()
        AND user_can_access_financial_statements_scope(
          i.church_unit_id,
          NULL,
          'view_details'
        )
    )
  );

CREATE POLICY "Users can create imported balance lines by import permissions"
  ON imported_trial_balance_lines FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM imported_trial_balances i
      WHERE i.id = imported_trial_balance_lines.import_id
        AND i.organization_id = get_user_organization_id()
        AND user_can_access_financial_statements_scope(
          i.church_unit_id,
          NULL,
          'create'
        )
    )
  );

CREATE POLICY "Users can delete imported balance lines by import permissions"
  ON imported_trial_balance_lines FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM imported_trial_balances i
      WHERE i.id = imported_trial_balance_lines.import_id
        AND i.organization_id = get_user_organization_id()
        AND user_can_access_financial_statements_scope(
          i.church_unit_id,
          NULL,
          'update'
        )
    )
  );

CREATE OR REPLACE FUNCTION public.prefill_fiscal_dossier(p_dossier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id        UUID;
  v_template_id   UUID;
  v_exercice_id   UUID;
  v_church_unit_id UUID;
  v_status        fiscal_dossier_status;
  v_date_debut    DATE;
  v_date_fin      DATE;
  v_count         INTEGER := 0;
  v_missing       INTEGER := 0;
  v_mapping       RECORD;
  v_solde         NUMERIC;
  v_prefixes      TEXT[];
BEGIN
  SELECT d.organization_id, d.template_id, d.exercice_id, d.church_unit_id, d.status
  INTO v_org_id, v_template_id, v_exercice_id, v_church_unit_id, v_status
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : dossier hors de votre organisation';
  END IF;

  IF v_status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Impossible de pre-remplir un dossier verrouille ou soumis.';
  END IF;

  IF NOT user_can_access_financial_statements_scope(
    v_church_unit_id,
    NULL,
    'update'
  ) THEN
    RAISE EXCEPTION 'Droit insuffisant pour pre-remplir ce dossier fiscal.'
      USING ERRCODE = '42501';
  END IF;

  IF v_exercice_id IS NOT NULL THEN
    SELECT date_debut, date_fin INTO v_date_debut, v_date_fin
    FROM public.exercices_comptables
    WHERE id = v_exercice_id;
  ELSE
    v_date_debut := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 1, 1);
    v_date_fin := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 12, 31);
  END IF;

  FOR v_mapping IN
    SELECT field_key, rule_type, params
    FROM public.fiscal_account_mapping
    WHERE template_id = v_template_id
  LOOP
    v_solde := 0;

    IF v_mapping.rule_type = 'sum_prefixes' THEN
      v_prefixes := ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'prefixes'));

      SELECT COALESCE(SUM(
        CASE
          WHEN cc.nature IN ('actif', 'charge', 'hors_activite_ordinaire')
            THEN le.debit - le.credit
          ELSE le.credit - le.debit
        END
      ), 0) INTO v_solde
      FROM public.lignes_ecritures le
      JOIN public.ecritures_comptables ec ON ec.id = le.id_ecriture
      JOIN public.comptes_comptables cc ON cc.id = le.id_compte_comptable
      WHERE ec.organization_id = v_org_id
        AND ec.deleted_at IS NULL
        AND ec.statut IN ('validee', 'cloturee')
        AND ec.date BETWEEN v_date_debut AND v_date_fin
        AND fiscal_scope_contains_unit(v_church_unit_id, ec.church_unit_id)
        AND user_can_access_financial_statements_scope(
          ec.church_unit_id,
          ec.id_assemblee_locale,
          'view_details'
        )
        AND EXISTS (
          SELECT 1 FROM unnest(v_prefixes) p
          WHERE cc.numero LIKE p || '%'
        );

    ELSIF v_mapping.rule_type = 'balance_class' THEN
      SELECT COALESCE(SUM(
        CASE
          WHEN cc.nature IN ('actif', 'charge', 'hors_activite_ordinaire')
            THEN le.debit - le.credit
          ELSE le.credit - le.debit
        END
      ), 0) INTO v_solde
      FROM public.lignes_ecritures le
      JOIN public.ecritures_comptables ec ON ec.id = le.id_ecriture
      JOIN public.comptes_comptables cc ON cc.id = le.id_compte_comptable
      WHERE ec.organization_id = v_org_id
        AND ec.deleted_at IS NULL
        AND ec.statut IN ('validee', 'cloturee')
        AND ec.date BETWEEN v_date_debut AND v_date_fin
        AND fiscal_scope_contains_unit(v_church_unit_id, ec.church_unit_id)
        AND user_can_access_financial_statements_scope(
          ec.church_unit_id,
          ec.id_assemblee_locale,
          'view_details'
        )
        AND cc.numero LIKE (v_mapping.params->>'class_prefix') || '%';

    ELSIF v_mapping.rule_type = 'sum_accounts' THEN
      SELECT COALESCE(SUM(
        CASE
          WHEN cc.nature IN ('actif', 'charge', 'hors_activite_ordinaire')
            THEN le.debit - le.credit
          ELSE le.credit - le.debit
        END
      ), 0) INTO v_solde
      FROM public.lignes_ecritures le
      JOIN public.ecritures_comptables ec ON ec.id = le.id_ecriture
      JOIN public.comptes_comptables cc ON cc.id = le.id_compte_comptable
      WHERE ec.organization_id = v_org_id
        AND ec.deleted_at IS NULL
        AND ec.statut IN ('validee', 'cloturee')
        AND ec.date BETWEEN v_date_debut AND v_date_fin
        AND fiscal_scope_contains_unit(v_church_unit_id, ec.church_unit_id)
        AND user_can_access_financial_statements_scope(
          ec.church_unit_id,
          ec.id_assemblee_locale,
          'view_details'
        )
        AND cc.numero = ANY(ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'accounts')));

    ELSE
      v_missing := v_missing + 1;
      CONTINUE;
    END IF;

    INSERT INTO public.fiscal_dossier_values (dossier_id, organization_id, field_key, value, source, updated_by, updated_at)
    VALUES (
      p_dossier_id,
      v_org_id,
      v_mapping.field_key,
      to_jsonb(v_solde),
      'computed',
      auth.uid(),
      NOW()
    )
    ON CONFLICT (dossier_id, field_key)
    DO UPDATE SET
      value = to_jsonb(v_solde),
      source = 'computed',
      updated_by = auth.uid(),
      updated_at = NOW();

    v_count := v_count + 1;
  END LOOP;

  UPDATE public.fiscal_dossiers
  SET status = 'in_progress', updated_at = NOW()
  WHERE id = p_dossier_id AND status = 'draft';

  RETURN jsonb_build_object(
    'success', TRUE,
    'filled', v_count,
    'skipped', v_missing,
    'date_debut', v_date_debut,
    'date_fin', v_date_fin
  );
END $$;

CREATE OR REPLACE FUNCTION public.prefill_fiscal_dossier_from_import(
  p_dossier_id UUID,
  p_import_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id        UUID;
  v_import_org    UUID;
  v_template_id   UUID;
  v_dossier_unit_id UUID;
  v_import_unit_id UUID;
  v_status        fiscal_dossier_status;
  v_count         INTEGER := 0;
  v_missing       INTEGER := 0;
  v_mapping       RECORD;
  v_solde         NUMERIC;
  v_prefixes      TEXT[];
BEGIN
  SELECT d.organization_id, d.template_id, d.church_unit_id, d.status
  INTO v_org_id, v_template_id, v_dossier_unit_id, v_status
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : dossier hors de votre organisation';
  END IF;

  IF v_status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Impossible de pre-remplir un dossier verrouille ou soumis.';
  END IF;

  IF NOT user_can_access_financial_statements_scope(
    v_dossier_unit_id,
    NULL,
    'update'
  ) THEN
    RAISE EXCEPTION 'Droit insuffisant pour pre-remplir ce dossier fiscal.'
      USING ERRCODE = '42501';
  END IF;

  SELECT organization_id, church_unit_id
  INTO v_import_org, v_import_unit_id
  FROM public.imported_trial_balances
  WHERE id = p_import_id;

  IF v_import_org IS NULL THEN
    RAISE EXCEPTION 'Balance importee introuvable : %', p_import_id;
  END IF;

  IF v_import_org <> v_org_id THEN
    RAISE EXCEPTION 'La balance importee n''appartient pas a votre organisation';
  END IF;

  IF NOT fiscal_scope_contains_unit(v_dossier_unit_id, v_import_unit_id) THEN
    RAISE EXCEPTION 'La balance importee n''appartient pas au perimetre du dossier fiscal.'
      USING ERRCODE = '42501';
  END IF;

  IF NOT user_can_access_financial_statements_scope(
    v_import_unit_id,
    NULL,
    'view_details'
  ) THEN
    RAISE EXCEPTION 'Droit insuffisant pour utiliser cette balance importee.'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.fiscal_dossiers
  SET import_id = p_import_id, updated_at = NOW()
  WHERE id = p_dossier_id;

  FOR v_mapping IN
    SELECT field_key, rule_type, params
    FROM public.fiscal_account_mapping
    WHERE template_id = v_template_id
  LOOP
    v_solde := 0;

    IF v_mapping.rule_type = 'sum_prefixes' THEN
      v_prefixes := ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'prefixes'));

      SELECT COALESCE(SUM(
        CASE
          WHEN LEFT(l.account_number, 1) IN ('1', '4', '7') THEN l.credit - l.debit
          ELSE l.debit - l.credit
        END
      ), 0) INTO v_solde
      FROM public.imported_trial_balance_lines l
      WHERE l.import_id = p_import_id
        AND EXISTS (
          SELECT 1 FROM unnest(v_prefixes) p
          WHERE l.account_number LIKE p || '%'
        );

    ELSIF v_mapping.rule_type = 'balance_class' THEN
      SELECT COALESCE(SUM(
        CASE
          WHEN LEFT(l.account_number, 1) IN ('1', '4', '7') THEN l.credit - l.debit
          ELSE l.debit - l.credit
        END
      ), 0) INTO v_solde
      FROM public.imported_trial_balance_lines l
      WHERE l.import_id = p_import_id
        AND l.account_number LIKE (v_mapping.params->>'class_prefix') || '%';

    ELSIF v_mapping.rule_type = 'sum_accounts' THEN
      SELECT COALESCE(SUM(
        CASE
          WHEN LEFT(l.account_number, 1) IN ('1', '4', '7') THEN l.credit - l.debit
          ELSE l.debit - l.credit
        END
      ), 0) INTO v_solde
      FROM public.imported_trial_balance_lines l
      WHERE l.import_id = p_import_id
        AND l.account_number = ANY(ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'accounts')));

    ELSE
      v_missing := v_missing + 1;
      CONTINUE;
    END IF;

    INSERT INTO public.fiscal_dossier_values (dossier_id, organization_id, field_key, value, source, updated_by, updated_at)
    VALUES (p_dossier_id, v_org_id, v_mapping.field_key, to_jsonb(v_solde), 'imported', auth.uid(), NOW())
    ON CONFLICT (dossier_id, field_key)
    DO UPDATE SET value = to_jsonb(v_solde), source = 'imported', updated_by = auth.uid(), updated_at = NOW();

    v_count := v_count + 1;
  END LOOP;

  UPDATE public.fiscal_dossiers
  SET status = 'in_progress', updated_at = NOW()
  WHERE id = p_dossier_id AND status = 'draft';

  RETURN jsonb_build_object('success', TRUE, 'filled', v_count, 'skipped', v_missing);
END $$;

CREATE OR REPLACE FUNCTION public.validate_fiscal_dossier(p_dossier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id      UUID;
  v_template_id UUID;
  v_church_unit_id UUID;
  v_status      fiscal_dossier_status;
  v_errors      JSONB := '[]'::JSONB;
  v_field       RECORD;
  v_val         JSONB;
  v_actif       NUMERIC := 0;
  v_passif      NUMERIC := 0;
  v_produits    NUMERIC := 0;
  v_charges     NUMERIC := 0;
  v_resultat    NUMERIC := 0;
  v_passif_res  NUMERIC := 0;
BEGIN
  SELECT d.organization_id, d.template_id, d.church_unit_id, d.status
  INTO v_org_id, v_template_id, v_church_unit_id, v_status
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : dossier hors de votre organisation';
  END IF;

  IF v_status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Impossible de valider un dossier verrouille ou soumis.';
  END IF;

  IF NOT user_can_access_financial_statements_scope(
    v_church_unit_id,
    NULL,
    'validate'
  ) THEN
    RAISE EXCEPTION 'Droit insuffisant pour valider ce dossier fiscal.'
      USING ERRCODE = '42501';
  END IF;

  FOR v_field IN
    SELECT f.field_key, f.label, p.code AS page_code
    FROM public.fiscal_template_fields f
    JOIN public.fiscal_template_pages p ON p.id = f.page_id
    WHERE p.template_id = v_template_id
      AND f.required = TRUE
  LOOP
    SELECT dv.value INTO v_val
    FROM public.fiscal_dossier_values dv
    WHERE dv.dossier_id = p_dossier_id
      AND dv.field_key = v_field.field_key;

    IF v_val IS NULL OR v_val = 'null'::JSONB OR v_val = '""'::JSONB THEN
      v_errors := v_errors || jsonb_build_array(
        jsonb_build_object(
          'code', 'REQUIRED_FIELD_MISSING',
          'message', 'Champ requis manquant : ' || v_field.label,
          'page_code', v_field.page_code,
          'field_key', v_field.field_key
        )
      );
    END IF;
  END LOOP;

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_actif
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'bilan.actif.total';

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_passif
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'bilan.passif.total';

  IF v_actif <> v_passif THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object(
        'code', 'ACTIF_PASSIF_MISMATCH',
        'message', format('Le total Actif (%s FCFA) doit etre egal au total Passif (%s FCFA).', v_actif, v_passif),
        'page_code', 'BILAN_ACTIF',
        'field_key', 'bilan.actif.total'
      )
    );
  END IF;

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_produits
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'resultat.produits.total';

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_charges
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'resultat.charges.total';

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_resultat
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'resultat.net';

  IF v_resultat <> (v_produits - v_charges) THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object(
        'code', 'RESULTAT_MISMATCH',
        'message', format('Le resultat net (%s) doit etre egal a Produits (%s) - Charges (%s) = %s.',
                          v_resultat, v_produits, v_charges, v_produits - v_charges),
        'page_code', 'RESULTAT',
        'field_key', 'resultat.net'
      )
    );
  END IF;

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_passif_res
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'bilan.passif.resultat.net';

  IF v_passif_res <> v_resultat THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object(
        'code', 'BILAN_RESULTAT_MISMATCH',
        'message', format('Le resultat au bilan passif (%s) doit correspondre au resultat net (%s).',
                          v_passif_res, v_resultat),
        'page_code', 'BILAN_PASSIF',
        'field_key', 'bilan.passif.resultat.net'
      )
    );
  END IF;

  IF jsonb_array_length(v_errors) = 0 THEN
    UPDATE public.fiscal_dossiers
    SET status = 'ready', updated_at = NOW()
    WHERE id = p_dossier_id AND status IN ('draft', 'in_progress');
  END IF;

  RETURN jsonb_build_object(
    'ok', jsonb_array_length(v_errors) = 0,
    'error_count', jsonb_array_length(v_errors),
    'errors', v_errors
  );
END $$;

CREATE OR REPLACE FUNCTION public.lock_fiscal_dossier(p_dossier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id    UUID;
  v_church_unit_id UUID;
  v_status    fiscal_dossier_status;
  v_result    JSONB;
BEGIN
  SELECT d.organization_id, d.church_unit_id, d.status
  INTO v_org_id, v_church_unit_id, v_status
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : dossier hors de votre organisation';
  END IF;

  IF NOT user_can_access_financial_statements_scope(
    v_church_unit_id,
    NULL,
    'consolidate'
  ) THEN
    RAISE EXCEPTION 'Droit insuffisant pour verrouiller ce dossier fiscal.'
      USING ERRCODE = '42501';
  END IF;

  IF v_status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Le dossier est deja verrouille ou soumis.';
  END IF;

  v_result := public.validate_fiscal_dossier(p_dossier_id);

  IF NOT (v_result->>'ok')::BOOLEAN THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Impossible de verrouiller : des erreurs de validation existent.',
      'validation', v_result
    );
  END IF;

  UPDATE public.fiscal_dossiers
  SET
    status = 'locked',
    locked_by = auth.uid(),
    locked_at = NOW(),
    updated_at = NOW()
  WHERE id = p_dossier_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'message', 'Dossier fiscal verrouille avec succes.',
    'locked_at', NOW(),
    'locked_by', auth.uid()
  );
END $$;

CREATE OR REPLACE FUNCTION report_balance_generale(
  p_org_id UUID,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  compte_id UUID,
  numero TEXT,
  intitule TEXT,
  nature TEXT,
  niveau INTEGER,
  total_debit DECIMAL(15,2),
  total_credit DECIMAL(15,2),
  solde_debiteur DECIMAL(15,2),
  solde_crediteur DECIMAL(15,2)
) AS $$
BEGIN
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.numero,
    c.intitule,
    c.nature::TEXT,
    c.niveau,
    COALESCE(SUM(
      CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END
    ), 0)::DECIMAL(15,2) AS total_debit,
    COALESCE(SUM(
      CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END
    ), 0)::DECIMAL(15,2) AS total_credit,
    CASE
      WHEN COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
        > COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
      THEN (
        COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
      )::DECIMAL(15,2)
      ELSE 0::DECIMAL(15,2)
    END AS solde_debiteur,
    CASE
      WHEN COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
        > COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
      THEN (
        COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
      )::DECIMAL(15,2)
      ELSE 0::DECIMAL(15,2)
    END AS solde_crediteur
  FROM comptes_comptables c
  LEFT JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  LEFT JOIN ecritures_comptables e ON e.id = l.id_ecriture
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  WHERE c.organization_id = p_org_id
    AND c.actif = TRUE
  GROUP BY c.id, c.numero, c.intitule, c.nature, c.niveau
  HAVING
    COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0) != 0
    OR COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION report_compte_resultat(
  p_org_id UUID,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  section TEXT,
  compte_id UUID,
  numero TEXT,
  intitule TEXT,
  montant DECIMAL(15,2)
) AS $$
BEGIN
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    'produits'::TEXT AS section,
    c.id,
    c.numero,
    c.intitule,
    (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2) AS montant
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.nature = 'produit'
    AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;

  RETURN QUERY
  SELECT
    'charges'::TEXT AS section,
    c.id,
    c.numero,
    c.intitule,
    (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2) AS montant
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.nature = 'charge'
    AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION report_bilan(
  p_org_id UUID,
  p_date_fin DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  section TEXT,
  sous_section TEXT,
  compte_id UUID,
  numero TEXT,
  intitule TEXT,
  solde DECIMAL(15,2)
) AS $$
BEGIN
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    'actif'::TEXT, 'immobilisations'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero LIKE '2%' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;

  RETURN QUERY
  SELECT
    'actif'::TEXT, 'circulant'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero ~ '^[345]' AND c.nature = 'actif' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;

  RETURN QUERY
  SELECT
    'passif'::TEXT, 'fonds_propres'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero LIKE '1%' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;

  RETURN QUERY
  SELECT
    'passif'::TEXT, 'dettes'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero LIKE '4%' AND c.nature = 'passif' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION report_grand_livre(
  p_org_id UUID,
  p_compte_id UUID DEFAULT NULL,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  compte_numero TEXT,
  compte_intitule TEXT,
  ecriture_date DATE,
  ecriture_libelle TEXT,
  reference_piece TEXT,
  journal_code TEXT,
  ligne_libelle TEXT,
  debit DECIMAL(15,2),
  credit DECIMAL(15,2),
  solde_cumule DECIMAL(15,2)
) AS $$
BEGIN
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    c.numero,
    c.intitule,
    e.date,
    e.libelle,
    e.reference_piece,
    j.code,
    l.libelle,
    COALESCE(l.debit, 0)::DECIMAL(15,2),
    COALESCE(l.credit, 0)::DECIMAL(15,2),
    SUM(COALESCE(l.debit, 0) - COALESCE(l.credit, 0))
      OVER (PARTITION BY c.id ORDER BY e.date, e.id ROWS UNBOUNDED PRECEDING)::DECIMAL(15,2) AS solde_cumule
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  JOIN journaux_comptables j ON j.id = e.id_journal
  WHERE c.organization_id = p_org_id
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_compte_id IS NULL OR c.id = p_compte_id)
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
  ORDER BY c.numero, e.date, e.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION public.prefill_fiscal_dossier(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prefill_fiscal_dossier_from_import(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.validate_fiscal_dossier(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.lock_fiscal_dossier(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION ensure_fiscal_statement_permission_rules(UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION fiscal_scope_contains_unit(UUID, UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_financial_statements_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_exports_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.prefill_fiscal_dossier(UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.prefill_fiscal_dossier_from_import(UUID, UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_fiscal_dossier(UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.lock_fiscal_dossier(UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_balance_generale(UUID, DATE, DATE)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_compte_resultat(UUID, DATE, DATE)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_bilan(UUID, DATE)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_grand_livre(UUID, UUID, DATE, DATE)
  TO authenticated;

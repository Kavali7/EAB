-- ============================================================================
-- Apply hierarchical permissions to scoped accounting tables
-- ============================================================================
-- Continues the permission rollout for accounting data attached to church_units:
--   - accounting references: centres_analytiques, tiers;
--   - accounting entries and lines;
--   - budgets and budget lines;
--   - fixed assets;
--   - bank statements / reconciliation.
--
-- Direct access to a user's own unit stays unchanged. Descendant access now
-- depends on the hierarchy permission matrix, with legacy assemblee fallback
-- only for rows still not linked to a flexible church_unit.

CREATE OR REPLACE FUNCTION user_can_access_accounting_references_scope(
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
        'accounting_entries',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NULL
      AND p_action_code IN ('view_summary', 'view_details')
      AND get_user_organization_id() IS NOT NULL
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_accounting_entries_scope(
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
        'accounting_entries',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_accounting_budgets_scope(
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
        'accounting_budgets',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_accounting_assets_scope(
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
        'accounting_assets',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_bank_reconciliation_scope(
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
        'bank_reconciliation',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION enforce_accounting_entry_workflow_permission()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_required_action TEXT := 'update';
  v_total_debit DECIMAL(15,2);
  v_total_credit DECIMAL(15,2);
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF NOT user_can_access_accounting_entries_scope(
      OLD.church_unit_id,
      OLD.id_assemblee_locale,
      'update'
    ) THEN
      RAISE EXCEPTION
        'Droit insuffisant pour supprimer cette ecriture comptable.'
        USING ERRCODE = '42501';
    END IF;

    RETURN OLD;
  END IF;

  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF OLD.statut IS DISTINCT FROM NEW.statut THEN
    IF NEW.statut = 'validee' THEN
      v_required_action := 'validate';
    ELSIF NEW.statut = 'cloturee' THEN
      v_required_action := 'consolidate';
    ELSE
      v_required_action := 'update';
    END IF;
  END IF;

  IF NOT user_can_access_accounting_entries_scope(
    NEW.church_unit_id,
    NEW.id_assemblee_locale,
    v_required_action
  ) THEN
    RAISE EXCEPTION
      'Droit insuffisant pour l''action % sur cette ecriture comptable.',
      v_required_action
      USING ERRCODE = '42501';
  END IF;

  IF OLD.statut IS DISTINCT FROM NEW.statut
     AND NEW.statut = 'validee' THEN
    SELECT
      COALESCE(SUM(debit), 0),
      COALESCE(SUM(credit), 0)
    INTO v_total_debit, v_total_credit
    FROM lignes_ecritures
    WHERE id_ecriture = NEW.id;

    IF v_total_debit = 0 AND v_total_credit = 0 THEN
      RAISE EXCEPTION 'Ecriture vide: aucune ligne.'
        USING ERRCODE = '23514';
    END IF;

    IF v_total_debit <> v_total_credit THEN
      RAISE EXCEPTION
        'Ecriture desequilibree: debit (%) != credit (%).',
        v_total_debit,
        v_total_credit
        USING ERRCODE = '23514';
    END IF;

    IF NEW.validated_by IS NULL THEN
      NEW.validated_by := auth.uid();
    END IF;

    IF NEW.validated_at IS NULL THEN
      NEW.validated_at := NOW();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_accounting_entry_workflow_permission_trigger
  ON ecritures_comptables;
CREATE TRIGGER enforce_accounting_entry_workflow_permission_trigger
  BEFORE UPDATE OR DELETE ON ecritures_comptables
  FOR EACH ROW
  EXECUTE FUNCTION enforce_accounting_entry_workflow_permission();

DROP POLICY IF EXISTS "Users can view centres in own org"
  ON centres_analytiques;
DROP POLICY IF EXISTS "Admin can manage centres"
  ON centres_analytiques;
DROP POLICY IF EXISTS "Users can view tiers based on access"
  ON tiers;
DROP POLICY IF EXISTS "Users can manage tiers based on access"
  ON tiers;
DROP POLICY IF EXISTS "Users can view ecritures based on access"
  ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can manage ecritures based on access"
  ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can view lignes via ecriture"
  ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can manage lignes via ecriture"
  ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can view budgets based on access"
  ON budgets_comptables;
DROP POLICY IF EXISTS "Users can manage budgets based on access"
  ON budgets_comptables;
DROP POLICY IF EXISTS "Users can view lignes budget via budget"
  ON lignes_budgets;
DROP POLICY IF EXISTS "Users can manage lignes budget via budget"
  ON lignes_budgets;
DROP POLICY IF EXISTS "Users can view immobilisations based on access"
  ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can manage immobilisations based on access"
  ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can view releves based on access"
  ON releves_bancaires;
DROP POLICY IF EXISTS "Users can manage releves based on access"
  ON releves_bancaires;

DROP POLICY IF EXISTS "Users can view accounting centers by hierarchy permissions"
  ON centres_analytiques;
DROP POLICY IF EXISTS "Users can create accounting centers by hierarchy permissions"
  ON centres_analytiques;
DROP POLICY IF EXISTS "Users can update accounting centers by hierarchy permissions"
  ON centres_analytiques;
DROP POLICY IF EXISTS "Users can delete accounting centers by hierarchy permissions"
  ON centres_analytiques;

DROP POLICY IF EXISTS "Users can view tiers by hierarchy permissions"
  ON tiers;
DROP POLICY IF EXISTS "Users can create tiers by hierarchy permissions"
  ON tiers;
DROP POLICY IF EXISTS "Users can update tiers by hierarchy permissions"
  ON tiers;
DROP POLICY IF EXISTS "Users can delete tiers by hierarchy permissions"
  ON tiers;

DROP POLICY IF EXISTS "Users can view accounting entries by hierarchy permissions"
  ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can create accounting entries by hierarchy permissions"
  ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can update accounting entries by hierarchy permissions"
  ON ecritures_comptables;
DROP POLICY IF EXISTS "Users can delete accounting entries by hierarchy permissions"
  ON ecritures_comptables;

DROP POLICY IF EXISTS "Users can view accounting lines by entry permissions"
  ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can create accounting lines by entry permissions"
  ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can update accounting lines by entry permissions"
  ON lignes_ecritures;
DROP POLICY IF EXISTS "Users can delete accounting lines by entry permissions"
  ON lignes_ecritures;

DROP POLICY IF EXISTS "Users can view accounting budgets by hierarchy permissions"
  ON budgets_comptables;
DROP POLICY IF EXISTS "Users can create accounting budgets by hierarchy permissions"
  ON budgets_comptables;
DROP POLICY IF EXISTS "Users can update accounting budgets by hierarchy permissions"
  ON budgets_comptables;
DROP POLICY IF EXISTS "Users can delete accounting budgets by hierarchy permissions"
  ON budgets_comptables;

DROP POLICY IF EXISTS "Users can view budget lines by budget permissions"
  ON lignes_budgets;
DROP POLICY IF EXISTS "Users can create budget lines by budget permissions"
  ON lignes_budgets;
DROP POLICY IF EXISTS "Users can update budget lines by budget permissions"
  ON lignes_budgets;
DROP POLICY IF EXISTS "Users can delete budget lines by budget permissions"
  ON lignes_budgets;

DROP POLICY IF EXISTS "Users can view accounting assets by hierarchy permissions"
  ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can create accounting assets by hierarchy permissions"
  ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can update accounting assets by hierarchy permissions"
  ON immobilisations_comptables;
DROP POLICY IF EXISTS "Users can delete accounting assets by hierarchy permissions"
  ON immobilisations_comptables;

DROP POLICY IF EXISTS "Users can view bank statements by hierarchy permissions"
  ON releves_bancaires;
DROP POLICY IF EXISTS "Users can create bank statements by hierarchy permissions"
  ON releves_bancaires;
DROP POLICY IF EXISTS "Users can update bank statements by hierarchy permissions"
  ON releves_bancaires;
DROP POLICY IF EXISTS "Users can delete bank statements by hierarchy permissions"
  ON releves_bancaires;

CREATE POLICY "Users can view accounting centers by hierarchy permissions"
  ON centres_analytiques FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create accounting centers by hierarchy permissions"
  ON centres_analytiques FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update accounting centers by hierarchy permissions"
  ON centres_analytiques FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete accounting centers by hierarchy permissions"
  ON centres_analytiques FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view tiers by hierarchy permissions"
  ON tiers FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create tiers by hierarchy permissions"
  ON tiers FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update tiers by hierarchy permissions"
  ON tiers FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete tiers by hierarchy permissions"
  ON tiers FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_references_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view accounting entries by hierarchy permissions"
  ON ecritures_comptables FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_entries_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create accounting entries by hierarchy permissions"
  ON ecritures_comptables FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_entries_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update accounting entries by hierarchy permissions"
  ON ecritures_comptables FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND (
      user_can_access_accounting_entries_scope(
        church_unit_id,
        id_assemblee_locale,
        'update'
      )
      OR user_can_access_accounting_entries_scope(
        church_unit_id,
        id_assemblee_locale,
        'validate'
      )
      OR user_can_access_accounting_entries_scope(
        church_unit_id,
        id_assemblee_locale,
        'consolidate'
      )
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      user_can_access_accounting_entries_scope(
        church_unit_id,
        id_assemblee_locale,
        'update'
      )
      OR user_can_access_accounting_entries_scope(
        church_unit_id,
        id_assemblee_locale,
        'validate'
      )
      OR user_can_access_accounting_entries_scope(
        church_unit_id,
        id_assemblee_locale,
        'consolidate'
      )
    )
  );

CREATE POLICY "Users can delete accounting entries by hierarchy permissions"
  ON ecritures_comptables FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_entries_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view accounting lines by entry permissions"
  ON lignes_ecritures FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND user_can_access_accounting_entries_scope(
          e.church_unit_id,
          e.id_assemblee_locale,
          'view_details'
        )
    )
  );

CREATE POLICY "Users can create accounting lines by entry permissions"
  ON lignes_ecritures FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND (
          user_can_access_accounting_entries_scope(
            e.church_unit_id,
            e.id_assemblee_locale,
            'create'
          )
          OR user_can_access_accounting_entries_scope(
            e.church_unit_id,
            e.id_assemblee_locale,
            'update'
          )
        )
    )
  );

CREATE POLICY "Users can update accounting lines by entry permissions"
  ON lignes_ecritures FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND user_can_access_accounting_entries_scope(
          e.church_unit_id,
          e.id_assemblee_locale,
          'update'
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND user_can_access_accounting_entries_scope(
          e.church_unit_id,
          e.id_assemblee_locale,
          'update'
        )
    )
  );

CREATE POLICY "Users can delete accounting lines by entry permissions"
  ON lignes_ecritures FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM ecritures_comptables e
      WHERE e.id = lignes_ecritures.id_ecriture
        AND e.organization_id = get_user_organization_id()
        AND user_can_access_accounting_entries_scope(
          e.church_unit_id,
          e.id_assemblee_locale,
          'update'
        )
    )
  );

CREATE POLICY "Users can view accounting budgets by hierarchy permissions"
  ON budgets_comptables FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_budgets_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create accounting budgets by hierarchy permissions"
  ON budgets_comptables FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_budgets_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update accounting budgets by hierarchy permissions"
  ON budgets_comptables FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_budgets_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_budgets_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete accounting budgets by hierarchy permissions"
  ON budgets_comptables FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_budgets_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view budget lines by budget permissions"
  ON lignes_budgets FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND user_can_access_accounting_budgets_scope(
          b.church_unit_id,
          b.id_assemblee_locale,
          'view_details'
        )
    )
  );

CREATE POLICY "Users can create budget lines by budget permissions"
  ON lignes_budgets FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND (
          user_can_access_accounting_budgets_scope(
            b.church_unit_id,
            b.id_assemblee_locale,
            'create'
          )
          OR user_can_access_accounting_budgets_scope(
            b.church_unit_id,
            b.id_assemblee_locale,
            'update'
          )
        )
    )
  );

CREATE POLICY "Users can update budget lines by budget permissions"
  ON lignes_budgets FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND user_can_access_accounting_budgets_scope(
          b.church_unit_id,
          b.id_assemblee_locale,
          'update'
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND user_can_access_accounting_budgets_scope(
          b.church_unit_id,
          b.id_assemblee_locale,
          'update'
        )
    )
  );

CREATE POLICY "Users can delete budget lines by budget permissions"
  ON lignes_budgets FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM budgets_comptables b
      WHERE b.id = lignes_budgets.id_budget
        AND b.organization_id = get_user_organization_id()
        AND user_can_access_accounting_budgets_scope(
          b.church_unit_id,
          b.id_assemblee_locale,
          'update'
        )
    )
  );

CREATE POLICY "Users can view accounting assets by hierarchy permissions"
  ON immobilisations_comptables FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_assets_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create accounting assets by hierarchy permissions"
  ON immobilisations_comptables FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_assets_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update accounting assets by hierarchy permissions"
  ON immobilisations_comptables FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_assets_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_assets_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete accounting assets by hierarchy permissions"
  ON immobilisations_comptables FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_accounting_assets_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can view bank statements by hierarchy permissions"
  ON releves_bancaires FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create bank statements by hierarchy permissions"
  ON releves_bancaires FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update bank statements by hierarchy permissions"
  ON releves_bancaires FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete bank statements by hierarchy permissions"
  ON releves_bancaires FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

GRANT EXECUTE ON FUNCTION user_can_access_accounting_references_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_accounting_entries_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_accounting_budgets_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_accounting_assets_scope(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_bank_reconciliation_scope(UUID, UUID, TEXT)
  TO authenticated;

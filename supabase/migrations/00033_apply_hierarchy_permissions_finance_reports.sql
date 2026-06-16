-- ============================================================================
-- Apply hierarchical permissions to operational finance and monthly reports
-- ============================================================================
-- Continues the progressive rollout started in 00032. Direct access to a user's
-- own unit stays unchanged, while descendant access now depends on the
-- permission matrix for:
--   - financial campaigns;
--   - financial pledges;
--   - financial movements;
--   - monthly reports.

CREATE OR REPLACE FUNCTION user_can_access_financial_campaigns_scope(
  p_church_unit_id UUID,
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
        'financial_campaigns',
        p_action_code
      )
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_financial_pledges_scope(
  p_church_unit_id UUID,
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
        'financial_pledges',
        p_action_code
      )
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_financial_movements_scope(
  p_church_unit_id UUID,
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
        'financial_movements',
        p_action_code
      )
    );
$$;

CREATE OR REPLACE FUNCTION user_can_access_monthly_reports_scope(
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
        'monthly_reports',
        p_action_code
      )
    )
    OR (
      p_church_unit_id IS NULL
      AND p_assemblee_id IS NOT NULL
      AND user_has_assemblee_access(p_assemblee_id)
    );
$$;

CREATE OR REPLACE FUNCTION ensure_extended_church_permission_rules(
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

  -- Monthly reports did not have default non-read permissions in 00031. Seed
  -- the accountant-facing actions for existing and future unit types.
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
    jsonb_build_object('seeded_from', '00033_monthly_reports_capabilities')
  FROM church_unit_types ancestor
  JOIN church_unit_types descendant
    ON descendant.organization_id = ancestor.organization_id
   AND descendant.level_order > ancestor.level_order
  JOIN church_permission_domains domain
    ON domain.organization_id = ancestor.organization_id
   AND domain.code = 'monthly_reports'
  JOIN church_permission_actions action
    ON action.organization_id = ancestor.organization_id
  WHERE ancestor.organization_id = p_org_id
    AND ancestor.can_view_descendants = TRUE
    AND (
      (
        ancestor.can_validate_finances = TRUE
        AND action.code IN ('validate', 'reject')
      )
      OR (
        ancestor.can_consolidate_finances = TRUE
        AND action.code IN ('consolidate', 'export')
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
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  v_org_id UUID;
BEGIN
  FOR v_org_id IN SELECT id FROM organizations
  LOOP
    PERFORM ensure_extended_church_permission_rules(v_org_id);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION enforce_financial_movement_workflow_permission()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_required_action TEXT := 'update';
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF OLD.statut IS DISTINCT FROM NEW.statut THEN
    IF NEW.statut = 'valide' THEN
      v_required_action := 'validate';
    ELSIF NEW.statut = 'rejete' THEN
      v_required_action := 'reject';
    ELSE
      v_required_action := 'update';
    END IF;
  END IF;

  IF NOT user_can_access_financial_movements_scope(
    NEW.church_unit_id,
    v_required_action
  ) THEN
    RAISE EXCEPTION
      'Droit insuffisant pour l''action % sur ce mouvement financier.',
      v_required_action
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_financial_movement_workflow_permission_trigger
  ON mouvements_financiers;
CREATE TRIGGER enforce_financial_movement_workflow_permission_trigger
  BEFORE UPDATE ON mouvements_financiers
  FOR EACH ROW
  EXECUTE FUNCTION enforce_financial_movement_workflow_permission();

DROP POLICY IF EXISTS "Users can view financial campaigns based on access"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can manage financial campaigns based on access"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can view financial pledges based on access"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can manage financial pledges based on access"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can view financial movements based on access"
  ON mouvements_financiers;
DROP POLICY IF EXISTS "Users can manage financial movements based on access"
  ON mouvements_financiers;
DROP POLICY IF EXISTS "Users can view rapports based on access"
  ON rapports_mensuels_eab;
DROP POLICY IF EXISTS "Users can manage rapports based on access"
  ON rapports_mensuels_eab;

DROP POLICY IF EXISTS "Users can view financial campaigns by hierarchy permissions"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can create financial campaigns by hierarchy permissions"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can update financial campaigns by hierarchy permissions"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can delete financial campaigns by hierarchy permissions"
  ON campagnes_financieres;

DROP POLICY IF EXISTS "Users can view financial pledges by hierarchy permissions"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can create financial pledges by hierarchy permissions"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can update financial pledges by hierarchy permissions"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can delete financial pledges by hierarchy permissions"
  ON promesses_financieres;

DROP POLICY IF EXISTS "Users can view financial movements by hierarchy permissions"
  ON mouvements_financiers;
DROP POLICY IF EXISTS "Users can create financial movements by hierarchy permissions"
  ON mouvements_financiers;
DROP POLICY IF EXISTS "Users can update financial movements by hierarchy permissions"
  ON mouvements_financiers;
DROP POLICY IF EXISTS "Users can delete financial movements by hierarchy permissions"
  ON mouvements_financiers;

DROP POLICY IF EXISTS "Users can view monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab;
DROP POLICY IF EXISTS "Users can create monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab;
DROP POLICY IF EXISTS "Users can update monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab;
DROP POLICY IF EXISTS "Users can delete monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab;

CREATE POLICY "Users can view financial campaigns by hierarchy permissions"
  ON campagnes_financieres FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_campaigns_scope(
      church_unit_id,
      'view_details'
    )
  );

CREATE POLICY "Users can create financial campaigns by hierarchy permissions"
  ON campagnes_financieres FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_campaigns_scope(church_unit_id, 'create')
  );

CREATE POLICY "Users can update financial campaigns by hierarchy permissions"
  ON campagnes_financieres FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_campaigns_scope(church_unit_id, 'update')
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_campaigns_scope(church_unit_id, 'update')
  );

CREATE POLICY "Users can delete financial campaigns by hierarchy permissions"
  ON campagnes_financieres FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_campaigns_scope(church_unit_id, 'update')
  );

CREATE POLICY "Users can view financial pledges by hierarchy permissions"
  ON promesses_financieres FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_pledges_scope(church_unit_id, 'view_details')
  );

CREATE POLICY "Users can create financial pledges by hierarchy permissions"
  ON promesses_financieres FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_pledges_scope(church_unit_id, 'create')
  );

CREATE POLICY "Users can update financial pledges by hierarchy permissions"
  ON promesses_financieres FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_pledges_scope(church_unit_id, 'update')
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_pledges_scope(church_unit_id, 'update')
  );

CREATE POLICY "Users can delete financial pledges by hierarchy permissions"
  ON promesses_financieres FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_pledges_scope(church_unit_id, 'update')
  );

CREATE POLICY "Users can view financial movements by hierarchy permissions"
  ON mouvements_financiers FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_movements_scope(
      church_unit_id,
      'view_details'
    )
  );

CREATE POLICY "Users can create financial movements by hierarchy permissions"
  ON mouvements_financiers FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_movements_scope(church_unit_id, 'create')
  );

CREATE POLICY "Users can update financial movements by hierarchy permissions"
  ON mouvements_financiers FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND (
      user_can_access_financial_movements_scope(church_unit_id, 'update')
      OR user_can_access_financial_movements_scope(church_unit_id, 'validate')
      OR user_can_access_financial_movements_scope(church_unit_id, 'reject')
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      user_can_access_financial_movements_scope(church_unit_id, 'update')
      OR user_can_access_financial_movements_scope(church_unit_id, 'validate')
      OR user_can_access_financial_movements_scope(church_unit_id, 'reject')
    )
  );

CREATE POLICY "Users can delete financial movements by hierarchy permissions"
  ON mouvements_financiers FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_financial_movements_scope(church_unit_id, 'update')
  );

CREATE POLICY "Users can view monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_monthly_reports_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_monthly_reports_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_monthly_reports_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_monthly_reports_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete monthly reports by hierarchy permissions"
  ON rapports_mensuels_eab FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_monthly_reports_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

GRANT EXECUTE ON FUNCTION user_can_access_financial_campaigns_scope(UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_financial_pledges_scope(UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_financial_movements_scope(UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_monthly_reports_scope(UUID, UUID, TEXT)
  TO authenticated;

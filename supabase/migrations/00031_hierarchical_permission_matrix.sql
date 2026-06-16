-- ============================================================================
-- Hierarchical permission matrix
-- ============================================================================
-- Adds a configurable decision layer for superior -> descendant visibility and
-- actions. Existing RLS policies remain conservative during rollout; this
-- migration provides the catalog, rules, overrides and RPCs that the settings UI
-- can use to control permissions point by point.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS church_permission_domains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  label TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  system_default BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT church_permission_domains_code_check
    CHECK (code ~ '^[a-z][a-z0-9_]*$'),
  CONSTRAINT church_permission_domains_label_not_blank
    CHECK (length(trim(label)) > 0),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS church_permission_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  label TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  system_default BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT church_permission_actions_code_check
    CHECK (code ~ '^[a-z][a-z0-9_]*$'),
  CONSTRAINT church_permission_actions_label_not_blank
    CHECK (length(trim(label)) > 0),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS church_hierarchy_permission_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  ancestor_type_id UUID NOT NULL REFERENCES church_unit_types(id) ON DELETE CASCADE,
  descendant_type_id UUID NOT NULL REFERENCES church_unit_types(id) ON DELETE CASCADE,
  domain_id UUID NOT NULL REFERENCES church_permission_domains(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES church_permission_actions(id) ON DELETE CASCADE,
  allowed BOOLEAN NOT NULL DEFAULT FALSE,
  requires_descendant_acceptance BOOLEAN NOT NULL DEFAULT FALSE,
  inherited BOOLEAN NOT NULL DEFAULT TRUE,
  configured_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT church_hierarchy_permission_rules_distinct_types
    CHECK (ancestor_type_id <> descendant_type_id),
  UNIQUE (
    organization_id,
    ancestor_type_id,
    descendant_type_id,
    domain_id,
    action_id
  )
);

CREATE TABLE IF NOT EXISTS church_unit_permission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  ancestor_unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  descendant_unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  domain_id UUID NOT NULL REFERENCES church_permission_domains(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES church_permission_actions(id) ON DELETE CASCADE,
  allowed BOOLEAN NOT NULL DEFAULT FALSE,
  requires_descendant_acceptance BOOLEAN NOT NULL DEFAULT FALSE,
  acceptance_status TEXT NOT NULL DEFAULT 'not_required',
  configured_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  accepted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  accepted_at TIMESTAMPTZ,
  reason TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT church_unit_permission_overrides_distinct_units
    CHECK (ancestor_unit_id <> descendant_unit_id),
  CONSTRAINT church_unit_permission_overrides_acceptance_check
    CHECK (
      acceptance_status IN (
        'not_required',
        'pending',
        'accepted',
        'rejected',
        'revoked'
      )
    ),
  UNIQUE (
    organization_id,
    ancestor_unit_id,
    descendant_unit_id,
    domain_id,
    action_id
  )
);

COMMENT ON TABLE church_permission_domains IS
  'Functional domains that can be controlled between hierarchy levels.';
COMMENT ON TABLE church_permission_actions IS
  'Actions that can be granted or denied for a controlled domain.';
COMMENT ON TABLE church_hierarchy_permission_rules IS
  'Default permissions between one superior unit type and one descendant unit type.';
COMMENT ON TABLE church_unit_permission_overrides IS
  'Concrete exceptions between two church units, optionally requiring descendant acceptance.';

CREATE INDEX IF NOT EXISTS idx_church_permission_domains_org
  ON church_permission_domains(organization_id);
CREATE INDEX IF NOT EXISTS idx_church_permission_actions_org
  ON church_permission_actions(organization_id);
CREATE INDEX IF NOT EXISTS idx_church_hierarchy_permission_rules_org
  ON church_hierarchy_permission_rules(organization_id);
CREATE INDEX IF NOT EXISTS idx_church_hierarchy_permission_rules_types
  ON church_hierarchy_permission_rules(ancestor_type_id, descendant_type_id);
CREATE INDEX IF NOT EXISTS idx_church_unit_permission_overrides_org
  ON church_unit_permission_overrides(organization_id);
CREATE INDEX IF NOT EXISTS idx_church_unit_permission_overrides_units
  ON church_unit_permission_overrides(ancestor_unit_id, descendant_unit_id);

CREATE OR REPLACE FUNCTION is_church_unit_ancestor(
  p_ancestor_unit_id UUID,
  p_descendant_unit_id UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SET search_path = public
AS $$
  WITH RECURSIVE parents AS (
    SELECT id, parent_id
    FROM church_units
    WHERE id = p_descendant_unit_id

    UNION ALL

    SELECT parent.id, parent.parent_id
    FROM church_units parent
    JOIN parents child ON child.parent_id = parent.id
  )
  SELECT EXISTS (
    SELECT 1
    FROM parents
    WHERE id = p_ancestor_unit_id
  );
$$;

CREATE OR REPLACE FUNCTION ensure_default_church_permission_catalog(
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

  INSERT INTO church_permission_domains (
    organization_id,
    code,
    label,
    description,
    sort_order,
    system_default
  )
  SELECT p_org_id, code, label, description, sort_order, TRUE
  FROM (
    VALUES
      ('members', 'Fideles', 'Membres et fideles rattaches aux unites.', 10),
      ('families', 'Familles', 'Familles et foyers rattaches aux unites.', 20),
      ('programs', 'Programmes', 'Programmes, activites et evenements.', 30),
      ('monthly_reports', 'Rapports mensuels', 'Rapports mensuels pastoraux et statistiques.', 40),
      ('financial_campaigns', 'Collectes et cotisations', 'Campagnes, cotisations et appels de fonds.', 50),
      ('financial_pledges', 'Promesses de don', 'Promesses de don et engagements associes.', 60),
      ('financial_movements', 'Mouvements financiers', 'Encaissements et decaissements operationnels.', 70),
      ('accounting_entries', 'Ecritures comptables', 'Ecritures SYSCEBNL et pieces comptables.', 80),
      ('accounting_budgets', 'Budgets', 'Budgets et lignes budgetaires.', 90),
      ('accounting_assets', 'Immobilisations', 'Immobilisations et amortissements.', 100),
      ('bank_reconciliation', 'Rapprochements', 'Releves bancaires et rapprochements.', 110),
      ('accounting_reports', 'Rapports comptables', 'Balance, grand livre et resultats comptables.', 120),
      ('financial_statements', 'Etats financiers', 'Bilan, resultat et etats financiers SYSCEBNL.', 130),
      ('notifications', 'Notifications', 'Messages envoyes aux niveaux inferieurs.', 140),
      ('exports', 'Exports', 'Exports PDF, Excel et fichiers de synthese.', 150),
      ('settings', 'Parametres', 'Parametres de structure, roles et organisation.', 160)
  ) AS d(code, label, description, sort_order)
  ON CONFLICT (organization_id, code) DO NOTHING;

  INSERT INTO church_permission_actions (
    organization_id,
    code,
    label,
    description,
    sort_order,
    system_default
  )
  SELECT p_org_id, code, label, description, sort_order, TRUE
  FROM (
    VALUES
      ('view_summary', 'Voir la synthese', 'Voir les totaux et indicateurs agreges.', 10),
      ('view_details', 'Voir le detail', 'Voir les lignes et fiches detaillees.', 20),
      ('create', 'Creer', 'Creer des donnees dans le perimetre descendant.', 30),
      ('update', 'Modifier', 'Modifier des donnees dans le perimetre descendant.', 40),
      ('validate', 'Valider', 'Valider ou approuver une donnee soumise.', 50),
      ('reject', 'Rejeter', 'Rejeter une donnee soumise avec motif.', 60),
      ('export', 'Exporter', 'Exporter les donnees autorisees.', 70),
      ('consolidate', 'Consolider', 'Produire une consolidation des niveaux inferieurs.', 80),
      ('notify', 'Notifier', 'Envoyer des notifications descendantes.', 90),
      ('configure', 'Configurer', 'Configurer les droits ou parametres du perimetre.', 100)
  ) AS a(code, label, description, sort_order)
  ON CONFLICT (organization_id, code) DO NOTHING;

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
    p_org_id,
    ancestor.id,
    descendant.id,
    domain.id,
    action.id,
    TRUE,
    FALSE,
    TRUE,
    jsonb_build_object('seeded_from', 'church_unit_type_capabilities')
  FROM church_unit_types ancestor
  JOIN church_unit_types descendant
    ON descendant.organization_id = ancestor.organization_id
   AND descendant.level_order > ancestor.level_order
  JOIN church_permission_domains domain
    ON domain.organization_id = ancestor.organization_id
  JOIN church_permission_actions action
    ON action.organization_id = ancestor.organization_id
  WHERE ancestor.organization_id = p_org_id
    AND ancestor.can_view_descendants = TRUE
    AND (
      (
        domain.code IN (
          'members',
          'families',
          'programs',
          'monthly_reports',
          'financial_campaigns',
          'financial_pledges',
          'financial_movements',
          'accounting_entries',
          'accounting_budgets',
          'accounting_assets',
          'bank_reconciliation',
          'accounting_reports',
          'financial_statements',
          'exports'
        )
        AND action.code IN ('view_summary', 'view_details')
      )
      OR (
        ancestor.can_create_programs = TRUE
        AND domain.code = 'programs'
        AND action.code IN ('create', 'update')
      )
      OR (
        ancestor.can_launch_contributions = TRUE
        AND domain.code IN ('financial_campaigns', 'financial_pledges')
        AND action.code IN ('create', 'update')
      )
      OR (
        ancestor.can_validate_finances = TRUE
        AND domain.code IN ('financial_movements', 'accounting_entries')
        AND action.code IN ('validate', 'reject')
      )
      OR (
        ancestor.can_consolidate_finances = TRUE
        AND domain.code IN ('accounting_reports', 'financial_statements', 'exports')
        AND action.code IN ('export', 'consolidate')
      )
      OR (
        ancestor.can_notify_descendants = TRUE
        AND domain.code = 'notifications'
        AND action.code IN ('create', 'notify')
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

CREATE OR REPLACE FUNCTION validate_church_hierarchy_permission_rule()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_ancestor_org_id UUID;
  v_descendant_org_id UUID;
  v_domain_org_id UUID;
  v_action_org_id UUID;
  v_ancestor_level INTEGER;
  v_descendant_level INTEGER;
BEGIN
  SELECT organization_id, level_order
  INTO v_ancestor_org_id, v_ancestor_level
  FROM church_unit_types
  WHERE id = NEW.ancestor_type_id;

  SELECT organization_id, level_order
  INTO v_descendant_org_id, v_descendant_level
  FROM church_unit_types
  WHERE id = NEW.descendant_type_id;

  SELECT organization_id
  INTO v_domain_org_id
  FROM church_permission_domains
  WHERE id = NEW.domain_id;

  SELECT organization_id
  INTO v_action_org_id
  FROM church_permission_actions
  WHERE id = NEW.action_id;

  IF NEW.organization_id IS DISTINCT FROM v_ancestor_org_id
     OR NEW.organization_id IS DISTINCT FROM v_descendant_org_id
     OR NEW.organization_id IS DISTINCT FROM v_domain_org_id
     OR NEW.organization_id IS DISTINCT FROM v_action_org_id THEN
    RAISE EXCEPTION 'La regle doit rester dans la meme organisation.'
      USING ERRCODE = '23514';
  END IF;

  IF v_ancestor_level >= v_descendant_level THEN
    RAISE EXCEPTION 'Une regle hierarchique doit aller du niveau superieur vers un niveau inferieur.'
      USING ERRCODE = '23514';
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION validate_church_unit_permission_override()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_ancestor_org_id UUID;
  v_descendant_org_id UUID;
  v_domain_org_id UUID;
  v_action_org_id UUID;
BEGIN
  SELECT organization_id
  INTO v_ancestor_org_id
  FROM church_units
  WHERE id = NEW.ancestor_unit_id;

  SELECT organization_id
  INTO v_descendant_org_id
  FROM church_units
  WHERE id = NEW.descendant_unit_id;

  SELECT organization_id
  INTO v_domain_org_id
  FROM church_permission_domains
  WHERE id = NEW.domain_id;

  SELECT organization_id
  INTO v_action_org_id
  FROM church_permission_actions
  WHERE id = NEW.action_id;

  IF NEW.organization_id IS DISTINCT FROM v_ancestor_org_id
     OR NEW.organization_id IS DISTINCT FROM v_descendant_org_id
     OR NEW.organization_id IS DISTINCT FROM v_domain_org_id
     OR NEW.organization_id IS DISTINCT FROM v_action_org_id THEN
    RAISE EXCEPTION 'La derogation doit rester dans la meme organisation.'
      USING ERRCODE = '23514';
  END IF;

  IF NOT is_church_unit_ancestor(NEW.ancestor_unit_id, NEW.descendant_unit_id) THEN
    RAISE EXCEPTION 'La derogation doit relier une unite superieure a une unite descendante.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.requires_descendant_acceptance = TRUE
     AND NEW.allowed = TRUE
     AND NEW.acceptance_status = 'not_required' THEN
    NEW.acceptance_status := 'pending';
  END IF;

  IF NEW.requires_descendant_acceptance = FALSE THEN
    NEW.acceptance_status := 'not_required';
    NEW.accepted_by := NULL;
    NEW.accepted_at := NULL;
  END IF;

  IF NEW.acceptance_status = 'accepted' AND NEW.accepted_at IS NULL THEN
    NEW.accepted_at := NOW();
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validate_church_hierarchy_permission_rule_trigger
  ON church_hierarchy_permission_rules;
CREATE TRIGGER validate_church_hierarchy_permission_rule_trigger
  BEFORE INSERT OR UPDATE ON church_hierarchy_permission_rules
  FOR EACH ROW
  EXECUTE FUNCTION validate_church_hierarchy_permission_rule();

DROP TRIGGER IF EXISTS validate_church_unit_permission_override_trigger
  ON church_unit_permission_overrides;
CREATE TRIGGER validate_church_unit_permission_override_trigger
  BEFORE INSERT OR UPDATE ON church_unit_permission_overrides
  FOR EACH ROW
  EXECUTE FUNCTION validate_church_unit_permission_override();

DROP TRIGGER IF EXISTS update_church_permission_domains_updated_at
  ON church_permission_domains;
CREATE TRIGGER update_church_permission_domains_updated_at
  BEFORE UPDATE ON church_permission_domains
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_church_permission_actions_updated_at
  ON church_permission_actions;
CREATE TRIGGER update_church_permission_actions_updated_at
  BEFORE UPDATE ON church_permission_actions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION seed_church_permissions_after_type_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM ensure_default_church_permission_catalog(NEW.organization_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS seed_church_permissions_after_type_change_trigger
  ON church_unit_types;
CREATE TRIGGER seed_church_permissions_after_type_change_trigger
  AFTER INSERT OR UPDATE OF level_order,
    can_create_programs,
    can_launch_contributions,
    can_validate_finances,
    can_consolidate_finances,
    can_notify_descendants,
    can_view_descendants
  ON church_unit_types
  FOR EACH ROW
  EXECUTE FUNCTION seed_church_permissions_after_type_change();

CREATE OR REPLACE FUNCTION get_church_hierarchy_permission(
  p_ancestor_unit_id UUID,
  p_descendant_unit_id UUID,
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
  v_org_id UUID;
  v_ancestor_type_id UUID;
  v_descendant_type_id UUID;
  v_domain_id UUID;
  v_action_id UUID;
  v_override church_unit_permission_overrides%ROWTYPE;
  v_rule church_hierarchy_permission_rules%ROWTYPE;
BEGIN
  IF p_ancestor_unit_id IS NULL
     OR p_descendant_unit_id IS NULL
     OR NULLIF(trim(p_domain_code), '') IS NULL
     OR NULLIF(trim(p_action_code), '') IS NULL THEN
    RETURN FALSE;
  END IF;

  IF p_ancestor_unit_id = p_descendant_unit_id THEN
    RETURN TRUE;
  END IF;

  SELECT ancestor.organization_id, ancestor.type_id, descendant.type_id
  INTO v_org_id, v_ancestor_type_id, v_descendant_type_id
  FROM church_units ancestor
  JOIN church_units descendant
    ON descendant.organization_id = ancestor.organization_id
  WHERE ancestor.id = p_ancestor_unit_id
    AND descendant.id = p_descendant_unit_id;

  IF v_org_id IS NULL THEN
    RETURN FALSE;
  END IF;

  IF auth.uid() IS NOT NULL
     AND v_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RETURN FALSE;
  END IF;

  IF NOT is_church_unit_ancestor(p_ancestor_unit_id, p_descendant_unit_id) THEN
    RETURN FALSE;
  END IF;

  SELECT id
  INTO v_domain_id
  FROM church_permission_domains
  WHERE organization_id = v_org_id
    AND code = lower(trim(p_domain_code))
    AND active = TRUE;

  SELECT id
  INTO v_action_id
  FROM church_permission_actions
  WHERE organization_id = v_org_id
    AND code = lower(trim(p_action_code))
    AND active = TRUE;

  IF v_domain_id IS NULL OR v_action_id IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT *
  INTO v_override
  FROM church_unit_permission_overrides
  WHERE organization_id = v_org_id
    AND ancestor_unit_id = p_ancestor_unit_id
    AND descendant_unit_id = p_descendant_unit_id
    AND domain_id = v_domain_id
    AND action_id = v_action_id
  LIMIT 1;

  IF FOUND THEN
    RETURN v_override.allowed
      AND (
        v_override.requires_descendant_acceptance = FALSE
        OR v_override.acceptance_status = 'accepted'
      );
  END IF;

  SELECT *
  INTO v_rule
  FROM church_hierarchy_permission_rules
  WHERE organization_id = v_org_id
    AND ancestor_type_id = v_ancestor_type_id
    AND descendant_type_id = v_descendant_type_id
    AND domain_id = v_domain_id
    AND action_id = v_action_id
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  RETURN v_rule.allowed
    AND v_rule.requires_descendant_acceptance = FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION set_church_unit_permission_override(
  p_ancestor_unit_id UUID,
  p_descendant_unit_id UUID,
  p_domain_code TEXT,
  p_action_code TEXT,
  p_allowed BOOLEAN,
  p_requires_descendant_acceptance BOOLEAN DEFAULT FALSE,
  p_reason TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_org_id UUID;
  v_domain_id UUID;
  v_action_id UUID;
  v_override_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifie.'
      USING ERRCODE = '28000';
  END IF;

  SELECT ancestor.organization_id
  INTO v_org_id
  FROM church_units ancestor
  JOIN church_units descendant
    ON descendant.organization_id = ancestor.organization_id
  WHERE ancestor.id = p_ancestor_unit_id
    AND descendant.id = p_descendant_unit_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Unites introuvables ou rattachees a des organisations differentes.'
      USING ERRCODE = '23514';
  END IF;

  IF v_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Autorisation hors organisation.'
      USING ERRCODE = '42501';
  END IF;

  IF get_user_role() <> 'admin_national'
     AND NOT user_has_church_unit_access(p_ancestor_unit_id) THEN
    RAISE EXCEPTION 'Droit insuffisant pour configurer cette autorisation.'
      USING ERRCODE = '42501';
  END IF;

  SELECT id
  INTO v_domain_id
  FROM church_permission_domains
  WHERE organization_id = v_org_id
    AND code = lower(trim(p_domain_code))
    AND active = TRUE;

  SELECT id
  INTO v_action_id
  FROM church_permission_actions
  WHERE organization_id = v_org_id
    AND code = lower(trim(p_action_code))
    AND active = TRUE;

  IF v_domain_id IS NULL OR v_action_id IS NULL THEN
    RAISE EXCEPTION 'Domaine ou action introuvable.'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO church_unit_permission_overrides (
    organization_id,
    ancestor_unit_id,
    descendant_unit_id,
    domain_id,
    action_id,
    allowed,
    requires_descendant_acceptance,
    acceptance_status,
    configured_by,
    reason
  )
  VALUES (
    v_org_id,
    p_ancestor_unit_id,
    p_descendant_unit_id,
    v_domain_id,
    v_action_id,
    coalesce(p_allowed, FALSE),
    coalesce(p_requires_descendant_acceptance, FALSE),
    CASE
      WHEN coalesce(p_allowed, FALSE)
        AND coalesce(p_requires_descendant_acceptance, FALSE)
        THEN 'pending'
      ELSE 'not_required'
    END,
    v_user_id,
    NULLIF(trim(p_reason), '')
  )
  ON CONFLICT (
    organization_id,
    ancestor_unit_id,
    descendant_unit_id,
    domain_id,
    action_id
  ) DO UPDATE SET
    allowed = EXCLUDED.allowed,
    requires_descendant_acceptance = EXCLUDED.requires_descendant_acceptance,
    acceptance_status = EXCLUDED.acceptance_status,
    configured_by = EXCLUDED.configured_by,
    accepted_by = NULL,
    accepted_at = NULL,
    reason = EXCLUDED.reason,
    updated_at = NOW()
  RETURNING id INTO v_override_id;

  RETURN v_override_id;
END;
$$;

CREATE OR REPLACE FUNCTION respond_church_unit_permission_override(
  p_override_id UUID,
  p_accept BOOLEAN,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_override church_unit_permission_overrides%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifie.'
      USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_override
  FROM church_unit_permission_overrides
  WHERE id = p_override_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Autorisation introuvable.'
      USING ERRCODE = '22023';
  END IF;

  IF v_override.organization_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Autorisation hors organisation.'
      USING ERRCODE = '42501';
  END IF;

  IF get_user_role() <> 'admin_national'
     AND NOT user_has_church_unit_access(v_override.descendant_unit_id) THEN
    RAISE EXCEPTION 'Droit insuffisant pour repondre a cette autorisation.'
      USING ERRCODE = '42501';
  END IF;

  UPDATE church_unit_permission_overrides
  SET
    acceptance_status = CASE
      WHEN coalesce(p_accept, FALSE) THEN 'accepted'
      ELSE 'rejected'
    END,
    accepted_by = CASE
      WHEN coalesce(p_accept, FALSE) THEN v_user_id
      ELSE NULL
    END,
    accepted_at = CASE
      WHEN coalesce(p_accept, FALSE) THEN NOW()
      ELSE NULL
    END,
    reason = COALESCE(NULLIF(trim(p_reason), ''), reason),
    updated_at = NOW()
  WHERE id = p_override_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_effective_church_unit_permissions(
  p_ancestor_unit_id UUID,
  p_descendant_unit_id UUID
)
RETURNS TABLE (
  domain_code TEXT,
  domain_label TEXT,
  action_code TEXT,
  action_label TEXT,
  allowed BOOLEAN,
  source TEXT,
  requires_descendant_acceptance BOOLEAN,
  acceptance_status TEXT
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  WITH unit_context AS (
    SELECT
      ancestor.organization_id,
      ancestor.type_id AS ancestor_type_id,
      descendant.type_id AS descendant_type_id
    FROM church_units ancestor
    JOIN church_units descendant
      ON descendant.organization_id = ancestor.organization_id
    WHERE ancestor.id = p_ancestor_unit_id
      AND descendant.id = p_descendant_unit_id
      AND is_church_unit_ancestor(p_ancestor_unit_id, p_descendant_unit_id)
      AND (
        auth.uid() IS NULL
        OR ancestor.organization_id = get_user_organization_id()
      )
  )
  SELECT
    domain.code AS domain_code,
    domain.label AS domain_label,
    action.code AS action_code,
    action.label AS action_label,
    COALESCE(
      override.allowed
        AND (
          override.requires_descendant_acceptance = FALSE
          OR override.acceptance_status = 'accepted'
        ),
      rule.allowed
        AND rule.requires_descendant_acceptance = FALSE,
      FALSE
    ) AS allowed,
    CASE
      WHEN override.id IS NOT NULL THEN 'override'
      WHEN rule.id IS NOT NULL THEN 'rule'
      ELSE 'none'
    END AS source,
    COALESCE(
      override.requires_descendant_acceptance,
      rule.requires_descendant_acceptance,
      FALSE
    ) AS requires_descendant_acceptance,
    COALESCE(override.acceptance_status, 'not_required') AS acceptance_status
  FROM unit_context ctx
  JOIN church_permission_domains domain
    ON domain.organization_id = ctx.organization_id
   AND domain.active = TRUE
  JOIN church_permission_actions action
    ON action.organization_id = ctx.organization_id
   AND action.active = TRUE
  LEFT JOIN church_hierarchy_permission_rules rule
    ON rule.organization_id = ctx.organization_id
   AND rule.ancestor_type_id = ctx.ancestor_type_id
   AND rule.descendant_type_id = ctx.descendant_type_id
   AND rule.domain_id = domain.id
   AND rule.action_id = action.id
  LEFT JOIN church_unit_permission_overrides override
    ON override.organization_id = ctx.organization_id
   AND override.ancestor_unit_id = p_ancestor_unit_id
   AND override.descendant_unit_id = p_descendant_unit_id
   AND override.domain_id = domain.id
   AND override.action_id = action.id
  ORDER BY domain.sort_order, action.sort_order;
$$;

ALTER TABLE church_permission_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE church_permission_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE church_hierarchy_permission_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE church_unit_permission_overrides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view permission domains"
  ON church_permission_domains;
DROP POLICY IF EXISTS "Admins can manage permission domains"
  ON church_permission_domains;
DROP POLICY IF EXISTS "Users can view permission actions"
  ON church_permission_actions;
DROP POLICY IF EXISTS "Admins can manage permission actions"
  ON church_permission_actions;
DROP POLICY IF EXISTS "Users can view hierarchy permission rules"
  ON church_hierarchy_permission_rules;
DROP POLICY IF EXISTS "Admins can manage hierarchy permission rules"
  ON church_hierarchy_permission_rules;
DROP POLICY IF EXISTS "Users can view unit permission overrides"
  ON church_unit_permission_overrides;
DROP POLICY IF EXISTS "Users can manage unit permission overrides"
  ON church_unit_permission_overrides;

CREATE POLICY "Users can view permission domains"
  ON church_permission_domains FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Admins can manage permission domains"
  ON church_permission_domains FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

CREATE POLICY "Users can view permission actions"
  ON church_permission_actions FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Admins can manage permission actions"
  ON church_permission_actions FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

CREATE POLICY "Users can view hierarchy permission rules"
  ON church_hierarchy_permission_rules FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Admins can manage hierarchy permission rules"
  ON church_hierarchy_permission_rules FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

CREATE POLICY "Users can view unit permission overrides"
  ON church_unit_permission_overrides FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(ancestor_unit_id)
      OR user_has_church_unit_access(descendant_unit_id)
    )
  );

CREATE POLICY "Users can manage unit permission overrides"
  ON church_unit_permission_overrides FOR ALL
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(ancestor_unit_id)
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(ancestor_unit_id)
    )
  );

GRANT ALL ON church_permission_domains TO authenticated;
GRANT ALL ON church_permission_actions TO authenticated;
GRANT ALL ON church_hierarchy_permission_rules TO authenticated;
GRANT ALL ON church_unit_permission_overrides TO authenticated;
GRANT EXECUTE ON FUNCTION is_church_unit_ancestor(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_church_hierarchy_permission(UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION set_church_unit_permission_override(UUID, UUID, TEXT, TEXT, BOOLEAN, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION respond_church_unit_permission_override(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_effective_church_unit_permissions(UUID, UUID) TO authenticated;

DO $$
DECLARE
  v_org_id UUID;
BEGIN
  FOR v_org_id IN SELECT id FROM organizations
  LOOP
    PERFORM ensure_default_church_permission_catalog(v_org_id);
  END LOOP;
END $$;

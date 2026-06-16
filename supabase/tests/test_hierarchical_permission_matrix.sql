-- ============================================================================
-- Test E2E DB - Hierarchical permission matrix
-- ============================================================================
-- Objectif :
--   1. Creer deux niveaux temporaires dans une organisation existante.
--   2. Verifier que le catalogue et les regles par defaut sont disponibles.
--   3. Verifier une exception qui exige l'acceptation du niveau inferieur.
--   4. Nettoyer les donnees de test avant COMMIT.
--
-- Ce script ne laisse pas de donnees de test persistantes.
-- ============================================================================

DROP TABLE IF EXISTS _hierarchical_permission_test_result;
CREATE TEMP TABLE _hierarchical_permission_test_result (
  sort_order INTEGER,
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
) ON COMMIT PRESERVE ROWS;

BEGIN;

DO $$
DECLARE
  v_admin_id UUID;
  v_org_id UUID;
  v_suffix TEXT := lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_parent_type_id UUID := gen_random_uuid();
  v_child_type_id UUID := gen_random_uuid();
  v_parent_unit_id UUID := gen_random_uuid();
  v_child_unit_id UUID := gen_random_uuid();
  v_domain_id UUID;
  v_action_id UUID;
  v_override_id UUID;
  v_default_allowed BOOLEAN;
  v_pending_allowed BOOLEAN;
  v_accepted_allowed BOOLEAN;
  v_effective_count INTEGER;
BEGIN
  SELECT p.id, p.organization_id
  INTO v_admin_id, v_org_id
  FROM profiles p
  WHERE p.role = 'admin_national'
    AND p.organization_id IS NOT NULL
  ORDER BY p.created_at
  LIMIT 1;

  IF v_admin_id IS NULL OR v_org_id IS NULL THEN
    RAISE EXCEPTION 'Aucun profil admin_national avec organisation_id trouve.';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);

  INSERT INTO church_unit_types (
    id,
    organization_id,
    code,
    label,
    level_order,
    is_local,
    is_financial_scope,
    can_have_members,
    can_create_programs,
    can_launch_contributions,
    can_validate_finances,
    can_consolidate_finances,
    can_notify_descendants,
    can_view_descendants
  )
  VALUES (
    v_parent_type_id,
    v_org_id,
    'codex_superieur_' || v_suffix,
    'Niveau superieur test',
    90,
    FALSE,
    TRUE,
    FALSE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE
  );

  INSERT INTO church_unit_types (
    id,
    organization_id,
    code,
    label,
    level_order,
    is_local,
    is_financial_scope,
    can_have_members,
    can_create_programs,
    can_launch_contributions,
    can_validate_finances,
    can_consolidate_finances,
    can_notify_descendants,
    can_view_descendants
  )
  VALUES (
    v_child_type_id,
    v_org_id,
    'codex_inferieur_' || v_suffix,
    'Niveau inferieur test',
    91,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE,
    FALSE,
    TRUE
  );

  INSERT INTO church_units (
    id,
    organization_id,
    type_id,
    parent_id,
    nom,
    code,
    metadata
  )
  VALUES (
    v_parent_unit_id,
    v_org_id,
    v_parent_type_id,
    NULL,
    'Unite superieure test',
    'TEST-SUP-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  );

  INSERT INTO church_units (
    id,
    organization_id,
    type_id,
    parent_id,
    nom,
    code,
    metadata
  )
  VALUES (
    v_child_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Unite inferieure test',
    'TEST-INF-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  );

  PERFORM ensure_default_church_permission_catalog(v_org_id);

  SELECT id
  INTO v_domain_id
  FROM church_permission_domains
  WHERE organization_id = v_org_id
    AND code = 'members';

  SELECT id
  INTO v_action_id
  FROM church_permission_actions
  WHERE organization_id = v_org_id
    AND code = 'view_details';

  SELECT get_church_hierarchy_permission(
    v_parent_unit_id,
    v_child_unit_id,
    'members',
    'view_details'
  )
  INTO v_default_allowed;

  SELECT set_church_unit_permission_override(
    v_parent_unit_id,
    v_child_unit_id,
    'members',
    'view_details',
    TRUE,
    TRUE,
    'Test acceptation descendante'
  )
  INTO v_override_id;

  SELECT get_church_hierarchy_permission(
    v_parent_unit_id,
    v_child_unit_id,
    'members',
    'view_details'
  )
  INTO v_pending_allowed;

  PERFORM respond_church_unit_permission_override(
    v_override_id,
    TRUE,
    'Acceptation test'
  );

  SELECT get_church_hierarchy_permission(
    v_parent_unit_id,
    v_child_unit_id,
    'members',
    'view_details'
  )
  INTO v_accepted_allowed;

  SELECT COUNT(*)
  INTO v_effective_count
  FROM get_effective_church_unit_permissions(v_parent_unit_id, v_child_unit_id);

  INSERT INTO _hierarchical_permission_test_result VALUES
    (
      1,
      'catalogue_cree',
      v_domain_id IS NOT NULL AND v_action_id IS NOT NULL,
      'domain=' || COALESCE(v_domain_id::text, 'NULL') ||
        ', action=' || COALESCE(v_action_id::text, 'NULL')
    ),
    (
      2,
      'regle_par_defaut_autorise',
      v_default_allowed = TRUE,
      'allowed=' || COALESCE(v_default_allowed::text, 'NULL')
    ),
    (
      3,
      'acceptation_descendante_exigee',
      v_pending_allowed = FALSE,
      'allowed_avant_acceptation=' || COALESCE(v_pending_allowed::text, 'NULL')
    ),
    (
      4,
      'autorisation_active_apres_acceptation',
      v_accepted_allowed = TRUE,
      'allowed_apres_acceptation=' || COALESCE(v_accepted_allowed::text, 'NULL')
    ),
    (
      5,
      'matrice_effective_disponible',
      v_effective_count > 0,
      'permissions_count=' || v_effective_count::text
    );

  DELETE FROM church_unit_permission_overrides WHERE id = v_override_id;
  DELETE FROM church_units WHERE id IN (v_child_unit_id, v_parent_unit_id);
  DELETE FROM church_unit_types WHERE id IN (v_child_type_id, v_parent_type_id);
  PERFORM set_config('request.jwt.claim.sub', '', true);
END $$;

COMMIT;

SELECT check_name, ok, detail
FROM _hierarchical_permission_test_result
ORDER BY sort_order;

-- ============================================================================
-- Onboarding completion and EAB demo identity
-- ============================================================================
-- Keeps skipped onboarding steps actionable from organization settings and
-- corrects the demo tenant identity.

UPDATE organizations
SET
  name = 'Église Apostolique du Bénin',
  sigle = 'EAB',
  description = 'Organisation principale de démonstration pour l''Église Apostolique du Bénin.'
WHERE id = '00000000-0000-0000-0000-000000000001';

CREATE OR REPLACE FUNCTION complete_organization_onboarding_steps(
  p_org_id UUID,
  p_completed_steps JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_params JSONB;
  v_onboarding JSONB;
  v_completed JSONB;
  v_skipped JSONB;
  v_step TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifie.'
      USING ERRCODE = '28000';
  END IF;

  IF jsonb_typeof(coalesce(p_completed_steps, '[]'::jsonb)) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Les etapes completees doivent etre une liste JSON.'
      USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = v_user_id
      AND p.organization_id = p_org_id
      AND p.role = 'admin_national'
  ) THEN
    RAISE EXCEPTION 'Seul un administrateur de cette organisation peut finaliser le demarrage.'
      USING ERRCODE = '42501';
  END IF;

  SELECT coalesce(parametres, '{}'::jsonb)
  INTO v_params
  FROM organizations
  WHERE id = p_org_id
  FOR UPDATE;

  IF v_params IS NULL THEN
    RAISE EXCEPTION 'Organisation introuvable.'
      USING ERRCODE = '02000';
  END IF;

  v_onboarding := coalesce(v_params->'onboarding', '{}'::jsonb);
  v_completed := coalesce(v_onboarding->'completed_steps', '[]'::jsonb);
  v_skipped := coalesce(v_onboarding->'skipped_steps', '[]'::jsonb);

  FOR v_step IN
    SELECT trim(value)
    FROM jsonb_array_elements_text(coalesce(p_completed_steps, '[]'::jsonb))
    WHERE trim(value) <> ''
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements_text(v_completed) item WHERE item = v_step
    ) THEN
      v_completed := v_completed || jsonb_build_array(v_step);
    END IF;

    SELECT coalesce(jsonb_agg(item), '[]'::jsonb)
    INTO v_skipped
    FROM jsonb_array_elements_text(v_skipped) item
    WHERE item <> v_step;
  END LOOP;

  v_onboarding := jsonb_set(v_onboarding, '{completed_steps}', v_completed, TRUE);
  v_onboarding := jsonb_set(v_onboarding, '{skipped_steps}', v_skipped, TRUE);
  v_onboarding := jsonb_set(
    v_onboarding,
    '{status}',
    to_jsonb(
      (
        CASE
          WHEN jsonb_array_length(v_skipped) = 0 THEN 'complete'
          ELSE 'in_progress'
        END
      )::TEXT
    ),
    TRUE
  );
  v_onboarding := jsonb_set(v_onboarding, '{updated_at}', to_jsonb(NOW()), TRUE);

  UPDATE organizations
  SET parametres = jsonb_set(v_params, '{onboarding}', v_onboarding, TRUE)
  WHERE id = p_org_id;

  RETURN v_onboarding;
END;
$$;

ALTER FUNCTION complete_organization_onboarding_steps(UUID, JSONB) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION complete_organization_onboarding_steps(UUID, JSONB)
TO authenticated;

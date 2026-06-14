-- ============================================================================
-- Organization onboarding
-- ============================================================================
-- Creates a new autonomous church/tenant from a minimal setup form.
-- Optional steps such as logo, colors, contact details and detailed hierarchy
-- can be skipped and completed later from the application settings.

CREATE OR REPLACE FUNCTION create_organization_onboarding(
  p_name TEXT,
  p_sigle TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_structure_model TEXT DEFAULT 'single',
  p_root_unit_name TEXT DEFAULT NULL,
  p_primary_color TEXT DEFAULT NULL,
  p_secondary_color TEXT DEFAULT NULL,
  p_logo_url TEXT DEFAULT NULL,
  p_contact JSONB DEFAULT '{}'::jsonb,
  p_skip_steps JSONB DEFAULT '[]'::jsonb,
  p_custom_levels JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_existing_org_id UUID;
  v_org_id UUID;
  v_root_type_id UUID;
  v_local_type_id UUID;
  v_root_unit_id UUID;
  v_primary_unit_id UUID;
  v_user_email TEXT;
  v_user_full_name TEXT;
  v_clean_name TEXT := NULLIF(trim(p_name), '');
  v_sigle TEXT := NULLIF(trim(p_sigle), '');
  v_description TEXT := NULLIF(trim(p_description), '');
  v_structure_model TEXT := lower(coalesce(NULLIF(trim(p_structure_model), ''), 'single'));
  v_root_unit_name TEXT := NULLIF(trim(p_root_unit_name), '');
  v_primary_color TEXT := NULLIF(trim(p_primary_color), '');
  v_secondary_color TEXT := NULLIF(trim(p_secondary_color), '');
  v_logo_url TEXT := NULLIF(trim(p_logo_url), '');
  v_contact JSONB := coalesce(p_contact, '{}'::jsonb);
  v_skip_steps JSONB := coalesce(p_skip_steps, '[]'::jsonb);
  v_custom_levels JSONB := coalesce(p_custom_levels, '[]'::jsonb);
  v_onboarding_params JSONB;
  v_code_base TEXT;
  v_code TEXT;
  v_level JSONB;
  v_level_count INTEGER;
  v_level_index INTEGER := 0;
  v_level_code TEXT;
  v_level_label TEXT;
  v_is_last_level BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifie.'
      USING ERRCODE = '28000';
  END IF;

  IF v_clean_name IS NULL THEN
    RAISE EXCEPTION 'Le nom de l''organisation est obligatoire.'
      USING ERRCODE = '22023';
  END IF;

  IF jsonb_typeof(v_contact) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Le contact doit etre un objet JSON.'
      USING ERRCODE = '22023';
  END IF;

  IF jsonb_typeof(v_skip_steps) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Les etapes ignorees doivent etre une liste JSON.'
      USING ERRCODE = '22023';
  END IF;

  IF jsonb_typeof(v_custom_levels) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Les niveaux personnalises doivent etre une liste JSON.'
      USING ERRCODE = '22023';
  END IF;

  SELECT p.organization_id
  INTO v_existing_org_id
  FROM profiles p
  WHERE p.id = v_user_id;

  IF v_existing_org_id IS NOT NULL THEN
    RAISE EXCEPTION 'Cet utilisateur est deja rattache a une organisation.'
      USING ERRCODE = '42501';
  END IF;

  SELECT
    u.email,
    COALESCE(
      NULLIF(u.raw_user_meta_data->>'full_name', ''),
      NULLIF(u.raw_user_meta_data->>'name', ''),
      u.email,
      'Administrateur'
    )
  INTO v_user_email, v_user_full_name
  FROM auth.users u
  WHERE u.id = v_user_id;

  IF v_user_email IS NULL THEN
    RAISE EXCEPTION 'Compte utilisateur introuvable.'
      USING ERRCODE = '28000';
  END IF;

  v_code_base := upper(
    regexp_replace(
      coalesce(v_sigle, v_clean_name),
      '[^a-zA-Z0-9]+',
      '-',
      'g'
    )
  );
  v_code_base := trim(both '-' FROM v_code_base);
  IF v_code_base = '' THEN
    v_code_base := 'ORG';
  END IF;
  v_code := left(v_code_base, 24) || '-' ||
    upper(substr(replace(uuid_generate_v4()::text, '-', ''), 1, 6));

  v_onboarding_params := jsonb_build_object(
    'onboarding',
    jsonb_build_object(
      'status', 'in_progress',
      'structure_model', v_structure_model,
      'completed_steps', jsonb_build_array('identity', 'admin', 'structure_minimum'),
      'skipped_steps', v_skip_steps,
      'created_from', 'create_organization_onboarding',
      'created_at', NOW()
    )
  );

  INSERT INTO organizations (
    name,
    code,
    description,
    logo_url,
    sigle,
    couleur_primaire,
    couleur_secondaire,
    adresse,
    telephone,
    email,
    site_web,
    devise,
    parametres
  )
  VALUES (
    v_clean_name,
    v_code,
    v_description,
    v_logo_url,
    v_sigle,
    v_primary_color,
    v_secondary_color,
    NULLIF(trim(coalesce(v_contact->>'adresse', '')), ''),
    NULLIF(trim(coalesce(v_contact->>'telephone', '')), ''),
    NULLIF(trim(coalesce(v_contact->>'email', '')), ''),
    NULLIF(trim(coalesce(v_contact->>'site_web', '')), ''),
    coalesce(NULLIF(trim(coalesce(v_contact->>'devise', '')), ''), 'FCFA'),
    v_onboarding_params
  )
  RETURNING id INTO v_org_id;

  IF jsonb_array_length(v_custom_levels) > 0 THEN
    v_level_count := jsonb_array_length(v_custom_levels);

    FOR v_level IN SELECT value FROM jsonb_array_elements(v_custom_levels)
    LOOP
      v_level_index := v_level_index + 1;
      v_is_last_level := v_level_index = v_level_count;
      v_level_label := coalesce(
        NULLIF(trim(v_level->>'label'), ''),
        'Niveau ' || v_level_index::text
      );
      v_level_code := lower(
        regexp_replace(
          coalesce(NULLIF(trim(v_level->>'code'), ''), v_level_label),
          '[^a-zA-Z0-9]+',
          '_',
          'g'
        )
      );
      v_level_code := trim(both '_' FROM v_level_code);
      IF v_level_code = '' THEN
        v_level_code := 'level_' || v_level_index::text;
      END IF;

      INSERT INTO church_unit_types (
        organization_id,
        code,
        label,
        level_order,
        is_local,
        is_financial_scope,
        can_have_members
      )
      VALUES (
        v_org_id,
        v_level_code,
        v_level_label,
        v_level_index - 1,
        coalesce((v_level->>'is_local')::BOOLEAN, v_is_last_level),
        coalesce((v_level->>'is_financial_scope')::BOOLEAN, v_is_last_level),
        coalesce((v_level->>'can_have_members')::BOOLEAN, v_is_last_level)
      )
      RETURNING id INTO v_root_type_id;

      IF v_level_index = 1 THEN
        INSERT INTO church_units (
          organization_id,
          type_id,
          parent_id,
          nom,
          code,
          description,
          metadata
        )
        VALUES (
          v_org_id,
          v_root_type_id,
          NULL,
          coalesce(v_root_unit_name, v_clean_name),
          'ROOT',
          v_description,
          jsonb_build_object('created_from', 'onboarding', 'root', TRUE)
        )
        RETURNING id INTO v_root_unit_id;
      END IF;
    END LOOP;

    v_primary_unit_id := v_root_unit_id;
  ELSIF v_structure_model = 'single' THEN
    INSERT INTO church_unit_types (
      organization_id,
      code,
      label,
      level_order,
      is_local,
      is_financial_scope,
      can_have_members
    )
    VALUES (v_org_id, 'local_church', 'Eglise locale', 0, TRUE, TRUE, TRUE)
    RETURNING id INTO v_root_type_id;

    INSERT INTO church_units (
      organization_id,
      type_id,
      parent_id,
      nom,
      code,
      description,
      metadata
    )
    VALUES (
      v_org_id,
      v_root_type_id,
      NULL,
      coalesce(v_root_unit_name, v_clean_name),
      'ROOT',
      v_description,
      jsonb_build_object('created_from', 'onboarding', 'single_church', TRUE)
    )
    RETURNING id INTO v_root_unit_id;

    v_primary_unit_id := v_root_unit_id;
  ELSIF v_structure_model = 'two_level' THEN
    INSERT INTO church_unit_types (
      organization_id,
      code,
      label,
      level_order,
      is_local,
      is_financial_scope,
      can_have_members
    )
    VALUES (v_org_id, 'organization', 'Organisation', 0, FALSE, TRUE, FALSE)
    RETURNING id INTO v_root_type_id;

    INSERT INTO church_unit_types (
      organization_id,
      code,
      label,
      level_order,
      is_local,
      is_financial_scope,
      can_have_members
    )
    VALUES (v_org_id, 'local_church', 'Eglise locale', 1, TRUE, TRUE, TRUE)
    RETURNING id INTO v_local_type_id;

    INSERT INTO church_units (
      organization_id,
      type_id,
      parent_id,
      nom,
      code,
      description,
      metadata
    )
    VALUES (
      v_org_id,
      v_root_type_id,
      NULL,
      v_clean_name,
      'ROOT',
      v_description,
      jsonb_build_object('created_from', 'onboarding', 'root', TRUE)
    )
    RETURNING id INTO v_root_unit_id;

    INSERT INTO church_units (
      organization_id,
      type_id,
      parent_id,
      nom,
      code,
      metadata
    )
    VALUES (
      v_org_id,
      v_local_type_id,
      v_root_unit_id,
      coalesce(v_root_unit_name, 'Assemblee principale'),
      'LOCAL-ROOT',
      jsonb_build_object('created_from', 'onboarding', 'default_local', TRUE)
    )
    RETURNING id INTO v_primary_unit_id;
  ELSIF v_structure_model = 'multi_level' THEN
    INSERT INTO church_unit_types (
      organization_id,
      code,
      label,
      level_order,
      is_local,
      is_financial_scope,
      can_have_members
    )
    VALUES
      (v_org_id, 'organization', 'Organisation', 0, FALSE, TRUE, FALSE),
      (v_org_id, 'region', 'Region', 1, FALSE, FALSE, FALSE),
      (v_org_id, 'district', 'District', 2, FALSE, FALSE, FALSE),
      (v_org_id, 'local_church', 'Eglise locale', 3, TRUE, TRUE, TRUE);

    SELECT id
    INTO v_root_type_id
    FROM church_unit_types
    WHERE organization_id = v_org_id
      AND code = 'organization';

    INSERT INTO church_units (
      organization_id,
      type_id,
      parent_id,
      nom,
      code,
      description,
      metadata
    )
    VALUES (
      v_org_id,
      v_root_type_id,
      NULL,
      coalesce(v_root_unit_name, v_clean_name),
      'ROOT',
      v_description,
      jsonb_build_object('created_from', 'onboarding', 'root', TRUE)
    )
    RETURNING id INTO v_root_unit_id;

    v_primary_unit_id := v_root_unit_id;
  ELSE
    RAISE EXCEPTION 'Mode de structure invalide: %', p_structure_model
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO profiles (
    id,
    organization_id,
    full_name,
    role,
    primary_church_unit_id
  )
  VALUES (
    v_user_id,
    v_org_id,
    v_user_full_name,
    'admin_national',
    v_primary_unit_id
  )
  ON CONFLICT (id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    full_name = COALESCE(NULLIF(profiles.full_name, ''), EXCLUDED.full_name),
    role = 'admin_national',
    primary_church_unit_id = EXCLUDED.primary_church_unit_id,
    updated_at = NOW();

  RETURN jsonb_build_object(
    'organization_id', v_org_id,
    'organization_code', v_code,
    'root_unit_id', v_root_unit_id,
    'primary_unit_id', v_primary_unit_id,
    'admin_user_id', v_user_id,
    'structure_model', v_structure_model,
    'skipped_steps', v_skip_steps
  );
END;
$$;

ALTER FUNCTION create_organization_onboarding(
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  JSONB,
  JSONB,
  JSONB
) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION create_organization_onboarding(
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  JSONB,
  JSONB,
  JSONB
) TO authenticated;

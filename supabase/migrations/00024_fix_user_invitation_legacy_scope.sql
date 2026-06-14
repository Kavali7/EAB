-- ============================================================================
-- Fix invitations de sous-comptes - portee legacy explicite
-- ============================================================================

CREATE OR REPLACE FUNCTION invite_user_to_org(
  p_org_id UUID,
  p_email TEXT,
  p_role TEXT,
  p_primary_church_unit_id UUID DEFAULT NULL,
  p_can_manage_children BOOLEAN DEFAULT FALSE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  normalized_email TEXT;
  invited_role role_utilisateur;
  invitation_id UUID;
  existing_user_id UUID;
  existing_user_email TEXT;
  existing_user_meta JSONB;
  existing_profile_org UUID;
  v_legacy_region_id UUID;
  v_legacy_district_id UUID;
  v_legacy_assemblee_id UUID;
BEGIN
  normalized_email := lower(trim(p_email));
  invited_role := normalize_user_role(p_role);

  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifie.'
      USING ERRCODE = '28000';
  END IF;

  IF get_user_role() <> 'admin_national'
     OR get_user_organization_id() IS DISTINCT FROM p_org_id THEN
    RAISE EXCEPTION 'Seul un administrateur de cette organisation peut inviter un utilisateur.'
      USING ERRCODE = '42501';
  END IF;

  IF position('@' in normalized_email) <= 1 THEN
    RAISE EXCEPTION 'Email invalide: %', p_email
      USING ERRCODE = '22023';
  END IF;

  IF p_primary_church_unit_id IS NOT NULL THEN
    SELECT cu.legacy_region_id, cu.legacy_district_id, cu.legacy_assemblee_id
    INTO v_legacy_region_id, v_legacy_district_id, v_legacy_assemblee_id
    FROM church_units cu
    WHERE cu.id = p_primary_church_unit_id
      AND cu.organization_id = p_org_id
      AND cu.active = TRUE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Perimetre d''eglise invalide pour cette organisation.'
        USING ERRCODE = '22023';
    END IF;
  END IF;

  SELECT id
  INTO invitation_id
  FROM organization_user_invitations
  WHERE organization_id = p_org_id
    AND email = normalized_email
    AND accepted_at IS NULL
    AND revoked_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1;

  IF invitation_id IS NULL THEN
    INSERT INTO organization_user_invitations (
      organization_id,
      email,
      role,
      primary_church_unit_id,
      can_manage_children,
      invited_by
    )
    VALUES (
      p_org_id,
      normalized_email,
      invited_role,
      p_primary_church_unit_id,
      p_can_manage_children,
      auth.uid()
    )
    RETURNING id INTO invitation_id;
  ELSE
    UPDATE organization_user_invitations
    SET role = invited_role,
        primary_church_unit_id = p_primary_church_unit_id,
        can_manage_children = p_can_manage_children,
        invited_by = auth.uid(),
        expires_at = NOW() + INTERVAL '14 days',
        updated_at = NOW()
    WHERE id = invitation_id;
  END IF;

  SELECT id, email, raw_user_meta_data
  INTO existing_user_id, existing_user_email, existing_user_meta
  FROM auth.users
  WHERE lower(email) = normalized_email
  LIMIT 1;

  IF existing_user_id IS NOT NULL THEN
    SELECT organization_id
    INTO existing_profile_org
    FROM profiles
    WHERE id = existing_user_id;

    IF existing_profile_org IS NOT NULL
       AND existing_profile_org IS DISTINCT FROM p_org_id THEN
      RAISE EXCEPTION 'Cet utilisateur appartient deja a une autre organisation.'
        USING ERRCODE = '42501';
    END IF;

    INSERT INTO profiles (
      id,
      organization_id,
      full_name,
      role,
      id_region,
      id_district,
      id_assemblee_locale,
      primary_church_unit_id
    )
    VALUES (
      existing_user_id,
      p_org_id,
      COALESCE(
        NULLIF(existing_user_meta->>'full_name', ''),
        NULLIF(existing_user_meta->>'name', ''),
        existing_user_email,
        normalized_email
      ),
      invited_role,
      v_legacy_region_id,
      v_legacy_district_id,
      v_legacy_assemblee_id,
      p_primary_church_unit_id
    )
    ON CONFLICT (id) DO UPDATE SET
      organization_id = EXCLUDED.organization_id,
      role = EXCLUDED.role,
      id_region = EXCLUDED.id_region,
      id_district = EXCLUDED.id_district,
      id_assemblee_locale = EXCLUDED.id_assemblee_locale,
      primary_church_unit_id = EXCLUDED.primary_church_unit_id,
      updated_at = NOW();

    IF p_primary_church_unit_id IS NOT NULL THEN
      INSERT INTO church_unit_user_scopes (
        organization_id,
        user_id,
        unit_id,
        role,
        can_manage_children
      )
      VALUES (
        p_org_id,
        existing_user_id,
        p_primary_church_unit_id,
        invited_role,
        p_can_manage_children
      )
      ON CONFLICT (user_id, unit_id, role) DO UPDATE SET
        can_manage_children = EXCLUDED.can_manage_children;
    END IF;

    UPDATE organization_user_invitations
    SET accepted_by = existing_user_id,
        accepted_at = NOW(),
        updated_at = NOW()
    WHERE id = invitation_id;
  END IF;

  RETURN invitation_id;
END;
$$;

ALTER FUNCTION invite_user_to_org(UUID, TEXT, TEXT, UUID, BOOLEAN) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION invite_user_to_org(UUID, TEXT, TEXT, UUID, BOOLEAN)
  TO authenticated;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  normalized_email TEXT;
  invitation RECORD;
  v_legacy_region_id UUID;
  v_legacy_district_id UUID;
  v_legacy_assemblee_id UUID;
BEGIN
  normalized_email := lower(trim(COALESCE(NEW.email, '')));

  SELECT *
  INTO invitation
  FROM organization_user_invitations
  WHERE email = normalized_email
    AND accepted_at IS NULL
    AND revoked_at IS NULL
    AND expires_at > NOW()
  ORDER BY created_at DESC
  LIMIT 1;

  IF FOUND THEN
    IF invitation.primary_church_unit_id IS NOT NULL THEN
      SELECT cu.legacy_region_id, cu.legacy_district_id, cu.legacy_assemblee_id
      INTO v_legacy_region_id, v_legacy_district_id, v_legacy_assemblee_id
      FROM church_units cu
      WHERE cu.id = invitation.primary_church_unit_id
        AND cu.organization_id = invitation.organization_id;
    END IF;

    INSERT INTO profiles (
      id,
      organization_id,
      full_name,
      role,
      id_region,
      id_district,
      id_assemblee_locale,
      primary_church_unit_id
    )
    VALUES (
      NEW.id,
      invitation.organization_id,
      COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
        NULLIF(NEW.raw_user_meta_data->>'name', ''),
        NEW.email,
        'Utilisateur'
      ),
      invitation.role,
      v_legacy_region_id,
      v_legacy_district_id,
      v_legacy_assemblee_id,
      invitation.primary_church_unit_id
    )
    ON CONFLICT (id) DO UPDATE SET
      organization_id = EXCLUDED.organization_id,
      full_name = EXCLUDED.full_name,
      role = EXCLUDED.role,
      id_region = EXCLUDED.id_region,
      id_district = EXCLUDED.id_district,
      id_assemblee_locale = EXCLUDED.id_assemblee_locale,
      primary_church_unit_id = EXCLUDED.primary_church_unit_id,
      updated_at = NOW();

    IF invitation.primary_church_unit_id IS NOT NULL THEN
      INSERT INTO church_unit_user_scopes (
        organization_id,
        user_id,
        unit_id,
        role,
        can_manage_children
      )
      VALUES (
        invitation.organization_id,
        NEW.id,
        invitation.primary_church_unit_id,
        invitation.role,
        invitation.can_manage_children
      )
      ON CONFLICT (user_id, unit_id, role) DO UPDATE SET
        can_manage_children = EXCLUDED.can_manage_children;
    END IF;

    UPDATE organization_user_invitations
    SET accepted_by = NEW.id,
        accepted_at = NOW(),
        updated_at = NOW()
    WHERE id = invitation.id;
  ELSE
    INSERT INTO profiles (id, full_name, role)
    VALUES (
      NEW.id,
      COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
        NULLIF(NEW.raw_user_meta_data->>'name', ''),
        NEW.email,
        'Utilisateur'
      ),
      'tresorier_assemblee'::role_utilisateur
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION handle_new_user() OWNER TO postgres;

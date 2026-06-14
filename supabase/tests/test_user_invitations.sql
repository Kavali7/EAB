-- ============================================================================
-- Test E2E DB - Invitations de sous-comptes
-- ============================================================================
-- Objectif :
--   1. Simuler un admin national connecte.
--   2. Appeler la vraie RPC invite_user_to_org().
--   3. Simuler une inscription Supabase Auth avec le meme email.
--   4. Verifier que handle_new_user() rattache le profil a l'organisation,
--      au role et au perimetre church_units.
--   5. Nettoyer les donnees de test avant COMMIT.
--
-- Ce script ne laisse pas de donnees de test persistantes.
-- ============================================================================

DROP TABLE IF EXISTS _user_invitation_test_result;
CREATE TEMP TABLE _user_invitation_test_result (
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
  v_unit_id UUID;
  v_user_id UUID := uuid_generate_v4();
  v_email TEXT := 'codex-subaccount-test-' ||
    replace(uuid_generate_v4()::text, '-', '') || '@example.test';
  v_invitation_id UUID;
  v_profile profiles%ROWTYPE;
  v_scope_count INTEGER;
  v_invitation organization_user_invitations%ROWTYPE;
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

  SELECT u.id
  INTO v_unit_id
  FROM church_units u
  JOIN church_unit_types t ON t.id = u.type_id
  WHERE u.organization_id = v_org_id
    AND u.active = TRUE
  ORDER BY t.can_have_members DESC, t.is_local DESC, t.level_order DESC, u.nom
  LIMIT 1;

  IF v_unit_id IS NULL THEN
    RAISE EXCEPTION 'Aucune unite church_units active trouvee pour l''organisation %. ', v_org_id;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);

  SELECT invite_user_to_org(
    v_org_id,
    v_email,
    'tresorierAssemblee',
    v_unit_id,
    FALSE
  )
  INTO v_invitation_id;

  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    v_email,
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', 'Compte test sous-compte'),
    NOW(),
    NOW()
  );

  SELECT *
  INTO v_profile
  FROM profiles
  WHERE id = v_user_id;

  SELECT COUNT(*)
  INTO v_scope_count
  FROM church_unit_user_scopes
  WHERE user_id = v_user_id
    AND organization_id = v_org_id
    AND unit_id = v_unit_id
    AND role = 'tresorier_assemblee';

  SELECT *
  INTO v_invitation
  FROM organization_user_invitations
  WHERE id = v_invitation_id;

  INSERT INTO _user_invitation_test_result VALUES
    (
      1,
      'invitation_creee',
      v_invitation_id IS NOT NULL,
      'invitation_id=' || COALESCE(v_invitation_id::text, 'NULL')
    ),
    (
      2,
      'profil_rattache_organisation',
      v_profile.organization_id = v_org_id,
      'profile_org=' || COALESCE(v_profile.organization_id::text, 'NULL') ||
        ', expected=' || v_org_id::text
    ),
    (
      3,
      'profil_role_correct',
      v_profile.role = 'tresorier_assemblee',
      'role=' || COALESCE(v_profile.role::text, 'NULL')
    ),
    (
      4,
      'profil_perimetre_correct',
      v_profile.primary_church_unit_id = v_unit_id,
      'profile_unit=' || COALESCE(v_profile.primary_church_unit_id::text, 'NULL') ||
        ', expected=' || v_unit_id::text
    ),
    (
      5,
      'scope_utilisateur_cree',
      v_scope_count = 1,
      'scope_count=' || v_scope_count::text
    ),
    (
      6,
      'invitation_marquee_acceptee',
      v_invitation.accepted_by = v_user_id AND v_invitation.accepted_at IS NOT NULL,
      'accepted_by=' || COALESCE(v_invitation.accepted_by::text, 'NULL') ||
        ', accepted_at=' || COALESCE(v_invitation.accepted_at::text, 'NULL')
    );

  DELETE FROM church_unit_user_scopes WHERE user_id = v_user_id;
  DELETE FROM organization_user_invitations WHERE id = v_invitation_id;
  DELETE FROM profiles WHERE id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
  PERFORM set_config('request.jwt.claim.sub', '', true);
END $$;

COMMIT;

SELECT check_name, ok, detail
FROM _user_invitation_test_result
ORDER BY sort_order;

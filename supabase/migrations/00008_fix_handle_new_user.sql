-- ============================================================================
-- EAB Backend - 00008 Fix handle_new_user trigger
-- ============================================================================
-- Correctif : le trigger handle_new_user() échouait à l'inscription
-- car le type role_utilisateur n'était pas correctement résolu.
-- Ce script recrée la fonction et le trigger de manière idempotente.
-- ============================================================================
-- Exécuté le 2026-02-23 via Supabase SQL Editor.
-- ============================================================================

-- 1) S'assurer que le type role_utilisateur existe
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_utilisateur') THEN
    CREATE TYPE role_utilisateur AS ENUM (
      'admin_national', 'responsable_region', 'surintendant_district', 'tresorier_assemblee'
    );
  END IF;
END $$;

-- 2) Recréer handle_new_user() correctement
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'tresorier_assemblee'::role_utilisateur
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3) Recréer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

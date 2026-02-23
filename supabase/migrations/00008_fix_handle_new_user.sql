-- ============================================================================
-- EAB Backend - 00008 Fix handle_new_user trigger
-- ============================================================================
-- Correctif : le trigger handle_new_user() échouait à l'inscription
-- car la politique RLS sur profiles bloquait l'INSERT.
--
-- Solution : 
--   1. Ajouter une politique INSERT spécifique pour le trigger (service_role)
--   2. Recréer la fonction avec SECURITY DEFINER + SET search_path
--   3. Changer le propriétaire de la fonction au rôle postgres (bypass RLS)
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

-- 2) Ajouter une politique INSERT pour les profils créés par le trigger
-- (le trigger s'exécute en SECURITY DEFINER avec le rôle postgres)
DROP POLICY IF EXISTS "Service role can insert profiles" ON profiles;
CREATE POLICY "Service role can insert profiles"
    ON profiles FOR INSERT
    WITH CHECK (true);

-- 3) Recréer handle_new_user() correctement avec search_path sécurisé
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'tresorier_assemblee'::role_utilisateur
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4) S'assurer que la fonction appartient au rôle postgres (bypass RLS)
ALTER FUNCTION handle_new_user() OWNER TO postgres;

-- 5) Recréer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

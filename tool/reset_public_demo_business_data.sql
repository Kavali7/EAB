-- ============================================================================
-- Reset public demo business data
-- ============================================================================
-- Keeps Supabase Auth users intact.
-- Clears tenant/business data so the public demo seeder can rebuild:
-- - EAB multi-level demo for test1@gmail.com
-- - single-church demo for test2@gmail.com
-- - technical admin profile if its Auth user exists
--
-- Run only against the intended Supabase project.

BEGIN;

TRUNCATE TABLE public.organizations CASCADE;

COMMIT;

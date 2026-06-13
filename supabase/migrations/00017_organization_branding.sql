-- ============================================================================
-- Organization branding and contact fields
-- ============================================================================
-- Completes the tenant identity model used by the web app.
-- Safe to apply on existing installations.

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS sigle TEXT,
  ADD COLUMN IF NOT EXISTS couleur_primaire TEXT,
  ADD COLUMN IF NOT EXISTS couleur_secondaire TEXT,
  ADD COLUMN IF NOT EXISTS adresse TEXT,
  ADD COLUMN IF NOT EXISTS telephone TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS site_web TEXT,
  ADD COLUMN IF NOT EXISTS devise TEXT NOT NULL DEFAULT 'FCFA',
  ADD COLUMN IF NOT EXISTS parametres JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE organizations
SET sigle = COALESCE(NULLIF(sigle, ''), NULLIF(code, ''))
WHERE sigle IS NULL OR sigle = '';

COMMENT ON COLUMN organizations.sigle IS
  'Display acronym or short brand name for the church/tenant.';
COMMENT ON COLUMN organizations.logo_url IS
  'Public logo URL for the church/tenant.';

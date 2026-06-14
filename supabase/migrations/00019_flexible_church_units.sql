-- ============================================================================
-- Flexible church hierarchy
-- ============================================================================
-- Adds a generic hierarchy model that supports:
-- - a single local church with no intermediate level,
-- - any number of custom levels,
-- - the current EAB demo structure as migrated data.
--
-- The legacy tables are preserved. This migration only mirrors them into the
-- new model so the app can move progressively without losing demo data.

CREATE TABLE IF NOT EXISTS church_unit_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  label TEXT NOT NULL,
  level_order INTEGER NOT NULL DEFAULT 0,
  is_local BOOLEAN NOT NULL DEFAULT FALSE,
  is_financial_scope BOOLEAN NOT NULL DEFAULT FALSE,
  can_have_members BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS church_units (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  type_id UUID NOT NULL REFERENCES church_unit_types(id) ON DELETE RESTRICT,
  parent_id UUID REFERENCES church_units(id) ON DELETE CASCADE,
  nom TEXT NOT NULL,
  code TEXT,
  description TEXT,
  ville TEXT,
  quartier TEXT,
  adresse TEXT,
  telephone TEXT,
  email TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  legacy_region_id UUID REFERENCES regions_eglise(id) ON DELETE SET NULL,
  legacy_district_id UUID REFERENCES districts_eglise(id) ON DELETE SET NULL,
  legacy_assemblee_id UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT church_units_parent_not_self CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_church_units_code_per_type
  ON church_units(organization_id, type_id, code)
  WHERE code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_church_units_organization
  ON church_units(organization_id);

CREATE INDEX IF NOT EXISTS idx_church_units_parent
  ON church_units(parent_id);

CREATE INDEX IF NOT EXISTS idx_church_units_legacy_region
  ON church_units(legacy_region_id)
  WHERE legacy_region_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_church_units_legacy_district
  ON church_units(legacy_district_id)
  WHERE legacy_district_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_church_units_legacy_assemblee
  ON church_units(legacy_assemblee_id)
  WHERE legacy_assemblee_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS church_unit_user_scopes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  role role_utilisateur NOT NULL,
  can_manage_children BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, unit_id, role)
);

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS primary_church_unit_id UUID
  REFERENCES church_units(id) ON DELETE SET NULL;

COMMENT ON TABLE church_unit_types IS
  'Configurable hierarchy levels for each tenant: organization, region, district, local church, etc.';
COMMENT ON TABLE church_units IS
  'Generic church hierarchy nodes. A tenant can be single-level or multi-level.';
COMMENT ON TABLE church_unit_user_scopes IS
  'User permissions attached to a specific church unit scope.';

-- ---------------------------------------------------------------------------
-- Default level definitions per existing organization.
-- ---------------------------------------------------------------------------

INSERT INTO church_unit_types (
  organization_id,
  code,
  label,
  level_order,
  is_local,
  is_financial_scope,
  can_have_members
)
SELECT id, 'organization', 'Organisation', 0, FALSE, TRUE, FALSE
FROM organizations
ON CONFLICT (organization_id, code) DO UPDATE SET
  label = EXCLUDED.label,
  level_order = EXCLUDED.level_order,
  is_financial_scope = EXCLUDED.is_financial_scope,
  updated_at = NOW();

INSERT INTO church_unit_types (
  organization_id,
  code,
  label,
  level_order,
  is_local,
  is_financial_scope,
  can_have_members
)
SELECT id, 'region', 'Region', 1, FALSE, FALSE, FALSE
FROM organizations
ON CONFLICT (organization_id, code) DO UPDATE SET
  label = EXCLUDED.label,
  level_order = EXCLUDED.level_order,
  updated_at = NOW();

INSERT INTO church_unit_types (
  organization_id,
  code,
  label,
  level_order,
  is_local,
  is_financial_scope,
  can_have_members
)
SELECT id, 'district', 'District', 2, FALSE, FALSE, FALSE
FROM organizations
ON CONFLICT (organization_id, code) DO UPDATE SET
  label = EXCLUDED.label,
  level_order = EXCLUDED.level_order,
  updated_at = NOW();

INSERT INTO church_unit_types (
  organization_id,
  code,
  label,
  level_order,
  is_local,
  is_financial_scope,
  can_have_members
)
SELECT id, 'local_church', 'Assemblee locale', 3, TRUE, TRUE, TRUE
FROM organizations
ON CONFLICT (organization_id, code) DO UPDATE SET
  label = EXCLUDED.label,
  level_order = EXCLUDED.level_order,
  is_local = EXCLUDED.is_local,
  is_financial_scope = EXCLUDED.is_financial_scope,
  can_have_members = EXCLUDED.can_have_members,
  updated_at = NOW();

-- ---------------------------------------------------------------------------
-- Backfill current demo data into the flexible hierarchy.
-- ---------------------------------------------------------------------------

INSERT INTO church_units (
  organization_id,
  type_id,
  parent_id,
  nom,
  code,
  description,
  metadata
)
SELECT
  o.id,
  t.id,
  NULL,
  o.name,
  'ORG_ROOT',
  o.description,
  jsonb_build_object('source_table', 'organizations', 'demo_preserved', TRUE)
FROM organizations o
JOIN church_unit_types t
  ON t.organization_id = o.id
 AND t.code = 'organization'
WHERE NOT EXISTS (
  SELECT 1
  FROM church_units existing
  WHERE existing.organization_id = o.id
    AND existing.parent_id IS NULL
);

INSERT INTO church_units (
  id,
  organization_id,
  type_id,
  parent_id,
  nom,
  code,
  description,
  legacy_region_id,
  metadata
)
SELECT
  r.id,
  r.organization_id,
  t.id,
  root.id,
  r.nom,
  r.code,
  r.description,
  r.id,
  jsonb_build_object('source_table', 'regions_eglise', 'demo_preserved', TRUE)
FROM regions_eglise r
JOIN church_unit_types t
  ON t.organization_id = r.organization_id
 AND t.code = 'region'
JOIN church_units root
  ON root.organization_id = r.organization_id
 AND root.parent_id IS NULL
WHERE NOT EXISTS (
  SELECT 1 FROM church_units existing WHERE existing.legacy_region_id = r.id
);

INSERT INTO church_units (
  id,
  organization_id,
  type_id,
  parent_id,
  nom,
  code,
  description,
  legacy_district_id,
  metadata
)
SELECT
  d.id,
  d.organization_id,
  t.id,
  parent.id,
  d.nom,
  d.code,
  d.description,
  d.id,
  jsonb_build_object('source_table', 'districts_eglise', 'demo_preserved', TRUE)
FROM districts_eglise d
JOIN church_unit_types t
  ON t.organization_id = d.organization_id
 AND t.code = 'district'
JOIN church_units parent
  ON parent.legacy_region_id = d.id_region
WHERE NOT EXISTS (
  SELECT 1 FROM church_units existing WHERE existing.legacy_district_id = d.id
);

INSERT INTO church_units (
  id,
  organization_id,
  type_id,
  parent_id,
  nom,
  code,
  ville,
  quartier,
  adresse,
  telephone,
  email,
  legacy_assemblee_id,
  metadata
)
SELECT
  a.id,
  a.organization_id,
  t.id,
  parent.id,
  a.nom,
  a.code,
  a.ville,
  a.quartier,
  a.adresse_postale,
  a.telephone,
  a.email,
  a.id,
  jsonb_build_object('source_table', 'assemblees_locales', 'demo_preserved', TRUE)
FROM assemblees_locales a
JOIN church_unit_types t
  ON t.organization_id = a.organization_id
 AND t.code = 'local_church'
JOIN church_units parent
  ON parent.legacy_district_id = a.id_district
WHERE NOT EXISTS (
  SELECT 1 FROM church_units existing WHERE existing.legacy_assemblee_id = a.id
);

UPDATE profiles p
SET primary_church_unit_id = COALESCE(
  (SELECT u.id FROM church_units u WHERE u.id = p.id_assemblee_locale),
  (SELECT u.id FROM church_units u WHERE u.id = p.id_district),
  (SELECT u.id FROM church_units u WHERE u.id = p.id_region),
  (
    SELECT root.id
    FROM church_units root
    WHERE root.organization_id = p.organization_id
      AND root.parent_id IS NULL
    LIMIT 1
  )
)
WHERE p.organization_id IS NOT NULL
  AND p.primary_church_unit_id IS NULL;

INSERT INTO church_unit_user_scopes (
  organization_id,
  user_id,
  unit_id,
  role,
  can_manage_children
)
SELECT
  p.organization_id,
  p.id,
  p.primary_church_unit_id,
  p.role,
  p.role IN ('admin_national', 'responsable_region', 'surintendant_district')
FROM profiles p
WHERE p.organization_id IS NOT NULL
  AND p.primary_church_unit_id IS NOT NULL
ON CONFLICT (user_id, unit_id, role) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Recursive helper used by future filters and permission checks.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_church_unit_descendants(p_unit_id UUID)
RETURNS TABLE(unit_id UUID)
LANGUAGE SQL
STABLE
AS $$
  WITH RECURSIVE tree AS (
    SELECT id
    FROM church_units
    WHERE id = p_unit_id

    UNION ALL

    SELECT child.id
    FROM church_units child
    JOIN tree parent ON child.parent_id = parent.id
  )
  SELECT id FROM tree;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE church_unit_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE church_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE church_unit_user_scopes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view church unit types"
  ON church_unit_types;
DROP POLICY IF EXISTS "Admins can manage church unit types"
  ON church_unit_types;
DROP POLICY IF EXISTS "Users can view church units"
  ON church_units;
DROP POLICY IF EXISTS "Admins can manage church units"
  ON church_units;
DROP POLICY IF EXISTS "Users can view church unit scopes"
  ON church_unit_user_scopes;
DROP POLICY IF EXISTS "Admins can manage church unit scopes"
  ON church_unit_user_scopes;

CREATE POLICY "Users can view church unit types"
  ON church_unit_types FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Admins can manage church unit types"
  ON church_unit_types FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

CREATE POLICY "Users can view church units"
  ON church_units FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Admins can manage church units"
  ON church_units FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

CREATE POLICY "Users can view church unit scopes"
  ON church_unit_user_scopes FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Admins can manage church unit scopes"
  ON church_unit_user_scopes FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

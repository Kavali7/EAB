-- =============================================================================
-- Migration 00011 : Tables Dossier Fiscal SYSCEBNL
-- =============================================================================
-- Objectif : Créer les tables pour le générateur de dossier fiscal multi-pages
-- Tables : fiscal_templates, fiscal_template_pages, fiscal_template_fields,
--          fiscal_account_mapping, fiscal_dossiers, fiscal_dossier_values,
--          imported_trial_balances, imported_trial_balance_lines
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Enum statut dossier fiscal
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE public.fiscal_dossier_status AS ENUM (
    'draft',
    'in_progress',
    'ready',
    'locked',
    'submitted'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Tables Templates (globales, read-only côté utilisateurs)
-- ─────────────────────────────────────────────────────────────────────────────

-- 2.1 Templates fiscaux versionnés
CREATE TABLE IF NOT EXISTS public.fiscal_templates (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code          TEXT NOT NULL,
  label         TEXT NOT NULL,
  version       INTEGER NOT NULL DEFAULT 1,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(code)
);

COMMENT ON TABLE public.fiscal_templates IS 'Templates fiscaux versionnés (ex: SYSCEBNL_2026). Globaux, read-only pour les utilisateurs.';

-- 2.2 Pages d'un template (ordonnées)
CREATE TABLE IF NOT EXISTS public.fiscal_template_pages (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id   UUID NOT NULL REFERENCES public.fiscal_templates(id) ON DELETE CASCADE,
  code          TEXT NOT NULL,
  title         TEXT NOT NULL,
  page_order    INTEGER NOT NULL,
  layout        JSONB NOT NULL DEFAULT '{}'::JSONB,
  rules         JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(template_id, code),
  UNIQUE(template_id, page_order)
);

COMMENT ON TABLE public.fiscal_template_pages IS 'Pages ordonnées d''un template fiscal (COVER, BILAN_ACTIF, etc.)';

-- 2.3 Champs d'une page template
CREATE TABLE IF NOT EXISTS public.fiscal_template_fields (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_id       UUID NOT NULL REFERENCES public.fiscal_template_pages(id) ON DELETE CASCADE,
  field_key     TEXT NOT NULL,
  label         TEXT NOT NULL,
  field_type    TEXT NOT NULL CHECK (field_type IN ('money','text','date','select','bool','percent','integer')),
  field_order   INTEGER NOT NULL DEFAULT 0,
  section       TEXT NULL,
  required      BOOLEAN NOT NULL DEFAULT FALSE,
  default_value JSONB NULL,
  compute       JSONB NULL,
  ui            JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(page_id, field_key)
);

COMMENT ON TABLE public.fiscal_template_fields IS 'Champs typés de chaque page template avec ordre, section, et règles de calcul.';

-- 2.4 Mapping comptes comptables → champs fiscaux (pré-remplissage)
CREATE TABLE IF NOT EXISTS public.fiscal_account_mapping (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id   UUID NOT NULL REFERENCES public.fiscal_templates(id) ON DELETE CASCADE,
  field_key     TEXT NOT NULL,
  rule_type     TEXT NOT NULL CHECK (rule_type IN ('sum_prefixes','sum_accounts','balance_class','custom_sql')),
  params        JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(template_id, field_key)
);

COMMENT ON TABLE public.fiscal_account_mapping IS 'Règles de mapping entre comptes comptables et champs fiscaux pour le pré-remplissage automatique.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Tables Dossiers (par organisation, multi-tenant)
-- ─────────────────────────────────────────────────────────────────────────────

-- 3.1 Dossiers fiscaux
CREATE TABLE IF NOT EXISTS public.fiscal_dossiers (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  template_id     UUID NOT NULL REFERENCES public.fiscal_templates(id),
  exercice_id     UUID NULL REFERENCES public.exercices_comptables(id),
  import_id       UUID NULL,
  status          public.fiscal_dossier_status NOT NULL DEFAULT 'draft',
  label           TEXT NULL,
  notes           TEXT NULL,
  created_by      UUID NULL REFERENCES auth.users(id),
  locked_by       UUID NULL REFERENCES auth.users(id),
  locked_at       TIMESTAMPTZ NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.fiscal_dossiers IS 'Dossiers fiscaux par organisation. Cycle : draft → in_progress → ready → locked → submitted.';

-- 3.2 Valeurs saisies/calculées des champs du dossier
CREATE TABLE IF NOT EXISTS public.fiscal_dossier_values (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dossier_id      UUID NOT NULL REFERENCES public.fiscal_dossiers(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  field_key       TEXT NOT NULL,
  value           JSONB NULL,
  source          TEXT NOT NULL CHECK (source IN ('manual','computed','imported')) DEFAULT 'manual',
  updated_by      UUID NULL REFERENCES auth.users(id),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(dossier_id, field_key)
);

COMMENT ON TABLE public.fiscal_dossier_values IS 'Valeurs des champs du dossier fiscal (manuelles, calculées ou importées).';

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Tables Import Balance CSV
-- ─────────────────────────────────────────────────────────────────────────────

-- 4.1 En-têtes de balances importées
CREATE TABLE IF NOT EXISTS public.imported_trial_balances (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  exercice_label  TEXT NULL,
  filename        TEXT NULL,
  total_debit     DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_credit    DECIMAL(15,2) NOT NULL DEFAULT 0,
  line_count      INTEGER NOT NULL DEFAULT 0,
  created_by      UUID NULL REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.imported_trial_balances IS 'En-têtes de balances CSV importées pour le mode "sans historique".';

-- 4.2 Lignes de balances importées
CREATE TABLE IF NOT EXISTS public.imported_trial_balance_lines (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  import_id       UUID NOT NULL REFERENCES public.imported_trial_balances(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  account_number  TEXT NOT NULL,
  account_label   TEXT NULL,
  debit           DECIMAL(15,2) NOT NULL DEFAULT 0,
  credit          DECIMAL(15,2) NOT NULL DEFAULT 0,
  solde           DECIMAL(15,2) NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.imported_trial_balance_lines IS 'Lignes individuelles d''une balance importée (n° compte, libellé, débit, crédit).';

-- FK import_id dans fiscal_dossiers → imported_trial_balances
ALTER TABLE public.fiscal_dossiers
  ADD CONSTRAINT fk_fiscal_dossiers_import
  FOREIGN KEY (import_id) REFERENCES public.imported_trial_balances(id) ON DELETE SET NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Index de performance
-- ─────────────────────────────────────────────────────────────────────────────

-- Templates
CREATE INDEX IF NOT EXISTS idx_fiscal_tpl_pages_template ON public.fiscal_template_pages(template_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_tpl_fields_page ON public.fiscal_template_fields(page_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_tpl_fields_order ON public.fiscal_template_fields(page_id, field_order);
CREATE INDEX IF NOT EXISTS idx_fiscal_mapping_template ON public.fiscal_account_mapping(template_id);

-- Dossiers
CREATE INDEX IF NOT EXISTS idx_fiscal_dossiers_org ON public.fiscal_dossiers(organization_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_dossiers_template ON public.fiscal_dossiers(template_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_dossiers_exercice ON public.fiscal_dossiers(exercice_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_dossiers_status ON public.fiscal_dossiers(status);
CREATE INDEX IF NOT EXISTS idx_fiscal_dossiers_import ON public.fiscal_dossiers(import_id);

-- Values
CREATE INDEX IF NOT EXISTS idx_fiscal_values_dossier ON public.fiscal_dossier_values(dossier_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_values_org ON public.fiscal_dossier_values(organization_id);
CREATE INDEX IF NOT EXISTS idx_fiscal_values_field ON public.fiscal_dossier_values(dossier_id, field_key);

-- Import balance
CREATE INDEX IF NOT EXISTS idx_import_balances_org ON public.imported_trial_balances(organization_id);
CREATE INDEX IF NOT EXISTS idx_import_balance_lines_import ON public.imported_trial_balance_lines(import_id);
CREATE INDEX IF NOT EXISTS idx_import_balance_lines_org ON public.imported_trial_balance_lines(organization_id);
CREATE INDEX IF NOT EXISTS idx_import_balance_lines_account ON public.imported_trial_balance_lines(account_number);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Triggers updated_at
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TRIGGER trg_fiscal_dossiers_updated_at
  BEFORE UPDATE ON public.fiscal_dossiers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_fiscal_dossier_values_updated_at
  BEFORE UPDATE ON public.fiscal_dossier_values
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

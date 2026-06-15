-- ============================================================================
-- Church unit capabilities and financial accounts
-- ============================================================================
-- Adds configurable capabilities to hierarchy levels without hard-coding EAB
-- labels, then introduces financial accounts attached to any church unit.
-- A financial account can represent cash, bank, or mobile money.

ALTER TABLE church_unit_types
  ADD COLUMN IF NOT EXISTS can_have_cash_accounts BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_have_bank_accounts BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_have_mobile_money_accounts BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_create_programs BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_launch_contributions BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_validate_finances BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_consolidate_finances BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_notify_descendants BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_view_descendants BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE church_unit_types
  ALTER COLUMN can_create_programs SET DEFAULT TRUE,
  ALTER COLUMN can_launch_contributions SET DEFAULT TRUE,
  ALTER COLUMN can_view_descendants SET DEFAULT TRUE;

UPDATE church_unit_types
SET
  can_have_cash_accounts = CASE
    WHEN is_financial_scope THEN TRUE ELSE can_have_cash_accounts
  END,
  can_have_bank_accounts = CASE
    WHEN is_financial_scope THEN TRUE ELSE can_have_bank_accounts
  END,
  can_have_mobile_money_accounts = CASE
    WHEN is_financial_scope THEN TRUE ELSE can_have_mobile_money_accounts
  END,
  can_create_programs = TRUE,
  can_launch_contributions = TRUE,
  can_validate_finances = CASE
    WHEN is_local THEN can_validate_finances ELSE TRUE
  END,
  can_consolidate_finances = CASE
    WHEN is_local THEN can_consolidate_finances ELSE TRUE
  END,
  can_notify_descendants = CASE
    WHEN is_local THEN can_notify_descendants ELSE TRUE
  END,
  can_view_descendants = TRUE,
  updated_at = NOW();

COMMENT ON COLUMN church_unit_types.can_have_cash_accounts IS
  'Allows units of this level to own one or more cash accounts.';
COMMENT ON COLUMN church_unit_types.can_have_bank_accounts IS
  'Allows units of this level to own one or more bank accounts.';
COMMENT ON COLUMN church_unit_types.can_have_mobile_money_accounts IS
  'Allows units of this level to own one or more mobile money wallets.';
COMMENT ON COLUMN church_unit_types.can_create_programs IS
  'Allows units of this level to create programs or activities.';
COMMENT ON COLUMN church_unit_types.can_launch_contributions IS
  'Allows units of this level to launch contributions, pledges or campaigns.';
COMMENT ON COLUMN church_unit_types.can_validate_finances IS
  'Allows units of this level to review or validate financial movements.';
COMMENT ON COLUMN church_unit_types.can_consolidate_finances IS
  'Allows units of this level to consolidate descendant financial data.';
COMMENT ON COLUMN church_unit_types.can_notify_descendants IS
  'Allows units of this level to notify descendant units or members.';
COMMENT ON COLUMN church_unit_types.can_view_descendants IS
  'Allows scoped users to include descendant units in their working perimeter.';

CREATE TABLE IF NOT EXISTS church_unit_financial_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  church_unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  label TEXT NOT NULL,
  provider TEXT,
  account_number TEXT,
  phone_number TEXT,
  currency TEXT NOT NULL DEFAULT 'FCFA',
  opening_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
  journal_id UUID REFERENCES journaux_comptables(id) ON DELETE SET NULL,
  comptable_account_id UUID REFERENCES comptes_comptables(id) ON DELETE SET NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT church_unit_financial_accounts_type_check
    CHECK (type IN ('cash', 'bank', 'mobile_money')),
  CONSTRAINT church_unit_financial_accounts_label_not_blank
    CHECK (length(trim(label)) > 0),
  CONSTRAINT church_unit_financial_accounts_currency_not_blank
    CHECK (length(trim(currency)) > 0)
);

COMMENT ON TABLE church_unit_financial_accounts IS
  'Cash, bank and mobile money accounts attached to configurable church units.';
COMMENT ON COLUMN church_unit_financial_accounts.type IS
  'cash, bank or mobile_money.';
COMMENT ON COLUMN church_unit_financial_accounts.provider IS
  'Provider name, for example Moov, MTN, Celtiis or a bank name.';
COMMENT ON COLUMN church_unit_financial_accounts.opening_balance IS
  'Initial balance used for setup only; live balances must be computed from validated movements.';

CREATE INDEX IF NOT EXISTS idx_church_unit_financial_accounts_org
  ON church_unit_financial_accounts(organization_id);

CREATE INDEX IF NOT EXISTS idx_church_unit_financial_accounts_unit
  ON church_unit_financial_accounts(church_unit_id);

CREATE INDEX IF NOT EXISTS idx_church_unit_financial_accounts_type
  ON church_unit_financial_accounts(type);

CREATE UNIQUE INDEX IF NOT EXISTS idx_church_unit_financial_accounts_label_active
  ON church_unit_financial_accounts(
    organization_id,
    church_unit_id,
    lower(label)
  )
  WHERE active = TRUE;

CREATE OR REPLACE FUNCTION enforce_church_unit_financial_account_capability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_unit_org_id UUID;
  v_can_cash BOOLEAN;
  v_can_bank BOOLEAN;
  v_can_mobile_money BOOLEAN;
BEGIN
  SELECT
    u.organization_id,
    t.can_have_cash_accounts,
    t.can_have_bank_accounts,
    t.can_have_mobile_money_accounts
  INTO
    v_unit_org_id,
    v_can_cash,
    v_can_bank,
    v_can_mobile_money
  FROM church_units u
  JOIN church_unit_types t ON t.id = u.type_id
  WHERE u.id = NEW.church_unit_id;

  IF v_unit_org_id IS NULL THEN
    RAISE EXCEPTION 'Unite d''eglise introuvable pour ce compte financier.'
      USING ERRCODE = '23503';
  END IF;

  IF NEW.organization_id <> v_unit_org_id THEN
    RAISE EXCEPTION 'Le compte financier doit appartenir a la meme organisation que l''unite.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.type = 'cash' AND NOT v_can_cash THEN
    RAISE EXCEPTION 'Ce niveau n''autorise pas les comptes caisse.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.type = 'bank' AND NOT v_can_bank THEN
    RAISE EXCEPTION 'Ce niveau n''autorise pas les comptes banque.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.type = 'mobile_money' AND NOT v_can_mobile_money THEN
    RAISE EXCEPTION 'Ce niveau n''autorise pas les comptes mobile money.'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_church_unit_financial_account_capability_trigger
  ON church_unit_financial_accounts;

CREATE TRIGGER enforce_church_unit_financial_account_capability_trigger
  BEFORE INSERT OR UPDATE ON church_unit_financial_accounts
  FOR EACH ROW
  EXECUTE FUNCTION enforce_church_unit_financial_account_capability();

DROP TRIGGER IF EXISTS update_church_unit_financial_accounts_updated_at
  ON church_unit_financial_accounts;

CREATE TRIGGER update_church_unit_financial_accounts_updated_at
  BEFORE UPDATE ON church_unit_financial_accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE church_unit_financial_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view unit financial accounts"
  ON church_unit_financial_accounts;
DROP POLICY IF EXISTS "Admins can manage unit financial accounts"
  ON church_unit_financial_accounts;

CREATE POLICY "Users can view unit financial accounts"
  ON church_unit_financial_accounts FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE POLICY "Admins can manage unit financial accounts"
  ON church_unit_financial_accounts FOR ALL
  USING (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  )
  WITH CHECK (
    get_user_role() = 'admin_national'
    AND organization_id = get_user_organization_id()
  );

GRANT ALL ON church_unit_financial_accounts TO authenticated;

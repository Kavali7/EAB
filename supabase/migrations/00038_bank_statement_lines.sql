-- ============================================================================
-- Bank statement lines for reconciliation
-- ============================================================================
-- The historical releves_bancaires table stores statement headers/monthly
-- balances. The reconciliation UI needs operation-level lines that can be
-- checked and optionally linked to accounting entries.

CREATE TABLE IF NOT EXISTS lignes_releves_bancaires (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  releve_id UUID REFERENCES releves_bancaires(id) ON DELETE CASCADE,
  church_unit_id UUID REFERENCES church_units(id) ON DELETE SET NULL,
  id_assemblee_locale UUID REFERENCES assemblees_locales(id) ON DELETE SET NULL,
  id_compte_banque UUID NOT NULL REFERENCES comptes_comptables(id) ON DELETE RESTRICT,
  financial_account_id UUID REFERENCES church_unit_financial_accounts(id) ON DELETE SET NULL,
  date_operation DATE NOT NULL,
  libelle TEXT NOT NULL,
  montant DECIMAL(15,2) NOT NULL,
  solde_apres_operation DECIMAL(15,2) NOT NULL DEFAULT 0,
  reference_operation TEXT,
  est_pointe BOOLEAN NOT NULL DEFAULT FALSE,
  id_ecriture_comptable_liee UUID REFERENCES ecritures_comptables(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT lignes_releves_bancaires_libelle_not_blank
    CHECK (length(trim(libelle)) > 0)
);

COMMENT ON TABLE lignes_releves_bancaires IS
  'Operation-level bank statement lines used by bank reconciliation.';
COMMENT ON COLUMN lignes_releves_bancaires.id_compte_banque IS
  'Accounting bank account used by the current reconciliation UI.';
COMMENT ON COLUMN lignes_releves_bancaires.financial_account_id IS
  'Optional operational bank account attached to the church unit.';
COMMENT ON COLUMN lignes_releves_bancaires.id_ecriture_comptable_liee IS
  'Optional accounting entry matched during reconciliation.';

CREATE INDEX IF NOT EXISTS idx_lignes_releves_org
  ON lignes_releves_bancaires(organization_id);
CREATE INDEX IF NOT EXISTS idx_lignes_releves_releve
  ON lignes_releves_bancaires(releve_id);
CREATE INDEX IF NOT EXISTS idx_lignes_releves_unit
  ON lignes_releves_bancaires(church_unit_id);
CREATE INDEX IF NOT EXISTS idx_lignes_releves_compte
  ON lignes_releves_bancaires(id_compte_banque);
CREATE INDEX IF NOT EXISTS idx_lignes_releves_financial_account
  ON lignes_releves_bancaires(financial_account_id);
CREATE INDEX IF NOT EXISTS idx_lignes_releves_date
  ON lignes_releves_bancaires(date_operation);
CREATE INDEX IF NOT EXISTS idx_lignes_releves_pointe
  ON lignes_releves_bancaires(est_pointe);

CREATE OR REPLACE FUNCTION sync_ligne_releve_bancaire_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_releve_org_id UUID;
  v_releve_unit_id UUID;
  v_releve_assemblee_id UUID;
  v_financial_org_id UUID;
  v_financial_unit_id UUID;
  v_financial_compte_id UUID;
  v_ecriture_org_id UUID;
  v_church_unit_id UUID;
  v_legacy_assemblee_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    NEW.organization_id := get_user_organization_id();
  END IF;

  IF NEW.releve_id IS NOT NULL THEN
    SELECT organization_id, church_unit_id, id_assemblee_locale
    INTO v_releve_org_id, v_releve_unit_id, v_releve_assemblee_id
    FROM releves_bancaires
    WHERE id = NEW.releve_id;

    IF v_releve_org_id IS NULL THEN
      RAISE EXCEPTION 'Releve bancaire introuvable.'
        USING ERRCODE = '23503';
    END IF;
    IF NEW.organization_id <> v_releve_org_id THEN
      RAISE EXCEPTION 'La ligne de releve doit appartenir a la meme organisation que le releve.'
        USING ERRCODE = '23514';
    END IF;

    NEW.church_unit_id := COALESCE(NEW.church_unit_id, v_releve_unit_id);
    NEW.id_assemblee_locale := COALESCE(
      NEW.id_assemblee_locale,
      v_releve_assemblee_id
    );
  END IF;

  IF NEW.financial_account_id IS NOT NULL THEN
    SELECT organization_id, church_unit_id, comptable_account_id
    INTO v_financial_org_id, v_financial_unit_id, v_financial_compte_id
    FROM church_unit_financial_accounts
    WHERE id = NEW.financial_account_id;

    IF v_financial_org_id IS NULL THEN
      RAISE EXCEPTION 'Compte financier introuvable.'
        USING ERRCODE = '23503';
    END IF;
    IF NEW.organization_id <> v_financial_org_id THEN
      RAISE EXCEPTION 'La ligne de releve doit appartenir a la meme organisation que le compte financier.'
        USING ERRCODE = '23514';
    END IF;

    NEW.church_unit_id := COALESCE(NEW.church_unit_id, v_financial_unit_id);
    NEW.id_compte_banque := COALESCE(NEW.id_compte_banque, v_financial_compte_id);
  END IF;

  IF NEW.church_unit_id IS NULL AND NEW.id_assemblee_locale IS NOT NULL THEN
    SELECT id INTO v_church_unit_id
    FROM church_units
    WHERE organization_id = NEW.organization_id
      AND legacy_assemblee_id = NEW.id_assemblee_locale
    LIMIT 1;

    NEW.church_unit_id := v_church_unit_id;
  END IF;

  IF NEW.id_assemblee_locale IS NULL AND NEW.church_unit_id IS NOT NULL THEN
    SELECT legacy_assemblee_id INTO v_legacy_assemblee_id
    FROM church_units
    WHERE id = NEW.church_unit_id
      AND organization_id = NEW.organization_id;

    NEW.id_assemblee_locale := v_legacy_assemblee_id;
  END IF;

  IF NEW.id_ecriture_comptable_liee IS NOT NULL THEN
    SELECT organization_id INTO v_ecriture_org_id
    FROM ecritures_comptables
    WHERE id = NEW.id_ecriture_comptable_liee;

    IF v_ecriture_org_id IS NULL THEN
      RAISE EXCEPTION 'Ecriture comptable liee introuvable.'
        USING ERRCODE = '23503';
    END IF;
    IF NEW.organization_id <> v_ecriture_org_id THEN
      RAISE EXCEPTION 'La ligne de releve et l''ecriture liee doivent appartenir a la meme organisation.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_ligne_releve_bancaire_scope_trigger
  ON lignes_releves_bancaires;
CREATE TRIGGER sync_ligne_releve_bancaire_scope_trigger
  BEFORE INSERT OR UPDATE OF organization_id, releve_id, church_unit_id,
    id_assemblee_locale, financial_account_id, id_compte_banque,
    id_ecriture_comptable_liee
  ON lignes_releves_bancaires
  FOR EACH ROW EXECUTE FUNCTION sync_ligne_releve_bancaire_scope();

DROP TRIGGER IF EXISTS update_lignes_releves_bancaires_updated_at
  ON lignes_releves_bancaires;
CREATE TRIGGER update_lignes_releves_bancaires_updated_at
  BEFORE UPDATE ON lignes_releves_bancaires
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE lignes_releves_bancaires ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires;
DROP POLICY IF EXISTS "Users can create bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires;
DROP POLICY IF EXISTS "Users can update bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires;
DROP POLICY IF EXISTS "Users can delete bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires;

CREATE POLICY "Users can view bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'view_details'
    )
  );

CREATE POLICY "Users can create bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires FOR INSERT
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'create'
    )
  );

CREATE POLICY "Users can update bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires FOR UPDATE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

CREATE POLICY "Users can delete bank statement lines by hierarchy permissions"
  ON lignes_releves_bancaires FOR DELETE
  USING (
    organization_id = get_user_organization_id()
    AND user_can_access_bank_reconciliation_scope(
      church_unit_id,
      id_assemblee_locale,
      'update'
    )
  );

GRANT ALL ON lignes_releves_bancaires TO authenticated;

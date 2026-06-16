-- ============================================================================
-- Operational financial campaigns, pledges and movements
-- ============================================================================
-- Adds a simple operational finance layer between church activities and formal
-- SYSCEBNL accounting. Secretaries can record pledges, contributions and
-- payments against a configured church unit financial account. Accountants can
-- later validate/classify these records and optionally link them to accounting
-- entries without forcing accounting knowledge at data-entry time.

CREATE TABLE IF NOT EXISTS campagnes_financieres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  church_unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  programme_id UUID REFERENCES programmes(id) ON DELETE SET NULL,
  titre TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'cotisation',
  description TEXT,
  objectif_montant DECIMAL(15,2),
  date_debut DATE NOT NULL DEFAULT CURRENT_DATE,
  date_fin DATE,
  periodicite TEXT,
  statut TEXT NOT NULL DEFAULT 'brouillon',
  allow_partial_payments BOOLEAN NOT NULL DEFAULT TRUE,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  closed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  closed_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT campagnes_financieres_titre_not_blank
    CHECK (length(trim(titre)) > 0),
  CONSTRAINT campagnes_financieres_type_check
    CHECK (type IN (
      'cotisation',
      'promesse_don',
      'offrande_speciale',
      'projet',
      'activite',
      'autre'
    )),
  CONSTRAINT campagnes_financieres_statut_check
    CHECK (statut IN ('brouillon', 'active', 'cloturee', 'annulee')),
  CONSTRAINT campagnes_financieres_objectif_positive
    CHECK (objectif_montant IS NULL OR objectif_montant >= 0),
  CONSTRAINT campagnes_financieres_dates_check
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

COMMENT ON TABLE campagnes_financieres IS
  'Operational contribution, pledge or activity funding campaigns before formal accounting.';
COMMENT ON COLUMN campagnes_financieres.programme_id IS
  'Optional linked church programme/activity. The campaign can still exist without a programme.';
COMMENT ON COLUMN campagnes_financieres.periodicite IS
  'Optional recurrence label, for example ponctuelle, hebdomadaire, mensuelle or trimestrielle.';

CREATE TABLE IF NOT EXISTS promesses_financieres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  campagne_id UUID NOT NULL REFERENCES campagnes_financieres(id) ON DELETE CASCADE,
  church_unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  membre_id UUID REFERENCES membres(id) ON DELETE SET NULL,
  tiers_id UUID REFERENCES tiers(id) ON DELETE SET NULL,
  contributeur_nom TEXT,
  montant_promis DECIMAL(15,2) NOT NULL,
  date_promesse DATE NOT NULL DEFAULT CURRENT_DATE,
  date_echeance DATE,
  statut TEXT NOT NULL DEFAULT 'ouverte',
  notes TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT promesses_financieres_montant_positive
    CHECK (montant_promis > 0),
  CONSTRAINT promesses_financieres_statut_check
    CHECK (statut IN ('ouverte', 'partielle', 'reglee', 'annulee')),
  CONSTRAINT promesses_financieres_contributeur_check
    CHECK (
      membre_id IS NOT NULL
      OR tiers_id IS NOT NULL
      OR length(trim(COALESCE(contributeur_nom, ''))) > 0
    ),
  CONSTRAINT promesses_financieres_dates_check
    CHECK (date_echeance IS NULL OR date_echeance >= date_promesse)
);

COMMENT ON TABLE promesses_financieres IS
  'Pledges made by members, third parties or external contributors for a financial campaign.';
COMMENT ON COLUMN promesses_financieres.statut IS
  'Auto-refreshed by movement triggers unless the pledge is cancelled.';

CREATE TABLE IF NOT EXISTS mouvements_financiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  church_unit_id UUID NOT NULL REFERENCES church_units(id) ON DELETE CASCADE,
  financial_account_id UUID NOT NULL REFERENCES church_unit_financial_accounts(id) ON DELETE RESTRICT,
  campagne_id UUID REFERENCES campagnes_financieres(id) ON DELETE SET NULL,
  programme_id UUID REFERENCES programmes(id) ON DELETE SET NULL,
  promesse_id UUID REFERENCES promesses_financieres(id) ON DELETE SET NULL,
  membre_id UUID REFERENCES membres(id) ON DELETE SET NULL,
  tiers_id UUID REFERENCES tiers(id) ON DELETE SET NULL,
  contributeur_nom TEXT,
  type TEXT NOT NULL DEFAULT 'encaissement',
  montant DECIMAL(15,2) NOT NULL,
  date_mouvement DATE NOT NULL DEFAULT CURRENT_DATE,
  libelle TEXT NOT NULL,
  mode_paiement mode_paiement,
  reference_externe TEXT,
  piece_justificative_url TEXT,
  statut TEXT NOT NULL DEFAULT 'brouillon',
  rejet_motif TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  submitted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  submitted_at TIMESTAMPTZ,
  validated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  validated_at TIMESTAMPTZ,
  ecriture_id UUID REFERENCES ecritures_comptables(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT mouvements_financiers_montant_positive
    CHECK (montant > 0),
  CONSTRAINT mouvements_financiers_libelle_not_blank
    CHECK (length(trim(libelle)) > 0),
  CONSTRAINT mouvements_financiers_type_check
    CHECK (type IN ('encaissement', 'decaissement', 'ajustement')),
  CONSTRAINT mouvements_financiers_statut_check
    CHECK (statut IN ('brouillon', 'soumis', 'valide', 'rejete', 'annule')),
  CONSTRAINT mouvements_financiers_rejet_motif_check
    CHECK (statut <> 'rejete' OR length(trim(COALESCE(rejet_motif, ''))) > 0)
);

COMMENT ON TABLE mouvements_financiers IS
  'Operational cash, bank or mobile money movements before or alongside formal SYSCEBNL accounting entries.';
COMMENT ON COLUMN mouvements_financiers.ecriture_id IS
  'Optional accounting entry generated or linked after review. Operational records do not create accounting entries automatically.';

CREATE INDEX IF NOT EXISTS idx_campagnes_financieres_org
  ON campagnes_financieres(organization_id);
CREATE INDEX IF NOT EXISTS idx_campagnes_financieres_unit
  ON campagnes_financieres(church_unit_id);
CREATE INDEX IF NOT EXISTS idx_campagnes_financieres_programme
  ON campagnes_financieres(programme_id);
CREATE INDEX IF NOT EXISTS idx_campagnes_financieres_statut
  ON campagnes_financieres(statut);
CREATE INDEX IF NOT EXISTS idx_campagnes_financieres_dates
  ON campagnes_financieres(date_debut, date_fin);

CREATE INDEX IF NOT EXISTS idx_promesses_financieres_org
  ON promesses_financieres(organization_id);
CREATE INDEX IF NOT EXISTS idx_promesses_financieres_campagne
  ON promesses_financieres(campagne_id);
CREATE INDEX IF NOT EXISTS idx_promesses_financieres_unit
  ON promesses_financieres(church_unit_id);
CREATE INDEX IF NOT EXISTS idx_promesses_financieres_membre
  ON promesses_financieres(membre_id);
CREATE INDEX IF NOT EXISTS idx_promesses_financieres_tiers
  ON promesses_financieres(tiers_id);
CREATE INDEX IF NOT EXISTS idx_promesses_financieres_statut
  ON promesses_financieres(statut);

CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_org
  ON mouvements_financiers(organization_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_unit
  ON mouvements_financiers(church_unit_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_account
  ON mouvements_financiers(financial_account_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_campagne
  ON mouvements_financiers(campagne_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_programme
  ON mouvements_financiers(programme_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_promesse
  ON mouvements_financiers(promesse_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_statut
  ON mouvements_financiers(statut);
CREATE INDEX IF NOT EXISTS idx_mouvements_financiers_date
  ON mouvements_financiers(date_mouvement);

CREATE OR REPLACE FUNCTION enforce_financial_campaign_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_unit_org_id UUID;
  v_can_launch_contributions BOOLEAN;
  v_program_org_id UUID;
BEGIN
  SELECT u.organization_id, t.can_launch_contributions
  INTO v_unit_org_id, v_can_launch_contributions
  FROM church_units u
  JOIN church_unit_types t ON t.id = u.type_id
  WHERE u.id = NEW.church_unit_id;

  IF v_unit_org_id IS NULL THEN
    RAISE EXCEPTION 'Unite d''eglise introuvable pour cette campagne financiere.'
      USING ERRCODE = '23503';
  END IF;

  IF NEW.organization_id <> v_unit_org_id THEN
    RAISE EXCEPTION 'La campagne financiere doit appartenir a la meme organisation que l''unite.'
      USING ERRCODE = '23514';
  END IF;

  IF NOT v_can_launch_contributions THEN
    RAISE EXCEPTION 'Ce niveau n''autorise pas les cotisations, promesses ou campagnes financieres.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.programme_id IS NOT NULL THEN
    SELECT organization_id INTO v_program_org_id
    FROM programmes
    WHERE id = NEW.programme_id;

    IF v_program_org_id IS NULL THEN
      RAISE EXCEPTION 'Programme introuvable pour cette campagne financiere.'
        USING ERRCODE = '23503';
    END IF;

    IF NEW.organization_id <> v_program_org_id THEN
      RAISE EXCEPTION 'La campagne et le programme doivent appartenir a la meme organisation.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.statut = 'cloturee' AND NEW.closed_at IS NULL THEN
    NEW.closed_at := NOW();
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION enforce_financial_pledge_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_campaign_org_id UUID;
  v_campaign_unit_id UUID;
  v_member_org_id UUID;
  v_tiers_org_id UUID;
BEGIN
  SELECT organization_id, church_unit_id
  INTO v_campaign_org_id, v_campaign_unit_id
  FROM campagnes_financieres
  WHERE id = NEW.campagne_id;

  IF v_campaign_org_id IS NULL THEN
    RAISE EXCEPTION 'Campagne financiere introuvable pour cette promesse.'
      USING ERRCODE = '23503';
  END IF;

  IF NEW.organization_id <> v_campaign_org_id THEN
    RAISE EXCEPTION 'La promesse doit appartenir a la meme organisation que la campagne.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.church_unit_id <> v_campaign_unit_id THEN
    RAISE EXCEPTION 'La promesse doit rester dans le meme perimetre que la campagne.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.membre_id IS NOT NULL THEN
    SELECT organization_id INTO v_member_org_id
    FROM membres
    WHERE id = NEW.membre_id;

    IF v_member_org_id IS NULL OR v_member_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Le membre rattache a la promesse est invalide pour cette organisation.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.tiers_id IS NOT NULL THEN
    SELECT organization_id INTO v_tiers_org_id
    FROM tiers
    WHERE id = NEW.tiers_id;

    IF v_tiers_org_id IS NULL OR v_tiers_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Le tiers rattache a la promesse est invalide pour cette organisation.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION enforce_financial_movement_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_account_org_id UUID;
  v_account_unit_id UUID;
  v_account_active BOOLEAN;
  v_campaign_org_id UUID;
  v_campaign_unit_id UUID;
  v_program_org_id UUID;
  v_pledge_org_id UUID;
  v_pledge_unit_id UUID;
  v_member_org_id UUID;
  v_tiers_org_id UUID;
BEGIN
  SELECT organization_id, church_unit_id, active
  INTO v_account_org_id, v_account_unit_id, v_account_active
  FROM church_unit_financial_accounts
  WHERE id = NEW.financial_account_id;

  IF v_account_org_id IS NULL THEN
    RAISE EXCEPTION 'Compte financier introuvable pour ce mouvement.'
      USING ERRCODE = '23503';
  END IF;

  IF NOT v_account_active THEN
    RAISE EXCEPTION 'Le compte financier selectionne est archive.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.organization_id <> v_account_org_id THEN
    RAISE EXCEPTION 'Le mouvement financier doit appartenir a la meme organisation que le compte.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.church_unit_id <> v_account_unit_id THEN
    RAISE EXCEPTION 'Le mouvement financier doit rester dans le meme perimetre que le compte.'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.campagne_id IS NOT NULL THEN
    SELECT organization_id, church_unit_id
    INTO v_campaign_org_id, v_campaign_unit_id
    FROM campagnes_financieres
    WHERE id = NEW.campagne_id;

    IF v_campaign_org_id IS NULL OR v_campaign_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Campagne financiere invalide pour ce mouvement.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.programme_id IS NOT NULL THEN
    SELECT organization_id INTO v_program_org_id
    FROM programmes
    WHERE id = NEW.programme_id;

    IF v_program_org_id IS NULL OR v_program_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Programme invalide pour ce mouvement.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.promesse_id IS NOT NULL THEN
    SELECT organization_id, church_unit_id
    INTO v_pledge_org_id, v_pledge_unit_id
    FROM promesses_financieres
    WHERE id = NEW.promesse_id;

    IF v_pledge_org_id IS NULL OR v_pledge_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Promesse financiere invalide pour ce mouvement.'
        USING ERRCODE = '23514';
    END IF;

    IF NEW.campagne_id IS NOT NULL AND v_campaign_unit_id <> v_pledge_unit_id THEN
      RAISE EXCEPTION 'La promesse et la campagne doivent rester dans le meme perimetre.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.membre_id IS NOT NULL THEN
    SELECT organization_id INTO v_member_org_id
    FROM membres
    WHERE id = NEW.membre_id;

    IF v_member_org_id IS NULL OR v_member_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Membre invalide pour ce mouvement financier.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.tiers_id IS NOT NULL THEN
    SELECT organization_id INTO v_tiers_org_id
    FROM tiers
    WHERE id = NEW.tiers_id;

    IF v_tiers_org_id IS NULL OR v_tiers_org_id <> NEW.organization_id THEN
      RAISE EXCEPTION 'Tiers invalide pour ce mouvement financier.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.statut = 'soumis' AND NEW.submitted_at IS NULL THEN
    NEW.submitted_at := NOW();
  END IF;

  IF NEW.statut = 'valide' AND NEW.validated_at IS NULL THEN
    NEW.validated_at := NOW();
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION recompute_financial_pledge_status(p_pledge_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_promised DECIMAL(15,2);
  v_paid DECIMAL(15,2);
  v_current_status TEXT;
BEGIN
  IF p_pledge_id IS NULL THEN
    RETURN;
  END IF;

  SELECT montant_promis, statut
  INTO v_promised, v_current_status
  FROM promesses_financieres
  WHERE id = p_pledge_id;

  IF v_promised IS NULL OR v_current_status = 'annulee' THEN
    RETURN;
  END IF;

  SELECT COALESCE(SUM(montant), 0)
  INTO v_paid
  FROM mouvements_financiers
  WHERE promesse_id = p_pledge_id
    AND type = 'encaissement'
    AND statut IN ('soumis', 'valide');

  UPDATE promesses_financieres
  SET
    statut = CASE
      WHEN v_paid <= 0 THEN 'ouverte'
      WHEN v_paid < v_promised THEN 'partielle'
      ELSE 'reglee'
    END,
    updated_at = NOW()
  WHERE id = p_pledge_id
    AND statut <> 'annulee';
END;
$$;

CREATE OR REPLACE FUNCTION refresh_financial_pledge_status_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    PERFORM recompute_financial_pledge_status(OLD.promesse_id);
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    PERFORM recompute_financial_pledge_status(NEW.promesse_id);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS enforce_financial_campaign_scope_trigger
  ON campagnes_financieres;
CREATE TRIGGER enforce_financial_campaign_scope_trigger
  BEFORE INSERT OR UPDATE ON campagnes_financieres
  FOR EACH ROW
  EXECUTE FUNCTION enforce_financial_campaign_scope();

DROP TRIGGER IF EXISTS enforce_financial_pledge_scope_trigger
  ON promesses_financieres;
CREATE TRIGGER enforce_financial_pledge_scope_trigger
  BEFORE INSERT OR UPDATE ON promesses_financieres
  FOR EACH ROW
  EXECUTE FUNCTION enforce_financial_pledge_scope();

DROP TRIGGER IF EXISTS enforce_financial_movement_scope_trigger
  ON mouvements_financiers;
CREATE TRIGGER enforce_financial_movement_scope_trigger
  BEFORE INSERT OR UPDATE ON mouvements_financiers
  FOR EACH ROW
  EXECUTE FUNCTION enforce_financial_movement_scope();

DROP TRIGGER IF EXISTS refresh_financial_pledge_status_after_movement
  ON mouvements_financiers;
CREATE TRIGGER refresh_financial_pledge_status_after_movement
  AFTER INSERT OR UPDATE OR DELETE ON mouvements_financiers
  FOR EACH ROW
  EXECUTE FUNCTION refresh_financial_pledge_status_trigger();

DROP TRIGGER IF EXISTS update_campagnes_financieres_updated_at
  ON campagnes_financieres;
CREATE TRIGGER update_campagnes_financieres_updated_at
  BEFORE UPDATE ON campagnes_financieres
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_promesses_financieres_updated_at
  ON promesses_financieres;
CREATE TRIGGER update_promesses_financieres_updated_at
  BEFORE UPDATE ON promesses_financieres
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_mouvements_financiers_updated_at
  ON mouvements_financiers;
CREATE TRIGGER update_mouvements_financiers_updated_at
  BEFORE UPDATE ON mouvements_financiers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE campagnes_financieres ENABLE ROW LEVEL SECURITY;
ALTER TABLE promesses_financieres ENABLE ROW LEVEL SECURITY;
ALTER TABLE mouvements_financiers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view financial campaigns based on access"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can manage financial campaigns based on access"
  ON campagnes_financieres;
DROP POLICY IF EXISTS "Users can view financial pledges based on access"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can manage financial pledges based on access"
  ON promesses_financieres;
DROP POLICY IF EXISTS "Users can view financial movements based on access"
  ON mouvements_financiers;
DROP POLICY IF EXISTS "Users can manage financial movements based on access"
  ON mouvements_financiers;

CREATE POLICY "Users can view financial campaigns based on access"
  ON campagnes_financieres FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE POLICY "Users can manage financial campaigns based on access"
  ON campagnes_financieres FOR ALL
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE POLICY "Users can view financial pledges based on access"
  ON promesses_financieres FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE POLICY "Users can manage financial pledges based on access"
  ON promesses_financieres FOR ALL
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE POLICY "Users can view financial movements based on access"
  ON mouvements_financiers FOR SELECT
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE POLICY "Users can manage financial movements based on access"
  ON mouvements_financiers FOR ALL
  USING (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  )
  WITH CHECK (
    organization_id = get_user_organization_id()
    AND (
      get_user_role() = 'admin_national'
      OR user_has_church_unit_access(church_unit_id)
    )
  );

CREATE OR REPLACE VIEW v_campagnes_financieres_resume
WITH (security_invoker = true) AS
SELECT
  c.id,
  c.organization_id,
  c.church_unit_id,
  c.programme_id,
  c.titre,
  c.type,
  c.statut,
  c.objectif_montant,
  COALESCE(p.montant_promis, 0)::DECIMAL(15,2) AS montant_promis,
  COALESCE(m.montant_encaisse, 0)::DECIMAL(15,2) AS montant_encaisse,
  COALESCE(m.montant_valide, 0)::DECIMAL(15,2) AS montant_valide,
  GREATEST(COALESCE(p.montant_promis, 0) - COALESCE(m.montant_encaisse, 0), 0)::DECIMAL(15,2)
    AS reste_sur_promesses,
  CASE
    WHEN c.objectif_montant IS NULL THEN NULL
    ELSE GREATEST(c.objectif_montant - COALESCE(m.montant_encaisse, 0), 0)::DECIMAL(15,2)
  END AS reste_sur_objectif,
  c.date_debut,
  c.date_fin,
  c.created_at,
  c.updated_at
FROM campagnes_financieres c
LEFT JOIN (
  SELECT
    campagne_id,
    SUM(montant_promis) AS montant_promis
  FROM promesses_financieres
  WHERE statut <> 'annulee'
  GROUP BY campagne_id
) p ON p.campagne_id = c.id
LEFT JOIN (
  SELECT
    campagne_id,
    SUM(montant) FILTER (
      WHERE type = 'encaissement'
        AND statut IN ('soumis', 'valide')
    ) AS montant_encaisse,
    SUM(montant) FILTER (
      WHERE type = 'encaissement'
        AND statut = 'valide'
    ) AS montant_valide
  FROM mouvements_financiers
  GROUP BY campagne_id
) m ON m.campagne_id = c.id;

GRANT ALL ON campagnes_financieres TO authenticated;
GRANT ALL ON promesses_financieres TO authenticated;
GRANT ALL ON mouvements_financiers TO authenticated;
GRANT SELECT ON v_campagnes_financieres_resume TO authenticated;

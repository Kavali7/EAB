-- ============================================================================
-- EAB Backend - 00008 Exercices V2 + RPCs Reports + Global Search
-- ============================================================================
-- Sprint A: Gestion des exercices comptables (statut enum, unicité, RPCs)
-- Sprint B: États financiers SYCEBNL (balance, résultat, bilan)
-- Sprint C: Recherche globale
-- ============================================================================

-- ============================================================================
-- SPRINT A : EXERCICES COMPTABLES V2
-- ============================================================================

-- 1. Créer le type enum statut_exercice
CREATE TYPE statut_exercice AS ENUM ('brouillon', 'ouvert', 'cloture');

-- 2. Ajouter la colonne statut + colonnes de liaison écritures
ALTER TABLE exercices_comptables
  ADD COLUMN IF NOT EXISTS statut statut_exercice NOT NULL DEFAULT 'brouillon',
  ADD COLUMN IF NOT EXISTS opening_entry_id UUID REFERENCES ecritures_comptables(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS closing_entry_id UUID REFERENCES ecritures_comptables(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 3. Migrer les données existantes (booleans → enum)
UPDATE exercices_comptables
SET statut = CASE
  WHEN est_cloture = TRUE THEN 'cloture'::statut_exercice
  WHEN est_ouvert = TRUE THEN 'ouvert'::statut_exercice
  ELSE 'brouillon'::statut_exercice
END;

-- 4. CHECK : date_debut <= date_fin
ALTER TABLE exercices_comptables
  ADD CONSTRAINT chk_exercice_dates CHECK (date_debut <= date_fin);

-- 5. Index unique partiel : 1 exercice ouvert max par org
CREATE UNIQUE INDEX IF NOT EXISTS ux_exercice_ouvert_par_org
  ON exercices_comptables (organization_id)
  WHERE (statut = 'ouvert' AND deleted_at IS NULL);

-- Index sur statut
CREATE INDEX IF NOT EXISTS idx_exercices_statut
  ON exercices_comptables(statut);

-- ============================================================================
-- RPC : Ouvrir un exercice
-- ============================================================================

CREATE OR REPLACE FUNCTION open_exercice(p_exercice_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exercice exercices_comptables%ROWTYPE;
BEGIN
  -- Vérifier admin
  IF get_user_role() != 'admin_national' THEN
    RAISE EXCEPTION 'Seul l''administrateur national peut ouvrir un exercice';
  END IF;

  -- Récupérer l'exercice
  SELECT * INTO v_exercice FROM exercices_comptables WHERE id = p_exercice_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Exercice non trouvé';
  END IF;

  -- C) Vérifier que l'exercice appartient à l'org de l'utilisateur
  IF NOT EXISTS (
    SELECT 1 FROM membres m
    WHERE m.user_id = auth.uid()
      AND m.organization_id = v_exercice.organization_id
  ) THEN
    RAISE EXCEPTION 'Accès refusé : vous n''appartenez pas à cette organisation';
  END IF;

  IF v_exercice.statut != 'brouillon' THEN
    RAISE EXCEPTION 'Seul un exercice en brouillon peut être ouvert (statut actuel: %)', v_exercice.statut;
  END IF;

  -- L'index unique ux_exercice_ouvert_par_org empêchera 2 exercices ouverts
  UPDATE exercices_comptables
  SET statut = 'ouvert', est_ouvert = TRUE, updated_at = NOW()
  WHERE id = p_exercice_id;

  -- Logger
  PERFORM log_audit_action('VALIDATION'::action_audit, 'exercices_comptables', p_exercice_id, NULL, to_jsonb(v_exercice));

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC : Obtenir l'exercice ouvert
-- ============================================================================

CREATE OR REPLACE FUNCTION get_exercice_ouvert(p_org_id UUID)
RETURNS exercices_comptables AS $$
DECLARE
  v_exercice exercices_comptables%ROWTYPE;
BEGIN
  SELECT * INTO v_exercice
  FROM exercices_comptables
  WHERE organization_id = p_org_id
    AND statut = 'ouvert'
    AND deleted_at IS NULL
  LIMIT 1;

  RETURN v_exercice;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- RPC : Vérifier si on peut saisir dans l'exercice courant
-- ============================================================================

CREATE OR REPLACE FUNCTION can_post_in_exercice(p_org_id UUID, p_date DATE)
RETURNS BOOLEAN AS $$
DECLARE
  v_exercice exercices_comptables%ROWTYPE;
BEGIN
  SELECT * INTO v_exercice
  FROM exercices_comptables
  WHERE organization_id = p_org_id
    AND statut = 'ouvert'
    AND deleted_at IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN FALSE; -- Aucun exercice ouvert
  END IF;

  -- Vérifier que la date est dans la plage
  RETURN p_date >= v_exercice.date_debut AND p_date <= v_exercice.date_fin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- RPC : Clôturer exercice V2 (enrichie avec résultat + à-nouveaux)
-- ============================================================================

CREATE OR REPLACE FUNCTION cloturer_exercice(p_exercice_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_exercice exercices_comptables%ROWTYPE;
  v_nb_ecritures_brouillon INTEGER;
  v_journal_od_id UUID;
  v_total_produits DECIMAL(15,2) := 0;
  v_total_charges DECIMAL(15,2) := 0;
  v_resultat DECIMAL(15,2);
  v_compte_resultat_id UUID;
  v_closing_entry_id UUID;
  v_opening_entry_id UUID;
  v_compte RECORD;
BEGIN
  -- Vérifier admin
  IF get_user_role() != 'admin_national' THEN
    RAISE EXCEPTION 'Seul l''administrateur national peut clôturer un exercice';
  END IF;

  -- Récupérer l'exercice
  SELECT * INTO v_exercice FROM exercices_comptables WHERE id = p_exercice_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Exercice non trouvé';
  END IF;

  IF v_exercice.statut = 'cloture' THEN
    RAISE EXCEPTION 'Cet exercice est déjà clôturé';
  END IF;

  IF v_exercice.statut != 'ouvert' THEN
    RAISE EXCEPTION 'Seul un exercice ouvert peut être clôturé';
  END IF;

  -- C) Vérifier que l'exercice appartient à l'org de l'utilisateur
  IF NOT EXISTS (
    SELECT 1 FROM membres m
    WHERE m.user_id = auth.uid()
      AND m.organization_id = v_exercice.organization_id
  ) THEN
    RAISE EXCEPTION 'Accès refusé : vous n''appartenez pas à cette organisation';
  END IF;

  -- Vérifier qu'il n'y a pas d'écritures en brouillon
  SELECT COUNT(*) INTO v_nb_ecritures_brouillon
  FROM ecritures_comptables e
  WHERE e.organization_id = v_exercice.organization_id
    AND e.date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
    AND e.statut = 'brouillon'
    AND e.deleted_at IS NULL;

  IF v_nb_ecritures_brouillon > 0 THEN
    RAISE EXCEPTION 'Il reste % écriture(s) en brouillon. Veuillez les valider ou les supprimer.', v_nb_ecritures_brouillon;
  END IF;

  -- Trouver le journal OD
  SELECT id INTO v_journal_od_id
  FROM journaux_comptables
  WHERE organization_id = v_exercice.organization_id
    AND type = 'operations_diverses'
  LIMIT 1;

  IF v_journal_od_id IS NULL THEN
    RAISE EXCEPTION 'Aucun journal d''opérations diverses trouvé';
  END IF;

  -- Trouver le compte de résultat — priorité OHADA : 12x (Résultat de l'exercice)
  -- Fallback : 131x (ancien usage / certaines organisations)
  SELECT id INTO v_compte_resultat_id
  FROM comptes_comptables
  WHERE organization_id = v_exercice.organization_id
    AND numero LIKE '12%'
    AND actif = TRUE
  ORDER BY numero
  LIMIT 1;

  IF v_compte_resultat_id IS NULL THEN
    -- Fallback 131x
    SELECT id INTO v_compte_resultat_id
    FROM comptes_comptables
    WHERE organization_id = v_exercice.organization_id
      AND numero LIKE '131%'
      AND actif = TRUE
    LIMIT 1;
  END IF;

  IF v_compte_resultat_id IS NULL THEN
    RAISE EXCEPTION 'Compte de résultat (12x ou 131x) non trouvé dans le plan comptable. Veuillez créer un compte 12xx ou 131x.';
  END IF;

  -- ══════════════════════════════════════════════════════════════
  -- ÉCRITURE DE RÉSULTAT (solde classes 6 et 7 → compte 131)
  -- ══════════════════════════════════════════════════════════════

  -- Calculer produits (classe 7) et charges (classe 6) de l'exercice
  SELECT
    COALESCE(SUM(CASE WHEN c.nature = 'produit' THEN l.credit - l.debit ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN c.nature = 'charge' THEN l.debit - l.credit ELSE 0 END), 0)
  INTO v_total_produits, v_total_charges
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  WHERE e.organization_id = v_exercice.organization_id
    AND e.date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
    AND e.statut = 'validee'
    AND e.deleted_at IS NULL
    AND c.nature IN ('produit', 'charge');

  v_resultat := v_total_produits - v_total_charges;

  -- Créer l'écriture de résultat
  INSERT INTO ecritures_comptables (
    organization_id, id_journal, date, libelle, statut, created_by
  ) VALUES (
    v_exercice.organization_id,
    v_journal_od_id,
    v_exercice.date_fin,
    'Écriture de résultat — Exercice ' || v_exercice.annee,
    'validee',
    auth.uid()
  ) RETURNING id INTO v_closing_entry_id;

  -- Lignes : solder les comptes de charges (classe 6) et produits (classe 7)
  -- Pour chaque compte de charge ayant un solde, créer une ligne crédit
  FOR v_compte IN
    SELECT c.id AS compte_id, c.numero,
      COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) AS solde
    FROM comptes_comptables c
    JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
    JOIN ecritures_comptables e ON e.id = l.id_ecriture
    WHERE c.organization_id = v_exercice.organization_id
      AND c.nature = 'charge'
      AND e.date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
      AND e.statut = 'validee' AND e.deleted_at IS NULL
    GROUP BY c.id, c.numero
    HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  LOOP
    INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
    VALUES (v_closing_entry_id, v_compte.compte_id,
      0, ABS(v_compte.solde),
      'Solde charge ' || v_compte.numero
    );
  END LOOP;

  -- Pour chaque compte de produit ayant un solde, créer une ligne débit
  FOR v_compte IN
    SELECT c.id AS compte_id, c.numero,
      COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) AS solde
    FROM comptes_comptables c
    JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
    JOIN ecritures_comptables e ON e.id = l.id_ecriture
    WHERE c.organization_id = v_exercice.organization_id
      AND c.nature = 'produit'
      AND e.date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
      AND e.statut = 'validee' AND e.deleted_at IS NULL
    GROUP BY c.id, c.numero
    HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  LOOP
    INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
    VALUES (v_closing_entry_id, v_compte.compte_id,
      ABS(v_compte.solde), 0,
      'Solde produit ' || v_compte.numero
    );
  END LOOP;

  -- Ligne résultat net
  IF v_resultat >= 0 THEN
    INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
    VALUES (v_closing_entry_id, v_compte_resultat_id, 0, v_resultat, 'Résultat net exercice ' || v_exercice.annee);
  ELSE
    INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
    VALUES (v_closing_entry_id, v_compte_resultat_id, ABS(v_resultat), 0, 'Perte nette exercice ' || v_exercice.annee);
  END IF;

  -- ══════════════════════════════════════════════════════════════
  -- ÉCRITURE D'À-NOUVEAUX (classes 1-5 → nouvel exercice)
  -- ══════════════════════════════════════════════════════════════

  INSERT INTO ecritures_comptables (
    organization_id, id_journal, date, libelle, statut, created_by
  ) VALUES (
    v_exercice.organization_id,
    v_journal_od_id,
    v_exercice.date_fin + INTERVAL '1 day',
    'À-nouveaux — Exercice ' || (v_exercice.annee + 1),
    'validee',
    auth.uid()
  ) RETURNING id INTO v_opening_entry_id;

  -- Reprendre les soldes des comptes de bilan (classes 1-5)
  FOR v_compte IN
    SELECT c.id AS compte_id, c.numero, c.nature,
      CASE
        WHEN c.nature IN ('actif', 'charge') THEN
          COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0)
        ELSE
          COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0)
      END AS solde
    FROM comptes_comptables c
    JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
    JOIN ecritures_comptables e ON e.id = l.id_ecriture
    WHERE c.organization_id = v_exercice.organization_id
      AND c.numero ~ '^[1-5]'  -- Classes 1 à 5
      AND e.date <= v_exercice.date_fin
      AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    GROUP BY c.id, c.numero, c.nature
    HAVING CASE
      WHEN c.nature IN ('actif', 'charge') THEN
        COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0)
      ELSE
        COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0)
    END != 0
  LOOP
    IF v_compte.nature IN ('actif') THEN
      INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
      VALUES (v_opening_entry_id, v_compte.compte_id,
        ABS(v_compte.solde), 0, 'AN ' || v_compte.numero);
    ELSE
      INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
      VALUES (v_opening_entry_id, v_compte.compte_id,
        0, ABS(v_compte.solde), 'AN ' || v_compte.numero);
    END IF;
  END LOOP;

  -- ══════════════════════════════════════════════════════════════
  -- CLÔTURE
  -- ══════════════════════════════════════════════════════════════

  -- Clôturer toutes les écritures de l'exercice
  UPDATE ecritures_comptables
  SET statut = 'cloturee'
  WHERE organization_id = v_exercice.organization_id
    AND date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
    AND statut = 'validee'
    AND deleted_at IS NULL;

  -- Mettre à jour l'exercice
  UPDATE exercices_comptables
  SET
    statut = 'cloture',
    est_ouvert = FALSE,
    est_cloture = TRUE,
    cloture_par = auth.uid(),
    cloture_at = NOW(),
    closing_entry_id = v_closing_entry_id,
    opening_entry_id = v_opening_entry_id
  WHERE id = p_exercice_id;

  -- Logger
  PERFORM log_audit_action('CLOTURE'::action_audit, 'exercices_comptables', p_exercice_id, NULL, to_jsonb(v_exercice));

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION open_exercice(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_exercice_ouvert(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_post_in_exercice(UUID, DATE) TO authenticated;

-- ============================================================================
-- SPRINT B : ÉTATS FINANCIERS SYCEBNL
-- ============================================================================

-- ============================================================================
-- RPC : Balance générale
-- ============================================================================

CREATE OR REPLACE FUNCTION report_balance_generale(
  p_org_id UUID,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  compte_id UUID,
  numero TEXT,
  intitule TEXT,
  nature TEXT,
  niveau INTEGER,
  total_debit DECIMAL(15,2),
  total_credit DECIMAL(15,2),
  solde_debiteur DECIMAL(15,2),
  solde_crediteur DECIMAL(15,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.numero,
    c.intitule,
    c.nature::TEXT,
    c.niveau,
    COALESCE(SUM(l.debit), 0)::DECIMAL(15,2) AS total_debit,
    COALESCE(SUM(l.credit), 0)::DECIMAL(15,2) AS total_credit,
    CASE
      WHEN COALESCE(SUM(l.debit), 0) > COALESCE(SUM(l.credit), 0)
      THEN (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2)
      ELSE 0::DECIMAL(15,2)
    END AS solde_debiteur,
    CASE
      WHEN COALESCE(SUM(l.credit), 0) > COALESCE(SUM(l.debit), 0)
      THEN (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2)
      ELSE 0::DECIMAL(15,2)
    END AS solde_crediteur
  FROM comptes_comptables c
  LEFT JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  LEFT JOIN ecritures_comptables e ON e.id = l.id_ecriture
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
  WHERE c.organization_id = p_org_id
    AND c.actif = TRUE
  GROUP BY c.id, c.numero, c.intitule, c.nature, c.niveau
  HAVING COALESCE(SUM(l.debit), 0) != 0 OR COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- RPC : Compte de résultat (Produits - Charges, SYCEBNL)
-- ============================================================================

CREATE OR REPLACE FUNCTION report_compte_resultat(
  p_org_id UUID,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  section TEXT,
  compte_id UUID,
  numero TEXT,
  intitule TEXT,
  montant DECIMAL(15,2)
) AS $$
BEGIN
  -- Produits (classe 7)
  RETURN QUERY
  SELECT
    'produits'::TEXT AS section,
    c.id,
    c.numero,
    c.intitule,
    (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2) AS montant
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.nature = 'produit'
    AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;

  -- Charges (classe 6)
  RETURN QUERY
  SELECT
    'charges'::TEXT AS section,
    c.id,
    c.numero,
    c.intitule,
    (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2) AS montant
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.nature = 'charge'
    AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- RPC : Bilan simplifié (SYCEBNL)
-- ============================================================================

CREATE OR REPLACE FUNCTION report_bilan(
  p_org_id UUID,
  p_date_fin DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  section TEXT,
  sous_section TEXT,
  compte_id UUID,
  numero TEXT,
  intitule TEXT,
  solde DECIMAL(15,2)
) AS $$
BEGIN
  -- ACTIF - Immobilisations (classe 2)
  RETURN QUERY
  SELECT
    'actif'::TEXT, 'immobilisations'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero LIKE '2%' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;

  -- ACTIF - Actif circulant (classes 3, 4 actif, 5)
  RETURN QUERY
  SELECT
    'actif'::TEXT, 'circulant'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero ~ '^[345]' AND c.nature = 'actif' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;

  -- PASSIF - Fonds propres (classe 1)
  RETURN QUERY
  SELECT
    'passif'::TEXT, 'fonds_propres'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero LIKE '1%' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;

  -- PASSIF - Dettes (classe 4 passif)
  RETURN QUERY
  SELECT
    'passif'::TEXT, 'dettes'::TEXT,
    c.id, c.numero, c.intitule,
    (COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0))::DECIMAL(15,2)
  FROM comptes_comptables c
  JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  WHERE c.organization_id = p_org_id
    AND c.numero LIKE '4%' AND c.nature = 'passif' AND c.actif = TRUE
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    AND e.date <= p_date_fin
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- RPC : Grand livre (mouvements par compte)
-- ============================================================================

CREATE OR REPLACE FUNCTION report_grand_livre(
  p_org_id UUID,
  p_compte_id UUID DEFAULT NULL,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  compte_numero TEXT,
  compte_intitule TEXT,
  ecriture_date DATE,
  ecriture_libelle TEXT,
  reference_piece TEXT,
  journal_code TEXT,
  ligne_libelle TEXT,
  debit DECIMAL(15,2),
  credit DECIMAL(15,2),
  solde_cumule DECIMAL(15,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.numero,
    c.intitule,
    e.date,
    e.libelle,
    e.reference_piece,
    j.code,
    l.libelle,
    COALESCE(l.debit, 0)::DECIMAL(15,2),
    COALESCE(l.credit, 0)::DECIMAL(15,2),
    SUM(COALESCE(l.debit, 0) - COALESCE(l.credit, 0))
      OVER (PARTITION BY c.id ORDER BY e.date, e.id ROWS UNBOUNDED PRECEDING)::DECIMAL(15,2) AS solde_cumule
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  JOIN journaux_comptables j ON j.id = e.id_journal
  WHERE c.organization_id = p_org_id
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_compte_id IS NULL OR c.id = p_compte_id)
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
  ORDER BY c.numero, e.date, e.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- GRANTS Sprint B
GRANT EXECUTE ON FUNCTION report_balance_generale(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION report_compte_resultat(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION report_bilan(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION report_grand_livre(UUID, UUID, DATE, DATE) TO authenticated;

-- ============================================================================
-- SPRINT C : RECHERCHE GLOBALE
-- ============================================================================

CREATE OR REPLACE FUNCTION global_search(
  p_org_id UUID,
  p_query TEXT,
  p_limit INTEGER DEFAULT 30
)
RETURNS TABLE (
  category TEXT,
  record_id UUID,
  title TEXT,
  subtitle TEXT,
  route TEXT,
  relevance REAL
) AS $$
DECLARE
  v_pattern TEXT;
BEGIN
  -- E) Protection : requête trop courte → aucun résultat
  IF LENGTH(TRIM(p_query)) < 2 THEN
    RETURN;
  END IF;

  -- Limiter à 50 max pour éviter abus
  IF p_limit > 50 THEN
    p_limit := 50;
  END IF;

  v_pattern := '%' || LOWER(TRIM(p_query)) || '%';

  -- Membres
  RETURN QUERY
  SELECT
    'membre'::TEXT,
    m.id,
    m.full_name,
    COALESCE(m.phone, m.email, m.role::TEXT),
    '/members'::TEXT,
    CASE
      WHEN LOWER(m.full_name) = LOWER(p_query) THEN 1.0
      WHEN LOWER(m.full_name) LIKE v_pattern THEN 0.8
      ELSE similarity(m.full_name, p_query)
    END::REAL
  FROM membres m
  WHERE m.organization_id = p_org_id
    AND m.deleted_at IS NULL
    AND (
      LOWER(m.full_name) LIKE v_pattern
      OR LOWER(m.phone) LIKE v_pattern
      OR LOWER(m.email) LIKE v_pattern
      OR similarity(m.full_name, p_query) > 0.3
    )
  ORDER BY relevance DESC
  LIMIT p_limit;

  -- Programmes
  RETURN QUERY
  SELECT
    'programme'::TEXT,
    p.id,
    p.type::TEXT || ' — ' || TO_CHAR(p.date, 'DD/MM/YYYY'),
    COALESCE(p.description, p.location),
    '/programs'::TEXT,
    CASE
      WHEN LOWER(p.description) LIKE v_pattern THEN 0.7
      WHEN LOWER(p.location) LIKE v_pattern THEN 0.6
      ELSE 0.4
    END::REAL
  FROM programmes p
  WHERE p.organization_id = p_org_id
    AND p.deleted_at IS NULL
    AND (
      LOWER(p.description) LIKE v_pattern
      OR LOWER(p.location) LIKE v_pattern
      OR p.type::TEXT ILIKE v_pattern
    )
  ORDER BY relevance DESC
  LIMIT p_limit;

  -- Écritures comptables
  RETURN QUERY
  SELECT
    'ecriture'::TEXT,
    ec.id,
    ec.libelle,
    COALESCE(ec.reference_piece, '') || ' — ' || TO_CHAR(ec.date, 'DD/MM/YYYY'),
    '/accounting'::TEXT,
    CASE
      WHEN LOWER(ec.libelle) LIKE v_pattern THEN 0.7
      WHEN LOWER(ec.reference_piece) LIKE v_pattern THEN 0.8
      ELSE 0.4
    END::REAL
  FROM ecritures_comptables ec
  WHERE ec.organization_id = p_org_id
    AND ec.deleted_at IS NULL
    AND (
      LOWER(ec.libelle) LIKE v_pattern
      OR LOWER(ec.reference_piece) LIKE v_pattern
    )
  ORDER BY relevance DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- GRANTS Sprint C
GRANT EXECUTE ON FUNCTION global_search(UUID, TEXT, INTEGER) TO authenticated;



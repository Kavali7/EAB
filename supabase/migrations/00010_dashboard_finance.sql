-- ============================================================================
-- H4 — Dashboard financier avancé
-- ============================================================================
-- 3 RPCs pour alimenter le dashboard financier côté Flutter :
-- 1. dashboard_finance_kpis : trésorerie, résultat, variation
-- 2. dashboard_finance_evolution : 12 mois produits/charges/solde
-- 3. dashboard_finance_repartition : camembert produits + charges
-- ============================================================================

-- ════════════════════════════════════════════════════════════════
-- 1. KPIs financiers
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION dashboard_finance_kpis(p_org_id UUID)
RETURNS TABLE (
  tresorerie_actuelle DECIMAL(15,2),
  resultat_exercice DECIMAL(15,2),
  total_produits DECIMAL(15,2),
  total_charges DECIMAL(15,2),
  resultat_mois_precedent DECIMAL(15,2),
  nb_ecritures_mois INTEGER
) AS $$
DECLARE
  v_debut_mois DATE;
  v_fin_mois DATE;
  v_debut_mois_prec DATE;
  v_fin_mois_prec DATE;
BEGIN
  v_debut_mois := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  v_fin_mois := (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE;
  v_debut_mois_prec := (v_debut_mois - INTERVAL '1 month')::DATE;
  v_fin_mois_prec := (v_debut_mois - INTERVAL '1 day')::DATE;

  RETURN QUERY
  SELECT
    -- Trésorerie : solde classe 5
    COALESCE((
      SELECT SUM(
        CASE WHEN c.nature = 'actif' THEN l.debit - l.credit
             ELSE l.credit - l.debit END
      )
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id
        AND c.numero LIKE '5%' AND c.actif = TRUE
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2),

    -- Résultat exercice courant (produits - charges)
    COALESCE((
      SELECT SUM(CASE WHEN c.nature = 'produit' THEN l.credit - l.debit
                      WHEN c.nature = 'charge' THEN -(l.debit - l.credit)
                      ELSE 0 END)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id
        AND c.nature IN ('produit', 'charge') AND c.actif = TRUE
        AND e.date >= v_debut_mois AND e.date <= v_fin_mois
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2),

    -- Total produits mois
    COALESCE((
      SELECT SUM(l.credit - l.debit)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id
        AND c.nature = 'produit' AND c.actif = TRUE
        AND e.date >= v_debut_mois AND e.date <= v_fin_mois
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2),

    -- Total charges mois
    COALESCE((
      SELECT SUM(l.debit - l.credit)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id
        AND c.nature = 'charge' AND c.actif = TRUE
        AND e.date >= v_debut_mois AND e.date <= v_fin_mois
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2),

    -- Résultat mois précédent (pour variation)
    COALESCE((
      SELECT SUM(CASE WHEN c.nature = 'produit' THEN l.credit - l.debit
                      WHEN c.nature = 'charge' THEN -(l.debit - l.credit)
                      ELSE 0 END)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id
        AND c.nature IN ('produit', 'charge') AND c.actif = TRUE
        AND e.date >= v_debut_mois_prec AND e.date <= v_fin_mois_prec
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2),

    -- Nombre d'écritures du mois
    COALESCE((
      SELECT COUNT(*)::INTEGER
      FROM ecritures_comptables e
      WHERE e.organization_id = p_org_id
        AND e.date >= v_debut_mois AND e.date <= v_fin_mois
        AND e.deleted_at IS NULL
    ), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════════════════
-- 2. Évolution mensuelle (12 derniers mois)
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION dashboard_finance_evolution(
  p_org_id UUID,
  p_nb_mois INTEGER DEFAULT 12
)
RETURNS TABLE (
  mois DATE,
  label_mois TEXT,
  produits DECIMAL(15,2),
  charges DECIMAL(15,2),
  solde_net DECIMAL(15,2)
) AS $$
BEGIN
  RETURN QUERY
  WITH mois_range AS (
    SELECT generate_series(
      DATE_TRUNC('month', CURRENT_DATE) - (p_nb_mois - 1) * INTERVAL '1 month',
      DATE_TRUNC('month', CURRENT_DATE),
      INTERVAL '1 month'
    )::DATE AS mois_debut
  )
  SELECT
    mr.mois_debut,
    TO_CHAR(mr.mois_debut, 'Mon YYYY') AS label_mois,
    COALESCE((
      SELECT SUM(l.credit - l.debit)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id AND c.nature = 'produit' AND c.actif = TRUE
        AND e.date >= mr.mois_debut
        AND e.date < mr.mois_debut + INTERVAL '1 month'
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2) AS produits,
    COALESCE((
      SELECT SUM(l.debit - l.credit)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id AND c.nature = 'charge' AND c.actif = TRUE
        AND e.date >= mr.mois_debut
        AND e.date < mr.mois_debut + INTERVAL '1 month'
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0)::DECIMAL(15,2) AS charges,
    (COALESCE((
      SELECT SUM(l.credit - l.debit)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id AND c.nature = 'produit' AND c.actif = TRUE
        AND e.date >= mr.mois_debut AND e.date < mr.mois_debut + INTERVAL '1 month'
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0) - COALESCE((
      SELECT SUM(l.debit - l.credit)
      FROM lignes_ecritures l
      JOIN ecritures_comptables e ON e.id = l.id_ecriture
      JOIN comptes_comptables c ON c.id = l.id_compte_comptable
      WHERE c.organization_id = p_org_id AND c.nature = 'charge' AND c.actif = TRUE
        AND e.date >= mr.mois_debut AND e.date < mr.mois_debut + INTERVAL '1 month'
        AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
    ), 0))::DECIMAL(15,2) AS solde_net
  FROM mois_range mr
  ORDER BY mr.mois_debut;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════════════════
-- 3. Répartition par catégorie (camemberts)
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION dashboard_finance_repartition(
  p_org_id UUID,
  p_date_debut DATE DEFAULT NULL,
  p_date_fin DATE DEFAULT NULL
)
RETURNS TABLE (
  section TEXT,
  compte_numero TEXT,
  compte_intitule TEXT,
  montant DECIMAL(15,2),
  pourcentage DECIMAL(5,2)
) AS $$
DECLARE
  v_date_debut DATE;
  v_date_fin DATE;
  v_total_produits DECIMAL(15,2);
  v_total_charges DECIMAL(15,2);
BEGIN
  v_date_debut := COALESCE(p_date_debut, DATE_TRUNC('year', CURRENT_DATE)::DATE);
  v_date_fin := COALESCE(p_date_fin, CURRENT_DATE);

  -- Calculer les totaux pour les pourcentages
  SELECT COALESCE(SUM(l.credit - l.debit), 0) INTO v_total_produits
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  WHERE c.organization_id = p_org_id AND c.nature = 'produit' AND c.actif = TRUE
    AND e.date >= v_date_debut AND e.date <= v_date_fin
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL;

  SELECT COALESCE(SUM(l.debit - l.credit), 0) INTO v_total_charges
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  WHERE c.organization_id = p_org_id AND c.nature = 'charge' AND c.actif = TRUE
    AND e.date >= v_date_debut AND e.date <= v_date_fin
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL;

  -- Produits par sous-compte (niveau 2 : 70, 71, 72...)
  RETURN QUERY
  SELECT
    'produits'::TEXT,
    LEFT(c.numero, 2),
    MIN(c.intitule),
    SUM(l.credit - l.debit)::DECIMAL(15,2),
    CASE WHEN v_total_produits > 0
         THEN (SUM(l.credit - l.debit) / v_total_produits * 100)::DECIMAL(5,2)
         ELSE 0::DECIMAL(5,2) END
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  WHERE c.organization_id = p_org_id AND c.nature = 'produit' AND c.actif = TRUE
    AND e.date >= v_date_debut AND e.date <= v_date_fin
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
  GROUP BY LEFT(c.numero, 2)
  HAVING SUM(l.credit - l.debit) > 0
  ORDER BY SUM(l.credit - l.debit) DESC;

  -- Charges par sous-compte (niveau 2 : 60, 61, 62...)
  RETURN QUERY
  SELECT
    'charges'::TEXT,
    LEFT(c.numero, 2),
    MIN(c.intitule),
    SUM(l.debit - l.credit)::DECIMAL(15,2),
    CASE WHEN v_total_charges > 0
         THEN (SUM(l.debit - l.credit) / v_total_charges * 100)::DECIMAL(5,2)
         ELSE 0::DECIMAL(5,2) END
  FROM lignes_ecritures l
  JOIN ecritures_comptables e ON e.id = l.id_ecriture
  JOIN comptes_comptables c ON c.id = l.id_compte_comptable
  WHERE c.organization_id = p_org_id AND c.nature = 'charge' AND c.actif = TRUE
    AND e.date >= v_date_debut AND e.date <= v_date_fin
    AND e.statut IN ('validee', 'cloturee') AND e.deleted_at IS NULL
  GROUP BY LEFT(c.numero, 2)
  HAVING SUM(l.debit - l.credit) > 0
  ORDER BY SUM(l.debit - l.credit) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════════════════
-- GRANTS
-- ════════════════════════════════════════════════════════════════

GRANT EXECUTE ON FUNCTION dashboard_finance_kpis(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION dashboard_finance_evolution(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION dashboard_finance_repartition(UUID, DATE, DATE) TO authenticated;

-- DONE ✅

-- ============================================================================
-- Active church-unit scope for financial statement reports
-- ============================================================================
-- Adds scoped report RPCs used by the frontend when a hierarchy context is
-- selected. Existing report_* functions are kept intact for compatibility.

CREATE OR REPLACE FUNCTION financial_statement_scope_contains_entry(
  p_requested_church_unit_id UUID,
  p_entry_church_unit_id UUID,
  p_entry_assemblee_id UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  WITH entry_scope AS (
    SELECT COALESCE(
      p_entry_church_unit_id,
      (
        SELECT cu.id
        FROM church_units cu
        WHERE cu.organization_id = get_user_organization_id()
          AND cu.legacy_assemblee_id = p_entry_assemblee_id
        LIMIT 1
      )
    ) AS unit_id
  )
  SELECT
    p_requested_church_unit_id IS NULL
    OR EXISTS (
      SELECT 1
      FROM church_units requested
      CROSS JOIN entry_scope entry
      WHERE requested.id = p_requested_church_unit_id
        AND requested.organization_id = get_user_organization_id()
        AND entry.unit_id IS NOT NULL
        AND fiscal_scope_contains_unit(requested.id, entry.unit_id)
    );
$$;

CREATE OR REPLACE FUNCTION report_balance_generale_scoped(
  p_org_id UUID,
  p_church_unit_id UUID DEFAULT NULL,
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
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  IF p_church_unit_id IS NOT NULL
     AND NOT user_can_access_financial_statements_scope(
       p_church_unit_id,
       NULL,
       'view_details'
     ) THEN
    RAISE EXCEPTION 'Acces refuse : perimetre financier non autorise.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.numero,
    c.intitule,
    c.nature::TEXT,
    c.niveau,
    COALESCE(SUM(
      CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END
    ), 0)::DECIMAL(15,2) AS total_debit,
    COALESCE(SUM(
      CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END
    ), 0)::DECIMAL(15,2) AS total_credit,
    CASE
      WHEN COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
        > COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
      THEN (
        COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
      )::DECIMAL(15,2)
      ELSE 0::DECIMAL(15,2)
    END AS solde_debiteur,
    CASE
      WHEN COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
        > COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
      THEN (
        COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0)
      )::DECIMAL(15,2)
      ELSE 0::DECIMAL(15,2)
    END AS solde_crediteur
  FROM comptes_comptables c
  LEFT JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
  LEFT JOIN ecritures_comptables e ON e.id = l.id_ecriture
    AND e.statut IN ('validee', 'cloturee')
    AND e.deleted_at IS NULL
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin)
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  WHERE c.organization_id = p_org_id
    AND c.actif = TRUE
  GROUP BY c.id, c.numero, c.intitule, c.nature, c.niveau
  HAVING
    COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.debit ELSE 0 END), 0) != 0
    OR COALESCE(SUM(CASE WHEN e.id IS NOT NULL THEN l.credit ELSE 0 END), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION report_compte_resultat_scoped(
  p_org_id UUID,
  p_church_unit_id UUID DEFAULT NULL,
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
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  IF p_church_unit_id IS NOT NULL
     AND NOT user_can_access_financial_statements_scope(
       p_church_unit_id,
       NULL,
       'view_details'
     ) THEN
    RAISE EXCEPTION 'Acces refuse : perimetre financier non autorise.'
      USING ERRCODE = '42501';
  END IF;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION report_bilan_scoped(
  p_org_id UUID,
  p_church_unit_id UUID DEFAULT NULL,
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
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  IF p_church_unit_id IS NOT NULL
     AND NOT user_can_access_financial_statements_scope(
       p_church_unit_id,
       NULL,
       'view_details'
     ) THEN
    RAISE EXCEPTION 'Acces refuse : perimetre financier non autorise.'
      USING ERRCODE = '42501';
  END IF;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) != 0
  ORDER BY c.numero;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  GROUP BY c.id, c.numero, c.intitule
  HAVING COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0) != 0
  ORDER BY c.numero;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION report_grand_livre_scoped(
  p_org_id UUID,
  p_church_unit_id UUID DEFAULT NULL,
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
  IF p_org_id IS DISTINCT FROM get_user_organization_id() THEN
    RAISE EXCEPTION 'Acces refuse : organisation non autorisee.'
      USING ERRCODE = '42501';
  END IF;

  IF p_church_unit_id IS NOT NULL
     AND NOT user_can_access_financial_statements_scope(
       p_church_unit_id,
       NULL,
       'view_details'
     ) THEN
    RAISE EXCEPTION 'Acces refuse : perimetre financier non autorise.'
      USING ERRCODE = '42501';
  END IF;

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
    AND user_can_access_financial_statements_scope(
      e.church_unit_id,
      e.id_assemblee_locale,
      'view_details'
    )
    AND financial_statement_scope_contains_entry(
      p_church_unit_id,
      e.church_unit_id,
      e.id_assemblee_locale
    )
  ORDER BY c.numero, e.date, e.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

REVOKE ALL ON FUNCTION financial_statement_scope_contains_entry(UUID, UUID, UUID)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION report_balance_generale_scoped(UUID, UUID, DATE, DATE)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION report_compte_resultat_scoped(UUID, UUID, DATE, DATE)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION report_bilan_scoped(UUID, UUID, DATE)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION report_grand_livre_scoped(UUID, UUID, UUID, DATE, DATE)
  FROM PUBLIC;

GRANT EXECUTE ON FUNCTION financial_statement_scope_contains_entry(UUID, UUID, UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_balance_generale_scoped(UUID, UUID, DATE, DATE)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_compte_resultat_scoped(UUID, UUID, DATE, DATE)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_bilan_scoped(UUID, UUID, DATE)
  TO authenticated;
GRANT EXECUTE ON FUNCTION report_grand_livre_scoped(UUID, UUID, UUID, DATE, DATE)
  TO authenticated;

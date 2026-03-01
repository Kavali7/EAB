-- ============================================================================
-- PATCH — Ajustements post-revue A/C/E
-- À exécuter dans la console Supabase SQL Editor
-- ============================================================================
-- A) Compte résultat : 12x prioritaire, 131x fallback
-- C) Org membership check dans open_exercice + cloturer_exercice
-- E) global_search : min 2 chars, LIMIT 30, cap 50
-- ============================================================================

-- ════════════════════════════════════════════════════════════════
-- 1. open_exercice — ajout vérification org membership
-- ════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════
-- 2. cloturer_exercice — compte 12x prioritaire + org membership
-- ════════════════════════════════════════════════════════════════

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

  -- A) Trouver le compte de résultat — priorité OHADA : 12x
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
  -- ÉCRITURE DE RÉSULTAT (solde classes 6 et 7 → compte 12x/131x)
  -- ══════════════════════════════════════════════════════════════

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
      AND c.numero ~ '^[1-5]'
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

  UPDATE ecritures_comptables
  SET statut = 'cloturee'
  WHERE organization_id = v_exercice.organization_id
    AND date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
    AND statut = 'validee'
    AND deleted_at IS NULL;

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

  PERFORM log_audit_action('CLOTURE'::action_audit, 'exercices_comptables', p_exercice_id, NULL, to_jsonb(v_exercice));

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ════════════════════════════════════════════════════════════════
-- 3. global_search — min 2 chars + LIMIT 30 + cap 50
-- ════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════
-- DONE ✅
-- ════════════════════════════════════════════════════════════════

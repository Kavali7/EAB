-- ============================================================================
-- EAB Backend - 00017 Fix user_id references in RPCs
-- ============================================================================
-- Corrige le bug: les RPCs open_exercice() et cloturer_exercice() référencent
-- m.user_id sur la table membres, mais cette colonne n'existe pas.
-- L'authentification passe par profiles.id = auth.uid().
-- ============================================================================

-- ============================================================================
-- FIX: open_exercice - remplacer membres.user_id par profiles.id
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

  -- Vérifier que l'exercice appartient à l'org de l'utilisateur
  IF NOT EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
      AND p.organization_id = v_exercice.organization_id
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
-- FIX: cloturer_exercice - remplacer membres.user_id par profiles.id
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

  -- Vérifier que l'exercice appartient à l'org de l'utilisateur (FIX: profiles au lieu de membres)
  IF NOT EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
      AND p.organization_id = v_exercice.organization_id
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

  -- Trouver le compte de résultat (12x ou 131x)
  SELECT id INTO v_compte_resultat_id
  FROM comptes_comptables
  WHERE organization_id = v_exercice.organization_id
    AND numero LIKE '12%'
    AND actif = TRUE
  ORDER BY numero
  LIMIT 1;

  IF v_compte_resultat_id IS NULL THEN
    SELECT id INTO v_compte_resultat_id
    FROM comptes_comptables
    WHERE organization_id = v_exercice.organization_id
      AND numero LIKE '131%'
      AND actif = TRUE
    LIMIT 1;
  END IF;

  IF v_compte_resultat_id IS NULL THEN
    RAISE EXCEPTION 'Compte de résultat (12x ou 131x) non trouvé dans le plan comptable.';
  END IF;

  -- ══════════════════════════════════════════════════════════════
  -- ÉCRITURE DE RÉSULTAT
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
    VALUES (v_closing_entry_id, v_compte.compte_id, 0, ABS(v_compte.solde), 'Solde charge ' || v_compte.numero);
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
    VALUES (v_closing_entry_id, v_compte.compte_id, ABS(v_compte.solde), 0, 'Solde produit ' || v_compte.numero);
  END LOOP;

  IF v_resultat >= 0 THEN
    INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
    VALUES (v_closing_entry_id, v_compte_resultat_id, 0, v_resultat, 'Résultat net exercice ' || v_exercice.annee);
  ELSE
    INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
    VALUES (v_closing_entry_id, v_compte_resultat_id, ABS(v_resultat), 0, 'Perte nette exercice ' || v_exercice.annee);
  END IF;

  -- ══════════════════════════════════════════════════════════════
  -- ÉCRITURE D'À-NOUVEAUX
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
      VALUES (v_opening_entry_id, v_compte.compte_id, ABS(v_compte.solde), 0, 'AN ' || v_compte.numero);
    ELSE
      INSERT INTO lignes_ecritures (id_ecriture, id_compte_comptable, debit, credit, libelle)
      VALUES (v_opening_entry_id, v_compte.compte_id, 0, ABS(v_compte.solde), 'AN ' || v_compte.numero);
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

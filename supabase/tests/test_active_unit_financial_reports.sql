-- ============================================================================
-- Test E2E DB - Active church-unit scope for financial reports
-- ============================================================================
-- Objectif :
--   1. Creer un parent et deux unites enfants temporaires.
--   2. Creer une ecriture validee distincte dans chaque enfant.
--   3. Verifier que les RPC *_scoped filtrent bien par unite active.
--   4. Nettoyer toutes les donnees de test avant COMMIT.
-- ============================================================================

DROP TABLE IF EXISTS _active_unit_financial_reports_test_result;
CREATE TEMP TABLE _active_unit_financial_reports_test_result (
  sort_order INTEGER,
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
) ON COMMIT PRESERVE ROWS;

BEGIN;

DO $$
DECLARE
  v_admin_id UUID;
  v_org_id UUID;
  v_suffix TEXT := lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_parent_type_id UUID := gen_random_uuid();
  v_child_type_id UUID := gen_random_uuid();
  v_parent_unit_id UUID := gen_random_uuid();
  v_child_unit_id UUID := gen_random_uuid();
  v_sibling_unit_id UUID := gen_random_uuid();
  v_journal_id UUID := gen_random_uuid();
  v_child_cash_account_id UUID := gen_random_uuid();
  v_child_revenue_account_id UUID := gen_random_uuid();
  v_sibling_cash_account_id UUID := gen_random_uuid();
  v_sibling_revenue_account_id UUID := gen_random_uuid();
  v_child_entry_id UUID := gen_random_uuid();
  v_sibling_entry_id UUID := gen_random_uuid();
  v_child_line_debit_id UUID := gen_random_uuid();
  v_child_line_credit_id UUID := gen_random_uuid();
  v_sibling_line_debit_id UUID := gen_random_uuid();
  v_sibling_line_credit_id UUID := gen_random_uuid();
  v_child_balance_has_child BOOLEAN;
  v_child_balance_has_sibling BOOLEAN;
  v_parent_balance_has_child BOOLEAN;
  v_parent_balance_has_sibling BOOLEAN;
  v_child_resultat_amount DECIMAL(15,2);
  v_child_resultat_has_sibling BOOLEAN;
  v_child_bilan_has_cash BOOLEAN;
  v_child_bilan_has_sibling_cash BOOLEAN;
  v_child_grand_livre_lines INTEGER;
  v_sibling_grand_livre_lines INTEGER;
BEGIN
  SELECT p.id, p.organization_id
  INTO v_admin_id, v_org_id
  FROM profiles p
  WHERE p.role = 'admin_national'
    AND p.organization_id IS NOT NULL
  ORDER BY p.created_at
  LIMIT 1;

  IF v_admin_id IS NULL OR v_org_id IS NULL THEN
    RAISE EXCEPTION 'Aucun profil admin_national avec organisation_id trouve.';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);

  INSERT INTO church_unit_types (
    id,
    organization_id,
    code,
    label,
    level_order,
    is_local,
    is_financial_scope,
    can_have_members,
    can_have_cash_accounts,
    can_have_bank_accounts,
    can_have_mobile_money_accounts,
    can_create_programs,
    can_launch_contributions,
    can_validate_finances,
    can_consolidate_finances,
    can_notify_descendants,
    can_view_descendants
  )
  VALUES
  (
    v_parent_type_id,
    v_org_id,
    'codex_report_parent_' || v_suffix,
    'Niveau parent test rapports',
    160,
    FALSE,
    TRUE,
    FALSE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    TRUE
  ),
  (
    v_child_type_id,
    v_org_id,
    'codex_report_child_' || v_suffix,
    'Niveau enfant test rapports',
    161,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE,
    FALSE,
    TRUE
  );

  INSERT INTO church_units (
    id,
    organization_id,
    type_id,
    parent_id,
    nom,
    code,
    metadata
  )
  VALUES
  (
    v_parent_unit_id,
    v_org_id,
    v_parent_type_id,
    NULL,
    'Parent rapports scoped',
    'TRPT-PARENT-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  ),
  (
    v_child_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Enfant rapports scoped',
    'TRPT-CHILD-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  ),
  (
    v_sibling_unit_id,
    v_org_id,
    v_child_type_id,
    v_parent_unit_id,
    'Voisin rapports scoped',
    'TRPT-SIBLING-' || upper(v_suffix),
    jsonb_build_object('created_by_test', TRUE)
  );

  INSERT INTO journaux_comptables (
    id,
    organization_id,
    code,
    intitule,
    type
  )
  VALUES (
    v_journal_id,
    v_org_id,
    'TRP' || upper(substr(v_suffix, 1, 6)),
    'Journal test rapports scoped',
    'operations_diverses'
  );

  INSERT INTO comptes_comptables (
    id,
    organization_id,
    numero,
    intitule,
    nature,
    niveau
  )
  VALUES
  (
    v_child_cash_account_id,
    v_org_id,
    '571' || substr(v_suffix, 1, 4),
    'Caisse enfant test scoped',
    'actif',
    2
  ),
  (
    v_child_revenue_account_id,
    v_org_id,
    '701' || substr(v_suffix, 1, 4),
    'Produit enfant test scoped',
    'produit',
    2
  ),
  (
    v_sibling_cash_account_id,
    v_org_id,
    '572' || substr(v_suffix, 1, 4),
    'Caisse voisin test scoped',
    'actif',
    2
  ),
  (
    v_sibling_revenue_account_id,
    v_org_id,
    '702' || substr(v_suffix, 1, 4),
    'Produit voisin test scoped',
    'produit',
    2
  );

  INSERT INTO ecritures_comptables (
    id,
    organization_id,
    church_unit_id,
    id_journal,
    date,
    reference_piece,
    libelle,
    statut,
    created_by
  )
  VALUES
  (
    v_child_entry_id,
    v_org_id,
    v_child_unit_id,
    v_journal_id,
    CURRENT_DATE,
    'TEST-RPT-CHILD-' || upper(v_suffix),
    'Ecriture enfant test rapports scoped',
    'validee',
    v_admin_id
  ),
  (
    v_sibling_entry_id,
    v_org_id,
    v_sibling_unit_id,
    v_journal_id,
    CURRENT_DATE,
    'TEST-RPT-SIBLING-' || upper(v_suffix),
    'Ecriture voisin test rapports scoped',
    'validee',
    v_admin_id
  );

  INSERT INTO lignes_ecritures (
    id,
    id_ecriture,
    id_compte_comptable,
    libelle,
    debit,
    credit,
    mode_paiement
  )
  VALUES
  (
    v_child_line_debit_id,
    v_child_entry_id,
    v_child_cash_account_id,
    'Debit enfant scoped',
    100000,
    0,
    'especes'
  ),
  (
    v_child_line_credit_id,
    v_child_entry_id,
    v_child_revenue_account_id,
    'Credit enfant scoped',
    0,
    100000,
    'especes'
  ),
  (
    v_sibling_line_debit_id,
    v_sibling_entry_id,
    v_sibling_cash_account_id,
    'Debit voisin scoped',
    50000,
    0,
    'especes'
  ),
  (
    v_sibling_line_credit_id,
    v_sibling_entry_id,
    v_sibling_revenue_account_id,
    'Credit voisin scoped',
    0,
    50000,
    'especes'
  );

  SELECT EXISTS (
    SELECT 1
    FROM report_balance_generale_scoped(
      v_org_id,
      v_child_unit_id,
      CURRENT_DATE,
      CURRENT_DATE
    ) r
    WHERE r.compte_id = v_child_cash_account_id
  )
  INTO v_child_balance_has_child;

  SELECT EXISTS (
    SELECT 1
    FROM report_balance_generale_scoped(
      v_org_id,
      v_child_unit_id,
      CURRENT_DATE,
      CURRENT_DATE
    ) r
    WHERE r.compte_id = v_sibling_cash_account_id
  )
  INTO v_child_balance_has_sibling;

  SELECT EXISTS (
    SELECT 1
    FROM report_balance_generale_scoped(
      v_org_id,
      v_parent_unit_id,
      CURRENT_DATE,
      CURRENT_DATE
    ) r
    WHERE r.compte_id = v_child_cash_account_id
  )
  INTO v_parent_balance_has_child;

  SELECT EXISTS (
    SELECT 1
    FROM report_balance_generale_scoped(
      v_org_id,
      v_parent_unit_id,
      CURRENT_DATE,
      CURRENT_DATE
    ) r
    WHERE r.compte_id = v_sibling_cash_account_id
  )
  INTO v_parent_balance_has_sibling;

  SELECT COALESCE(SUM(r.montant), 0)
  INTO v_child_resultat_amount
  FROM report_compte_resultat_scoped(
    v_org_id,
    v_child_unit_id,
    CURRENT_DATE,
    CURRENT_DATE
  ) r
  WHERE r.compte_id = v_child_revenue_account_id;

  SELECT EXISTS (
    SELECT 1
    FROM report_compte_resultat_scoped(
      v_org_id,
      v_child_unit_id,
      CURRENT_DATE,
      CURRENT_DATE
    ) r
    WHERE r.compte_id = v_sibling_revenue_account_id
  )
  INTO v_child_resultat_has_sibling;

  SELECT EXISTS (
    SELECT 1
    FROM report_bilan_scoped(v_org_id, v_child_unit_id, CURRENT_DATE) r
    WHERE r.compte_id = v_child_cash_account_id
  )
  INTO v_child_bilan_has_cash;

  SELECT EXISTS (
    SELECT 1
    FROM report_bilan_scoped(v_org_id, v_child_unit_id, CURRENT_DATE) r
    WHERE r.compte_id = v_sibling_cash_account_id
  )
  INTO v_child_bilan_has_sibling_cash;

  SELECT COUNT(*)
  INTO v_child_grand_livre_lines
  FROM report_grand_livre_scoped(
    v_org_id,
    v_child_unit_id,
    NULL,
    CURRENT_DATE,
    CURRENT_DATE
  );

  SELECT COUNT(*)
  INTO v_sibling_grand_livre_lines
  FROM report_grand_livre_scoped(
    v_org_id,
    v_sibling_unit_id,
    NULL,
    CURRENT_DATE,
    CURRENT_DATE
  );

  INSERT INTO _active_unit_financial_reports_test_result VALUES
    (
      1,
      'balance_enfant_inclut_son_ecriture',
      v_child_balance_has_child = TRUE,
      'child_balance_has_child=' ||
        COALESCE(v_child_balance_has_child::text, 'NULL')
    ),
    (
      2,
      'balance_enfant_exclut_voisin',
      v_child_balance_has_sibling = FALSE,
      'child_balance_has_sibling=' ||
        COALESCE(v_child_balance_has_sibling::text, 'NULL')
    ),
    (
      3,
      'balance_parent_consolide_descendants',
      v_parent_balance_has_child = TRUE
        AND v_parent_balance_has_sibling = TRUE,
      'parent_child=' || COALESCE(v_parent_balance_has_child::text, 'NULL') ||
        ', parent_sibling=' ||
        COALESCE(v_parent_balance_has_sibling::text, 'NULL')
    ),
    (
      4,
      'resultat_enfant_filtre',
      v_child_resultat_amount = 100000
        AND v_child_resultat_has_sibling = FALSE,
      'child_resultat=' || COALESCE(v_child_resultat_amount::text, 'NULL') ||
        ', sibling_visible=' ||
        COALESCE(v_child_resultat_has_sibling::text, 'NULL')
    ),
    (
      5,
      'bilan_enfant_filtre',
      v_child_bilan_has_cash = TRUE
        AND v_child_bilan_has_sibling_cash = FALSE,
      'child_cash=' || COALESCE(v_child_bilan_has_cash::text, 'NULL') ||
        ', sibling_cash=' ||
        COALESCE(v_child_bilan_has_sibling_cash::text, 'NULL')
    ),
    (
      6,
      'grand_livre_filtre_par_unite',
      v_child_grand_livre_lines = 2
        AND v_sibling_grand_livre_lines = 2,
      'child_lines=' || COALESCE(v_child_grand_livre_lines::text, 'NULL') ||
        ', sibling_lines=' ||
        COALESCE(v_sibling_grand_livre_lines::text, 'NULL')
    );

  DELETE FROM lignes_ecritures
  WHERE id IN (
    v_child_line_debit_id,
    v_child_line_credit_id,
    v_sibling_line_debit_id,
    v_sibling_line_credit_id
  );

  -- Ces ecritures sont volontairement validees pour tester les exports.
  -- Le nettoyage du test doit donc contourner uniquement cette protection.
  BEGIN
    ALTER TABLE ecritures_comptables
      DISABLE TRIGGER protect_validated_ecritures;

    DELETE FROM ecritures_comptables
    WHERE id IN (v_child_entry_id, v_sibling_entry_id);

    ALTER TABLE ecritures_comptables
      ENABLE TRIGGER protect_validated_ecritures;
  EXCEPTION
    WHEN OTHERS THEN
      ALTER TABLE ecritures_comptables
        ENABLE TRIGGER protect_validated_ecritures;
      RAISE;
  END;

  DELETE FROM comptes_comptables
  WHERE id IN (
    v_child_cash_account_id,
    v_child_revenue_account_id,
    v_sibling_cash_account_id,
    v_sibling_revenue_account_id
  );
  DELETE FROM journaux_comptables WHERE id = v_journal_id;
  DELETE FROM church_units
  WHERE id IN (v_child_unit_id, v_sibling_unit_id, v_parent_unit_id);
  DELETE FROM church_unit_types
  WHERE id IN (v_child_type_id, v_parent_type_id);
  PERFORM set_config('request.jwt.claim.sub', '', true);
END $$;

COMMIT;

SELECT check_name, ok, detail
FROM _active_unit_financial_reports_test_result
ORDER BY sort_order;

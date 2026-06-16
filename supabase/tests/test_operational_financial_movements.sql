-- ============================================================================
-- Test E2E DB - Mouvements financiers operationnels
-- ============================================================================
-- Objectif :
--   1. Utiliser une organisation existante et une unite financiere autorisee.
--   2. Creer un compte financier de test, une campagne et une promesse.
--   3. Enregistrer un encaissement soumis.
--   4. Verifier le statut de promesse et la vue de synthese.
--   5. Nettoyer les donnees de test avant COMMIT.
--
-- Ce script ne laisse pas de donnees de test persistantes.
-- ============================================================================

DROP TABLE IF EXISTS _operational_finance_test_result;
CREATE TEMP TABLE _operational_finance_test_result (
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
  v_unit_id UUID;
  v_account_id UUID := gen_random_uuid();
  v_campaign_id UUID := gen_random_uuid();
  v_pledge_id UUID := gen_random_uuid();
  v_movement_id UUID := gen_random_uuid();
  v_pledge_status TEXT;
  v_summary v_campagnes_financieres_resume%ROWTYPE;
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

  SELECT u.id
  INTO v_unit_id
  FROM church_units u
  JOIN church_unit_types t ON t.id = u.type_id
  WHERE u.organization_id = v_org_id
    AND u.active = TRUE
    AND t.can_launch_contributions = TRUE
    AND t.can_have_cash_accounts = TRUE
  ORDER BY t.level_order DESC, u.nom
  LIMIT 1;

  IF v_unit_id IS NULL THEN
    RAISE EXCEPTION 'Aucune unite active ne permet a la fois cotisations et caisse.';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_admin_id::text, true);

  INSERT INTO church_unit_financial_accounts (
    id,
    organization_id,
    church_unit_id,
    type,
    label,
    currency
  )
  VALUES (
    v_account_id,
    v_org_id,
    v_unit_id,
    'cash',
    'Caisse test mouvements',
    'FCFA'
  );

  INSERT INTO campagnes_financieres (
    id,
    organization_id,
    church_unit_id,
    titre,
    type,
    objectif_montant,
    statut,
    created_by
  )
  VALUES (
    v_campaign_id,
    v_org_id,
    v_unit_id,
    'Campagne test operational finance',
    'cotisation',
    100000,
    'active',
    v_admin_id
  );

  INSERT INTO promesses_financieres (
    id,
    organization_id,
    campagne_id,
    church_unit_id,
    contributeur_nom,
    montant_promis,
    created_by
  )
  VALUES (
    v_pledge_id,
    v_org_id,
    v_campaign_id,
    v_unit_id,
    'Contributeur test',
    50000,
    v_admin_id
  );

  INSERT INTO mouvements_financiers (
    id,
    organization_id,
    church_unit_id,
    financial_account_id,
    campagne_id,
    promesse_id,
    contributeur_nom,
    type,
    montant,
    libelle,
    mode_paiement,
    statut,
    submitted_by
  )
  VALUES (
    v_movement_id,
    v_org_id,
    v_unit_id,
    v_account_id,
    v_campaign_id,
    v_pledge_id,
    'Contributeur test',
    'encaissement',
    30000,
    'Paiement partiel test',
    'especes',
    'soumis',
    v_admin_id
  );

  SELECT statut
  INTO v_pledge_status
  FROM promesses_financieres
  WHERE id = v_pledge_id;

  SELECT *
  INTO v_summary
  FROM v_campagnes_financieres_resume
  WHERE id = v_campaign_id;

  INSERT INTO _operational_finance_test_result VALUES
    (
      1,
      'campagne_creee',
      EXISTS (
        SELECT 1 FROM campagnes_financieres
        WHERE id = v_campaign_id
          AND organization_id = v_org_id
          AND church_unit_id = v_unit_id
      ),
      'campaign_id=' || v_campaign_id::text
    ),
    (
      2,
      'promesse_partielle',
      v_pledge_status = 'partielle',
      'statut=' || COALESCE(v_pledge_status, 'NULL')
    ),
    (
      3,
      'mouvement_soumis',
      EXISTS (
        SELECT 1 FROM mouvements_financiers
        WHERE id = v_movement_id
          AND statut = 'soumis'
          AND submitted_at IS NOT NULL
      ),
      'movement_id=' || v_movement_id::text
    ),
    (
      4,
      'resume_montants_corrects',
      v_summary.montant_promis = 50000
        AND v_summary.montant_encaisse = 30000
        AND v_summary.reste_sur_promesses = 20000
        AND v_summary.reste_sur_objectif = 70000,
      'promis=' || COALESCE(v_summary.montant_promis::text, 'NULL') ||
        ', encaisse=' || COALESCE(v_summary.montant_encaisse::text, 'NULL') ||
        ', reste_promesses=' || COALESCE(v_summary.reste_sur_promesses::text, 'NULL') ||
        ', reste_objectif=' || COALESCE(v_summary.reste_sur_objectif::text, 'NULL')
    );

  DELETE FROM mouvements_financiers WHERE id = v_movement_id;
  DELETE FROM promesses_financieres WHERE id = v_pledge_id;
  DELETE FROM campagnes_financieres WHERE id = v_campaign_id;
  DELETE FROM church_unit_financial_accounts WHERE id = v_account_id;
  PERFORM set_config('request.jwt.claim.sub', '', true);
END $$;

COMMIT;

SELECT check_name, ok, detail
FROM _operational_finance_test_result
ORDER BY sort_order;

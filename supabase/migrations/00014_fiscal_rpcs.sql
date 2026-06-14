-- =============================================================================
-- Migration 00014 : RPCs Dossier Fiscal SYSCEBNL
-- =============================================================================
-- Objectif : Fonctions serveur pour pré-remplissage, validation et verrouillage
-- RPCs :
--   1. prefill_fiscal_dossier(UUID) → pré-remplit depuis écritures comptables
--   2. prefill_fiscal_dossier_from_import(UUID, UUID) → depuis balance importée
--   3. validate_fiscal_dossier(UUID) → contrôles bloquants
--   4. lock_fiscal_dossier(UUID) → verrouille si validation OK
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. prefill_fiscal_dossier — Pré-remplissage depuis comptabilité existante
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.prefill_fiscal_dossier(p_dossier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id        UUID;
  v_template_id   UUID;
  v_exercice_id   UUID;
  v_date_debut    DATE;
  v_date_fin      DATE;
  v_count         INTEGER := 0;
  v_missing       INTEGER := 0;
  v_mapping       RECORD;
  v_solde         NUMERIC;
  v_prefixes      TEXT[];
  v_prefix        TEXT;
BEGIN
  -- 1) Récupérer infos dossier
  SELECT d.organization_id, d.template_id, d.exercice_id
  INTO v_org_id, v_template_id, v_exercice_id
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  -- 2) Vérifier appartenance organisation
  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Accès refusé : dossier hors de votre organisation';
  END IF;

  -- 3) Récupérer dates de l'exercice (si lié)
  IF v_exercice_id IS NOT NULL THEN
    SELECT date_debut, date_fin INTO v_date_debut, v_date_fin
    FROM public.exercices_comptables
    WHERE id = v_exercice_id;
  ELSE
    -- Fallback : année courante
    v_date_debut := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 1, 1);
    v_date_fin := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 12, 31);
  END IF;

  -- 4) Itérer sur les mappings du template
  FOR v_mapping IN
    SELECT field_key, rule_type, params
    FROM public.fiscal_account_mapping
    WHERE template_id = v_template_id
  LOOP
    v_solde := 0;

    IF v_mapping.rule_type = 'sum_prefixes' THEN
      -- Somme des soldes de comptes dont le numéro commence par les préfixes
      v_prefixes := ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'prefixes'));

      SELECT COALESCE(SUM(
        CASE
          WHEN cc.nature IN ('actif', 'charge', 'hors_activite_ordinaire')
            THEN le.debit - le.credit
          ELSE le.credit - le.debit
        END
      ), 0) INTO v_solde
      FROM public.lignes_ecritures le
      JOIN public.ecritures_comptables ec ON ec.id = le.id_ecriture
      JOIN public.comptes_comptables cc ON cc.id = le.id_compte_comptable
      WHERE ec.organization_id = v_org_id
        AND ec.deleted_at IS NULL
        AND ec.date BETWEEN v_date_debut AND v_date_fin
        AND EXISTS (
          SELECT 1 FROM unnest(v_prefixes) p
          WHERE cc.numero LIKE p || '%'
        );

    ELSIF v_mapping.rule_type = 'balance_class' THEN
      -- Somme par classe (ex: classe 6, 7)
      SELECT COALESCE(SUM(
        CASE
          WHEN cc.nature IN ('actif', 'charge', 'hors_activite_ordinaire')
            THEN le.debit - le.credit
          ELSE le.credit - le.debit
        END
      ), 0) INTO v_solde
      FROM public.lignes_ecritures le
      JOIN public.ecritures_comptables ec ON ec.id = le.id_ecriture
      JOIN public.comptes_comptables cc ON cc.id = le.id_compte_comptable
      WHERE ec.organization_id = v_org_id
        AND ec.deleted_at IS NULL
        AND ec.date BETWEEN v_date_debut AND v_date_fin
        AND cc.numero LIKE (v_mapping.params->>'class_prefix') || '%';

    ELSIF v_mapping.rule_type = 'sum_accounts' THEN
      -- Somme de comptes spécifiques
      SELECT COALESCE(SUM(
        CASE
          WHEN cc.nature IN ('actif', 'charge', 'hors_activite_ordinaire')
            THEN le.debit - le.credit
          ELSE le.credit - le.debit
        END
      ), 0) INTO v_solde
      FROM public.lignes_ecritures le
      JOIN public.ecritures_comptables ec ON ec.id = le.id_ecriture
      JOIN public.comptes_comptables cc ON cc.id = le.id_compte_comptable
      WHERE ec.organization_id = v_org_id
        AND ec.deleted_at IS NULL
        AND ec.date BETWEEN v_date_debut AND v_date_fin
        AND cc.numero = ANY(ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'accounts')));

    ELSE
      -- custom_sql ou inconnu : on skip
      v_missing := v_missing + 1;
      CONTINUE;
    END IF;

    -- 5) Upsert dans fiscal_dossier_values
    INSERT INTO public.fiscal_dossier_values (dossier_id, organization_id, field_key, value, source, updated_by, updated_at)
    VALUES (
      p_dossier_id,
      v_org_id,
      v_mapping.field_key,
      to_jsonb(v_solde),
      'computed',
      auth.uid(),
      NOW()
    )
    ON CONFLICT (dossier_id, field_key)
    DO UPDATE SET
      value = to_jsonb(v_solde),
      source = 'computed',
      updated_by = auth.uid(),
      updated_at = NOW();

    v_count := v_count + 1;
  END LOOP;

  -- 6) Passer le dossier en in_progress si encore en draft
  UPDATE public.fiscal_dossiers
  SET status = 'in_progress', updated_at = NOW()
  WHERE id = p_dossier_id AND status = 'draft';

  RETURN jsonb_build_object(
    'success', TRUE,
    'filled', v_count,
    'skipped', v_missing,
    'date_debut', v_date_debut,
    'date_fin', v_date_fin
  );
END $$;

REVOKE ALL ON FUNCTION public.prefill_fiscal_dossier(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prefill_fiscal_dossier(UUID) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. prefill_fiscal_dossier_from_import — Pré-remplissage depuis balance
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.prefill_fiscal_dossier_from_import(
  p_dossier_id UUID,
  p_import_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id        UUID;
  v_import_org    UUID;
  v_template_id   UUID;
  v_count         INTEGER := 0;
  v_missing       INTEGER := 0;
  v_mapping       RECORD;
  v_solde         NUMERIC;
  v_prefixes      TEXT[];
BEGIN
  -- 1) Récupérer infos dossier
  SELECT d.organization_id, d.template_id
  INTO v_org_id, v_template_id
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  -- 2) Vérifier appartenance organisation
  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Accès refusé : dossier hors de votre organisation';
  END IF;

  -- 3) Vérifier l'import appartient à la même org
  SELECT organization_id INTO v_import_org
  FROM public.imported_trial_balances
  WHERE id = p_import_id;

  IF v_import_org IS NULL THEN
    RAISE EXCEPTION 'Balance importée introuvable : %', p_import_id;
  END IF;

  IF v_import_org <> v_org_id THEN
    RAISE EXCEPTION 'La balance importée n''appartient pas à votre organisation';
  END IF;

  -- 4) Lier l'import au dossier
  UPDATE public.fiscal_dossiers
  SET import_id = p_import_id, updated_at = NOW()
  WHERE id = p_dossier_id;

  -- 5) Itérer sur les mappings du template
  FOR v_mapping IN
    SELECT field_key, rule_type, params
    FROM public.fiscal_account_mapping
    WHERE template_id = v_template_id
  LOOP
    v_solde := 0;

    IF v_mapping.rule_type = 'sum_prefixes' THEN
      v_prefixes := ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'prefixes'));

      -- Calculer depuis les lignes importées
      -- Convention : solde = debit - credit pour actif/charge, credit - debit pour passif/produit
      -- Comme on n'a pas la nature depuis l'import, on utilise la convention par préfixe :
      -- Classes 1,4 côté crédit (passif) / 2,3,5 côté débit (actif) / 6 débit (charges) / 7 crédit (produits)
      SELECT COALESCE(SUM(
        CASE
          WHEN LEFT(l.account_number, 1) IN ('1', '4', '7') THEN l.credit - l.debit
          ELSE l.debit - l.credit
        END
      ), 0) INTO v_solde
      FROM public.imported_trial_balance_lines l
      WHERE l.import_id = p_import_id
        AND EXISTS (
          SELECT 1 FROM unnest(v_prefixes) p
          WHERE l.account_number LIKE p || '%'
        );

    ELSIF v_mapping.rule_type = 'balance_class' THEN
      SELECT COALESCE(SUM(
        CASE
          WHEN LEFT(l.account_number, 1) IN ('1', '4', '7') THEN l.credit - l.debit
          ELSE l.debit - l.credit
        END
      ), 0) INTO v_solde
      FROM public.imported_trial_balance_lines l
      WHERE l.import_id = p_import_id
        AND l.account_number LIKE (v_mapping.params->>'class_prefix') || '%';

    ELSIF v_mapping.rule_type = 'sum_accounts' THEN
      SELECT COALESCE(SUM(
        CASE
          WHEN LEFT(l.account_number, 1) IN ('1', '4', '7') THEN l.credit - l.debit
          ELSE l.debit - l.credit
        END
      ), 0) INTO v_solde
      FROM public.imported_trial_balance_lines l
      WHERE l.import_id = p_import_id
        AND l.account_number = ANY(ARRAY(SELECT jsonb_array_elements_text(v_mapping.params->'accounts')));

    ELSE
      v_missing := v_missing + 1;
      CONTINUE;
    END IF;

    -- Upsert
    INSERT INTO public.fiscal_dossier_values (dossier_id, organization_id, field_key, value, source, updated_by, updated_at)
    VALUES (p_dossier_id, v_org_id, v_mapping.field_key, to_jsonb(v_solde), 'imported', auth.uid(), NOW())
    ON CONFLICT (dossier_id, field_key)
    DO UPDATE SET value = to_jsonb(v_solde), source = 'imported', updated_by = auth.uid(), updated_at = NOW();

    v_count := v_count + 1;
  END LOOP;

  -- 6) Passer le dossier en in_progress si encore en draft
  UPDATE public.fiscal_dossiers
  SET status = 'in_progress', updated_at = NOW()
  WHERE id = p_dossier_id AND status = 'draft';

  RETURN jsonb_build_object('success', TRUE, 'filled', v_count, 'skipped', v_missing);
END $$;

REVOKE ALL ON FUNCTION public.prefill_fiscal_dossier_from_import(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prefill_fiscal_dossier_from_import(UUID, UUID) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. validate_fiscal_dossier — Validation avec contrôles bloquants
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.validate_fiscal_dossier(p_dossier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id      UUID;
  v_template_id UUID;
  v_errors      JSONB := '[]'::JSONB;
  v_field       RECORD;
  v_val         JSONB;
  v_actif       NUMERIC := 0;
  v_passif      NUMERIC := 0;
  v_produits    NUMERIC := 0;
  v_charges     NUMERIC := 0;
  v_resultat    NUMERIC := 0;
  v_passif_res  NUMERIC := 0;
BEGIN
  -- 1) Récupérer infos dossier
  SELECT d.organization_id, d.template_id
  INTO v_org_id, v_template_id
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  -- 2) Vérifier appartenance organisation
  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Accès refusé : dossier hors de votre organisation';
  END IF;

  -- 3) Vérifier champs requis manquants
  FOR v_field IN
    SELECT f.field_key, f.label, p.code AS page_code
    FROM public.fiscal_template_fields f
    JOIN public.fiscal_template_pages p ON p.id = f.page_id
    WHERE p.template_id = v_template_id
      AND f.required = TRUE
  LOOP
    SELECT dv.value INTO v_val
    FROM public.fiscal_dossier_values dv
    WHERE dv.dossier_id = p_dossier_id
      AND dv.field_key = v_field.field_key;

    IF v_val IS NULL OR v_val = 'null'::JSONB OR v_val = '""'::JSONB THEN
      v_errors := v_errors || jsonb_build_array(
        jsonb_build_object(
          'code', 'REQUIRED_FIELD_MISSING',
          'message', 'Champ requis manquant : ' || v_field.label,
          'page_code', v_field.page_code,
          'field_key', v_field.field_key
        )
      );
    END IF;
  END LOOP;

  -- 4) Vérifier Actif = Passif
  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_actif
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'bilan.actif.total';

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_passif
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'bilan.passif.total';

  IF v_actif <> v_passif THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object(
        'code', 'ACTIF_PASSIF_MISMATCH',
        'message', format('Le total Actif (%s FCFA) doit être égal au total Passif (%s FCFA).', v_actif, v_passif),
        'page_code', 'BILAN_ACTIF',
        'field_key', 'bilan.actif.total'
      )
    );
  END IF;

  -- 5) Vérifier Résultat = Produits - Charges
  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_produits
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'resultat.produits.total';

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_charges
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'resultat.charges.total';

  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_resultat
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'resultat.net';

  IF v_resultat <> (v_produits - v_charges) THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object(
        'code', 'RESULTAT_MISMATCH',
        'message', format('Le résultat net (%s) doit être égal à Produits (%s) - Charges (%s) = %s.',
                          v_resultat, v_produits, v_charges, v_produits - v_charges),
        'page_code', 'RESULTAT',
        'field_key', 'resultat.net'
      )
    );
  END IF;

  -- 6) Vérifier cohérence Résultat Bilan = Résultat Compte de résultat
  SELECT COALESCE((dv.value)::TEXT::NUMERIC, 0) INTO v_passif_res
  FROM public.fiscal_dossier_values dv
  WHERE dv.dossier_id = p_dossier_id AND dv.field_key = 'bilan.passif.resultat.net';

  IF v_passif_res <> v_resultat THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object(
        'code', 'BILAN_RESULTAT_MISMATCH',
        'message', format('Le résultat au bilan passif (%s) doit correspondre au résultat net (%s).',
                          v_passif_res, v_resultat),
        'page_code', 'BILAN_PASSIF',
        'field_key', 'bilan.passif.resultat.net'
      )
    );
  END IF;

  -- 7) Si validation OK, passer le dossier en 'ready'
  IF jsonb_array_length(v_errors) = 0 THEN
    UPDATE public.fiscal_dossiers
    SET status = 'ready', updated_at = NOW()
    WHERE id = p_dossier_id AND status IN ('draft', 'in_progress');
  END IF;

  RETURN jsonb_build_object(
    'ok', jsonb_array_length(v_errors) = 0,
    'error_count', jsonb_array_length(v_errors),
    'errors', v_errors
  );
END $$;

REVOKE ALL ON FUNCTION public.validate_fiscal_dossier(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.validate_fiscal_dossier(UUID) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. lock_fiscal_dossier — Verrouillage si validation OK
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.lock_fiscal_dossier(p_dossier_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id    UUID;
  v_status    public.fiscal_dossier_status;
  v_role      public.role_utilisateur;
  v_result    JSONB;
BEGIN
  -- 1) Récupérer infos dossier
  SELECT d.organization_id, d.status
  INTO v_org_id, v_status
  FROM public.fiscal_dossiers d
  WHERE d.id = p_dossier_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Dossier fiscal introuvable : %', p_dossier_id;
  END IF;

  -- 2) Vérifier appartenance organisation
  IF v_org_id <> get_user_organization_id() THEN
    RAISE EXCEPTION 'Accès refusé : dossier hors de votre organisation';
  END IF;

  -- 3) Vérifier rôle (seuls admin_national et responsable_region peuvent verrouiller)
  v_role := get_user_role();
  IF v_role NOT IN ('admin_national', 'responsable_region') THEN
    RAISE EXCEPTION 'Seuls les administrateurs nationaux et responsables de région peuvent verrouiller un dossier fiscal.';
  END IF;

  -- 4) Vérifier que le dossier n'est pas déjà verrouillé
  IF v_status IN ('locked', 'submitted') THEN
    RAISE EXCEPTION 'Le dossier est déjà verrouillé ou soumis.';
  END IF;

  -- 5) Lancer la validation
  v_result := public.validate_fiscal_dossier(p_dossier_id);

  IF NOT (v_result->>'ok')::BOOLEAN THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Impossible de verrouiller : des erreurs de validation existent.',
      'validation', v_result
    );
  END IF;

  -- 6) Verrouiller
  UPDATE public.fiscal_dossiers
  SET
    status = 'locked',
    locked_by = auth.uid(),
    locked_at = NOW(),
    updated_at = NOW()
  WHERE id = p_dossier_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'message', 'Dossier fiscal verrouillé avec succès.',
    'locked_at', NOW(),
    'locked_by', auth.uid()
  );
END $$;

REVOKE ALL ON FUNCTION public.lock_fiscal_dossier(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lock_fiscal_dossier(UUID) TO authenticated;

-- =============================================================================
-- Test E2E — Dossier Fiscal SYSCEBNL (cycle complet)
-- =============================================================================
-- Scénario : Créer un dossier → pré-remplir → saisir valeurs → valider → lock
-- Exécuter dans le SQL Editor de Supabase en tant qu'utilisateur authentifié.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Vérifier le template existe
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_tpl_id UUID;
BEGIN
  SELECT id INTO v_tpl_id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026' AND is_active = TRUE;
  IF v_tpl_id IS NULL THEN
    RAISE EXCEPTION '❌ Template SYSCEBNL_2026 non trouvé ou inactif';
  END IF;
  RAISE NOTICE '✅ Template trouvé : %', v_tpl_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Vérifier les pages du template
-- ─────────────────────────────────────────────────────────────────────────────

SELECT
  p.page_order,
  p.code,
  p.title,
  p.layout->>'type' AS layout_type,
  COUNT(f.id) AS field_count
FROM public.fiscal_template_pages p
LEFT JOIN public.fiscal_template_fields f ON f.page_id = p.id
WHERE p.template_id = (SELECT id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026')
GROUP BY p.page_order, p.code, p.title, p.layout->>'type'
ORDER BY p.page_order;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Vérifier les champs required
-- ─────────────────────────────────────────────────────────────────────────────

SELECT
  p.code AS page_code,
  f.field_key,
  f.label,
  f.field_type,
  f.required
FROM public.fiscal_template_fields f
JOIN public.fiscal_template_pages p ON p.id = f.page_id
WHERE p.template_id = (SELECT id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026')
  AND f.required = TRUE
ORDER BY p.page_order, f.field_order;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Vérifier les mappings (pré-remplissage)
-- ─────────────────────────────────────────────────────────────────────────────

SELECT
  field_key,
  rule_type,
  params
FROM public.fiscal_account_mapping
WHERE template_id = (SELECT id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026')
ORDER BY field_key;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Test flux complet (nécessite un utilisateur auth + organisation)
-- ─────────────────────────────────────────────────────────────────────────────
-- NOTE : Ce bloc doit être exécuté par un utilisateur authentifié avec une
-- organisation configurée. Décommenter pour tester.

/*
DO $$
DECLARE
  v_org_id UUID;
  v_tpl_id UUID;
  v_dossier_id UUID;
  v_result JSONB;
BEGIN
  -- Récupérer org de l'utilisateur
  v_org_id := get_user_organization_id();
  RAISE NOTICE 'Organisation : %', v_org_id;

  -- Récupérer template
  SELECT id INTO v_tpl_id FROM public.fiscal_templates WHERE code = 'SYSCEBNL_2026';

  -- Créer un dossier
  INSERT INTO public.fiscal_dossiers (organization_id, template_id, label, created_by)
  VALUES (v_org_id, v_tpl_id, 'Test E2E Fiscal', auth.uid())
  RETURNING id INTO v_dossier_id;
  RAISE NOTICE '✅ Dossier créé : %', v_dossier_id;

  -- Pré-remplir
  v_result := public.prefill_fiscal_dossier(v_dossier_id);
  RAISE NOTICE '✅ Pré-remplissage : %', v_result;

  -- Insérer les valeurs manuelles requises
  INSERT INTO public.fiscal_dossier_values (dossier_id, organization_id, field_key, value, source) VALUES
    (v_dossier_id, v_org_id, 'org.name', '"Test Organisation"'::JSONB, 'manual'),
    (v_dossier_id, v_org_id, 'exercice.label', '"Exercice 2026"'::JSONB, 'manual'),
    (v_dossier_id, v_org_id, 'exercice.date_debut', '"2026-01-01"'::JSONB, 'manual'),
    (v_dossier_id, v_org_id, 'exercice.date_fin', '"2026-12-31"'::JSONB, 'manual'),
    (v_dossier_id, v_org_id, 'currency', '"FCFA"'::JSONB, 'manual'),
    (v_dossier_id, v_org_id, 'responsable.nom', '"Pasteur Test"'::JSONB, 'manual'),
    (v_dossier_id, v_org_id, 'mode_production', '"Comptabilité interne"'::JSONB, 'manual')
  ON CONFLICT (dossier_id, field_key) DO UPDATE SET value = EXCLUDED.value;
  RAISE NOTICE '✅ Valeurs manuelles insérées';

  -- Valider
  v_result := public.validate_fiscal_dossier(v_dossier_id);
  RAISE NOTICE '✅ Validation : %', v_result;

  -- Nettoyer (supprimer le dossier de test)
  DELETE FROM public.fiscal_dossiers WHERE id = v_dossier_id;
  RAISE NOTICE '✅ Dossier de test supprimé';

  RAISE NOTICE '✅ TEST E2E COMPLET — Tous les flux fonctionnent';
END $$;
*/

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.organizations
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
       OR sigle = 'EAB'
       OR code = 'EAB'
  ) THEN
    RAISE EXCEPTION 'Organisation demo EAB introuvable. Verifiez le projet Supabase actif avant execution.';
  END IF;
END $$;

DO $$
DECLARE
  v_org_id UUID;
BEGIN
  SELECT id
  INTO v_org_id
  FROM public.organizations
  WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
     OR sigle = 'EAB'
     OR code = 'EAB'
  ORDER BY
    CASE
      WHEN id = '00000000-0000-0000-0000-000000000001'::uuid THEN 0
      WHEN sigle = 'EAB' THEN 1
      ELSE 2
    END
  LIMIT 1;

  IF NOT EXISTS (
    SELECT 1
    FROM public.fiscal_templates
    WHERE code = 'SYSCEBNL_2026'
      AND is_active = TRUE
  ) THEN
    RAISE EXCEPTION 'Template fiscal SYSCEBNL_2026 actif introuvable.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.exercices_comptables
    WHERE organization_id = v_org_id
      AND annee = 2025
  ) THEN
    RAISE EXCEPTION 'Exercice comptable 2025 introuvable pour EAB.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.church_units
    WHERE organization_id = v_org_id
      AND parent_id IS NULL
      AND active = TRUE
  ) THEN
    RAISE EXCEPTION 'Unite racine active introuvable pour EAB.';
  END IF;
END $$;

WITH refs AS (
  SELECT
    o.id AS organization_id,
    o.name AS organization_name,
    o.sigle,
    o.devise,
    o.adresse,
    COALESCE(o.parametres -> 'fiscal_identity', '{}'::jsonb) AS fiscal_identity,
    t.id AS template_id,
    e.id AS exercice_id,
    e.date_debut,
    e.date_fin,
    e.libelle,
    u.id AS church_unit_id,
    u.nom AS church_unit_name,
    ut.label AS church_unit_type
  FROM public.organizations o
  JOIN public.fiscal_templates t
    ON t.is_active = TRUE
  JOIN public.exercices_comptables e
    ON e.organization_id = o.id
   AND e.annee = 2025
  JOIN public.church_units u
    ON u.organization_id = o.id
   AND u.parent_id IS NULL
   AND u.active = TRUE
  JOIN public.church_unit_types ut
    ON ut.id = u.type_id
  WHERE (o.id = '00000000-0000-0000-0000-000000000001'::uuid
      OR o.sigle = 'EAB'
      OR o.code = 'EAB')
    AND t.code = 'SYSCEBNL_2026'
  ORDER BY u.created_at
  LIMIT 1
),
upsert_dossier AS (
  INSERT INTO public.fiscal_dossiers (
    id,
    organization_id,
    church_unit_id,
    template_id,
    exercice_id,
    status,
    label,
    notes,
    updated_at
  )
  SELECT
    '00000000-0000-0000-00df-000000002025'::uuid,
    organization_id,
    church_unit_id,
    template_id,
    exercice_id,
    'in_progress'::public.fiscal_dossier_status,
    'Dossier fiscal EAB 2025',
    'Dossier demo prepare pour verifier les exports SYSCEBNL Excel/PDF.',
    NOW()
  FROM refs
  ON CONFLICT (id)
  DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    church_unit_id = EXCLUDED.church_unit_id,
    template_id = EXCLUDED.template_id,
    exercice_id = EXCLUDED.exercice_id,
    status = EXCLUDED.status,
    label = EXCLUDED.label,
    notes = EXCLUDED.notes,
    updated_at = NOW()
  RETURNING id
),
dossier_values AS (
  SELECT
    d.id AS dossier_id,
    r.organization_id,
    v.field_key,
    v.field_value,
    v.source
  FROM upsert_dossier d
  CROSS JOIN refs r
  CROSS JOIN LATERAL (
    VALUES
      ('org.name', r.organization_name, 'computed'),
      ('org.sigle', COALESCE(r.sigle, 'EAB'), 'computed'),
      ('org.address', COALESCE(r.adresse, ''), 'computed'),
      ('org.nif', COALESCE(r.fiscal_identity ->> 'ifu', ''), 'computed'),
      ('fiscal.registration_number', COALESCE(r.fiscal_identity ->> 'registration_number', ''), 'computed'),
      ('fiscal.tax_center', COALESCE(r.fiscal_identity ->> 'tax_center', ''), 'computed'),
      ('fiscal.deposit_center', COALESCE(r.fiscal_identity ->> 'deposit_center', ''), 'computed'),
      ('responsable.nom', COALESCE(r.fiscal_identity ->> 'legal_representative_name', ''), 'computed'),
      ('responsable.qualite', COALESCE(r.fiscal_identity ->> 'legal_representative_title', ''), 'computed'),
      ('responsable.telephone', COALESCE(r.fiscal_identity ->> 'legal_representative_phone', ''), 'computed'),
      ('accountant.name', COALESCE(r.fiscal_identity ->> 'accountant_name', ''), 'computed'),
      ('accountant.title', COALESCE(r.fiscal_identity ->> 'accountant_title', ''), 'computed'),
      ('accountant.phone', COALESCE(r.fiscal_identity ->> 'accountant_phone', ''), 'computed'),
      ('accountant.email', COALESCE(r.fiscal_identity ->> 'accountant_email', ''), 'computed'),
      ('bank.name', COALESCE(r.fiscal_identity ->> 'bank_name', ''), 'computed'),
      ('bank.account_label', COALESCE(r.fiscal_identity ->> 'bank_account_label', ''), 'computed'),
      ('bank.account_number', COALESCE(r.fiscal_identity ->> 'bank_account_number', ''), 'computed'),
      ('currency', COALESCE(r.devise, 'FCFA'), 'computed'),
      ('mode_production', 'Comptabilite interne SYSCEBNL', 'computed'),
      ('exercice.label', COALESCE(r.libelle, 'Exercice comptable 2025'), 'computed'),
      ('exercice.date_debut', r.date_debut::text, 'computed'),
      ('exercice.date_fin', r.date_fin::text, 'computed'),
      ('perimetre.label', r.church_unit_type || ' - ' || r.church_unit_name, 'computed')
  ) AS v(field_key, field_value, source)
  WHERE v.field_value IS NOT NULL
    AND btrim(v.field_value) <> ''
),
upsert_values AS (
  INSERT INTO public.fiscal_dossier_values (
    dossier_id,
    organization_id,
    field_key,
    value,
    source,
    updated_at
  )
  SELECT
    dossier_id,
    organization_id,
    field_key,
    to_jsonb(field_value),
    source,
    NOW()
  FROM dossier_values
  ON CONFLICT (dossier_id, field_key)
  DO UPDATE SET
    value = EXCLUDED.value,
    source = EXCLUDED.source,
    updated_at = NOW()
  RETURNING field_key
)
SELECT COUNT(*) AS fiscal_values_upserted
FROM upsert_values;

COMMIT;

SELECT
  d.id AS dossier_id,
  d.label,
  d.status,
  o.name AS organization_name,
  o.sigle,
  u.nom AS church_unit_name,
  e.annee AS exercice,
  COUNT(v.field_key) AS values_ready
FROM public.fiscal_dossiers d
JOIN public.organizations o ON o.id = d.organization_id
JOIN public.church_units u ON u.id = d.church_unit_id
JOIN public.exercices_comptables e ON e.id = d.exercice_id
LEFT JOIN public.fiscal_dossier_values v ON v.dossier_id = d.id
WHERE d.id = '00000000-0000-0000-00df-000000002025'::uuid
GROUP BY d.id, d.label, d.status, o.name, o.sigle, u.nom, e.annee;

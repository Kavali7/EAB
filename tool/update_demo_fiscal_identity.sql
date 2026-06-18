BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM organizations
    WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
       OR sigle = 'EAB'
       OR code = 'EAB'
  ) THEN
    RAISE EXCEPTION 'Organisation demo EAB introuvable. Verifiez le projet Supabase actif avant execution.';
  END IF;
END $$;

WITH target AS (
  SELECT id
  FROM organizations
  WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
     OR sigle = 'EAB'
     OR code = 'EAB'
  ORDER BY
    CASE
      WHEN id = '00000000-0000-0000-0000-000000000001'::uuid THEN 0
      WHEN sigle = 'EAB' THEN 1
      ELSE 2
    END
  LIMIT 1
),
source AS (
  SELECT
    o.id,
    COALESCE(o.parametres, '{}'::jsonb) AS parametres,
    COALESCE(o.parametres -> 'onboarding', '{}'::jsonb) AS onboarding
  FROM organizations o
  JOIN target t ON t.id = o.id
),
completed_steps AS (
  SELECT
    s.id,
    COALESCE(jsonb_agg(DISTINCT step), '[]'::jsonb) AS steps
  FROM source s
  CROSS JOIN LATERAL (
    SELECT jsonb_array_elements_text(
      COALESCE(s.onboarding -> 'completed_steps', '[]'::jsonb)
    ) AS step
    UNION
    SELECT 'fiscal_identity'
  ) all_steps
  GROUP BY s.id
),
updated AS (
  UPDATE organizations o
  SET
    adresse = COALESCE(NULLIF(o.adresse, ''), 'Cotonou, Littoral, Benin'),
    telephone = COALESCE(NULLIF(o.telephone, ''), '+229 01 00 00 00 00'),
    email = COALESCE(NULLIF(o.email, ''), 'contact.demo@example.com'),
    site_web = COALESCE(NULLIF(o.site_web, ''), 'https://demo.eglisewise.local'),
    devise = COALESCE(NULLIF(o.devise, ''), 'FCFA'),
    parametres =
      s.parametres ||
      jsonb_build_object(
        'fiscal_identity',
        jsonb_build_object(
          'ifu', '3202600000001',
          'registration_number', 'EAB-DEMO-2026-001',
          'tax_center', 'Centre des impots des organisations religieuses - Cotonou',
          'deposit_center', 'Direction generale des impots - Cotonou',
          'country', 'Benin',
          'head_office_address', 'Cotonou, Littoral, Benin',
          'activity_description', 'Organisation religieuse a but non lucratif, gestion cultuelle, sociale et administrative des eglises locales.',
          'legal_representative_name', 'Georges GUIDAN',
          'legal_representative_title', 'Representant legal de demonstration',
          'legal_representative_phone', '+229 01 00 00 00 00',
          'accountant_name', 'Comptable Demo Eglise',
          'accountant_title', 'Comptable responsable des etats SYSCEBNL',
          'accountant_phone', '+229 01 00 00 00 01',
          'accountant_email', 'comptable.demo@example.com',
          'bank_name', 'Banque Demo Benin',
          'bank_account_label', 'Compte principal de demonstration'
        ),
        'onboarding',
        s.onboarding || jsonb_build_object('completed_steps', cs.steps)
      )
  FROM source s
  JOIN completed_steps cs ON cs.id = s.id
  WHERE o.id = s.id
  RETURNING
    o.id,
    o.name,
    o.sigle,
    o.adresse,
    o.telephone,
    o.email,
    o.site_web,
    o.devise,
    o.parametres -> 'fiscal_identity' AS fiscal_identity,
    o.parametres #> '{onboarding,completed_steps}' AS completed_steps
)
SELECT
  id,
  name,
  sigle,
  adresse,
  telephone,
  email,
  site_web,
  devise,
  jsonb_object_keys(fiscal_identity) AS fiscal_identity_field
FROM updated
ORDER BY fiscal_identity_field;

COMMIT;

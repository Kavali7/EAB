-- ============================================================================
-- Enrich public demo business data
-- ============================================================================
-- Complements the two public demo tenants without touching platform owners:
-- - test1@gmail.com / EAB multi-level demo
-- - test2@gmail.com / ALPN single-church demo
--
-- This script is incremental and can be run more than once.

CREATE OR REPLACE FUNCTION pg_temp.demo_uuid(p_value TEXT)
RETURNS UUID
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT (
    substr(md5(p_value), 1, 8) || '-' ||
    substr(md5(p_value), 9, 4) || '-' ||
    substr(md5(p_value), 13, 4) || '-' ||
    substr(md5(p_value), 17, 4) || '-' ||
    substr(md5(p_value), 21, 12)
  )::UUID;
$$;

BEGIN;

-- 1) More members for the single-church demo.
WITH alpn AS (
  SELECT o.id AS organization_id, cu.id AS church_unit_id, f.id AS family_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  LEFT JOIN familles f ON f.organization_id = o.id
  WHERE o.id = '00000000-0000-0000-0000-000000000002'::UUID
    AND cut.can_have_members = TRUE
  ORDER BY cu.created_at, f.created_at NULLS LAST
  LIMIT 1
),
extra_members AS (
  SELECT *
  FROM (VALUES
    (7, 'Pierre GBENOU', 'male'::gender, 'ancien'::role_fidele, 'marie'::statut_matrimonial),
    (8, 'Esther HOUNGBEDJI', 'female'::gender, 'membre'::role_fidele, 'marie'::statut_matrimonial),
    (9, 'Daniel KIKI', 'male'::gender, 'evangeliste'::role_fidele, 'celibataire'::statut_matrimonial),
    (10, 'Judith AZON', 'female'::gender, 'membre'::role_fidele, 'celibataire'::statut_matrimonial),
    (11, 'Paul AGBOTON', 'male'::gender, 'membre'::role_fidele, 'veuf'::statut_matrimonial),
    (12, 'Rebecca KPADE', 'female'::gender, 'membre'::role_fidele, 'veuve'::statut_matrimonial)
  ) AS x(sort_order, full_name, gender, role, statut_matrimonial)
)
INSERT INTO membres (
  id,
  organization_id,
  church_unit_id,
  id_famille,
  full_name,
  gender,
  date_naissance,
  phone,
  email,
  address,
  statut_matrimonial,
  date_conversion,
  date_bapteme,
  statut,
  role,
  date_entree
)
SELECT
  pg_temp.demo_uuid('alpn-member-extra:' || m.sort_order),
  a.organization_id,
  a.church_unit_id,
  CASE WHEN m.sort_order IN (7, 8) THEN a.family_id ELSE NULL END,
  m.full_name,
  m.gender,
  DATE '1978-01-01' + (m.sort_order * INTERVAL '420 days'),
  '+229 61 10 00 ' || lpad(m.sort_order::TEXT, 2, '0'),
  lower(replace(m.full_name, ' ', '.')) || '@demo.eglisewise.local',
  'Porto-Novo, Oueme, Benin',
  m.statut_matrimonial,
  DATE '2020-01-15',
  DATE '2021-03-20',
  'actif'::statut_fidele,
  m.role,
  DATE '2022-01-01'
FROM alpn a
CROSS JOIN extra_members m
ON CONFLICT (id) DO NOTHING;

-- 2) Add two richer activity types for every local demo unit.
WITH local_units AS (
  SELECT o.id AS organization_id, o.sigle, cu.id AS unit_id,
         row_number() OVER (PARTITION BY o.id ORDER BY cu.created_at, cu.id) AS rn
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
),
program_specs AS (
  SELECT *
  FROM (VALUES
    ('evangelisation', 'evangelisation_masse'::type_programme, DATE '2025-03-22', 'Place publique', 'Evangelisation de masse avec equipe jeunesse et chorale', 64, 78, 18, 22, 4, 6),
    ('visite', 'visite'::type_programme, DATE '2025-03-27', 'Quartier pastoral', 'Visites pastorales et suivi des familles vulnerables', 7, 9, 3, 4, 0, 1)
  ) AS x(code, type, date, location, description, hommes, femmes, garcons, filles, conversions_hommes, conversions_femmes)
)
INSERT INTO programmes (
  id,
  organization_id,
  church_unit_id,
  type,
  date,
  location,
  description,
  nombre_hommes,
  nombre_femmes,
  nombre_garcons,
  nombre_filles,
  conversions_hommes,
  conversions_femmes
)
SELECT
  pg_temp.demo_uuid('demo-program-extra:' || u.unit_id || ':' || p.code),
  u.organization_id,
  u.unit_id,
  p.type,
  p.date,
  p.location,
  p.description,
  p.hommes + u.rn,
  p.femmes + u.rn,
  p.garcons,
  p.filles,
  p.conversions_hommes,
  p.conversions_femmes
FROM local_units u
CROSS JOIN program_specs p
ON CONFLICT (id) DO NOTHING;

-- 3) Add January and February monthly reports for every local demo unit.
WITH local_units AS (
  SELECT o.id AS organization_id, cu.id AS unit_id,
         row_number() OVER (PARTITION BY o.id ORDER BY cu.created_at, cu.id) AS rn
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
),
report_specs AS (
  SELECT *
  FROM (VALUES
    (1, 475, 210000, 250000, 45000, 35000, 'Demarrage de l annee pastorale et visites de familles.'),
    (2, 505, 235000, 280000, 60000, 42000, 'Suivi des cellules de priere et preparation sociale.')
  ) AS x(mois, presents, dimes, offrandes, dons, charges, resume)
)
INSERT INTO rapports_mensuels_eab (
  id,
  organization_id,
  church_unit_id,
  annee,
  mois,
  stats_membres,
  stats_activites,
  stats_finances,
  resume_activites,
  projets_realisations,
  projets_mois_suivant,
  observations
)
SELECT
  pg_temp.demo_uuid('demo-report-extra:' || u.unit_id || ':' || r.mois),
  u.organization_id,
  u.unit_id,
  2025,
  r.mois,
  jsonb_build_object(
    'total', 38 + u.rn + r.mois,
    'hommes', 18 + u.rn,
    'femmes', 20 + u.rn,
    'nouveaux', 1,
    'baptises', CASE WHEN r.mois = 1 THEN 1 ELSE 0 END
  ),
  jsonb_build_object(
    'cultes', 4,
    'reunions_priere', 4,
    'evangelisations', CASE WHEN r.mois = 1 THEN 0 ELSE 1 END,
    'total_presents', r.presents + u.rn
  ),
  jsonb_build_object(
    'dimes', r.dimes,
    'offrandes', r.offrandes,
    'dons', r.dons,
    'charges', r.charges
  ),
  r.resume,
  'Campagne de renovation, action sociale et suivi pastoral.',
  CASE WHEN r.mois = 2 THEN 'Preparation du rapport trimestriel.' ELSE NULL END,
  'Donnees fictives pour demonstration publique.'
FROM local_units u
CROSS JOIN report_specs r
WHERE NOT EXISTS (
  SELECT 1
  FROM rapports_mensuels_eab existing
  WHERE existing.organization_id = u.organization_id
    AND existing.church_unit_id = u.unit_id
    AND existing.annee = 2025
    AND existing.mois = r.mois
);

-- 4) Add richer financial campaigns, pledges and movements on each demo's primary local unit.
WITH primary_units AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organization_id,
    o.sigle,
    cu.id AS unit_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
  ORDER BY o.id, cu.created_at, cu.id
),
campaign_specs AS (
  SELECT *
  FROM (VALUES
    ('mission-rurale', 'Offrande speciale mission rurale', 'offrande_speciale', 'Collecte affectee aux visites pastorales et missions rurales.', 600000, DATE '2025-03-10', DATE '2025-04-10', 'ponctuelle', 'active'),
    ('sonorisation', 'Fonds equipement sonorisation', 'projet', 'Projet d equipement pour ameliorer cultes, croisades et formations.', 950000, DATE '2025-04-01', DATE '2025-07-31', 'mensuelle', 'active')
  ) AS x(code, titre, type, description, objectif, date_debut, date_fin, periodicite, statut)
)
INSERT INTO campagnes_financieres (
  id,
  organization_id,
  church_unit_id,
  titre,
  type,
  description,
  objectif_montant,
  date_debut,
  date_fin,
  periodicite,
  statut,
  allow_partial_payments
)
SELECT
  pg_temp.demo_uuid('demo-campaign-extra:' || p.organization_id || ':' || c.code),
  p.organization_id,
  p.unit_id,
  c.titre,
  c.type,
  c.description,
  c.objectif,
  c.date_debut,
  c.date_fin,
  c.periodicite,
  c.statut,
  TRUE
FROM primary_units p
CROSS JOIN campaign_specs c
ON CONFLICT (id) DO NOTHING;

WITH primary_units AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organization_id,
    cu.id AS unit_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
  ORDER BY o.id, cu.created_at, cu.id
),
members_ranked AS (
  SELECT m.organization_id, m.id,
         row_number() OVER (PARTITION BY m.organization_id ORDER BY m.created_at, m.id) AS rn
  FROM membres m
  JOIN primary_units p ON p.organization_id = m.organization_id
),
tiers_ranked AS (
  SELECT t.organization_id, t.id,
         row_number() OVER (PARTITION BY t.organization_id ORDER BY t.created_at, t.id) AS rn
  FROM tiers t
  JOIN primary_units p ON p.organization_id = t.organization_id
),
pledge_specs AS (
  SELECT *
  FROM (VALUES
    ('mission-1', 'mission-rurale', 4, NULL::INT, NULL::TEXT, 45000, DATE '2025-03-11', DATE '2025-04-05', 'reglee'),
    ('mission-2', 'mission-rurale', 5, NULL::INT, NULL::TEXT, 80000, DATE '2025-03-12', DATE '2025-04-10', 'partielle'),
    ('sono-1', 'sonorisation', 6, NULL::INT, NULL::TEXT, 125000, DATE '2025-04-02', DATE '2025-06-30', 'ouverte'),
    ('sono-2', 'sonorisation', NULL::INT, 1, NULL::TEXT, 250000, DATE '2025-04-08', DATE '2025-07-15', 'partielle'),
    ('sono-3', 'sonorisation', NULL::INT, NULL::INT, 'Anciens membres diaspora', 300000, DATE '2025-04-15', DATE '2025-07-31', 'ouverte')
  ) AS x(code, campaign_code, member_rn, tiers_rn, contributor, amount, date_promesse, date_echeance, statut)
)
INSERT INTO promesses_financieres (
  id,
  organization_id,
  campagne_id,
  church_unit_id,
  membre_id,
  tiers_id,
  contributeur_nom,
  montant_promis,
  date_promesse,
  date_echeance,
  statut,
  notes
)
SELECT
  pg_temp.demo_uuid('demo-pledge-extra:' || p.organization_id || ':' || ps.code),
  p.organization_id,
  pg_temp.demo_uuid('demo-campaign-extra:' || p.organization_id || ':' || ps.campaign_code),
  p.unit_id,
  mr.id,
  tr.id,
  ps.contributor,
  ps.amount,
  ps.date_promesse,
  ps.date_echeance,
  ps.statut,
  'Promesse demo enrichie pour presenter le suivi financier.'
FROM primary_units p
CROSS JOIN pledge_specs ps
LEFT JOIN members_ranked mr
  ON mr.organization_id = p.organization_id
 AND mr.rn = ps.member_rn
LEFT JOIN tiers_ranked tr
  ON tr.organization_id = p.organization_id
 AND tr.rn = ps.tiers_rn
ON CONFLICT (id) DO NOTHING;

WITH primary_units AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organization_id,
    cu.id AS unit_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
  ORDER BY o.id, cu.created_at, cu.id
),
accounts AS (
  SELECT p.organization_id, p.unit_id,
         min(fa.id::TEXT) FILTER (WHERE fa.type = 'cash')::UUID AS cash_id,
         min(fa.id::TEXT) FILTER (WHERE fa.type = 'bank')::UUID AS bank_id,
         min(fa.id::TEXT) FILTER (WHERE fa.type = 'mobile_money')::UUID AS momo_id
  FROM primary_units p
  JOIN church_unit_financial_accounts fa
    ON fa.organization_id = p.organization_id
   AND fa.church_unit_id = p.unit_id
  GROUP BY p.organization_id, p.unit_id
),
members_ranked AS (
  SELECT m.organization_id, m.id,
         row_number() OVER (PARTITION BY m.organization_id ORDER BY m.created_at, m.id) AS rn
  FROM membres m
),
tiers_ranked AS (
  SELECT t.organization_id, t.id,
         row_number() OVER (PARTITION BY t.organization_id ORDER BY t.created_at, t.id) AS rn
  FROM tiers t
),
movement_specs AS (
  SELECT *
  FROM (VALUES
    ('mission-encaisse', 'cash', 'mission-rurale', 'mission-1', 4, NULL::INT, NULL::TEXT, 'encaissement', 45000, DATE '2025-03-14', 'Offrande speciale mission rurale', 'especes'::mode_paiement, 'REC-MIS-001', 'valide', 'https://demo.eglisewise.local/justificatifs/recu-mission-rurale.pdf', NULL::TEXT),
    ('mission-partiel', 'momo', 'mission-rurale', 'mission-2', 5, NULL::INT, NULL::TEXT, 'encaissement', 30000, DATE '2025-03-18', 'Premier versement mission rurale', 'mobile_money'::mode_paiement, 'MTN-MIS-002', 'soumis', NULL::TEXT, NULL::TEXT),
    ('sono-appui', 'bank', 'sonorisation', 'sono-2', NULL::INT, 1, NULL::TEXT, 'encaissement', 100000, DATE '2025-04-12', 'Appui fournisseur sonorisation', 'virement_bancaire'::mode_paiement, 'VIR-SONO-001', 'valide', 'https://demo.eglisewise.local/justificatifs/virement-sonorisation.pdf', NULL::TEXT),
    ('sono-acompte', 'bank', 'sonorisation', NULL::TEXT, NULL::INT, 1, NULL::TEXT, 'decaissement', 280000, DATE '2025-04-18', 'Acompte achat sonorisation', 'virement_bancaire'::mode_paiement, 'DEP-SONO-001', 'soumis', 'https://demo.eglisewise.local/justificatifs/facture-sonorisation.pdf', NULL::TEXT),
    ('visite-transport', 'cash', NULL::TEXT, NULL::TEXT, NULL::INT, 1, NULL::TEXT, 'decaissement', 35000, DATE '2025-04-20', 'Transport equipe de visite pastorale', 'especes'::mode_paiement, 'DEP-VIS-001', 'valide', 'https://demo.eglisewise.local/justificatifs/recu-transport-visite.pdf', NULL::TEXT),
    ('diaspora-brouillon', 'momo', 'sonorisation', 'sono-3', NULL::INT, NULL::INT, 'Anciens membres diaspora', 'encaissement', 150000, DATE '2025-04-22', 'Contribution diaspora equipement', 'mobile_money'::mode_paiement, 'MOMO-SONO-002', 'brouillon', NULL::TEXT, NULL::TEXT)
  ) AS x(code, account_kind, campaign_code, pledge_code, member_rn, tiers_rn, contributor, type, amount, date_mouvement, label, payment_mode, reference, statut, proof_url, reject_reason)
)
INSERT INTO mouvements_financiers (
  id,
  organization_id,
  church_unit_id,
  financial_account_id,
  campagne_id,
  promesse_id,
  membre_id,
  tiers_id,
  contributeur_nom,
  type,
  montant,
  date_mouvement,
  libelle,
  mode_paiement,
  reference_externe,
  piece_justificative_url,
  statut,
  submitted_at,
  validated_at,
  rejet_motif
)
SELECT
  pg_temp.demo_uuid('demo-movement-extra:' || p.organization_id || ':' || ms.code),
  p.organization_id,
  p.unit_id,
  CASE ms.account_kind
    WHEN 'cash' THEN a.cash_id
    WHEN 'bank' THEN a.bank_id
    ELSE a.momo_id
  END,
  CASE WHEN ms.campaign_code IS NULL THEN NULL ELSE pg_temp.demo_uuid('demo-campaign-extra:' || p.organization_id || ':' || ms.campaign_code) END,
  CASE WHEN ms.pledge_code IS NULL THEN NULL ELSE pg_temp.demo_uuid('demo-pledge-extra:' || p.organization_id || ':' || ms.pledge_code) END,
  mr.id,
  tr.id,
  ms.contributor,
  ms.type,
  ms.amount,
  ms.date_mouvement,
  ms.label,
  ms.payment_mode,
  ms.reference,
  ms.proof_url,
  ms.statut,
  CASE WHEN ms.statut = 'soumis' THEN (ms.date_mouvement::TEXT || 'T09:00:00Z')::TIMESTAMPTZ ELSE NULL END,
  CASE WHEN ms.statut = 'valide' THEN (ms.date_mouvement::TEXT || 'T12:00:00Z')::TIMESTAMPTZ ELSE NULL END,
  ms.reject_reason
FROM primary_units p
JOIN accounts a ON a.organization_id = p.organization_id
CROSS JOIN movement_specs ms
LEFT JOIN members_ranked mr
  ON mr.organization_id = p.organization_id
 AND mr.rn = ms.member_rn
LEFT JOIN tiers_ranked tr
  ON tr.organization_id = p.organization_id
 AND tr.rn = ms.tiers_rn
ON CONFLICT (id) DO NOTHING;

-- 5) Add balanced SYSCEBNL accounting entries for validated enrichment movements.
WITH primary_units AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organization_id,
    cu.id AS unit_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
  ORDER BY o.id, cu.created_at, cu.id
),
journals AS (
  SELECT p.organization_id, p.unit_id,
         min(j.id::TEXT) FILTER (WHERE j.type = 'caisse')::UUID AS cash_journal_id,
         min(j.id::TEXT) FILTER (WHERE j.type = 'banque')::UUID AS bank_journal_id
  FROM primary_units p
  JOIN journaux_comptables j ON j.organization_id = p.organization_id
  GROUP BY p.organization_id, p.unit_id
),
entry_specs AS (
  SELECT *
  FROM (VALUES
    ('mission-recette', 'cash', DATE '2025-03-14', 'REC-MIS-001', 'Offrande speciale mission rurale'),
    ('sono-recette', 'bank', DATE '2025-04-12', 'REC-SONO-001', 'Appui fournisseur sonorisation'),
    ('sono-depense', 'bank', DATE '2025-04-18', 'DEP-SONO-001', 'Acompte achat sonorisation'),
    ('visite-depense', 'cash', DATE '2025-04-20', 'DEP-VIS-001', 'Transport equipe de visite pastorale')
  ) AS x(code, journal_kind, date, reference, label)
)
INSERT INTO ecritures_comptables (
  id,
  organization_id,
  church_unit_id,
  id_journal,
  date,
  reference_piece,
  libelle,
  statut,
  validated_at
)
SELECT
  pg_temp.demo_uuid('demo-entry-extra:' || p.organization_id || ':' || e.code),
  p.organization_id,
  p.unit_id,
  CASE e.journal_kind WHEN 'bank' THEN j.bank_journal_id ELSE j.cash_journal_id END,
  e.date,
  e.reference,
  e.label,
  'validee'::statut_ecriture,
  (e.date::TEXT || 'T12:00:00Z')::TIMESTAMPTZ
FROM primary_units p
JOIN journals j ON j.organization_id = p.organization_id
CROSS JOIN entry_specs e
ON CONFLICT (id) DO NOTHING;

WITH primary_units AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organization_id,
    cu.id AS unit_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
  ORDER BY o.id, cu.created_at, cu.id
),
account_map AS (
  SELECT organization_id,
         min(id::TEXT) FILTER (WHERE numero = '5121')::UUID AS bank_account_id,
         min(id::TEXT) FILTER (WHERE numero = '531')::UUID AS cash_account_id,
         min(id::TEXT) FILTER (WHERE numero = '2183')::UUID AS equipment_account_id,
         min(id::TEXT) FILTER (WHERE numero = '613')::UUID AS expense_account_id,
         min(id::TEXT) FILTER (WHERE numero = '706')::UUID AS donation_account_id,
         min(id::TEXT) FILTER (WHERE numero = '758')::UUID AS other_income_account_id
  FROM comptes_comptables
  GROUP BY organization_id
),
center_map AS (
  SELECT DISTINCT ON (organization_id) organization_id, id AS center_id
  FROM centres_analytiques
  ORDER BY organization_id, created_at, id
),
third_party_map AS (
  SELECT DISTINCT ON (organization_id) organization_id, id AS third_party_id
  FROM tiers
  ORDER BY organization_id, created_at, id
),
line_specs AS (
  SELECT *
  FROM (VALUES
    ('mission-recette', 1, 'cash', 'Encaissement caisse mission rurale', 45000, 0, 'especes'::mode_paiement),
    ('mission-recette', 2, 'other_income', 'Offrande speciale mission rurale', 0, 45000, NULL::mode_paiement),
    ('sono-recette', 1, 'bank', 'Encaissement banque sonorisation', 100000, 0, 'virement_bancaire'::mode_paiement),
    ('sono-recette', 2, 'donation', 'Don affecte sonorisation', 0, 100000, NULL::mode_paiement),
    ('sono-depense', 1, 'equipment', 'Materiel de sonorisation', 280000, 0, NULL::mode_paiement),
    ('sono-depense', 2, 'bank', 'Reglement banque sonorisation', 0, 280000, 'virement_bancaire'::mode_paiement),
    ('visite-depense', 1, 'expense', 'Transport mission pastorale', 35000, 0, NULL::mode_paiement),
    ('visite-depense', 2, 'cash', 'Sortie caisse transport pastoral', 0, 35000, 'especes'::mode_paiement)
  ) AS x(entry_code, line_no, account_kind, label, debit, credit, payment_mode)
)
INSERT INTO lignes_ecritures (
  id,
  id_ecriture,
  id_compte_comptable,
  id_centre_analytique,
  id_tiers,
  libelle,
  debit,
  credit,
  mode_paiement
)
SELECT
  pg_temp.demo_uuid('demo-entry-line-extra:' || p.organization_id || ':' || ls.entry_code || ':' || ls.line_no),
  pg_temp.demo_uuid('demo-entry-extra:' || p.organization_id || ':' || ls.entry_code),
  CASE ls.account_kind
    WHEN 'cash' THEN a.cash_account_id
    WHEN 'bank' THEN a.bank_account_id
    WHEN 'equipment' THEN a.equipment_account_id
    WHEN 'donation' THEN a.donation_account_id
    WHEN 'other_income' THEN a.other_income_account_id
    ELSE a.expense_account_id
  END,
  c.center_id,
  CASE WHEN ls.account_kind IN ('equipment', 'expense') THEN t.third_party_id ELSE NULL END,
  ls.label,
  ls.debit,
  ls.credit,
  ls.payment_mode
FROM primary_units p
JOIN account_map a ON a.organization_id = p.organization_id
LEFT JOIN center_map c ON c.organization_id = p.organization_id
LEFT JOIN third_party_map t ON t.organization_id = p.organization_id
CROSS JOIN line_specs ls
ON CONFLICT (id) DO NOTHING;

-- 6) Extend bank statements with April movements.
WITH primary_units AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organization_id,
    cu.id AS unit_id
  FROM organizations o
  JOIN church_units cu ON cu.organization_id = o.id
  JOIN church_unit_types cut ON cut.id = cu.type_id
  WHERE o.id IN (
      '00000000-0000-0000-0000-000000000001'::UUID,
      '00000000-0000-0000-0000-000000000002'::UUID
    )
    AND cut.can_have_members = TRUE
  ORDER BY o.id, cu.created_at, cu.id
),
statement_map AS (
  SELECT DISTINCT ON (rb.organization_id) rb.organization_id, rb.id AS statement_id
  FROM releves_bancaires rb
  JOIN primary_units p ON p.organization_id = rb.organization_id
  ORDER BY rb.organization_id, rb.created_at, rb.id
),
bank_account_map AS (
  SELECT p.organization_id,
         min(fa.id::TEXT) FILTER (WHERE fa.type = 'bank')::UUID AS financial_account_id,
         min(fa.comptable_account_id::TEXT) FILTER (WHERE fa.type = 'bank')::UUID AS comptable_account_id
  FROM primary_units p
  JOIN church_unit_financial_accounts fa
    ON fa.organization_id = p.organization_id
   AND fa.church_unit_id = p.unit_id
  GROUP BY p.organization_id
),
bank_specs AS (
  SELECT *
  FROM (VALUES
    ('sono-appui', DATE '2025-04-12', 'Appui fournisseur sonorisation', 100000, -380000, 'VIR-SONO-001', 'sono-recette'),
    ('sono-acompte', DATE '2025-04-18', 'Acompte achat sonorisation', -280000, -660000, 'DEP-SONO-001', 'sono-depense')
  ) AS x(code, date_operation, label, amount, balance_after, reference, entry_code)
)
INSERT INTO lignes_releves_bancaires (
  id,
  organization_id,
  releve_id,
  church_unit_id,
  id_compte_banque,
  financial_account_id,
  date_operation,
  libelle,
  montant,
  solde_apres_operation,
  reference_operation,
  est_pointe,
  id_ecriture_comptable_liee
)
SELECT
  pg_temp.demo_uuid('demo-bank-line-extra:' || p.organization_id || ':' || bs.code),
  p.organization_id,
  sm.statement_id,
  p.unit_id,
  bam.comptable_account_id,
  bam.financial_account_id,
  bs.date_operation,
  bs.label,
  bs.amount,
  bs.balance_after,
  bs.reference,
  TRUE,
  pg_temp.demo_uuid('demo-entry-extra:' || p.organization_id || ':' || bs.entry_code)
FROM primary_units p
JOIN statement_map sm ON sm.organization_id = p.organization_id
JOIN bank_account_map bam ON bam.organization_id = p.organization_id
CROSS JOIN bank_specs bs
ON CONFLICT (id) DO NOTHING;

UPDATE releves_bancaires rb
SET date_releve = DATE '2025-04-30',
    solde_final = -660000
WHERE rb.organization_id IN (
  '00000000-0000-0000-0000-000000000001'::UUID,
  '00000000-0000-0000-0000-000000000002'::UUID
);

COMMIT;

SELECT
  o.sigle,
  (SELECT COUNT(*) FROM membres x WHERE x.organization_id = o.id) AS membres,
  (SELECT COUNT(*) FROM programmes x WHERE x.organization_id = o.id) AS programmes,
  (SELECT COUNT(*) FROM rapports_mensuels_eab x WHERE x.organization_id = o.id) AS rapports_mensuels,
  (SELECT COUNT(*) FROM campagnes_financieres x WHERE x.organization_id = o.id) AS campagnes,
  (SELECT COUNT(*) FROM promesses_financieres x WHERE x.organization_id = o.id) AS promesses,
  (SELECT COUNT(*) FROM mouvements_financiers x WHERE x.organization_id = o.id) AS mouvements,
  (SELECT COUNT(*) FROM ecritures_comptables x WHERE x.organization_id = o.id) AS ecritures,
  (
    SELECT COUNT(*)
    FROM lignes_ecritures lx
    JOIN ecritures_comptables ex ON ex.id = lx.id_ecriture
    WHERE ex.organization_id = o.id
  ) AS lignes_ecritures,
  (SELECT COUNT(*) FROM lignes_releves_bancaires x WHERE x.organization_id = o.id) AS lignes_releves
FROM organizations o
WHERE o.id IN (
  '00000000-0000-0000-0000-000000000001'::UUID,
  '00000000-0000-0000-0000-000000000002'::UUID
)
ORDER BY o.sigle;

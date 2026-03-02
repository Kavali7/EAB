-- =============================================================================
-- Migration 00015 : Seed Template SYSCEBNL V1
-- =============================================================================
-- Objectif : Injecter le template fiscal SYSCEBNL standard V1 avec :
--   - 5 pages : COVER, IDENTITY, BILAN_ACTIF, BILAN_PASSIF, RESULTAT
--   - ~30 champs typés avec sections et ordres
--   - Mappings comptes→champs pour le pré-remplissage automatique
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Template principal
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.fiscal_templates (id, code, label, version, is_active)
VALUES (
  'a0000000-0000-0000-0000-000000000001'::UUID,
  'SYSCEBNL_2026',
  'Dossier Fiscal SYSCEBNL — Entités à But Non Lucratif (V1)',
  1,
  TRUE
)
ON CONFLICT (code) DO NOTHING;

-- Variable pour référence
-- Template ID: a0000000-0000-0000-0000-000000000001

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Pages du template (5 pages ordonnées)
-- ─────────────────────────────────────────────────────────────────────────────

-- Page 1 : COVER (Page de garde)
INSERT INTO public.fiscal_template_pages (id, template_id, code, title, page_order, layout)
VALUES (
  'b0000000-0000-0000-0000-000000000001'::UUID,
  'a0000000-0000-0000-0000-000000000001'::UUID,
  'COVER',
  'Page de Garde',
  1,
  '{"type": "form", "columns": 1}'::JSONB
)
ON CONFLICT (template_id, code) DO NOTHING;

-- Page 2 : IDENTITY (Identification)
INSERT INTO public.fiscal_template_pages (id, template_id, code, title, page_order, layout)
VALUES (
  'b0000000-0000-0000-0000-000000000002'::UUID,
  'a0000000-0000-0000-0000-000000000001'::UUID,
  'IDENTITY',
  'Identification de l''Entité',
  2,
  '{"type": "form", "columns": 2}'::JSONB
)
ON CONFLICT (template_id, code) DO NOTHING;

-- Page 3 : BILAN_ACTIF
INSERT INTO public.fiscal_template_pages (id, template_id, code, title, page_order, layout, rules)
VALUES (
  'b0000000-0000-0000-0000-000000000003'::UUID,
  'a0000000-0000-0000-0000-000000000001'::UUID,
  'BILAN_ACTIF',
  'Bilan — Actif',
  3,
  '{"type": "grid", "columns": ["Poste", "Montant brut", "Amort./Dépréc.", "Montant net"]}'::JSONB,
  '{"validate_total": "bilan.actif.total"}'::JSONB
)
ON CONFLICT (template_id, code) DO NOTHING;

-- Page 4 : BILAN_PASSIF
INSERT INTO public.fiscal_template_pages (id, template_id, code, title, page_order, layout, rules)
VALUES (
  'b0000000-0000-0000-0000-000000000004'::UUID,
  'a0000000-0000-0000-0000-000000000001'::UUID,
  'BILAN_PASSIF',
  'Bilan — Passif',
  4,
  '{"type": "grid", "columns": ["Poste", "Montant"]}'::JSONB,
  '{"validate_total": "bilan.passif.total", "must_equal": "bilan.actif.total"}'::JSONB
)
ON CONFLICT (template_id, code) DO NOTHING;

-- Page 5 : RESULTAT (Compte de résultat)
INSERT INTO public.fiscal_template_pages (id, template_id, code, title, page_order, layout, rules)
VALUES (
  'b0000000-0000-0000-0000-000000000005'::UUID,
  'a0000000-0000-0000-0000-000000000001'::UUID,
  'RESULTAT',
  'Compte de Résultat',
  5,
  '{"type": "grid", "columns": ["Poste", "Montant"]}'::JSONB,
  '{"validate_formula": "resultat.net = resultat.produits.total - resultat.charges.total"}'::JSONB
)
ON CONFLICT (template_id, code) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Champs par page
-- ─────────────────────────────────────────────────────────────────────────────

-- ========================
-- PAGE 1 : COVER
-- ========================
INSERT INTO public.fiscal_template_fields (page_id, field_key, label, field_type, field_order, section, required, ui) VALUES
('b0000000-0000-0000-0000-000000000001'::UUID, 'org.name',             'Nom de l''organisation',      'text',   1,  'Organisation',   TRUE,  '{"placeholder": "Ex: Église Évangélique du Bénin"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'org.sigle',            'Sigle',                       'text',   2,  'Organisation',   FALSE, '{"placeholder": "Ex: EEB"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'org.address',          'Adresse du siège',            'text',   3,  'Organisation',   FALSE, '{"placeholder": "BP 1234, Cotonou"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'org.phone',            'Téléphone',                   'text',   4,  'Organisation',   FALSE, '{"placeholder": "+229 97 00 00 00"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'org.email',            'Email',                       'text',   5,  'Organisation',   FALSE, '{"placeholder": "contact@eglise.org"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'org.nif',              'NIF (Numéro d''identification fiscale)', 'text', 6, 'Fiscal', FALSE, '{"placeholder": "Numéro fiscal"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'exercice.label',       'Libellé de l''exercice',      'text',   7,  'Exercice',       TRUE,  '{"placeholder": "Ex: Exercice 2026"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'exercice.date_debut',  'Date de début',               'date',   8,  'Exercice',       TRUE,  '{}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'exercice.date_fin',    'Date de fin',                 'date',   9,  'Exercice',       TRUE,  '{}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'currency',             'Devise',                      'text',   10, 'Exercice',       TRUE,  '{"default": "FCFA"}'::JSONB),
('b0000000-0000-0000-0000-000000000001'::UUID, 'is_draft',             'Document brouillon',          'bool',   11, 'Statut',         FALSE, '{}'::JSONB)
ON CONFLICT (page_id, field_key) DO NOTHING;

-- ========================
-- PAGE 2 : IDENTITY
-- ========================
INSERT INTO public.fiscal_template_fields (page_id, field_key, label, field_type, field_order, section, required, ui) VALUES
('b0000000-0000-0000-0000-000000000002'::UUID, 'org.type',               'Nature juridique',                 'select', 1,  'Nature',       FALSE, '{"options": ["Église", "ONG", "Association", "Fondation", "Autre"]}'::JSONB),
('b0000000-0000-0000-0000-000000000002'::UUID, 'org.registre',           'Numéro de registre / récépissé',   'text',   2,  'Nature',       FALSE, '{"placeholder": "Récépissé n°..."}'::JSONB),
('b0000000-0000-0000-0000-000000000002'::UUID, 'responsable.nom',        'Nom du responsable légal',         'text',   3,  'Responsable',  TRUE,  '{"placeholder": "Pasteur / Président"}'::JSONB),
('b0000000-0000-0000-0000-000000000002'::UUID, 'responsable.fonction',   'Fonction',                         'text',   4,  'Responsable',  FALSE, '{"placeholder": "Pasteur principal"}'::JSONB),
('b0000000-0000-0000-0000-000000000002'::UUID, 'responsable.contact',    'Contact du responsable',           'text',   5,  'Responsable',  FALSE, '{"placeholder": "Téléphone ou email"}'::JSONB),
('b0000000-0000-0000-0000-000000000002'::UUID, 'mode_production',        'Mode de production des comptes',   'select', 6,  'Méthode',      TRUE,  '{"options": ["Comptabilité interne", "Balance importée"]}'::JSONB),
('b0000000-0000-0000-0000-000000000002'::UUID, 'certification',          'Déclaration de sincérité',         'bool',   7,  'Déclaration',  FALSE, '{"hint": "Je certifie que les informations contenues dans ce dossier sont sincères et conformes."}'::JSONB)
ON CONFLICT (page_id, field_key) DO NOTHING;

-- ========================
-- PAGE 3 : BILAN_ACTIF
-- ========================
INSERT INTO public.fiscal_template_fields (page_id, field_key, label, field_type, field_order, section, required, compute, ui) VALUES
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.immo.brut',       'Immobilisations (brut)',           'money', 1,  'Immobilisations (classe 2)', FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.immo.amort',      'Amortissements et dépréciations',  'money', 2,  'Immobilisations (classe 2)', FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.immo.net',        'Immobilisations (net)',            'money', 3,  'Immobilisations (classe 2)', FALSE, '{"type": "formula", "formula": "bilan.actif.immo.brut - bilan.actif.immo.amort"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.stocks',          'Stocks (classe 3)',               'money', 4,  'Actif circulant',            FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.creances',        'Créances (classe 4 débiteur)',     'money', 5,  'Actif circulant',            FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.circulant.total', 'Total actif circulant',           'money', 6,  'Actif circulant',            FALSE, '{"type": "formula", "formula": "bilan.actif.stocks + bilan.actif.creances"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.tresorerie.total','Trésorerie active (classe 5)',     'money', 7,  'Trésorerie',                 FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000003'::UUID, 'bilan.actif.total',           'TOTAL ACTIF',                     'money', 8,  'Total',                      TRUE,  '{"type": "formula", "formula": "bilan.actif.immo.net + bilan.actif.circulant.total + bilan.actif.tresorerie.total"}'::JSONB, '{"readonly": true, "bold": true}'::JSONB)
ON CONFLICT (page_id, field_key) DO NOTHING;

-- ========================
-- PAGE 4 : BILAN_PASSIF
-- ========================
INSERT INTO public.fiscal_template_fields (page_id, field_key, label, field_type, field_order, section, required, compute, ui) VALUES
('b0000000-0000-0000-0000-000000000004'::UUID, 'bilan.passif.fonds_propres.total',  'Fonds propres / associatifs (classe 1)',  'money', 1, 'Fonds propres',    FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000004'::UUID, 'bilan.passif.resultat.net',         'Résultat net de l''exercice',            'money', 2, 'Fonds propres',    FALSE, '{"type": "mirror", "source": "resultat.net"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000004'::UUID, 'bilan.passif.dettes.total',         'Dettes (classe 4 créditeur + autres)',    'money', 3, 'Dettes',           FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000004'::UUID, 'bilan.passif.total',                'TOTAL PASSIF',                           'money', 4, 'Total',            TRUE,  '{"type": "formula", "formula": "bilan.passif.fonds_propres.total + bilan.passif.resultat.net + bilan.passif.dettes.total"}'::JSONB, '{"readonly": true, "bold": true}'::JSONB)
ON CONFLICT (page_id, field_key) DO NOTHING;

-- ========================
-- PAGE 5 : RESULTAT
-- ========================
INSERT INTO public.fiscal_template_fields (page_id, field_key, label, field_type, field_order, section, required, compute, ui) VALUES
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.produits.activites',     'Produits des activités ordinaires (cl. 7)', 'money', 1, 'Produits',  FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.produits.hao',           'Produits hors activités ordinaires (cl. 8 crédit)', 'money', 2, 'Produits', FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.produits.total',         'TOTAL PRODUITS',                            'money', 3, 'Produits',  TRUE,  '{"type": "formula", "formula": "resultat.produits.activites + resultat.produits.hao"}'::JSONB, '{"readonly": true, "bold": true}'::JSONB),
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.charges.activites',      'Charges des activités ordinaires (cl. 6)',   'money', 4, 'Charges',   FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.charges.hao',            'Charges hors activités ordinaires (cl. 8 débit)', 'money', 5, 'Charges', FALSE, '{"type": "auto"}'::JSONB, '{"readonly": true}'::JSONB),
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.charges.total',          'TOTAL CHARGES',                             'money', 6, 'Charges',   TRUE,  '{"type": "formula", "formula": "resultat.charges.activites + resultat.charges.hao"}'::JSONB, '{"readonly": true, "bold": true}'::JSONB),
('b0000000-0000-0000-0000-000000000005'::UUID, 'resultat.net',                    'RÉSULTAT NET',                              'money', 7, 'Résultat',  TRUE,  '{"type": "formula", "formula": "resultat.produits.total - resultat.charges.total"}'::JSONB, '{"readonly": true, "bold": true, "highlight": true}'::JSONB)
ON CONFLICT (page_id, field_key) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Mappings comptes → champs (pré-remplissage automatique)
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.fiscal_account_mapping (template_id, field_key, rule_type, params) VALUES
-- BILAN ACTIF
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.actif.immo.brut',        'sum_prefixes', '{"prefixes": ["2"], "sign": "debit"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.actif.immo.amort',       'sum_prefixes', '{"prefixes": ["28"], "sign": "credit"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.actif.stocks',           'sum_prefixes', '{"prefixes": ["3"], "sign": "debit"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.actif.creances',         'sum_prefixes', '{"prefixes": ["4"], "sign": "debit"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.actif.tresorerie.total', 'sum_prefixes', '{"prefixes": ["5"], "sign": "debit"}'::JSONB),

-- BILAN PASSIF
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.passif.fonds_propres.total', 'sum_prefixes', '{"prefixes": ["1"], "sign": "credit"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'bilan.passif.dettes.total',        'sum_prefixes', '{"prefixes": ["4"], "sign": "credit"}'::JSONB),

-- RÉSULTAT
('a0000000-0000-0000-0000-000000000001'::UUID, 'resultat.produits.activites', 'balance_class', '{"class_prefix": "7"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'resultat.produits.hao',       'sum_prefixes',  '{"prefixes": ["8"], "sign": "credit"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'resultat.charges.activites',  'balance_class', '{"class_prefix": "6"}'::JSONB),
('a0000000-0000-0000-0000-000000000001'::UUID, 'resultat.charges.hao',        'sum_prefixes',  '{"prefixes": ["8"], "sign": "debit"}'::JSONB)
ON CONFLICT (template_id, field_key) DO NOTHING;

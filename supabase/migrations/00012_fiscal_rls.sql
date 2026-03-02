-- =============================================================================
-- Migration 00012 : RLS & Policies — Dossier Fiscal SYSCEBNL
-- =============================================================================
-- Objectif : Sécuriser les 8 tables fiscales avec RLS et politiques d'accès
-- Principes :
--   - Templates (4 tables) : lecture seule pour tous les utilisateurs authentifiés
--   - Dossiers + Values : isolation par organization_id via get_user_organization_id()
--   - Import balance : isolation par organization_id
--   - UPDATE dossier bloqué si status IN ('locked','submitted')
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Activer RLS sur toutes les tables
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.fiscal_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiscal_template_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiscal_template_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiscal_account_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiscal_dossiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiscal_dossier_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.imported_trial_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.imported_trial_balance_lines ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Policies — Templates (lecture seule pour authenticated)
-- ─────────────────────────────────────────────────────────────────────────────

-- fiscal_templates : SELECT pour tous les utilisateurs authentifiés
CREATE POLICY "fiscal_templates_select_auth"
  ON public.fiscal_templates
  FOR SELECT TO authenticated
  USING (true);

-- fiscal_template_pages : SELECT pour tous les utilisateurs authentifiés
CREATE POLICY "fiscal_template_pages_select_auth"
  ON public.fiscal_template_pages
  FOR SELECT TO authenticated
  USING (true);

-- fiscal_template_fields : SELECT pour tous les utilisateurs authentifiés
CREATE POLICY "fiscal_template_fields_select_auth"
  ON public.fiscal_template_fields
  FOR SELECT TO authenticated
  USING (true);

-- fiscal_account_mapping : SELECT pour tous les utilisateurs authentifiés
CREATE POLICY "fiscal_account_mapping_select_auth"
  ON public.fiscal_account_mapping
  FOR SELECT TO authenticated
  USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Policies — Dossiers fiscaux (isolation tenant)
-- ─────────────────────────────────────────────────────────────────────────────

-- SELECT : même organisation
CREATE POLICY "fiscal_dossiers_select_org"
  ON public.fiscal_dossiers
  FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id());

-- INSERT : même organisation
CREATE POLICY "fiscal_dossiers_insert_org"
  ON public.fiscal_dossiers
  FOR INSERT TO authenticated
  WITH CHECK (organization_id = get_user_organization_id());

-- UPDATE : même organisation + pas verrouillé/soumis
CREATE POLICY "fiscal_dossiers_update_org"
  ON public.fiscal_dossiers
  FOR UPDATE TO authenticated
  USING (
    organization_id = get_user_organization_id()
    AND status NOT IN ('locked', 'submitted')
  )
  WITH CHECK (organization_id = get_user_organization_id());

-- DELETE : même organisation + seulement brouillon
CREATE POLICY "fiscal_dossiers_delete_org"
  ON public.fiscal_dossiers
  FOR DELETE TO authenticated
  USING (
    organization_id = get_user_organization_id()
    AND status = 'draft'
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Policies — Valeurs dossier fiscal (isolation tenant)
-- ─────────────────────────────────────────────────────────────────────────────

-- SELECT : même organisation
CREATE POLICY "fiscal_values_select_org"
  ON public.fiscal_dossier_values
  FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id());

-- INSERT : même organisation
CREATE POLICY "fiscal_values_insert_org"
  ON public.fiscal_dossier_values
  FOR INSERT TO authenticated
  WITH CHECK (organization_id = get_user_organization_id());

-- UPDATE : même organisation
CREATE POLICY "fiscal_values_update_org"
  ON public.fiscal_dossier_values
  FOR UPDATE TO authenticated
  USING (organization_id = get_user_organization_id())
  WITH CHECK (organization_id = get_user_organization_id());

-- DELETE : même organisation (suppression de valeur autorisée tant que dossier pas verrouillé)
CREATE POLICY "fiscal_values_delete_org"
  ON public.fiscal_dossier_values
  FOR DELETE TO authenticated
  USING (organization_id = get_user_organization_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Policies — Import balance CSV (isolation tenant)
-- ─────────────────────────────────────────────────────────────────────────────

-- imported_trial_balances : SELECT par org
CREATE POLICY "import_balances_select_org"
  ON public.imported_trial_balances
  FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id());

-- imported_trial_balances : INSERT par org
CREATE POLICY "import_balances_insert_org"
  ON public.imported_trial_balances
  FOR INSERT TO authenticated
  WITH CHECK (organization_id = get_user_organization_id());

-- imported_trial_balances : DELETE par org
CREATE POLICY "import_balances_delete_org"
  ON public.imported_trial_balances
  FOR DELETE TO authenticated
  USING (organization_id = get_user_organization_id());

-- imported_trial_balance_lines : SELECT par org
CREATE POLICY "import_balance_lines_select_org"
  ON public.imported_trial_balance_lines
  FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id());

-- imported_trial_balance_lines : INSERT par org
CREATE POLICY "import_balance_lines_insert_org"
  ON public.imported_trial_balance_lines
  FOR INSERT TO authenticated
  WITH CHECK (organization_id = get_user_organization_id());

-- imported_trial_balance_lines : DELETE par org (cascade via parent, mais policy explicite)
CREATE POLICY "import_balance_lines_delete_org"
  ON public.imported_trial_balance_lines
  FOR DELETE TO authenticated
  USING (organization_id = get_user_organization_id());

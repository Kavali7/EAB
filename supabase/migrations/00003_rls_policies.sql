-- ============================================================================
-- EAB Backend - 00003 RLS Policies
-- ============================================================================
-- Politiques de sécurité Row Level Security par rôle
-- ============================================================================

-- ============================================================================
-- HELPER FUNCTIONS FOR RLS
-- ============================================================================

-- Get current user's organization ID
CREATE OR REPLACE FUNCTION get_user_organization_id()
RETURNS UUID AS $$
    SELECT organization_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS role_utilisateur AS $$
    SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user's region ID
CREATE OR REPLACE FUNCTION get_user_region_id()
RETURNS UUID AS $$
    SELECT id_region FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user's district ID
CREATE OR REPLACE FUNCTION get_user_district_id()
RETURNS UUID AS $$
    SELECT id_district FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user's assemblee ID
CREATE OR REPLACE FUNCTION get_user_assemblee_id()
RETURNS UUID AS $$
    SELECT id_assemblee_locale FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if user has access to a specific region
CREATE OR REPLACE FUNCTION user_has_region_access(target_region_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_role role_utilisateur;
    user_region_id UUID;
BEGIN
    SELECT role, id_region INTO user_role, user_region_id 
    FROM profiles WHERE id = auth.uid();
    
    -- Admin national has access to everything
    IF user_role = 'admin_national' THEN
        RETURN TRUE;
    END IF;
    
    -- Responsable région has access to their region
    IF user_role = 'responsable_region' AND user_region_id = target_region_id THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if user has access to a specific district
CREATE OR REPLACE FUNCTION user_has_district_access(target_district_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_role role_utilisateur;
    user_region_id UUID;
    user_district_id UUID;
    district_region_id UUID;
BEGIN
    SELECT role, id_region, id_district INTO user_role, user_region_id, user_district_id 
    FROM profiles WHERE id = auth.uid();
    
    -- Admin national has access to everything
    IF user_role = 'admin_national' THEN
        RETURN TRUE;
    END IF;
    
    -- Get the region of the target district
    SELECT id_region INTO district_region_id 
    FROM districts_eglise WHERE id = target_district_id;
    
    -- Responsable région has access to districts in their region
    IF user_role = 'responsable_region' AND user_region_id = district_region_id THEN
        RETURN TRUE;
    END IF;
    
    -- Surintendant has access to their district
    IF user_role = 'surintendant_district' AND user_district_id = target_district_id THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if user has access to a specific assemblee
CREATE OR REPLACE FUNCTION user_has_assemblee_access(target_assemblee_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_role role_utilisateur;
    user_region_id UUID;
    user_district_id UUID;
    user_assemblee_id UUID;
    assemblee_district_id UUID;
    district_region_id UUID;
BEGIN
    SELECT role, id_region, id_district, id_assemblee_locale 
    INTO user_role, user_region_id, user_district_id, user_assemblee_id 
    FROM profiles WHERE id = auth.uid();
    
    -- Admin national has access to everything
    IF user_role = 'admin_national' THEN
        RETURN TRUE;
    END IF;
    
    -- Get the district and region of the target assemblee
    SELECT a.id_district, d.id_region 
    INTO assemblee_district_id, district_region_id
    FROM assemblees_locales a
    JOIN districts_eglise d ON d.id = a.id_district
    WHERE a.id = target_assemblee_id;
    
    -- Responsable région has access to assemblees in their region
    IF user_role = 'responsable_region' AND user_region_id = district_region_id THEN
        RETURN TRUE;
    END IF;
    
    -- Surintendant has access to assemblees in their district
    IF user_role = 'surintendant_district' AND user_district_id = assemblee_district_id THEN
        RETURN TRUE;
    END IF;
    
    -- Trésorier has access to their assemblee only
    IF user_role = 'tresorier_assemblee' AND user_assemblee_id = target_assemblee_id THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- ORGANIZATIONS POLICIES
-- ============================================================================

-- Users can only see their own organization
CREATE POLICY "Users can view own organization"
    ON organizations FOR SELECT
    USING (id = get_user_organization_id());

-- Only admin_national can insert/update/delete organizations
CREATE POLICY "Admin can manage organizations"
    ON organizations FOR ALL
    USING (get_user_role() = 'admin_national' AND id = get_user_organization_id());

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================

-- Users can view profiles in their organization
CREATE POLICY "Users can view profiles in own org"
    ON profiles FOR SELECT
    USING (organization_id = get_user_organization_id());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (id = auth.uid());

-- Admin can manage all profiles in their org
CREATE POLICY "Admin can manage profiles"
    ON profiles FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- ============================================================================
-- REGIONS POLICIES
-- ============================================================================

-- View: based on organization
CREATE POLICY "Users can view regions in own org"
    ON regions_eglise FOR SELECT
    USING (organization_id = get_user_organization_id());

-- Insert/Update/Delete: Admin national only
CREATE POLICY "Admin can manage regions"
    ON regions_eglise FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Responsable region can update their region
CREATE POLICY "Responsable can update own region"
    ON regions_eglise FOR UPDATE
    USING (
        get_user_role() = 'responsable_region' 
        AND organization_id = get_user_organization_id()
        AND id = get_user_region_id()
    );

-- ============================================================================
-- DISTRICTS POLICIES
-- ============================================================================

-- View: based on organization
CREATE POLICY "Users can view districts in own org"
    ON districts_eglise FOR SELECT
    USING (organization_id = get_user_organization_id());

-- Admin can manage all districts
CREATE POLICY "Admin can manage districts"
    ON districts_eglise FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Responsable region can manage districts in their region
CREATE POLICY "Responsable can manage districts in region"
    ON districts_eglise FOR ALL
    USING (
        get_user_role() = 'responsable_region' 
        AND organization_id = get_user_organization_id()
        AND id_region = get_user_region_id()
    );

-- ============================================================================
-- ASSEMBLEES POLICIES
-- ============================================================================

-- View: based on organization
CREATE POLICY "Users can view assemblees in own org"
    ON assemblees_locales FOR SELECT
    USING (organization_id = get_user_organization_id());

-- Admin can manage all assemblees
CREATE POLICY "Admin can manage assemblees"
    ON assemblees_locales FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Responsable region can manage assemblees in their region
CREATE POLICY "Responsable can manage assemblees in region"
    ON assemblees_locales FOR ALL
    USING (
        get_user_role() = 'responsable_region' 
        AND organization_id = get_user_organization_id()
        AND user_has_assemblee_access(id)
    );

-- Surintendant can manage assemblees in their district
CREATE POLICY "Surintendant can manage assemblees in district"
    ON assemblees_locales FOR ALL
    USING (
        get_user_role() = 'surintendant_district' 
        AND organization_id = get_user_organization_id()
        AND id_district = get_user_district_id()
    );

-- Trésorier can update their assemblee
CREATE POLICY "Tresorier can update own assemblee"
    ON assemblees_locales FOR UPDATE
    USING (
        get_user_role() = 'tresorier_assemblee' 
        AND organization_id = get_user_organization_id()
        AND id = get_user_assemblee_id()
    );

-- ============================================================================
-- MEMBRES POLICIES
-- ============================================================================

-- View: based on user access level
CREATE POLICY "Users can view membres based on access"
    ON membres FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- Insert/Update/Delete: based on user access level
CREATE POLICY "Users can manage membres based on access"
    ON membres FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- ============================================================================
-- FAMILLES POLICIES
-- ============================================================================

CREATE POLICY "Users can view familles based on access"
    ON familles FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage familles based on access"
    ON familles FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- ============================================================================
-- PROGRAMMES POLICIES
-- ============================================================================

CREATE POLICY "Users can view programmes based on access"
    ON programmes FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage programmes based on access"
    ON programmes FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- ============================================================================
-- ACCOUNTING TABLES POLICIES (Same pattern)
-- ============================================================================

-- Comptes comptables (read by all in org, manage by admin)
CREATE POLICY "Users can view comptes in own org"
    ON comptes_comptables FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Admin can manage comptes"
    ON comptes_comptables FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Journaux comptables
CREATE POLICY "Users can view journaux in own org"
    ON journaux_comptables FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Admin can manage journaux"
    ON journaux_comptables FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Centres analytiques
CREATE POLICY "Users can view centres in own org"
    ON centres_analytiques FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Admin can manage centres"
    ON centres_analytiques FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Tiers
CREATE POLICY "Users can view tiers based on access"
    ON tiers FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
            OR id_assemblee_locale IS NULL
        )
    );

CREATE POLICY "Users can manage tiers based on access"
    ON tiers FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- Ecritures comptables
CREATE POLICY "Users can view ecritures based on access"
    ON ecritures_comptables FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage ecritures based on access"
    ON ecritures_comptables FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- Lignes d'écritures (via parent ecriture)
CREATE POLICY "Users can view lignes via ecriture"
    ON lignes_ecritures FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM ecritures_comptables e 
            WHERE e.id = lignes_ecritures.id_ecriture
            AND e.organization_id = get_user_organization_id()
            AND (
                get_user_role() = 'admin_national'
                OR user_has_assemblee_access(e.id_assemblee_locale)
            )
        )
    );

CREATE POLICY "Users can manage lignes via ecriture"
    ON lignes_ecritures FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM ecritures_comptables e 
            WHERE e.id = lignes_ecritures.id_ecriture
            AND e.organization_id = get_user_organization_id()
            AND (
                get_user_role() = 'admin_national'
                OR user_has_assemblee_access(e.id_assemblee_locale)
            )
        )
    );

-- Budgets
CREATE POLICY "Users can view budgets based on access"
    ON budgets_comptables FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage budgets based on access"
    ON budgets_comptables FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- Lignes de budget (via parent budget)
CREATE POLICY "Users can view lignes budget via budget"
    ON lignes_budgets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM budgets_comptables b 
            WHERE b.id = lignes_budgets.id_budget
            AND b.organization_id = get_user_organization_id()
            AND (
                get_user_role() = 'admin_national'
                OR user_has_assemblee_access(b.id_assemblee_locale)
            )
        )
    );

CREATE POLICY "Users can manage lignes budget via budget"
    ON lignes_budgets FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM budgets_comptables b 
            WHERE b.id = lignes_budgets.id_budget
            AND b.organization_id = get_user_organization_id()
            AND (
                get_user_role() = 'admin_national'
                OR user_has_assemblee_access(b.id_assemblee_locale)
            )
        )
    );

-- Immobilisations
CREATE POLICY "Users can view immobilisations based on access"
    ON immobilisations_comptables FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage immobilisations based on access"
    ON immobilisations_comptables FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- Rapports mensuels
CREATE POLICY "Users can view rapports based on access"
    ON rapports_mensuels_eab FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage rapports based on access"
    ON rapports_mensuels_eab FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

-- Relevés bancaires
CREATE POLICY "Users can view releves based on access"
    ON releves_bancaires FOR SELECT
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

CREATE POLICY "Users can manage releves based on access"
    ON releves_bancaires FOR ALL
    USING (
        organization_id = get_user_organization_id()
        AND (
            get_user_role() = 'admin_national'
            OR user_has_assemblee_access(id_assemblee_locale)
        )
    );

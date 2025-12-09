-- ============================================================================
-- EAB Backend - 00004 Functions & Triggers
-- ============================================================================
-- Fonctions et triggers pour la logique métier
-- ============================================================================

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_regions_eglise_updated_at
    BEFORE UPDATE ON regions_eglise
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_districts_eglise_updated_at
    BEFORE UPDATE ON districts_eglise
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assemblees_locales_updated_at
    BEFORE UPDATE ON assemblees_locales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_familles_updated_at
    BEFORE UPDATE ON familles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_membres_updated_at
    BEFORE UPDATE ON membres
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_programmes_updated_at
    BEFORE UPDATE ON programmes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comptes_comptables_updated_at
    BEFORE UPDATE ON comptes_comptables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_journaux_comptables_updated_at
    BEFORE UPDATE ON journaux_comptables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_centres_analytiques_updated_at
    BEFORE UPDATE ON centres_analytiques
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tiers_updated_at
    BEFORE UPDATE ON tiers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ecritures_comptables_updated_at
    BEFORE UPDATE ON ecritures_comptables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lignes_ecritures_updated_at
    BEFORE UPDATE ON lignes_ecritures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_comptables_updated_at
    BEFORE UPDATE ON budgets_comptables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lignes_budgets_updated_at
    BEFORE UPDATE ON lignes_budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_immobilisations_comptables_updated_at
    BEFORE UPDATE ON immobilisations_comptables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rapports_mensuels_eab_updated_at
    BEFORE UPDATE ON rapports_mensuels_eab
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_releves_bancaires_updated_at
    BEFORE UPDATE ON releves_bancaires
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- HANDLE NEW USER (Create profile on signup)
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'tresorier_assemblee'::role_utilisateur
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- VERIFY ECRITURE EQUILIBREE
-- ============================================================================
-- Ensures that total debits = total credits for an accounting entry

CREATE OR REPLACE FUNCTION verify_ecriture_equilibree()
RETURNS TRIGGER AS $$
DECLARE
    total_debit DECIMAL(15,2);
    total_credit DECIMAL(15,2);
    ecriture_statut statut_ecriture;
BEGIN
    -- Get the status of the parent ecriture
    SELECT statut INTO ecriture_statut
    FROM ecritures_comptables
    WHERE id = COALESCE(NEW.id_ecriture, OLD.id_ecriture);
    
    -- Only check for validated or closed entries
    IF ecriture_statut IN ('validee', 'cloturee') THEN
        SELECT 
            COALESCE(SUM(debit), 0),
            COALESCE(SUM(credit), 0)
        INTO total_debit, total_credit
        FROM lignes_ecritures
        WHERE id_ecriture = COALESCE(NEW.id_ecriture, OLD.id_ecriture);
        
        IF total_debit != total_credit THEN
            RAISE EXCEPTION 'Écriture déséquilibrée: Débit (%) != Crédit (%)', total_debit, total_credit;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger after insert/update/delete on lignes_ecritures
CREATE TRIGGER check_ecriture_equilibree
    AFTER INSERT OR UPDATE OR DELETE ON lignes_ecritures
    FOR EACH ROW EXECUTE FUNCTION verify_ecriture_equilibree();

-- ============================================================================
-- PREVENT MODIFICATION OF VALIDATED ECRITURES
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_modification_validated_ecriture()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.statut IN ('validee', 'cloturee') AND TG_OP = 'UPDATE' THEN
        -- Allow only changing status from validee to cloturee
        IF NEW.statut = OLD.statut OR (OLD.statut = 'validee' AND NEW.statut = 'cloturee') THEN
            -- Check if any other field changed
            IF NEW.date != OLD.date 
               OR NEW.id_journal != OLD.id_journal 
               OR NEW.libelle != OLD.libelle 
               OR NEW.reference_piece != OLD.reference_piece THEN
                RAISE EXCEPTION 'Impossible de modifier une écriture validée ou clôturée';
            END IF;
        ELSE
            RAISE EXCEPTION 'Impossible de modifier le statut d''une écriture clôturée';
        END IF;
    END IF;
    
    IF OLD.statut IN ('validee', 'cloturee') AND TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Impossible de supprimer une écriture validée ou clôturée';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER protect_validated_ecritures
    BEFORE UPDATE OR DELETE ON ecritures_comptables
    FOR EACH ROW EXECUTE FUNCTION prevent_modification_validated_ecriture();

-- ============================================================================
-- VALIDATE ECRITURE (Set validated_by and validated_at)
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_ecriture(ecriture_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    total_debit DECIMAL(15,2);
    total_credit DECIMAL(15,2);
BEGIN
    -- Check balance
    SELECT 
        COALESCE(SUM(debit), 0),
        COALESCE(SUM(credit), 0)
    INTO total_debit, total_credit
    FROM lignes_ecritures
    WHERE id_ecriture = ecriture_id;
    
    IF total_debit != total_credit THEN
        RAISE EXCEPTION 'Écriture déséquilibrée: Débit (%) != Crédit (%)', total_debit, total_credit;
        RETURN FALSE;
    END IF;
    
    IF total_debit = 0 THEN
        RAISE EXCEPTION 'Écriture vide: aucune ligne';
        RETURN FALSE;
    END IF;
    
    -- Update status
    UPDATE ecritures_comptables
    SET 
        statut = 'validee',
        validated_by = auth.uid(),
        validated_at = NOW()
    WHERE id = ecriture_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- CALCULATE SOLDE COMPTE
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_solde_compte(
    p_compte_id UUID,
    p_date_debut DATE DEFAULT NULL,
    p_date_fin DATE DEFAULT NULL
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    total_debit DECIMAL(15,2);
    total_credit DECIMAL(15,2);
    compte_nature nature_compte;
BEGIN
    -- Get account nature
    SELECT nature INTO compte_nature
    FROM comptes_comptables
    WHERE id = p_compte_id;
    
    -- Calculate totals
    SELECT 
        COALESCE(SUM(l.debit), 0),
        COALESCE(SUM(l.credit), 0)
    INTO total_debit, total_credit
    FROM lignes_ecritures l
    JOIN ecritures_comptables e ON e.id = l.id_ecriture
    WHERE l.id_compte_comptable = p_compte_id
    AND e.statut IN ('validee', 'cloturee')
    AND (p_date_debut IS NULL OR e.date >= p_date_debut)
    AND (p_date_fin IS NULL OR e.date <= p_date_fin);
    
    -- Return based on account nature
    -- Actif/Charge: Solde = Débit - Crédit
    -- Passif/Produit: Solde = Crédit - Débit
    IF compte_nature IN ('actif', 'charge') THEN
        RETURN total_debit - total_credit;
    ELSE
        RETURN total_credit - total_debit;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- GENERATE RAPPORT MENSUEL
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_rapport_mensuel(
    p_assemblee_id UUID,
    p_annee INTEGER,
    p_mois INTEGER
)
RETURNS UUID AS $$
DECLARE
    v_organization_id UUID;
    v_rapport_id UUID;
    v_date_debut DATE;
    v_date_fin DATE;
    v_stats_membres JSONB;
    v_stats_activites JSONB;
    v_stats_finances JSONB;
BEGIN
    -- Get organization
    SELECT organization_id INTO v_organization_id
    FROM assemblees_locales WHERE id = p_assemblee_id;
    
    -- Calculate date range
    v_date_debut := make_date(p_annee, p_mois, 1);
    v_date_fin := (v_date_debut + interval '1 month - 1 day')::date;
    
    -- Calculate stats membres
    SELECT jsonb_build_object(
        'totalMembresActifs', COUNT(*) FILTER (WHERE statut = 'actif'),
        'totalHommesActifs', COUNT(*) FILTER (WHERE statut = 'actif' AND gender = 'male'),
        'totalFemmesActives', COUNT(*) FILTER (WHERE statut = 'actif' AND gender = 'female'),
        'totalOfficiers', COUNT(*) FILTER (WHERE statut = 'actif' AND role != 'membre'),
        'nouveauxConvertis', COUNT(*) FILTER (WHERE date_conversion BETWEEN v_date_debut AND v_date_fin),
        'nouveauxBaptises', COUNT(*) FILTER (WHERE date_bapteme BETWEEN v_date_debut AND v_date_fin),
        'deces', COUNT(*) FILTER (WHERE date_deces BETWEEN v_date_debut AND v_date_fin)
    ) INTO v_stats_membres
    FROM membres
    WHERE id_assemblee_locale = p_assemblee_id;
    
    -- Calculate stats activites
    SELECT jsonb_build_object(
        'nbCultes', COUNT(*) FILTER (WHERE type = 'culte'),
        'nbEvangelisationsMasse', COUNT(*) FILTER (WHERE type = 'evangelisation_masse'),
        'nbBaptemes', COUNT(*) FILTER (WHERE type = 'baptemes'),
        'nbSaintesCenes', COUNT(*) FILTER (WHERE type = 'sainte_cene'),
        'nbReunionsPriere', COUNT(*) FILTER (WHERE type = 'reunion_priere'),
        'nbMariages', COUNT(*) FILTER (WHERE type = 'mariage'),
        'totalConversions', SUM(COALESCE(conversions_hommes, 0) + COALESCE(conversions_femmes, 0) + COALESCE(conversions_garcons, 0) + COALESCE(conversions_filles, 0))
    ) INTO v_stats_activites
    FROM programmes
    WHERE id_assemblee_locale = p_assemblee_id
    AND date BETWEEN v_date_debut AND v_date_fin;
    
    -- Calculate stats finances
    SELECT jsonb_build_object(
        'totalProduits', COALESCE(SUM(l.credit) FILTER (WHERE c.nature = 'produit'), 0),
        'totalCharges', COALESCE(SUM(l.debit) FILTER (WHERE c.nature = 'charge'), 0)
    ) INTO v_stats_finances
    FROM lignes_ecritures l
    JOIN ecritures_comptables e ON e.id = l.id_ecriture
    JOIN comptes_comptables c ON c.id = l.id_compte_comptable
    WHERE e.id_assemblee_locale = p_assemblee_id
    AND e.date BETWEEN v_date_debut AND v_date_fin
    AND e.statut IN ('validee', 'cloturee');
    
    -- Insert or update rapport
    INSERT INTO rapports_mensuels_eab (
        organization_id,
        id_assemblee_locale,
        annee,
        mois,
        stats_membres,
        stats_activites,
        stats_finances
    ) VALUES (
        v_organization_id,
        p_assemblee_id,
        p_annee,
        p_mois,
        v_stats_membres,
        v_stats_activites,
        v_stats_finances
    )
    ON CONFLICT (organization_id, id_assemblee_locale, annee, mois)
    DO UPDATE SET
        stats_membres = EXCLUDED.stats_membres,
        stats_activites = EXCLUDED.stats_activites,
        stats_finances = EXCLUDED.stats_finances,
        updated_at = NOW()
    RETURNING id INTO v_rapport_id;
    
    RETURN v_rapport_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GET HIERARCHY (For navigation)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_assemblee_hierarchy(p_assemblee_id UUID)
RETURNS TABLE (
    assemblee_id UUID,
    assemblee_nom TEXT,
    district_id UUID,
    district_nom TEXT,
    region_id UUID,
    region_nom TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.nom,
        d.id,
        d.nom,
        r.id,
        r.nom
    FROM assemblees_locales a
    JOIN districts_eglise d ON d.id = a.id_district
    JOIN regions_eglise r ON r.id = d.id_region
    WHERE a.id = p_assemblee_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

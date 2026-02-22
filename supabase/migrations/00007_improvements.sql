-- ============================================================================
-- EAB Backend - 00007 Improvements
-- ============================================================================
-- Améliorations : Exercices comptables, Soft Delete, Audit Trail, 
-- Numérotation automatique, Calcul des amortissements
-- ============================================================================

-- ============================================================================
-- TABLE DES EXERCICES COMPTABLES
-- ============================================================================

CREATE TABLE exercices_comptables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    annee INTEGER NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    libelle TEXT,
    
    -- État de l'exercice
    est_ouvert BOOLEAN NOT NULL DEFAULT TRUE,
    est_cloture BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Clôture
    cloture_par UUID REFERENCES profiles(id) ON DELETE SET NULL,
    cloture_at TIMESTAMPTZ,
    
    -- Métadonnées
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, annee)
);

COMMENT ON TABLE exercices_comptables IS 'Exercices comptables pour la gestion des périodes comptables.';

-- Trigger updated_at
CREATE TRIGGER update_exercices_comptables_updated_at
    BEFORE UPDATE ON exercices_comptables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE exercices_comptables ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view exercices in own org"
    ON exercices_comptables FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Admin can manage exercices"
    ON exercices_comptables FOR ALL
    USING (get_user_role() = 'admin_national' AND organization_id = get_user_organization_id());

-- Index
CREATE INDEX idx_exercices_organization ON exercices_comptables(organization_id);
CREATE INDEX idx_exercices_annee ON exercices_comptables(annee);
CREATE INDEX idx_exercices_dates ON exercices_comptables(date_debut, date_fin);

-- ============================================================================
-- SÉQUENCE POUR NUMÉROTATION AUTOMATIQUE DES PIÈCES
-- ============================================================================

CREATE TABLE sequences_pieces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    id_journal UUID NOT NULL REFERENCES journaux_comptables(id) ON DELETE CASCADE,
    exercice INTEGER NOT NULL,
    dernier_numero INTEGER NOT NULL DEFAULT 0,
    prefixe TEXT, -- ex: "CAI-2025-"
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(organization_id, id_journal, exercice)
);

COMMENT ON TABLE sequences_pieces IS 'Séquences de numérotation automatique des pièces comptables par journal et exercice.';

-- Fonction pour obtenir le prochain numéro de pièce
CREATE OR REPLACE FUNCTION get_next_piece_number(
    p_organization_id UUID,
    p_journal_id UUID,
    p_exercice INTEGER
)
RETURNS TEXT AS $$
DECLARE
    v_sequence sequences_pieces%ROWTYPE;
    v_nouveau_numero INTEGER;
    v_prefixe TEXT;
    v_code_journal TEXT;
BEGIN
    -- Obtenir le code du journal
    SELECT code INTO v_code_journal
    FROM journaux_comptables
    WHERE id = p_journal_id;
    
    -- Chercher ou créer la séquence
    SELECT * INTO v_sequence
    FROM sequences_pieces
    WHERE organization_id = p_organization_id
    AND id_journal = p_journal_id
    AND exercice = p_exercice
    FOR UPDATE;
    
    IF NOT FOUND THEN
        -- Créer la séquence
        v_prefixe := v_code_journal || '-' || p_exercice || '-';
        INSERT INTO sequences_pieces (organization_id, id_journal, exercice, dernier_numero, prefixe)
        VALUES (p_organization_id, p_journal_id, p_exercice, 1, v_prefixe)
        RETURNING * INTO v_sequence;
        
        RETURN v_sequence.prefixe || LPAD('1', 6, '0');
    ELSE
        -- Incrémenter
        v_nouveau_numero := v_sequence.dernier_numero + 1;
        
        UPDATE sequences_pieces
        SET dernier_numero = v_nouveau_numero, updated_at = NOW()
        WHERE id = v_sequence.id;
        
        RETURN v_sequence.prefixe || LPAD(v_nouveau_numero::TEXT, 6, '0');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS et Index pour sequences_pieces
ALTER TABLE sequences_pieces ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view sequences in own org"
    ON sequences_pieces FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "System can manage sequences"
    ON sequences_pieces FOR ALL
    USING (organization_id = get_user_organization_id());

CREATE INDEX idx_sequences_organization ON sequences_pieces(organization_id);
CREATE INDEX idx_sequences_journal ON sequences_pieces(id_journal);

-- ============================================================================
-- SOFT DELETE - Ajout de deleted_at sur les tables principales
-- ============================================================================

-- Membres
ALTER TABLE membres ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_membres_deleted ON membres(deleted_at);

-- Familles
ALTER TABLE familles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_familles_deleted ON familles(deleted_at);

-- Programmes
ALTER TABLE programmes ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_programmes_deleted ON programmes(deleted_at);

-- Tiers
ALTER TABLE tiers ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_tiers_deleted ON tiers(deleted_at);

-- Ecritures comptables
ALTER TABLE ecritures_comptables ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_ecritures_deleted ON ecritures_comptables(deleted_at);

-- Budgets
ALTER TABLE budgets_comptables ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_budgets_deleted ON budgets_comptables(deleted_at);

-- Immobilisations
ALTER TABLE immobilisations_comptables ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX idx_immobilisations_deleted ON immobilisations_comptables(deleted_at);

-- Fonction de soft delete
CREATE OR REPLACE FUNCTION soft_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Au lieu de supprimer, on marque comme supprimé
    NEW.deleted_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Vue pour les membres actifs (non supprimés)
CREATE OR REPLACE VIEW membres_actifs AS
SELECT * FROM membres WHERE deleted_at IS NULL;

-- Vue pour les écritures actives (non supprimées)
CREATE OR REPLACE VIEW ecritures_actives AS
SELECT * FROM ecritures_comptables WHERE deleted_at IS NULL;

-- ============================================================================
-- AUDIT TRAIL - Table de journalisation des actions
-- ============================================================================

CREATE TYPE action_audit AS ENUM (
    'INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE',
    'LOGIN', 'LOGOUT', 'VALIDATION', 'CLOTURE'
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    
    -- Qui
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_email TEXT,
    user_role TEXT,
    
    -- Quoi
    action action_audit NOT NULL,
    table_name TEXT,
    record_id UUID,
    
    -- Détails
    old_data JSONB,
    new_data JSONB,
    changes JSONB, -- Résumé des changements
    
    -- Contexte
    ip_address INET,
    user_agent TEXT,
    
    -- Quand
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE audit_logs IS 'Journal d''audit pour tracer toutes les actions importantes.';

-- Index pour recherche rapide
CREATE INDEX idx_audit_organization ON audit_logs(organization_id);
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_table ON audit_logs(table_name);
CREATE INDEX idx_audit_record ON audit_logs(record_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created ON audit_logs(created_at);

-- RLS - Seuls les admins peuvent voir les logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view audit logs"
    ON audit_logs FOR SELECT
    USING (
        get_user_role() = 'admin_national' 
        AND (organization_id = get_user_organization_id() OR organization_id IS NULL)
    );

-- Fonction générique pour logger les actions
CREATE OR REPLACE FUNCTION log_audit_action(
    p_action action_audit,
    p_table_name TEXT,
    p_record_id UUID,
    p_old_data JSONB DEFAULT NULL,
    p_new_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
    v_user_email TEXT;
    v_user_role TEXT;
    v_changes JSONB;
BEGIN
    -- Obtenir info utilisateur
    SELECT email INTO v_user_email
    FROM auth.users WHERE id = auth.uid();
    
    SELECT role::TEXT INTO v_user_role
    FROM profiles WHERE id = auth.uid();
    
    -- Calculer les changements
    IF p_old_data IS NOT NULL AND p_new_data IS NOT NULL THEN
        SELECT jsonb_object_agg(key, value)
        INTO v_changes
        FROM (
            SELECT key, p_new_data->key AS value
            FROM jsonb_object_keys(p_new_data) AS key
            WHERE p_old_data->key IS DISTINCT FROM p_new_data->key
        ) AS diff;
    END IF;
    
    INSERT INTO audit_logs (
        organization_id,
        user_id,
        user_email,
        user_role,
        action,
        table_name,
        record_id,
        old_data,
        new_data,
        changes
    ) VALUES (
        get_user_organization_id(),
        auth.uid(),
        v_user_email,
        v_user_role,
        p_action,
        p_table_name,
        p_record_id,
        p_old_data,
        p_new_data,
        v_changes
    )
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger d'audit pour les membres
CREATE OR REPLACE FUNCTION audit_membres()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM log_audit_action('INSERT'::action_audit, 'membres', NEW.id, NULL, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
            PERFORM log_audit_action('SOFT_DELETE'::action_audit, 'membres', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        ELSE
            PERFORM log_audit_action('UPDATE'::action_audit, 'membres', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM log_audit_action('DELETE'::action_audit, 'membres', OLD.id, to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_membres_trigger
    AFTER INSERT OR UPDATE OR DELETE ON membres
    FOR EACH ROW EXECUTE FUNCTION audit_membres();

-- Trigger d'audit pour les écritures comptables
CREATE OR REPLACE FUNCTION audit_ecritures()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM log_audit_action('INSERT'::action_audit, 'ecritures_comptables', NEW.id, NULL, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.statut = 'validee' AND OLD.statut = 'brouillon' THEN
            PERFORM log_audit_action('VALIDATION'::action_audit, 'ecritures_comptables', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        ELSIF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
            PERFORM log_audit_action('SOFT_DELETE'::action_audit, 'ecritures_comptables', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        ELSE
            PERFORM log_audit_action('UPDATE'::action_audit, 'ecritures_comptables', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM log_audit_action('DELETE'::action_audit, 'ecritures_comptables', OLD.id, to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_ecritures_trigger
    AFTER INSERT OR UPDATE OR DELETE ON ecritures_comptables
    FOR EACH ROW EXECUTE FUNCTION audit_ecritures();

-- ============================================================================
-- FONCTION DE CALCUL DES AMORTISSEMENTS
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_amortissement(
    p_immobilisation_id UUID,
    p_date_calcul DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    cumul_amortissement DECIMAL(15,2),
    dotation_annuelle DECIMAL(15,2),
    valeur_nette_comptable DECIMAL(15,2),
    taux_amortissement DECIMAL(5,2),
    annees_restantes INTEGER
) AS $$
DECLARE
    v_immo immobilisations_comptables%ROWTYPE;
    v_base_amortissable DECIMAL(15,2);
    v_taux DECIMAL(5,2);
    v_dotation_annuelle DECIMAL(15,2);
    v_nb_annees_ecoulees INTEGER;
    v_cumul DECIMAL(15,2);
    v_vnc DECIMAL(15,2);
BEGIN
    -- Récupérer l'immobilisation
    SELECT * INTO v_immo FROM immobilisations_comptables WHERE id = p_immobilisation_id;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- Si durée = 0 (terrain), pas d'amortissement
    IF v_immo.duree_utilite_en_annees = 0 THEN
        RETURN QUERY SELECT 
            0::DECIMAL(15,2),
            0::DECIMAL(15,2),
            v_immo.valeur_acquisition,
            0::DECIMAL(5,2),
            0;
        RETURN;
    END IF;
    
    -- Calcul de la base amortissable
    v_base_amortissable := v_immo.valeur_acquisition - COALESCE(v_immo.valeur_residuelle, 0);
    
    -- Taux d'amortissement linéaire
    v_taux := 100.0 / v_immo.duree_utilite_en_annees;
    
    -- Dotation annuelle
    v_dotation_annuelle := v_base_amortissable / v_immo.duree_utilite_en_annees;
    
    -- Nombre d'années écoulées
    v_nb_annees_ecoulees := EXTRACT(YEAR FROM p_date_calcul) - EXTRACT(YEAR FROM v_immo.date_acquisition);
    IF v_nb_annees_ecoulees < 0 THEN v_nb_annees_ecoulees := 0; END IF;
    IF v_nb_annees_ecoulees > v_immo.duree_utilite_en_annees THEN 
        v_nb_annees_ecoulees := v_immo.duree_utilite_en_annees; 
    END IF;
    
    -- Cumul des amortissements
    v_cumul := v_dotation_annuelle * v_nb_annees_ecoulees;
    IF v_cumul > v_base_amortissable THEN v_cumul := v_base_amortissable; END IF;
    
    -- Valeur nette comptable
    v_vnc := v_immo.valeur_acquisition - v_cumul;
    
    RETURN QUERY SELECT 
        v_cumul,
        v_dotation_annuelle,
        v_vnc,
        v_taux,
        GREATEST(0, v_immo.duree_utilite_en_annees - v_nb_annees_ecoulees);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FONCTION DE CLÔTURE D'EXERCICE
-- ============================================================================

CREATE OR REPLACE FUNCTION cloturer_exercice(p_exercice_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_exercice exercices_comptables%ROWTYPE;
    v_nb_ecritures_brouillon INTEGER;
BEGIN
    -- Vérifier les permissions
    IF get_user_role() != 'admin_national' THEN
        RAISE EXCEPTION 'Seul l''administrateur national peut clôturer un exercice';
    END IF;
    
    -- Récupérer l'exercice
    SELECT * INTO v_exercice FROM exercices_comptables WHERE id = p_exercice_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Exercice non trouvé';
    END IF;
    
    IF v_exercice.est_cloture THEN
        RAISE EXCEPTION 'Cet exercice est déjà clôturé';
    END IF;
    
    -- Vérifier qu'il n'y a pas d'écritures en brouillon
    SELECT COUNT(*) INTO v_nb_ecritures_brouillon
    FROM ecritures_comptables e
    WHERE e.organization_id = v_exercice.organization_id
    AND e.date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
    AND e.statut = 'brouillon'
    AND e.deleted_at IS NULL;
    
    IF v_nb_ecritures_brouillon > 0 THEN
        RAISE EXCEPTION 'Il reste % écriture(s) en brouillon. Veuillez les valider ou les supprimer.', v_nb_ecritures_brouillon;
    END IF;
    
    -- Clôturer l'exercice
    UPDATE exercices_comptables
    SET 
        est_ouvert = FALSE,
        est_cloture = TRUE,
        cloture_par = auth.uid(),
        cloture_at = NOW()
    WHERE id = p_exercice_id;
    
    -- Clôturer toutes les écritures de l'exercice
    UPDATE ecritures_comptables
    SET statut = 'cloturee'
    WHERE organization_id = v_exercice.organization_id
    AND date BETWEEN v_exercice.date_debut AND v_exercice.date_fin
    AND statut = 'validee'
    AND deleted_at IS NULL;
    
    -- Logger l'action
    PERFORM log_audit_action('CLOTURE'::action_audit, 'exercices_comptables', p_exercice_id, NULL, to_jsonb(v_exercice));
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VUES UTILES
-- ============================================================================

-- Vue du solde des comptes
CREATE OR REPLACE VIEW vue_soldes_comptes AS
SELECT 
    c.id,
    c.organization_id,
    c.numero,
    c.intitule,
    c.nature,
    COALESCE(SUM(l.debit), 0) AS total_debit,
    COALESCE(SUM(l.credit), 0) AS total_credit,
    CASE 
        WHEN c.nature IN ('actif', 'charge') THEN COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0)
        ELSE COALESCE(SUM(l.credit), 0) - COALESCE(SUM(l.debit), 0)
    END AS solde
FROM comptes_comptables c
LEFT JOIN lignes_ecritures l ON l.id_compte_comptable = c.id
LEFT JOIN ecritures_comptables e ON e.id = l.id_ecriture 
    AND e.statut IN ('validee', 'cloturee') 
    AND e.deleted_at IS NULL
WHERE c.actif = TRUE
GROUP BY c.id, c.organization_id, c.numero, c.intitule, c.nature;

-- Vue du tableau de bord financier
CREATE OR REPLACE VIEW vue_tableau_bord_financier AS
SELECT 
    e.organization_id,
    e.id_assemblee_locale,
    DATE_TRUNC('month', e.date) AS mois,
    SUM(CASE WHEN c.nature = 'produit' THEN l.credit ELSE 0 END) AS total_produits,
    SUM(CASE WHEN c.nature = 'charge' THEN l.debit ELSE 0 END) AS total_charges,
    SUM(CASE WHEN c.nature = 'produit' THEN l.credit ELSE 0 END) - 
    SUM(CASE WHEN c.nature = 'charge' THEN l.debit ELSE 0 END) AS resultat
FROM ecritures_comptables e
JOIN lignes_ecritures l ON l.id_ecriture = e.id
JOIN comptes_comptables c ON c.id = l.id_compte_comptable
WHERE e.statut IN ('validee', 'cloturee')
AND e.deleted_at IS NULL
GROUP BY e.organization_id, e.id_assemblee_locale, DATE_TRUNC('month', e.date);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

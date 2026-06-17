-- =============================================================================
-- Migration 00037 : Dates d'exercice des dossiers fiscaux
-- =============================================================================
-- Objectif :
--   - renseigner automatiquement les champs exercice.date_debut/date_fin
--     d'un dossier fiscal depuis l'exercice comptable rattache ;
--   - conserver les valeurs manuelles existantes, sauf inversion annuelle
--     evidente 31/12 -> 01/01 ;
--   - eviter que l'export Excel fiscal parte d'un dossier sans periode lisible.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.sync_fiscal_dossier_exercice_date_values()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_date_debut DATE;
  v_date_fin   DATE;
BEGIN
  IF NEW.exercice_id IS NOT NULL THEN
    SELECT e.date_debut, e.date_fin
    INTO v_date_debut, v_date_fin
    FROM public.exercices_comptables e
    WHERE e.id = NEW.exercice_id
      AND e.organization_id = NEW.organization_id;
  END IF;

  IF v_date_debut IS NULL OR v_date_fin IS NULL THEN
    v_date_debut := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 1, 1);
    v_date_fin := make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 12, 31);
  END IF;

  IF v_date_debut > v_date_fin THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.fiscal_dossier_values (
    dossier_id,
    organization_id,
    field_key,
    value,
    source,
    updated_by,
    updated_at
  )
  VALUES
    (
      NEW.id,
      NEW.organization_id,
      'exercice.date_debut',
      to_jsonb(v_date_debut::TEXT),
      'computed',
      auth.uid(),
      NOW()
    ),
    (
      NEW.id,
      NEW.organization_id,
      'exercice.date_fin',
      to_jsonb(v_date_fin::TEXT),
      'computed',
      auth.uid(),
      NOW()
    )
  ON CONFLICT (dossier_id, field_key)
  DO UPDATE SET
    value = EXCLUDED.value,
    source = EXCLUDED.source,
    updated_by = EXCLUDED.updated_by,
    updated_at = NOW()
  WHERE fiscal_dossier_values.source <> 'manual';

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS sync_fiscal_dossier_exercice_date_values_insert
  ON public.fiscal_dossiers;
CREATE TRIGGER sync_fiscal_dossier_exercice_date_values_insert
  AFTER INSERT ON public.fiscal_dossiers
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_fiscal_dossier_exercice_date_values();

DROP TRIGGER IF EXISTS sync_fiscal_dossier_exercice_date_values_update
  ON public.fiscal_dossiers;
CREATE TRIGGER sync_fiscal_dossier_exercice_date_values_update
  AFTER UPDATE OF exercice_id, status ON public.fiscal_dossiers
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_fiscal_dossier_exercice_date_values();

-- Backfill des dossiers existants sans periode explicite.
INSERT INTO public.fiscal_dossier_values (
  dossier_id,
  organization_id,
  field_key,
  value,
  source,
  updated_at
)
SELECT
  d.id,
  d.organization_id,
  field_key,
  to_jsonb(field_value::TEXT),
  'computed',
  NOW()
FROM public.fiscal_dossiers d
LEFT JOIN public.exercices_comptables e
  ON e.id = d.exercice_id
 AND e.organization_id = d.organization_id
CROSS JOIN LATERAL (
  VALUES
    (
      'exercice.date_debut',
      COALESCE(
        e.date_debut,
        make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 1, 1)
      )
    ),
    (
      'exercice.date_fin',
      COALESCE(
        e.date_fin,
        make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 12, 31)
      )
    )
) AS generated(field_key, field_value)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.fiscal_dossier_values existing
  WHERE existing.dossier_id = d.id
    AND existing.field_key = generated.field_key
);

-- Correction limite : inversion annuelle evidente de type debut=31/12/AAAA
-- et fin=01/01/AAAA. Les autres erreurs restent bloquees par le preflight.
CREATE TEMP TABLE _fiscal_date_swaps ON COMMIT DROP AS
SELECT
  start_value.dossier_id,
  (start_value.value #>> '{}')::DATE AS wrong_start_date,
  (end_value.value #>> '{}')::DATE AS wrong_end_date
FROM public.fiscal_dossier_values start_value
JOIN public.fiscal_dossier_values end_value
  ON end_value.dossier_id = start_value.dossier_id
 AND end_value.field_key = 'exercice.date_fin'
WHERE start_value.field_key = 'exercice.date_debut'
  AND (start_value.value #>> '{}') ~ '^\d{4}-\d{2}-\d{2}$'
  AND (end_value.value #>> '{}') ~ '^\d{4}-\d{2}-\d{2}$'
  AND (start_value.value #>> '{}')::DATE > (end_value.value #>> '{}')::DATE
  AND EXTRACT(YEAR FROM (start_value.value #>> '{}')::DATE)
      = EXTRACT(YEAR FROM (end_value.value #>> '{}')::DATE)
  AND EXTRACT(MONTH FROM (start_value.value #>> '{}')::DATE) = 12
  AND EXTRACT(DAY FROM (start_value.value #>> '{}')::DATE) = 31
  AND EXTRACT(MONTH FROM (end_value.value #>> '{}')::DATE) = 1
  AND EXTRACT(DAY FROM (end_value.value #>> '{}')::DATE) = 1;

UPDATE public.fiscal_dossier_values v
SET
  value = to_jsonb(s.wrong_end_date::TEXT),
  updated_at = NOW()
FROM _fiscal_date_swaps s
WHERE v.dossier_id = s.dossier_id
  AND v.field_key = 'exercice.date_debut';

UPDATE public.fiscal_dossier_values v
SET
  value = to_jsonb(s.wrong_start_date::TEXT),
  updated_at = NOW()
FROM _fiscal_date_swaps s
WHERE v.dossier_id = s.dossier_id
  AND v.field_key = 'exercice.date_fin';

COMMENT ON FUNCTION public.sync_fiscal_dossier_exercice_date_values() IS
  'Synchronise les champs exercice.date_debut/date_fin des dossiers fiscaux depuis l''exercice comptable rattache ou l''annee courante.';

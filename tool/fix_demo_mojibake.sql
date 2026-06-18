BEGIN;

CREATE TEMP TABLE _mojibake_fix_result (
  table_name TEXT NOT NULL,
  column_name TEXT NOT NULL,
  updated_rows INTEGER NOT NULL
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.fix_demo_mojibake(p_value TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_value IS NULL OR p_value !~ U&'[\00C3\00C2]' THEN
    RETURN p_value;
  END IF;

  BEGIN
    RETURN convert_from(convert_to(p_value, 'WIN1252'), 'UTF8');
  EXCEPTION WHEN OTHERS THEN
    RETURN p_value;
  END;
END;
$$;

DO $$
DECLARE
  v_org_id UUID;
  v_record RECORD;
  v_count INTEGER;
BEGIN
  SELECT id
  INTO v_org_id
  FROM organizations
  WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
     OR sigle = 'EAB'
     OR code = 'EAB'
     OR name IN (
       U&'\00C9glise Apostolique du B\00E9nin',
       U&'\00C3\2030glise Apostolique du B\00C3\00A9nin'
     )
  ORDER BY
    CASE
      WHEN id = '00000000-0000-0000-0000-000000000001'::uuid THEN 0
      WHEN sigle = 'EAB' THEN 1
      WHEN code = 'EAB' THEN 2
      ELSE 3
    END
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Organisation demo EAB introuvable. Verifiez le projet Supabase actif avant execution.';
  END IF;

  FOR v_record IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'organizations'
      AND data_type IN ('text', 'character varying')
  LOOP
    EXECUTE format(
      'UPDATE public.organizations
       SET %1$I = pg_temp.fix_demo_mojibake(%1$I)
       WHERE id = $1
         AND %1$I IS NOT NULL
         AND %1$I ~ U&''[\00C3\00C2]''',
      v_record.column_name
    )
    USING v_org_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count > 0 THEN
      INSERT INTO _mojibake_fix_result VALUES (
        'organizations',
        v_record.column_name,
        v_count
      );
    END IF;
  END LOOP;

  FOR v_record IN
    SELECT c.table_schema, c.table_name, c.column_name
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.data_type IN ('text', 'character varying')
      AND EXISTS (
        SELECT 1
        FROM information_schema.columns org_col
        WHERE org_col.table_schema = c.table_schema
          AND org_col.table_name = c.table_name
          AND org_col.column_name = 'organization_id'
      )
    ORDER BY c.table_name, c.column_name
  LOOP
    EXECUTE format(
      'UPDATE %1$I.%2$I
       SET %3$I = pg_temp.fix_demo_mojibake(%3$I)
       WHERE organization_id = $1
         AND %3$I IS NOT NULL
         AND %3$I ~ U&''[\00C3\00C2]''',
      v_record.table_schema,
      v_record.table_name,
      v_record.column_name
    )
    USING v_org_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count > 0 THEN
      INSERT INTO _mojibake_fix_result VALUES (
        v_record.table_name,
        v_record.column_name,
        v_count
      );
    END IF;
  END LOOP;

  UPDATE organizations
  SET
    name = U&'\00C9glise Apostolique du B\00E9nin',
    sigle = 'EAB',
    description = U&'Organisation principale de d\00E9monstration pour l''\00C9glise Apostolique du B\00E9nin.'
  WHERE id = v_org_id;
END $$;

SELECT
  table_name,
  column_name,
  updated_rows
FROM _mojibake_fix_result
ORDER BY table_name, column_name;

SELECT
  id,
  name,
  sigle,
  description
FROM organizations
WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
   OR sigle = 'EAB'
ORDER BY id
LIMIT 1;

COMMIT;

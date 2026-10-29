-- 1. Grain check, before quality filters, including whitespace-only IDs.
-- The Minnesota scope is the proposed fact input. Other scopes aid reconciliation.
WITH normalized AS (
  SELECT
    'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288'
      AS release_key,
    NULLIF(TRIM(hud_id), '') AS project_id,
    UPPER(TRIM(proj_st)) AS state_code,
    SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS service_year
  FROM `lucky-seis-732.HUD_LIHTC.projects`
), scopes AS (
  SELECT 'NATIONWIDE' AS scope_name, release_key, project_id FROM normalized
  UNION ALL
  SELECT 'MINNESOTA', release_key, project_id
  FROM normalized WHERE state_code = 'MN'
  UNION ALL
  SELECT 'MN_VALID_SERVICE_YEAR', release_key, project_id
  FROM normalized
  WHERE state_code = 'MN' AND service_year BETWEEN 1987 AND 2024
), grain_groups AS (
  SELECT scope_name, release_key, project_id, COUNT(*) AS rows_per_key
  FROM scopes
  GROUP BY scope_name, release_key, project_id
), scope_names AS (
  SELECT scope_name
  FROM UNNEST(['NATIONWIDE', 'MINNESOTA', 'MN_VALID_SERVICE_YEAR']) AS scope_name
)
SELECT
  s.scope_name,
  COALESCE(SUM(g.rows_per_key), 0) AS source_rows,
  COALESCE(SUM(IF(g.project_id IS NULL, g.rows_per_key, 0)), 0)
    AS rows_with_missing_id,
  COUNTIF(g.project_id IS NOT NULL) AS distinct_nonblank_ids,
  COUNTIF(g.project_id IS NOT NULL AND g.rows_per_key > 1)
    AS repeated_id_groups,
  COALESCE(SUM(IF(g.project_id IS NOT NULL AND g.rows_per_key > 1,
                  g.rows_per_key - 1, 0)), 0) AS excess_rows_in_repeated_groups
FROM scope_names AS s
LEFT JOIN grain_groups AS g USING (scope_name)
GROUP BY s.scope_name
ORDER BY s.scope_name;

-- 2. Focused quality and cohort check for the primary question.
-- Unit consistency is checked independently from the year filter.
WITH mn AS (
  SELECT
    NULLIF(UPPER(TRIM(proj_cty)), '') AS normalized_city_label,
    SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS service_year,
    SAFE_CAST(NULLIF(TRIM(n_units), '') AS NUMERIC) AS total_units,
    SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC) AS low_income_units,
    NULLIF(TRIM(resyndication_cd), '') AS resyndication_code
  FROM `lucky-seis-732.HUD_LIHTC.projects`
  WHERE UPPER(TRIM(proj_st)) = 'MN'
), classified AS (
  SELECT *,
    IF(total_units > 0 AND low_income_units >= 0
       AND low_income_units <= total_units, TRUE, FALSE) AS units_eligible
  FROM mn
)
SELECT
  COUNT(*) AS mn_source_rows,
  COUNTIF(service_year BETWEEN 1987 AND 2024) AS valid_year_records,
  COUNTIF(service_year = 9999) AS year_9999_records,
  COUNTIF(service_year = 8888) AS year_8888_records,
  COUNTIF(service_year IS NULL) AS missing_or_invalid_year_records,
  COUNTIF(service_year IS NOT NULL
          AND service_year NOT BETWEEN 1987 AND 2024
          AND service_year NOT IN (8888, 9999)) AS other_outside_window_records,
  MIN(IF(service_year BETWEEN 1987 AND 2024, service_year, NULL))
    AS first_valid_service_year,
  MAX(IF(service_year BETWEEN 1987 AND 2024, service_year, NULL))
    AS last_valid_service_year,
  COUNTIF(normalized_city_label IS NULL) AS blank_city_records,
  COUNT(DISTINCT normalized_city_label) AS distinct_normalized_city_labels,
  COUNTIF(total_units IS NULL) AS missing_or_invalid_total_unit_records,
  COUNTIF(low_income_units IS NULL) AS missing_or_invalid_low_income_unit_records,
  COUNTIF(low_income_units > total_units) AS inconsistent_unit_records,
  COUNTIF(NOT units_eligible) AS all_year_unit_ineligible_records,
  COUNTIF(service_year BETWEEN 1987 AND 2024 AND NOT units_eligible)
    AS valid_year_unit_ineligible_records,
  COUNTIF(resyndication_code = '1') AS flagged_resyndication_records,
  COUNTIF(resyndication_code IS NULL) AS unreported_resyndication_records
FROM classified;

-- 3. Inspect the imported schema, without returning source rows.
-- Reuse sql/02_validate_load.sql for the full 80-column order/type comparison.
SELECT column_name, data_type, is_nullable, ordinal_position
FROM `lucky-seis-732.HUD_LIHTC.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'projects'
ORDER BY ordinal_position;


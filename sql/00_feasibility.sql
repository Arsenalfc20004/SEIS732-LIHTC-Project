-- GoogleSQL: Minnesota affordable-housing case study.
-- Prepared for the proposed imported table AFTER instructor approval.
-- No BigQuery queries have been executed for this P0 submission.
-- validator estimates before execution. All 80 raw columns are STRING.

-- 01: Inspect the imported schema.
SELECT column_name, data_type, is_nullable
FROM `YOUR_COURSE_PROJECT.lucky_lihtc.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'projects'
ORDER BY ordinal_position;

-- 02: Reconcile the national and Minnesota counts and source keys.
SELECT
  COUNT(*) AS national_row_count,
  COUNTIF(UPPER(TRIM(proj_st)) = 'MN') AS mn_row_count,
  COUNTIF(hud_id IS NULL OR TRIM(hud_id) = '') AS missing_hud_ids,
  COUNT(DISTINCT NULLIF(TRIM(hud_id), '')) AS distinct_nonblank_hud_ids
FROM `YOUR_COURSE_PROJECT.lucky_lihtc.projects`;

-- 03: Count duplicate-key groups without returning project identifiers.
SELECT
  COUNT(*) AS duplicate_key_groups,
  COALESCE(SUM(n - 1), 0) AS excess_rows_for_repeated_keys
FROM (
  SELECT TRIM(hud_id) AS key_value, COUNT(*) AS n
  FROM `YOUR_COURSE_PROJECT.lucky_lihtc.projects`
  WHERE NULLIF(TRIM(hud_id), '') IS NOT NULL
  GROUP BY key_value
  HAVING COUNT(*) > 1
);

-- 04: Minnesota date, unit, city, and identifier quality.
WITH mn AS (
  SELECT
    NULLIF(TRIM(proj_cty), '') AS city_label,
    TRIM(fips2020) AS tract_code,
    NULLIF(TRIM(resyndication_cd), '') AS resyndication_code,
    SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS service_year,
    SAFE_CAST(NULLIF(TRIM(n_units), '') AS NUMERIC) AS total_units,
    SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC) AS low_income_units
  FROM `YOUR_COURSE_PROJECT.lucky_lihtc.projects`
  WHERE UPPER(TRIM(proj_st)) = 'MN'
)
SELECT
  COUNT(*) AS mn_row_count,
  COUNTIF(service_year BETWEEN 1987 AND 2024) AS valid_year_rows,
  MIN(IF(service_year BETWEEN 1987 AND 2024, service_year, NULL)) AS first_valid_year,
  MAX(IF(service_year BETWEEN 1987 AND 2024, service_year, NULL)) AS last_valid_year,
  COUNTIF(service_year = 8888) AS unconfirmed_service_status_rows,
  COUNTIF(service_year = 9999) AS confirmed_status_missing_year_rows,
  COUNTIF(service_year IS NULL) AS missing_or_invalid_year_rows,
  COUNTIF(service_year NOT BETWEEN 1987 AND 2024 AND service_year NOT IN (8888, 9999)) AS other_outside_window_rows,
  COUNTIF(city_label IS NULL) AS missing_city_rows,
  COUNT(DISTINCT UPPER(city_label)) AS distinct_normalized_city_labels,
  COUNTIF(resyndication_code = '1') AS resyndicated_rows,
  COUNTIF(resyndication_code IS NULL) AS unreported_resyndication_rows,
  COUNTIF(total_units IS NULL) AS missing_or_invalid_total_unit_rows,
  COUNTIF(low_income_units IS NULL) AS missing_or_invalid_low_income_unit_rows,
  COUNTIF(total_units <= 0) AS nonpositive_total_unit_rows,
  COUNTIF(low_income_units < 0) AS negative_low_income_unit_rows,
  COUNTIF(low_income_units > total_units) AS inconsistent_unit_rows,
  COUNTIF(REGEXP_CONTAINS(tract_code, r'X')) AS tract_placeholder_rows,
  COUNTIF(REGEXP_CONTAINS(tract_code, r'^\d{11}$')) AS valid_11_digit_tract_rows
FROM mn;

-- 05: Year coverage for the initial Minnesota historical cohort.
SELECT
  SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS service_year,
  COUNT(*) AS project_record_count
FROM `YOUR_COURSE_PROJECT.lucky_lihtc.projects`
WHERE UPPER(TRIM(proj_st)) = 'MN'
  AND SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) BETWEEN 1987 AND 2024
GROUP BY service_year
ORDER BY service_year;

-- 06: City-level aggregate feasibility check.
-- Both unit sums use the SAME eligible records. The measures describe
-- reported project activity, not unique physical housing stock.
WITH cohort AS (
  SELECT
    COALESCE(NULLIF(UPPER(TRIM(proj_cty)), ''), 'UNKNOWN') AS city_label,
    SAFE_CAST(NULLIF(TRIM(n_units), '') AS NUMERIC) AS total_units,
    SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC) AS low_income_units
  FROM `YOUR_COURSE_PROJECT.lucky_lihtc.projects`
  WHERE UPPER(TRIM(proj_st)) = 'MN'
    AND SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) BETWEEN 1987 AND 2024
), classified AS (
  SELECT
    *,
    CASE WHEN total_units > 0 AND low_income_units >= 0
                   AND low_income_units <= total_units
         THEN TRUE ELSE FALSE END AS units_usable
  FROM cohort
)
SELECT
  city_label,
  COUNT(*) AS project_record_count,
  COUNTIF(units_usable) AS records_with_usable_units,
  COUNTIF(NOT units_usable) AS records_excluded_from_unit_measure,
  SUM(IF(units_usable, total_units, NULL)) AS reported_total_units,
  SUM(IF(units_usable, low_income_units, NULL)) AS reported_low_income_units,
  100 * SAFE_DIVIDE(
    SUM(IF(units_usable, low_income_units, NULL)),
    SUM(IF(units_usable, total_units, NULL))
  ) AS low_income_share_of_reported_units_pct
FROM classified
GROUP BY city_label
ORDER BY project_record_count DESC, city_label;


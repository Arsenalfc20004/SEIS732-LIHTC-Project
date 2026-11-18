-- P2 / 04: inspect the implemented Raw -> Curated path. GoogleSQL; US.
DECLARE v_release_key STRING DEFAULT (
  SELECT IF(COUNT(*) = 1, ANY_VALUE(release_key), NULL)
  FROM `lucky-seis-732.HUD_LIHTC.dim_release`
  WHERE source_csv_uri = 'gs://lihtc-hud-data-seis732/projects.csv'
);
DECLARE v_checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
ASSERT v_release_key IS NOT NULL
  AS 'Select exactly one registered release; set its explicit release key.';

CREATE TEMP TABLE checked_fact AS
SELECT * FROM `lucky-seis-732.HUD_LIHTC.fact_project_activity`
WHERE release_key = v_release_key;

-- CHECK 1: keys and the actual joins, not just the Raw identifier profile.
CREATE TEMP TABLE joined_fact AS
SELECT f.*, c.state_code, c.normalized_city_label,
  y.service_year, r.archive_sha256
FROM checked_fact AS f
JOIN `lucky-seis-732.HUD_LIHTC.dim_city` AS c USING (city_key)
JOIN `lucky-seis-732.HUD_LIHTC.dim_service_year` AS y USING (service_year_key)
JOIN `lucky-seis-732.HUD_LIHTC.dim_release` AS r USING (release_key);

CREATE TEMP TABLE grain_metrics AS
SELECT
  (SELECT COUNT(*) FROM `lucky-seis-732.HUD_LIHTC.projects`
   WHERE UPPER(TRIM(proj_st)) = 'MN') AS raw_mn_records,
  (SELECT COUNT(*) FROM checked_fact) AS curated_records,
  (SELECT COUNT(*) FROM joined_fact) AS records_after_dimension_joins,
  (SELECT COALESCE(SUM(project_record_count), 0) FROM joined_fact)
    AS project_count_after_dimension_joins,
  (SELECT COUNTIF(NULLIF(TRIM(hud_id), '') IS NULL
                  OR activity_key IS NULL OR release_key IS NULL)
   FROM checked_fact) AS missing_fact_keys,
  (SELECT COUNT(*) FROM (
    SELECT release_key, hud_id FROM checked_fact
    GROUP BY release_key, hud_id HAVING COUNT(*) > 1
  )) AS repeated_business_key_groups,
  (SELECT COUNT(*) FROM (
    SELECT activity_key FROM checked_fact
    GROUP BY activity_key HAVING COUNT(*) > 1
  )) AS repeated_activity_key_groups,
  (SELECT COUNT(*) FROM (
    SELECT release_key, hud_id FROM joined_fact
    GROUP BY release_key, hud_id HAVING COUNT(*) > 1
  )) AS repeated_groups_after_joins,
  (SELECT COUNT(*) FROM (
    SELECT city_key FROM `lucky-seis-732.HUD_LIHTC.dim_city`
    GROUP BY city_key HAVING COUNT(*) > 1
  )) AS repeated_city_keys,
  (SELECT COUNT(*) FROM (
    SELECT service_year_key FROM `lucky-seis-732.HUD_LIHTC.dim_service_year`
    GROUP BY service_year_key HAVING COUNT(*) > 1
  )) AS repeated_year_keys,
  (SELECT COUNT(*) FROM (
    SELECT release_key FROM `lucky-seis-732.HUD_LIHTC.dim_release`
    GROUP BY release_key HAVING COUNT(*) > 1
  )) AS repeated_release_keys,
  (SELECT COUNT(*) FROM checked_fact AS f
   LEFT JOIN `lucky-seis-732.HUD_LIHTC.dim_city` AS c USING (city_key)
   LEFT JOIN `lucky-seis-732.HUD_LIHTC.dim_service_year` AS y USING (service_year_key)
   LEFT JOIN `lucky-seis-732.HUD_LIHTC.dim_release` AS r USING (release_key)
   WHERE c.city_key IS NULL OR y.service_year_key IS NULL
      OR r.release_key IS NULL) AS unmatched_relationship_rows,
  (SELECT COUNTIF(project_record_count IS DISTINCT FROM 1)
   FROM checked_fact) AS project_count_rule_errors;

-- CHECK 2: recompute eligibility directly from Raw, without using Curated flags.
CREATE TEMP TABLE expected_from_raw AS
WITH parsed AS (
  SELECT
    NULLIF(TRIM(hud_id), '') AS hud_id,
    NULLIF(UPPER(TRIM(proj_cty)), '') AS expected_city,
    SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS service_year,
    SAFE_CAST(NULLIF(TRIM(n_units), '') AS NUMERIC) AS total_units,
    SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC) AS low_income_units
  FROM `lucky-seis-732.HUD_LIHTC.projects`
  WHERE UPPER(TRIM(proj_st)) = 'MN'
)
SELECT *,
  COALESCE(service_year BETWEEN 1987 AND 2024, FALSE) AS valid_year,
  COALESCE(total_units > 0 AND low_income_units >= 0
           AND low_income_units <= total_units, FALSE) AS expected_units_eligible
FROM parsed;

CREATE TEMP TABLE field_comparisons AS
SELECT
  COUNTIF(e.hud_id IS NULL OR f.hud_id IS NULL) AS missing_or_unexpected_ids,
  COUNTIF(f.units_eligible IS DISTINCT FROM e.expected_units_eligible)
    AS eligibility_flag_errors,
  COUNTIF(f.reported_total_units IS DISTINCT FROM
            IF(e.expected_units_eligible, e.total_units, NULL)
       OR f.reported_low_income_units IS DISTINCT FROM
            IF(e.expected_units_eligible, e.low_income_units, NULL))
    AS unit_measure_errors,
  COUNTIF(f.service_year_key IS DISTINCT FROM IF(e.valid_year, e.service_year, 0))
    AS service_year_mapping_errors
FROM expected_from_raw AS e
FULL OUTER JOIN checked_fact AS f USING (hud_id);

CREATE TEMP TABLE audience_raw AS
SELECT
  COUNT(*) AS valid_year_records,
  COUNTIF(expected_units_eligible) AS unit_eligible_records,
  COUNTIF(NOT expected_units_eligible) AS unit_excluded_records,
  SUM(IF(expected_units_eligible, total_units, NULL)) AS total_units,
  SUM(IF(expected_units_eligible, low_income_units, NULL)) AS low_income_units
FROM expected_from_raw WHERE valid_year;

CREATE TEMP TABLE audience_curated AS
SELECT
  COUNT(*) AS valid_year_records,
  COUNTIF(units_eligible) AS unit_eligible_records,
  COUNTIF(NOT units_eligible) AS unit_excluded_records,
  SUM(reported_total_units) AS total_units,
  SUM(reported_low_income_units) AS low_income_units
FROM joined_fact
WHERE state_code = 'MN' AND service_year BETWEEN 1987 AND 2024;

CREATE TEMP TABLE meaning_metrics AS
SELECT x.*,
  (SELECT COUNT(*) FROM expected_from_raw AS e
   JOIN joined_fact AS j USING (hud_id)
   WHERE j.state_code IS DISTINCT FROM 'MN'
      OR j.normalized_city_label IS DISTINCT FROM e.expected_city)
    AS city_mapping_errors,
  (SELECT COUNTIF(NOT units_eligible
                  AND (reported_total_units IS NOT NULL
                       OR reported_low_income_units IS NOT NULL))
   FROM checked_fact) AS ineligible_records_with_unit_measures,
  r.valid_year_records AS raw_valid_year_records,
  c.valid_year_records AS curated_valid_year_records,
  r.unit_eligible_records AS raw_unit_eligible_records,
  c.unit_eligible_records AS curated_unit_eligible_records,
  r.unit_excluded_records AS raw_unit_excluded_records,
  c.unit_excluded_records AS curated_unit_excluded_records,
  r.total_units AS raw_eligible_total_units,
  c.total_units AS curated_eligible_total_units,
  r.low_income_units AS raw_eligible_low_income_units,
  c.low_income_units AS curated_eligible_low_income_units
FROM field_comparisons AS x
CROSS JOIN audience_raw AS r CROSS JOIN audience_curated AS c;

-- Keep both acceptance checks together in the final result grid.
CREATE TEMP TABLE acceptance_results AS
SELECT
  v_checked_at AS checked_at_utc,
  '1. Curated grain and relationships' AS acceptance_check,
  'MN Raw = Curated = joined project count; zero key or relationship violations'
    AS expected,
  TO_JSON_STRING(g) AS observed_metrics,
  IF(raw_mn_records = curated_records
     AND curated_records = records_after_dimension_joins
     AND curated_records = project_count_after_dimension_joins
     AND curated_records > 0
     AND missing_fact_keys = 0 AND repeated_business_key_groups = 0
     AND repeated_activity_key_groups = 0 AND repeated_groups_after_joins = 0
     AND repeated_city_keys = 0 AND repeated_year_keys = 0
     AND repeated_release_keys = 0 AND unmatched_relationship_rows = 0
     AND project_count_rule_errors = 0,
     'PASS', 'REVIEW') AS result
FROM grain_metrics AS g
UNION ALL
SELECT
  v_checked_at,
  '2. Year scope and eligible unit meaning',
  'Zero field-rule errors; Raw and Curated counts and unit sums reconcile',
  TO_JSON_STRING(m),
  IF(missing_or_unexpected_ids = 0 AND eligibility_flag_errors = 0
     AND unit_measure_errors = 0 AND service_year_mapping_errors = 0
     AND city_mapping_errors = 0 AND ineligible_records_with_unit_measures = 0
     AND raw_valid_year_records = curated_valid_year_records
     AND raw_unit_eligible_records = curated_unit_eligible_records
     AND raw_unit_excluded_records = curated_unit_excluded_records
     AND raw_eligible_total_units IS NOT DISTINCT FROM curated_eligible_total_units
     AND raw_eligible_low_income_units IS NOT DISTINCT FROM curated_eligible_low_income_units,
     'PASS', 'REVIEW')
FROM meaning_metrics AS m
ORDER BY acceptance_check;

-- FINAL RESULT: two acceptance rows plus the same compact field-trace JSON.
SELECT a.*,
  TO_JSON_STRING(STRUCT(
  v_release_key AS release_key,
  (SELECT COUNT(*) FROM checked_fact) AS curated_project_records,
  r.valid_year_records AS raw_valid_year_records,
  c.valid_year_records AS curated_valid_year_records,
  r.unit_eligible_records AS raw_unit_eligible_records_valid_years,
  c.unit_eligible_records AS curated_unit_eligible_records_valid_years,
  r.unit_excluded_records AS raw_unit_excluded_records_valid_years,
  c.unit_excluded_records AS curated_unit_excluded_records_valid_years,
  r.low_income_units AS independently_calculated_reported_low_income_units,
  c.low_income_units AS curated_reported_low_income_units,
  r.total_units AS independently_calculated_reported_total_units,
  c.total_units AS curated_reported_total_units
  )) AS field_trace
FROM acceptance_results AS a
CROSS JOIN audience_raw AS r CROSS JOIN audience_curated AS c
ORDER BY acceptance_check;

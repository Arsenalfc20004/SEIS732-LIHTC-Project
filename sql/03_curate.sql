-- P2 / 03: build the P1 Minnesota star model. GoogleSQL; US.
DECLARE v_archive_sha256 STRING DEFAULT 'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288';
DECLARE v_source_confirmed BOOL DEFAULT TRUE; -- declaration used for this recorded P2 input
DECLARE v_acquisition_date DATE DEFAULT NULL;
DECLARE v_run_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
DECLARE v_release_key STRING DEFAULT LOWER(TRIM(v_archive_sha256));
DECLARE v_rule_version STRING DEFAULT 'p2_v1';

ASSERT v_source_confirmed
  AS 'Confirm the source release, LIHTCPUB.xlsx/Data, and P1 conditions first.';
ASSERT REGEXP_CONTAINS(v_release_key, r'^[0-9a-f]{64}$')
  AS 'Enter the actual 64-character archive SHA-256; do not use a placeholder.';
ASSERT (SELECT COUNT(*) FROM `lucky-seis-732.HUD_LIHTC.projects`) = 55345
  AS 'Nationwide Raw count differs from the P0/P1 input. Investigate first.';

-- Temporary parsing stage. Raw is left intact. No arbitrary deduplication.
-- BEGIN_STAGE_QUERY
CREATE TEMP TABLE staged_mn AS
WITH parsed AS (
  SELECT
    NULLIF(TRIM(hud_id), '') AS hud_id,
    'MN' AS state_code,
    NULLIF(UPPER(TRIM(proj_cty)), '') AS normalized_city_label,
    SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS parsed_service_year,
    SAFE_CAST(NULLIF(TRIM(n_units), '') AS NUMERIC) AS parsed_total_units,
    SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC) AS parsed_low_income_units,
    NULLIF(TRIM(resyndication_cd), '') AS resyndication_cd
  FROM `lucky-seis-732.HUD_LIHTC.projects`
  WHERE UPPER(TRIM(proj_st)) = 'MN'
), classified AS (
  SELECT *,
    CASE
      WHEN parsed_service_year BETWEEN 1987 AND 2024 THEN 'valid_1987_2024'
      WHEN parsed_service_year = 9999 THEN 'unknown_9999'
      WHEN parsed_service_year = 8888 THEN 'unknown_8888'
      WHEN parsed_service_year IS NULL THEN 'missing_or_invalid'
      ELSE 'outside_1987_2024'
    END AS service_year_status,
    CASE
      WHEN parsed_total_units IS NULL THEN 'missing_or_invalid_total_units'
      WHEN parsed_low_income_units IS NULL THEN 'missing_or_invalid_low_income_units'
      WHEN parsed_total_units <= 0 THEN 'nonpositive_total_units'
      WHEN parsed_low_income_units < 0 THEN 'negative_low_income_units'
      WHEN parsed_low_income_units > parsed_total_units THEN 'low_income_exceeds_total'
      ELSE 'eligible'
    END AS unit_status
  FROM parsed
)
SELECT
  TO_HEX(SHA256(TO_JSON_STRING(STRUCT(
    v_release_key AS release_key, hud_id AS hud_id)))) AS activity_key,
  v_release_key AS release_key,
  hud_id,
  TO_HEX(SHA256(TO_JSON_STRING(STRUCT(
    state_code AS state_code,
    normalized_city_label AS normalized_city_label)))) AS city_key,
  IF(service_year_status = 'valid_1987_2024',
     parsed_service_year, 0) AS service_year_key,
  1 AS project_record_count,
  service_year_status,
  unit_status,
  unit_status = 'eligible' AS units_eligible,
  IF(unit_status = 'eligible', parsed_total_units, NULL) AS reported_total_units,
  IF(unit_status = 'eligible', parsed_low_income_units, NULL) AS reported_low_income_units,
  resyndication_cd,
  state_code,
  normalized_city_label
FROM classified;
-- END_STAGE_QUERY

ASSERT (SELECT COUNT(*) FROM staged_mn) = 1144
  AS 'Minnesota subset differs from the P0/P1 input. Investigate first.';
ASSERT (SELECT COUNTIF(hud_id IS NULL) FROM staged_mn) = 0
  AS 'A Minnesota project ID is missing. Do not silently discard it.';
ASSERT (SELECT COUNT(*) FROM (
  SELECT release_key, hud_id FROM staged_mn
  GROUP BY release_key, hud_id HAVING COUNT(*) > 1
)) = 0 AS 'Repeated Minnesota project IDs violate the proposed fact grain.';

-- Create absent objects, preserving any earlier releases already built.
-- Permanent DDL occurs before the transaction.
CREATE TABLE IF NOT EXISTS `lucky-seis-732.HUD_LIHTC.dim_release` (
  release_key STRING,
  archive_sha256 STRING,
  source_csv_uri STRING,
  source_archive_url STRING,
  source_member STRING,
  source_sheet STRING,
  acquisition_date DATE,
  coverage_label STRING,
  curation_rule_version STRING,
  nationwide_raw_rows INT64,
  minnesota_raw_rows INT64,
  first_registered_at TIMESTAMP,
  last_built_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS `lucky-seis-732.HUD_LIHTC.dim_city` (
  city_key STRING, state_code STRING, normalized_city_label STRING,
  display_city_label STRING, is_unknown BOOL
);
CREATE TABLE IF NOT EXISTS `lucky-seis-732.HUD_LIHTC.dim_service_year` (
  service_year_key INT64, service_year INT64, decade INT64, is_unknown BOOL
);
CREATE TABLE IF NOT EXISTS `lucky-seis-732.HUD_LIHTC.fact_project_activity` (
  activity_key STRING, release_key STRING, hud_id STRING,
  city_key STRING, service_year_key INT64, project_record_count INT64,
  service_year_status STRING, unit_status STRING, units_eligible BOOL,
  reported_total_units NUMERIC, reported_low_income_units NUMERIC,
  resyndication_cd STRING
);

-- A changed rule needs a documented migration; do not silently relabel history.
ASSERT NOT EXISTS (
  SELECT 1 FROM `lucky-seis-732.HUD_LIHTC.dim_release`
  WHERE release_key = v_release_key
    AND curation_rule_version IS DISTINCT FROM v_rule_version
) AS 'This release already uses another rule version. Review before rebuilding.';

CREATE TEMP TABLE staged_cities AS
SELECT DISTINCT city_key, state_code, normalized_city_label,
  COALESCE(normalized_city_label, '[Unknown city]') AS display_city_label,
  normalized_city_label IS NULL AS is_unknown
FROM staged_mn
UNION DISTINCT
SELECT
  TO_HEX(SHA256(TO_JSON_STRING(STRUCT(
    'MN' AS state_code, CAST(NULL AS STRING) AS normalized_city_label)))),
  'MN', CAST(NULL AS STRING), '[Unknown city]', TRUE;

CREATE TEMP TABLE staged_years AS
SELECT service_year AS service_year_key, service_year,
  DIV(service_year, 10) * 10 AS decade, FALSE AS is_unknown
FROM UNNEST(GENERATE_ARRAY(1987, 2024)) AS service_year
UNION ALL
SELECT 0, CAST(NULL AS INT64), CAST(NULL AS INT64), TRUE;

-- Replace facts only for the selected release; keep other releases intact.
-- INSERT/DELETE/MERGE are committed together. Temp stages disappear afterward.
BEGIN TRANSACTION;

MERGE `lucky-seis-732.HUD_LIHTC.dim_release` AS t
USING (SELECT v_release_key AS release_key) AS s
ON t.release_key = s.release_key
WHEN MATCHED THEN UPDATE SET last_built_at = v_run_at
WHEN NOT MATCHED THEN INSERT (
  release_key, archive_sha256, source_csv_uri, source_archive_url,
  source_member, source_sheet, acquisition_date, coverage_label,
  curation_rule_version, nationwide_raw_rows, minnesota_raw_rows,
  first_registered_at, last_built_at
) VALUES (
  v_release_key, v_release_key,
  'gs://lihtc-hud-data-seis732/projects.csv',
  'https://www.huduser.gov/lihtc/lihtcpub.zip',
  'LIHTCPUB.xlsx', 'Data', v_acquisition_date, 'Service years 1987-2024',
  v_rule_version, 55345, 1144, v_run_at, v_run_at
);

MERGE `lucky-seis-732.HUD_LIHTC.dim_city` AS t
USING staged_cities AS s ON t.city_key = s.city_key
WHEN NOT MATCHED THEN INSERT (
  city_key, state_code, normalized_city_label, display_city_label, is_unknown
) VALUES (
  s.city_key, s.state_code, s.normalized_city_label,
  s.display_city_label, s.is_unknown
);

MERGE `lucky-seis-732.HUD_LIHTC.dim_service_year` AS t
USING staged_years AS s ON t.service_year_key = s.service_year_key
WHEN NOT MATCHED THEN INSERT (
  service_year_key, service_year, decade, is_unknown
) VALUES (s.service_year_key, s.service_year, s.decade, s.is_unknown);

DELETE FROM `lucky-seis-732.HUD_LIHTC.fact_project_activity`
WHERE release_key = v_release_key;

INSERT INTO `lucky-seis-732.HUD_LIHTC.fact_project_activity` (
  activity_key, release_key, hud_id, city_key, service_year_key,
  project_record_count, service_year_status, unit_status, units_eligible,
  reported_total_units, reported_low_income_units, resyndication_cd
)
SELECT activity_key, release_key, hud_id, city_key, service_year_key,
  project_record_count, service_year_status, unit_status, units_eligible,
  reported_total_units, reported_low_income_units, resyndication_cd
FROM staged_mn;

COMMIT TRANSACTION;

-- Save this one-row result, then run 04_acceptance.sql.
SELECT
  'P2_CURATED_BUILD' AS result_set,
  v_run_at AS build_started_at_utc,
  v_release_key AS release_key,
  COUNT(*) AS curated_project_records,
  COUNT(DISTINCT hud_id) AS distinct_hud_ids,
  COUNTIF(service_year_key BETWEEN 1987 AND 2024) AS valid_year_records,
  COUNTIF(service_year_key = 0) AS unknown_or_outside_year_records,
  COUNTIF(units_eligible) AS unit_eligible_records_all_years,
  COUNTIF(NOT units_eligible) AS unit_excluded_records_all_years,
  COUNTIF(service_year_key BETWEEN 1987 AND 2024 AND units_eligible)
    AS unit_eligible_records_valid_years,
  COUNTIF(service_year_key BETWEEN 1987 AND 2024 AND NOT units_eligible)
    AS unit_excluded_records_valid_years
FROM `lucky-seis-732.HUD_LIHTC.fact_project_activity`
WHERE release_key = v_release_key;

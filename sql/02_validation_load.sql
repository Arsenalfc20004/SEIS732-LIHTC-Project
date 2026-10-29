-- 1. Compare all 80 field names, their order, and raw STRING types.
WITH expected AS (
  SELECT column_name, pos + 1 AS expected_position
  FROM UNNEST([
    'hud_id',
    'project',
    'proj_add',
    'proj_cty',
    'proj_st',
    'proj_zip',
    'state_id',
    'latitude',
    'longitude',
    'place1990',
    'place2000',
    'place2010',
    'place2020',
    'fips1990',
    'fips2000',
    'fips2010',
    'fips2020',
    'st2020',
    'cnty2020',
    'trct2020',
    'scattered_site_cd',
    'resyndication_cd',
    'allocamt',
    'n_units',
    'li_units',
    'n_0br',
    'n_1br',
    'n_2br',
    'n_3br',
    'n_4br',
    'aff_period',
    'aff_yrs',
    'inc_ceil',
    'low_ceil',
    'ceilunit',
    'yr_pis',
    'yr_alloc',
    'non_prof',
    'basis',
    'bond',
    'mff_ra',
    'fmha_514',
    'fmha_515',
    'fmha_538',
    'home',
    'home_amt',
    'tcap',
    'tcap_amt',
    'cdbg',
    'cdbg_amt',
    'htf',
    'htf_amt',
    'fha',
    'hopevi',
    'hpvi_amt',
    'tcep',
    'tcep_amt',
    'rad',
    'qozf',
    'qozf_amt',
    'rentassist',
    'trgt_pop',
    'trgt_fam',
    'trgt_eld',
    'trgt_dis',
    'trgt_hml',
    'trgt_oth',
    'trgt_spc',
    'type',
    'credit',
    'n_unitsr',
    'li_unitr',
    'metro',
    'dda',
    'qct',
    'nonprog',
    'nlm_reason',
    'nlm_spc',
    'datanote',
    'record_stat'
  ]) AS column_name WITH OFFSET AS pos
), actual AS (
  SELECT column_name, data_type, ordinal_position
  FROM `lucky-seis-732.HUD_LIHTC.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'projects'
), counts AS (
  SELECT
    (SELECT COUNT(*) FROM actual) AS actual_columns,
    COUNTIF(a.column_name IS NULL) AS missing_expected_columns,
    COUNTIF(a.data_type != 'STRING') AS wrong_raw_types,
    COUNTIF(a.ordinal_position != e.expected_position) AS wrong_positions,
    (SELECT COUNT(*) FROM actual
     WHERE column_name NOT IN (SELECT column_name FROM expected))
      AS unexpected_columns
  FROM expected AS e
  LEFT JOIN actual AS a USING (column_name)
)
SELECT *,
  IF(actual_columns = 80 AND missing_expected_columns = 0
     AND wrong_raw_types = 0 AND wrong_positions = 0
     AND unexpected_columns = 0, 'MATCH', 'REVIEW') AS schema_result
FROM counts;

-- 2. Compare compact aggregate checks with the existing local profile.
WITH typed AS (
  SELECT
    NULLIF(TRIM(hud_id), '') AS id,
    UPPER(TRIM(proj_st)) AS state,
    NULLIF(UPPER(TRIM(proj_cty)), '') AS city,
    TRIM(fips2020) AS tract_code,
    NULLIF(TRIM(resyndication_cd), '') AS resyndication_code,
    SAFE_CAST(NULLIF(TRIM(yr_pis), '') AS INT64) AS service_year,
    SAFE_CAST(NULLIF(TRIM(n_units), '') AS NUMERIC) AS total_units,
    SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC) AS low_income_units
  FROM `lucky-seis-732.HUD_LIHTC.projects`
), national AS (
  SELECT COUNT(*) AS row_count,
    COUNT(DISTINCT id) AS distinct_ids,
    COUNTIF(id IS NULL) AS blank_ids
  FROM typed
), mn AS (
  SELECT COUNT(*) AS row_count,
    COUNT(DISTINCT id) AS distinct_ids,
    COUNTIF(id IS NULL) AS blank_ids,
    COUNTIF(service_year BETWEEN 1987 AND 2024) AS valid_year_rows,
    MIN(IF(service_year BETWEEN 1987 AND 2024, service_year, NULL)) AS first_year,
    MAX(IF(service_year BETWEEN 1987 AND 2024, service_year, NULL)) AS last_year,
    COUNTIF(service_year = 8888) AS year_8888,
    COUNTIF(service_year = 9999) AS year_9999,
    COUNTIF(service_year IS NULL) AS missing_or_invalid_years,
    COUNTIF(total_units IS NULL) AS missing_or_invalid_total_units,
    COUNTIF(low_income_units IS NULL) AS missing_or_invalid_low_income_units,
    COUNTIF(low_income_units > total_units) AS inconsistent_units,
    COUNTIF(total_units < 0) AS negative_total_units,
    COUNTIF(low_income_units < 0) AS negative_low_income_units,
    COUNTIF(city IS NULL) AS blank_city_labels,
    COUNT(DISTINCT city) AS distinct_city_labels,
    COUNTIF(REGEXP_CONTAINS(tract_code, r'^\d{11}$')) AS valid_tract_codes,
    COUNTIF(REGEXP_CONTAINS(UPPER(tract_code), r'X')) AS tract_placeholders,
    COUNTIF(resyndication_code = '1') AS resyndicated,
    COUNTIF(resyndication_code IS NULL) AS unreported_resyndication
  FROM typed WHERE state = 'MN'
), duplicates AS (
  SELECT COUNT(*) AS duplicate_groups,
    COALESCE(SUM(n - 1), 0) AS excess_rows
  FROM (
    SELECT id, COUNT(*) AS n
    FROM typed WHERE state = 'MN' AND id IS NOT NULL
    GROUP BY id HAVING COUNT(*) > 1
  )
), checks AS (
  SELECT validation_check.*
  FROM national AS n CROSS JOIN mn AS m CROSS JOIN duplicates AS d,
  UNNEST([
    STRUCT('Nationwide rows' AS check_name, 55345 AS local_reference,
           n.row_count AS bigquery_result),
    STRUCT('Nationwide distinct IDs', 55345, n.distinct_ids),
    STRUCT('Nationwide blank IDs', 0, n.blank_ids),
    STRUCT('Minnesota rows', 1144, m.row_count),
    STRUCT('Minnesota distinct IDs', 1144, m.distinct_ids),
    STRUCT('Minnesota blank IDs', 0, m.blank_ids),
    STRUCT('Minnesota duplicate ID groups', 0, d.duplicate_groups),
    STRUCT('Minnesota excess rows for repeated IDs', 0, d.excess_rows),
    STRUCT('Minnesota valid service year rows', 1143, m.valid_year_rows),
    STRUCT('Minnesota first valid service year', 1987, m.first_year),
    STRUCT('Minnesota last valid service year', 2024, m.last_year),
    STRUCT('Minnesota year code 8888', 0, m.year_8888),
    STRUCT('Minnesota year code 9999', 1, m.year_9999),
    STRUCT('Minnesota missing or invalid years', 0, m.missing_or_invalid_years),
    STRUCT('Minnesota missing or invalid total units', 0,
           m.missing_or_invalid_total_units),
    STRUCT('Minnesota missing or invalid low income units', 0,
           m.missing_or_invalid_low_income_units),
    STRUCT('Minnesota low income units exceed total', 2, m.inconsistent_units),
    STRUCT('Minnesota negative total units', 0, m.negative_total_units),
    STRUCT('Minnesota negative low income units', 0, m.negative_low_income_units),
    STRUCT('Minnesota blank city labels', 0, m.blank_city_labels),
    STRUCT('Minnesota normalized city labels', 266, m.distinct_city_labels),
    STRUCT('Minnesota complete tract codes', 970, m.valid_tract_codes),
    STRUCT('Minnesota tract placeholders', 174, m.tract_placeholders),
    STRUCT('Minnesota resyndicated records', 34, m.resyndicated),
    STRUCT('Minnesota unreported resyndication', 681, m.unreported_resyndication)
  ]) AS validation_check
)
SELECT check_name, local_reference, bigquery_result,
  IF(local_reference = bigquery_result, 'MATCH', 'REVIEW') AS result
FROM checks
ORDER BY check_name;

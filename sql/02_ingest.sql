-- P2 / 02: verify and reuse the existing Raw table. GoogleSQL; US.
DECLARE v_verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
DECLARE v_expected_columns ARRAY<STRING> DEFAULT [
  'hud_id', 'project', 'proj_add', 'proj_cty', 'proj_st', 'proj_zip',
  'state_id', 'latitude', 'longitude', 'place1990', 'place2000', 'place2010',
  'place2020', 'fips1990', 'fips2000', 'fips2010', 'fips2020', 'st2020',
  'cnty2020', 'trct2020', 'scattered_site_cd', 'resyndication_cd', 'allocamt', 'n_units',
  'li_units', 'n_0br', 'n_1br', 'n_2br', 'n_3br', 'n_4br',
  'aff_period', 'aff_yrs', 'inc_ceil', 'low_ceil', 'ceilunit', 'yr_pis',
  'yr_alloc', 'non_prof', 'basis', 'bond', 'mff_ra', 'fmha_514',
  'fmha_515', 'fmha_538', 'home', 'home_amt', 'tcap', 'tcap_amt',
  'cdbg', 'cdbg_amt', 'htf', 'htf_amt', 'fha', 'hopevi',
  'hpvi_amt', 'tcep', 'tcep_amt', 'rad', 'qozf', 'qozf_amt',
  'rentassist', 'trgt_pop', 'trgt_fam', 'trgt_eld', 'trgt_dis', 'trgt_hml',
  'trgt_oth', 'trgt_spc', 'type', 'credit', 'n_unitsr', 'li_unitr',
  'metro', 'dda', 'qct', 'nonprog', 'nlm_reason', 'nlm_spc',
  'datanote', 'record_stat'
];

-- Match every field name, position, and type against the declared CSV schema.
CREATE TEMP TABLE raw_schema_issues AS
WITH expected AS (
  SELECT name AS expected_name, offset_index + 1 AS ordinal_position
  FROM UNNEST(v_expected_columns) AS name WITH OFFSET AS offset_index
), actual AS (
  SELECT column_name, ordinal_position, data_type
  FROM `lucky-seis-732.HUD_LIHTC.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name = 'projects'
)
SELECT e.expected_name, a.column_name, a.data_type
FROM expected AS e
FULL OUTER JOIN actual AS a USING (ordinal_position)
WHERE e.expected_name IS DISTINCT FROM a.column_name
   OR a.data_type IS DISTINCT FROM 'STRING';

ASSERT (SELECT COUNT(*) FROM raw_schema_issues) = 0
  AS 'Raw schema differs: inspect raw_schema_issues before curating.';

-- Save this aggregate result as the current P2 input verification.
SELECT
  'P2_RAW_VERIFICATION' AS result_set,
  v_verified_at AS verified_at_utc,
  'gs://lihtc-hud-data-seis732/projects.csv' AS source_csv,
  'lucky-seis-732.HUD_LIHTC.projects' AS raw_table,
  COUNT(*) AS nationwide_raw_rows,
  COUNTIF(UPPER(TRIM(proj_st)) = 'MN') AS minnesota_raw_rows,
  COUNTIF(UPPER(TRIM(proj_st)) = 'MN'
          AND NULLIF(TRIM(hud_id), '') IS NULL) AS mn_missing_ids,
  COUNT(DISTINCT IF(UPPER(TRIM(proj_st)) = 'MN',
                     NULLIF(TRIM(hud_id), ''), NULL)) AS mn_distinct_ids,
  ARRAY_LENGTH(v_expected_columns) AS declared_columns,
  (SELECT COUNT(*) FROM raw_schema_issues) AS schema_issues
FROM `lucky-seis-732.HUD_LIHTC.projects`;

/*
-- CREATE SCHEMA IF NOT EXISTS `lucky-seis-732.HUD_LIHTC` OPTIONS(location='US');
-- LOAD DATA OVERWRITE `lucky-seis-732.HUD_LIHTC.projects`
(
  hud_id STRING,
  project STRING,
  proj_add STRING,
  proj_cty STRING,
  proj_st STRING,
  proj_zip STRING,
  state_id STRING,
  latitude STRING,
  longitude STRING,
  place1990 STRING,
  place2000 STRING,
  place2010 STRING,
  place2020 STRING,
  fips1990 STRING,
  fips2000 STRING,
  fips2010 STRING,
  fips2020 STRING,
  st2020 STRING,
  cnty2020 STRING,
  trct2020 STRING,
  scattered_site_cd STRING,
  resyndication_cd STRING,
  allocamt STRING,
  n_units STRING,
  li_units STRING,
  n_0br STRING,
  n_1br STRING,
  n_2br STRING,
  n_3br STRING,
  n_4br STRING,
  aff_period STRING,
  aff_yrs STRING,
  inc_ceil STRING,
  low_ceil STRING,
  ceilunit STRING,
  yr_pis STRING,
  yr_alloc STRING,
  non_prof STRING,
  basis STRING,
  bond STRING,
  mff_ra STRING,
  fmha_514 STRING,
  fmha_515 STRING,
  fmha_538 STRING,
  home STRING,
  home_amt STRING,
  tcap STRING,
  tcap_amt STRING,
  cdbg STRING,
  cdbg_amt STRING,
  htf STRING,
  htf_amt STRING,
  fha STRING,
  hopevi STRING,
  hpvi_amt STRING,
  tcep STRING,
  tcep_amt STRING,
  rad STRING,
  qozf STRING,
  qozf_amt STRING,
  rentassist STRING,
  trgt_pop STRING,
  trgt_fam STRING,
  trgt_eld STRING,
  trgt_dis STRING,
  trgt_hml STRING,
  trgt_oth STRING,
  trgt_spc STRING,
  type STRING,
  credit STRING,
  n_unitsr STRING,
  li_unitr STRING,
  metro STRING,
  dda STRING,
  qct STRING,
  nonprog STRING,
  nlm_reason STRING,
  nlm_spc STRING,
  datanote STRING,
  record_stat STRING
)
FROM FILES (
  format='CSV',
  uris=['gs://lihtc-hud-data-seis732/projects.csv'],
  skip_leading_rows=1,
  encoding='UTF-8',
  allow_quoted_newlines=TRUE,
  max_bad_records=0
);

*/

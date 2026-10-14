# HUD LIHTC to BigQuery: Ingestion Checklist

My plan is to load HUD's LIHTC project data into BigQuery and use Minnesota as the case study. The source has been profiled locally. I will complete the cloud setup and loading steps after instructor approval, before starting P1 modeling.

## 1. Confirm approval and cloud resources

Before loading the data, I will:

- Request instructor approval for HUD's official download and the use-rights plan.
- Confirm permission to use Cloud Storage and BigQuery in the authorized project.
- Confirm that the bucket and BigQuery dataset use compatible locations.
- Record the actual project ID, bucket, dataset, region, and setup date.

I will use the following names consistently in this plan:

| Resource | Proposed value |
| --- | --- |
| Google Cloud project ID | `seis-lihtc-project` |
| BigQuery dataset | `HUD_LIHTC` |
| BigQuery table | `projects` |
| Cloud Storage bucket | `lihtc-hud-data-seis732` |
| Bucket and dataset location | `US` multi-region |

These resources have not been created or confirmed. The project ID and bucket name are proposed and may be unavailable. If the course requires a different project ID, bucket, or location, I will update every reference before running the commands. The project ID is lowercase; `HUD_LIHTC` is the dataset name and `projects` is the table name.

## 2. Download the source and prepare the CSV

I will download the [official HUD archive](https://www.huduser.gov/lihtc/lihtcpub.zip). The main workbook in the profiled release is `LIHTCPUB.xlsx`. Its `Data` sheet contains 80 columns and 55,345 project records nationwide. I will use this main workbook for the Minnesota analysis.

To prepare the file, I will open the workbook, select the `Data` sheet, and export it as a UTF-8 CSV named `projects.csv`. I will preserve the 80 columns in their original order, one header row, blank values, text identifiers, and special year codes. I will check the exported header and identifier formatting before loading.

The ZIP, workbook, and CSV will stay in local folders such as `downloads/` and `data/`, which are excluded from Git. I will record the download date and checksum. If the downloaded release differs from the profiled release, I will use its new counts for reconciliation.

## 3. Create the destination

After approval, I will create or use the authorized bucket and the `HUD_LIHTC` dataset in compatible locations, then upload `projects.csv` to the bucket. The planned storage path is:

```text
gs://lihtc-hud-data-seis732/projects.csv
```

I will keep the all-state source in one raw table and select Minnesota in the analytical queries with `UPPER(TRIM(proj_st)) = 'MN'`. All 80 raw columns will be STRING to preserve the source values. The analytical SQL will use `SAFE_CAST` for years and unit counts.

The full SQL destination is `seis-lihtc-project.HUD_LIHTC.projects`. Once the actual project ID and dataset are confirmed, I will run this definition to create the empty table:

```sql
CREATE TABLE `seis-lihtc-project.HUD_LIHTC.projects` (
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
);
```

## 4. Load the CSV

I will use Cloud Shell to load the CSV after creating the table. First, I will save the table's explicit schema to a temporary local file:

```bash
bq show --schema --format=prettyjson \
  seis-lihtc-project:HUD_LIHTC.projects > /tmp/hud-lihtc-schema.json
```

After confirming that this file contains all 80 STRING columns, I will run:

```bash
bq --project_id=seis-lihtc-project --location=US load \
  --replace \
  --source_format=CSV \
  --encoding=UTF-8 \
  --skip_leading_rows=1 \
  --allow_quoted_newlines \
  --max_bad_records=0 \
  seis-lihtc-project:HUD_LIHTC.projects \
  gs://lihtc-hud-data-seis732/projects.csv \
  /tmp/hud-lihtc-schema.json
```

The command replaces the contents of this raw table with the selected snapshot, avoiding duplicate rows from repeated loads. It supplies the explicit schema again because a replacement load can replace the table schema. The temporary JSON contains only schema metadata and will stay outside Git. I will not use schema autodetection for this raw load.

The SQL table path uses `project.dataset.table`. The command-line destination uses `project:dataset.table`. Both point to the same table.

## 5. Validate and record results

I will confirm that `sql/00_feasibility.sql` uses the actual project ID and the same `HUD_LIHTC.projects` destination. The supplied queries currently use the proposed ID, `seis-lihtc-project`. I will run the statements one at a time in the confirmed location, checking estimated bytes before execution and following the course's query-cost controls.

For the profiled release, I will compare the loaded results with:

- 55,345 nationwide rows and 1,144 Minnesota rows.
- Unique, nonblank project IDs.
- 1,143 Minnesota records with usable service years from 1987 through 2024.
- One Minnesota service-year code of `9999`.
- Two Minnesota records where low-income units exceed total units.
- City-label completeness, tract placeholders, and resyndication flags.

I will add the actual cloud identifiers, query dates, estimated bytes, bytes processed, counts, and quality results to `evidence/p0-feasibility-results.md`. The local profile and the new BigQuery results will remain clearly labeled.

## 6. Prepare the Minnesota analytical scope

My initial analysis will use Minnesota project records within the valid service-year window. I will keep unknown years separate, review city labels, and decide how repeated financing rounds should affect unit counts.

For low-income unit shares, I will use the same eligible records in the numerator and denominator. The two inconsistent unit records will be excluded from both sums until resolved. The results will describe reported project activity, with the counting policy explained before I present unit totals.

I will begin P1 modeling after instructor approval and the required load validation.



## References: 
CSV loading (https://docs.cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv)
schema definition and export (https://docs.cloud.google.com/bigquery/docs/schemas)
Google Cloud project IDs (https://docs.cloud.google.com/resource-manager/docs/creating-managing-projects).

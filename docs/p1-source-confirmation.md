# My HUD source record for P1

## Source approval

My instructor approved the HUD source for P1 with conditions. The approval is recorded in `external-source-request.md`. I still need to confirm the actual cloud resources and add the load-validation results.

## The file I plan to load

| Item | Recorded source detail |
| --- | --- |
| Provider | U.S. Department of Housing and Urban Development |
| Dataset | National LIHTC property-level database covering projects through 2024 |
| HUD source page | https://www.huduser.gov/portal/datasets/lihtc/property.html |
| Official archive | https://www.huduser.gov/lihtc/lihtcpub.zip |
| Acquisition recorded in P0 | October 13, 2026, America/Chicago |
| Selected workbook | `LIHTCPUB.xlsx` |
| Selected worksheet | `Data` |
| Dictionary | 1987–2024 Data Dictionary, April 2026 |
| HUD page revision date | May 28, 2026; recorded separately from the acquisition date |
| Archive size in the P0 profile | 29,421,665 bytes |
| Uncompressed workbook size in the P0 profile | 12,975,834 bytes |
| Archive SHA-256 recorded in P0 | `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288` |
| File for loading after conversion | `projects.csv`, UTF-8, one header, all 80 columns in source order |
| Local row counts | 55,345 nationwide; 1,144 Minnesota |

I will compare the archive I actually use with this recorded checksum before loading. The earlier profile found an Excel workbook and no CSV, while HUD's page lists a CSV. I will use the contents of my selected archive to confirm the format.

If I use a different archive, I will record its acquisition date, selected file and sheet or CSV header, checksum, and local results. The earlier counts will remain a reference for the earlier input.

## My cloud naming plan

| Resource | Planned name |
| --- | --- |
| Execution project | `lucky-seis-732` |
| BigQuery dataset | `HUD_LIHTC` |
| Raw table | `projects` |
| Full SQL identifier | `lucky-seis-732.HUD_LIHTC.projects` |
| Cloud Storage bucket | `lihtc-hud-data-seis732` |
| CSV object | `gs://lihtc-hud-data-seis732/projects.csv` |
| Bucket and dataset location | `US` multi-region |

The project name comes from my class SQL. I will confirm that I can use it for this load and that the proposed bucket name is available. If an authorized name changes, I will update the affected SQL and documents together.

## How I will check the load

After verifying and uploading the CSV, I will run `sql/01_create_and_load.sql`. I will then run the statements in `sql/02_validate_load.sql` separately, checking estimated bytes first. My actual results will go in `evidence/p1-load-validation.md`. Any REVIEW result needs an explanation before I rely on the imported table.

P1 allows an observed local grain check while an approved external source awaits loading. I will follow any deadline attached to the source conditions and add the BigQuery comparison after loading.

My fact grain is one Minnesota HUD project record in one source release. Retaining more than one release requires the release identifier as well as `hud_id`. I will count reported project activity, preserve `resyndication_cd`, and leave unreported flags unknown. Unit totals will be labeled **reported low-income units**, since repeated financing records can refer to the same physical housing. The unit-eligibility rules are explained in `p1-plan.md`.


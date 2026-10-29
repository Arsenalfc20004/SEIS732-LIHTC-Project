# My HUD source record for P1

## Source approval

My instructor approved the HUD source for P1 with conditions. The approval is recorded in `external-source-request.md`. The uploaded object and queried BigQuery table are now recorded below. The row counts and 14 comparison checks matched P0. Actual input hashes and exact job metadata still need to be entered.

## P0 source record and uploaded file

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

I still need to compare the actual archive with this recorded checksum. The completed load and aggregate matches do not establish byte-for-byte archive identity. The earlier profile found an Excel workbook and no CSV, while HUD's page lists a CSV. I will use the contents of my selected archive to confirm the format.

If I use a different archive, I will record its acquisition date, selected file and sheet or CSV header, checksum, and local results. The earlier counts will remain a reference for the earlier input.

## Cloud resources used for the reported checks

| Resource | Recorded name |
| --- | --- |
| Execution project | `lucky-seis-732` |
| BigQuery dataset | `HUD_LIHTC` |
| Raw table | `projects` |
| Full SQL identifier | `lucky-seis-732.HUD_LIHTC.projects` |
| Cloud Storage bucket | `lihtc-hud-data-seis732` |
| CSV object | `gs://lihtc-hud-data-seis732/projects.csv` |
| Location | `US` specified in the loading SQL; exact job metadata not yet captured |

The object URI was confirmed during upload. The BigQuery table was queried successfully with 55,345 nationwide rows and 1,144 Minnesota rows. These are the resource names used in the reported checks. Any later name change will be reflected consistently in the SQL and documents.

## Load comparison recorded

I used the supplied loading SQL and reported the nationwide/Minnesota counts, followed by MATCH for all 14 rows in the comparison query. Those executed checks are saved as statements 4 and 5 in `sql/01_source_profile.sql`. The full results and remaining provenance details are recorded in `evidence/p1-load-validation.md`.

The observed schema results confirm 80 STRING columns. The separate full name/order audit and all 25 checks in `sql/02_validate_load.sql` are available, but are not claimed as executed here.

The exact archive and exported CSV hashes still need to be recorded against the P0 source selection. I will follow any deadline attached to my instructor's source conditions.

My fact grain is one Minnesota HUD project record in one source release. Retaining several releases requires the verified release identifier with `hud_id`. I will count reported project activity, preserve `resyndication_cd`, keep unreported flags unknown, and label unit sums as **reported low-income units**. The unit rules are explained in `p1-plan.md`.

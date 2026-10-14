# P0 Feasibility Evidence: Minnesota LIHTC Case Study

## What was checked

The initial checks were completed locally on HUD's official project workbook. These results support the external-source request. They are not BigQuery query results, and a completed cloud load is not claimed.

## Source record

- Source page: https://www.huduser.gov/portal/datasets/lihtc/property.html
- Download: https://www.huduser.gov/lihtc/lihtcpub.zip
- Acquisition date: October 13, 2026, America/Chicago.
- Selected file and sheet: `LIHTCPUB.xlsx`, `Data`.
- Archive size: 29,421,665 bytes, about 29.4 MB.
- Main workbook size: 12,975,834 uncompressed bytes, about 13 MB.
- Source columns: 80.
- Dictionary: 1987-2024 Data Dictionary, April 2026, included in the archive.
- SHA-256: `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288`.

The observed archive contained Excel and Access files, a building-address workbook, and the dictionary. No CSV was present. The source file will need conversion for the proposed CSV load. The building-address workbook was not profiled for this project's questions; no building row count or building-key uniqueness is claimed.

## Minnesota profile

These counts describe all Minnesota source records before the unknown service-year record is excluded from the initial historical analysis.

| Check | Observed result |
| --- | ---: |
| Minnesota records | 1,144 |
| Distinct nonblank `hud_id` values | 1,144 |
| Missing IDs | 0 |
| Duplicate-ID groups / excess rows | 0 / 0 |
| Exact duplicate rows | 0 |
| Valid service years from 1987 through 2024 | 1,143 records |
| First and last year within the chosen window | 1987 / 2024 |
| Service year coded `9999` | 1 |
| Service year coded `8888` | 0 |
| Missing total / low-income unit counts | 0 / 0 |
| Low-income units greater than total units | 2 |
| Negative total / low-income unit values | 0 / 0 |
| Blank city labels | 0 |
| Distinct city labels after trimming and uppercasing | 266 |
| Complete 11-digit `fips2020` values | 970 |
| `fips2020` values containing X placeholders | 174 |
| Records flagged as resyndicated | 34 |
| Unreported resyndication flag | 681 |

The raw unit ranges are 8-1,303 total units and 7-1,200 low-income units per project record.

## Nationwide context

The main source has 55,345 records, each with a distinct nonblank `hud_id`. Of those, 52,513 have service years within 1987-2024. Special year codes occur in 1,991 records for `8888` and 774 for `9999`. There are also 66 records with 2025 and one with 2027, which are outside the chosen analysis window.

Nationwide, 303 total-unit counts and 1,885 low-income-unit counts are missing. There are 439 records in which low-income units exceed total units. These nationwide counts provide context; Minnesota is the case study.

## Interpretation

The initial source is large enough for a focused Minnesota project and has the state, city, year, and unit fields needed for the proposed questions. The source identifier is unique in this release, but that does not establish uniqueness of physical properties across financing rounds.

The usable source names are `hud_id`, `proj_st`, `proj_cty`, `yr_pis`, `yr_alloc`, `n_units`, `li_units`, `fips2020`, and `resyndication_cd`. Tract identifiers are present; some contain placeholders.

I will keep unknown years separate, review city-label spelling, and resolve the two inconsistent Minnesota unit records before using unit measures. For unit shares, the numerator and denominator must come from the same eligible records. The share refers to reported units in these project records, not all housing in a city.

The dictionary describes `n_unitsr` and `li_unitr` as replacement measures. Those fields will not silently replace `n_units` and `li_units`. The compliance-monitoring field `nonprog` also does not establish whether a property remains affordable today.

No separate license file was included in the observed archive. The public download and HUD's public-database description are the use-rights evidence submitted for instructor review. No unverified public-domain license is claimed.

## Reproduce the core checks after loading

The figures above were produced locally from the official workbook before this P0 submission. The source checksum identifies that release. The seven-file submission keeps the summarized evidence and the SQL needed to repeat the core checks in BigQuery after source approval.

Follow `docs/ingestion-checklist.md` to load the main workbook. Confirm that `sql/00_feasibility.sql` uses the actual authorized project ID; its proposed destination is `seis-lihtc-project.HUD_LIHTC.projects`. Then run the statements one at a time after checking the estimated bytes. Compare the loaded counts, identifier behavior, year categories, city completeness, tract codes, and unit inconsistencies with this evidence.

The exact full-row duplicate count was a local check; the SQL checks duplicate project IDs. If a fresh source download has a different checksum, record the new acquisition date and results. Keep downloaded data outside Git.

## Cloud validation after approval

The planned table is `seis-lihtc-project.HUD_LIHTC.projects`, the proposed bucket is `lihtc-hud-data-seis732`, and the planned location is the `US` multi-region. These are setup proposals; the actual identifiers and access have not been confirmed.

| Check | Status |
| --- | --- |
| Instructor approval of external source | Pending |
| Actual course project, bucket, dataset, and region | Proposed; not observed |
| Imported nationwide and Minnesota row counts | Not executed |
| Imported key, date, geography, and unit checks | Not executed |
| Query estimates and bytes processed | Not recorded yet |
| Allocation-year coverage | Not summarized in the current local profile |

**Feasibility decision:** The official source appears suitable for the proposed historical Minnesota dashboard, subject to instructor approval and a reconciled BigQuery load. P1 can begin after that approval and the required validation.


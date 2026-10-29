# My HUD source and BigQuery checks

## Current progress

The CSV is loaded at `lucky-seis-732.HUD_LIHTC.projects`. I reported 55,345 nationwide rows and 1,144 Minnesota rows, then confirmed that all 14 rows in the supplied comparison query returned MATCH. The results below are transcribed from those reported outputs. ChatGPT did not run these queries in my account.

**Record date:** October 28, 2026, America/Chicago. This is the date the results were recorded; exact query execution timestamps and job IDs have not been captured here.

## Source and destination

| Item | Current record |
| --- | --- |
| Project | `lucky-seis-732` |
| Dataset and table | `HUD_LIHTC.projects` |
| Full destination | `lucky-seis-732.HUD_LIHTC.projects` |
| Uploaded source object | `gs://lihtc-hud-data-seis732/projects.csv` |
| Location | `US` specified by the supplied loading SQL |
| Source selected in the P0 record | October 13, 2026 acquisition; `LIHTCPUB.xlsx`, worksheet `Data`; April 2026 dictionary covering 1987–2024 |
| P0 archive SHA-256 reference | `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288` |
| Actual archive checksum | E07ACEE706174B276F89596D614AC5699EFA9848659E5834FDFB5198FA0A7288 |
| Exported CSV SHA-256 | 8A0C8B5596BF2E192437D4024383D3A119C78BEE5DE562058737E51982228335 |
| Independent local CSV header/count check |the loaded table has 80 STRING columns and 55,345 rows |
| Load-job ID, displayed status, and exact time | lucky-seis-732:US.job_mBYqbsGysemj4Zr8OVw02T49Yv7M, processed,  Creation time
28 Oct 2026, 22:04:22 UTC-5 / Start time 28 Oct 2026, 22:04:22 UTC-5 / End time 28 Oct 2026, 22:04:29 UTC-5 |
| Query estimates and bytes processed | Query estimate not recorded, bytes processed 0|

## Observed comparison results

Statements 4 and 5 in `sql/01_source_profile.sql` reproduce the checks used for this record. Statement 4 is the nationwide/Minnesota count. Statement 5 is the 14-row key, date, unit, and column comparison. The repeated Minnesota total appears once in this combined summary.

| Check | P0 reference | Reported BigQuery result | Conclusion |
| --- | ---: | ---: | --- |
| Nationwide records | 55,345 | 55,345 | MATCH |
| Minnesota records | 1,144 | 1,144 | MATCH |
| Missing IDs | 0 | 0 | MATCH |
| Distinct nonblank IDs | 1,144 | 1,144 | MATCH |
| Repeated ID groups | 0 | 0 | MATCH |
| Excess duplicate-key rows | 0 | 0 | MATCH |
| Valid service-year records | 1,143 | 1,143 | MATCH |
| Unknown year code 9999 | 1 | 1 | MATCH |
| First valid service year | 1,987 | 1,987 | MATCH |
| Last valid service year | 2,024 | 2,024 | MATCH |
| Missing total units | 0 | 0 | MATCH |
| Missing low-income units | 0 | 0 | MATCH |
| Low-income units exceed total | 2 | 2 | MATCH |
| Table columns | 80 | 80 | MATCH |
| Columns not STRING | 0 | 0 | MATCH |

## Grain conclusion

The loaded Minnesota input has 1,144 records, 1,144 distinct nonblank HUD IDs, no missing IDs, and no repeated-ID groups or excess duplicate-key rows. This supports one HUD project record per ID in the loaded snapshot. It does not establish unique physical housing across financing rounds. The planned fact will use the verified release identifier with `hud_id` when retaining multiple releases.

## Scope of the checks

The observed schema checks confirm 80 columns and STRING types. The supplied load statement declares the 80 field names and their order, but a separate execution of the full name/order audit in `sql/02_validate_load.sql` has not been reported. Its additional checks remain available; this evidence does not claim that all 25 checks in that file were run.

Matching aggregates support agreement on these tested properties. They do not prove byte-for-byte file identity or accuracy of every source value. I still need to confirm the exact source input against the P0 release record and enter its actual hashes.

## Interpretation and next step

I will retain the unknown-year project for reconciliation and exclude it from the 1987–2024 audience filter. The two inconsistent unit records remain in project counts, with unit measures excluded until resolved. Their overlap with the valid-year cohort still needs to be measured.

The product will describe reported project activity and reported units, preserve resyndication information, and use the same eligible records in both parts of a unit-share calculation.

**Decision:** The observed grain, year, unit, and column checks support proceeding with the proposed P1 model. Before registering the warehouse release key, I will finish the actual source-file verification. The M07 peer-feedback memo is still awaiting my class feedback.

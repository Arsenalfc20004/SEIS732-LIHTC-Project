# My HUD source and load checks

## Current progress

Instructor has approved the HUD source with conditions. The P0 local profile is documented separately. I will use this file to record the actual cloud resources, load job, and BigQuery comparisons; these results still need to be entered.

## File and destination record

| Item | Current record |
| --- | --- |
| Project | `lucky-seis-732` |
| Destination | `lucky-seis-732.HUD_LIHTC.projects` |
| CSV object | `gs://lihtc-hud-data-seis732/projects.csv` |
| Location | Planned as `US` |
| Selected source | `LIHTCPUB.xlsx`, sheet `Data` |
| P0 archive SHA-256 | `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288` |
| Checksum of the archive used | Downloads\projects.csv |
| Exported CSV SHA-256 | Downloads\projects.csv|
| CSV header and record count | Not yet recorded; expect 80 fields and 55,345 data rows for the pinned input |
| Load job ID, status, and time | Not yet recorded |

## Schema comparison

I will run statement 1 in `sql/02_validate_load.sql` and enter all six output values here. For the planned schema, I expect `actual_columns = 80`, zero missing columns, zero wrong types, zero wrong positions, zero unexpected columns, and `schema_result = MATCH`.

**Actual result:** Not yet recorded.

## Counts and field checks

Statement 2 in `sql/02_validate_load.sql` compares 25 aggregate checks with the P0 profile. I will add its result table here, keeping the reference and observed BigQuery values clearly labeled.

**Actual results:** Not yet recorded.

For each query, I will record the date, job location, estimated bytes, and actual bytes processed. If a check says REVIEW, I will record the difference, investigate the source and load settings, and explain what I changed or learned. A new input needs a new baseline; changing an old reference just to produce MATCH would not establish agreement.

## Grain check for P1

I will run the first statement in `sql/01_source_profile.sql`. For the pinned Minnesota input, I expect 1,144 source rows, 1,144 distinct nonblank IDs, zero missing IDs, zero repeated-ID groups, and zero excess rows. I will put the observed result beside the grain explanation in `docs/p1-plan.md` and link back to this evidence.

**Actual grain result:** Not yet recorded.

## What the results mean

The checks will show whether the imported table agrees with the selected source on the tested fields and counts. They will not establish that each HUD ID represents different physical housing. My analysis will describe reported LIHTC project activity and reported units, preserve special year codes and resyndication information, and use the same eligible records for both parts of any unit-share calculation.

## My decision after the checks

Pending. I will record whether the imported table is ready to use, explain any unresolved difference, and link the result from my P1 plan. Until loading is complete, P1 can use the supported local grain result, subject to any deadline in my instructor's source conditions.


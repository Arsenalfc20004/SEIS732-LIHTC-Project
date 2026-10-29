# My HUD source and load checks

## Current progress

My instructor has approved the HUD source with conditions. The P0 local profile is documented separately. I will use this file to record the actual cloud resources, load job, and BigQuery comparisons; those results still need to be entered.

## File and destination record

| Item | Current record |
| --- | --- |
| Project | `lucky-seis-732`; from my class SQL. HUD loading permissions still need confirmation |
| Destination | `lucky-seis-732.HUD_LIHTC.projects`; creation not yet recorded |
| CSV object | `gs://lihtc-hud-data-seis732/projects.csv`; bucket and upload not yet confirmed |
| Location | Planned as `US`; actual bucket and dataset locations still need to be recorded |
| Selected source | `LIHTCPUB.xlsx`, sheet `Data`, October 13, 2026 acquisition recorded in P0 |
| P0 archive SHA-256 | `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288` |
| Checksum of the archive used | E07ACEE706174B276F89596D614AC5699EFA9848659E5834FDFB5198FA0A7288|
| Exported CSV SHA-256 | 8A0C8B5596BF2E192437D4024383D3A119C78BEE5DE562058737E51982228335 | 
| CSV header and record count | Exported CSV contains 80 columns and 55,345 data rows, excluding the header. These counts match the loaded BigQuery table. |
| Load job ID, status, and time |lucky-seis-732:US.job_mBYqbsGysemj4Zr8OVw02T49Yv7M, processed,  Creation time
28 Oct 2026, 22:04:22 UTC-5 / Start time 28 Oct 2026, 22:04:22 UTC-5 / End time 28 Oct 2026, 22:04:29 UTC-5|

## Schema comparison

I will run statement 1 in `sql/02_validate_load.sql` and enter all six output values here. For the planned schema, I expect `actual_columns = 80`, zero missing columns, zero wrong types, zero wrong positions, zero unexpected columns, and `schema_result = MATCH`.

**Actual result:** Matched.

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

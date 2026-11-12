# P1 Plan: Affordable Housing in Minnesota

My instructor's P1 feedback supported the meaning of my city totals, my treatment of unusable unit values, and my decision to keep releases separate. The requested follow-up was to bring this main plan up to date and link directly to the diagram and comparison SQL. This revision records the completed Raw load and reconciliation, the archive checksum, and the P2 Curated build and acceptance results. The audience, question, fact grain, and release-history design remain the same. Serving and the history demonstration remain planned for P3.

**Direct links:** [Model diagram](model.svg) · [P1 source-comparison SQL, statements 4–5](../sql/01_source_profile.sql) · [Current Raw verification SQL](../sql/02_ingest.sql) · [P2 build and observed results](p2-build.md).


## 1. Establish the question and check the source

I chose Minnesota to keep the project focused on one state and make the city comparisons manageable. My intended user is a Minnesota Housing program analyst reviewing the history of LIHTC project activity. The analyst could use the results to identify cities for closer review and prepare for planning discussions. This is an audience scenario for the course project; it does not represent a request or endorsement from Minnesota Housing.

**My main question:** Which Minnesota cities have the most reported LIHTC project records and reported low-income units for projects placed in service from 1987 through 2024?

**Supporting question:** How has the number of reported project records changed by placed-in-service year?

Each comparison will use one selected HUD release. I am studying the activity recorded in the database. These records alone cannot tell me how many unique new homes were created, how many units are vacant, or where current housing need is greatest.

**What changed after P0 and P1 feedback.** I narrowed the project to one main question and one supporting question and kept each release identifiable. I loaded the CSV into my own BigQuery project and reconciled it with the local profile. The earlier 14 comparison checks matched, and my recent Raw verification again found 55,345 nationwide rows, 1,144 Minnesota rows, and zero full-schema issues. The archive checksum I reported matches P0. In P2, I built the Minnesota fact and dimensions and obtained PASS on both acceptance checks. These are progress updates to the original model; they do not change what a project record means.

**My source and loaded table.** My P0 profile used HUD's [National LIHTC property-level database](https://www.huduser.gov/portal/datasets/lihtc/property.html), downloaded as [lihtcpub.zip](https://www.huduser.gov/lihtc/lihtcpub.zip). The selected source file is `LIHTCPUB.xlsx`, worksheet `Data`, containing 80 columns. Its recorded archive SHA-256 is:

```text
e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288
```

The dictionary recorded in P0 is dated April 2026 and covers 1987–2024. HUD's recorded page revision date, May 28, 2026, is separate from the acquisition date. My declared source selection is the P0 archive's `LIHTCPUB.xlsx`, worksheet `Data`, exported to `gs://lihtc-hud-data-seis732/projects.csv`. my most recent archive SHA-256 matches the P0 value above and is the release key used in P2. The Raw schema and counts also agree with the profile. The archive comparison supports file identity; the SQL checks do not independently audit the manual spreadsheet export.

One source row is a HUD project record in that release. The local P0 profile recorded 55,345 nationwide rows, including 1,144 Minnesota rows. Of the Minnesota records, 1,143 have service years in 1987–2024, and one uses the unknown-year code `9999`. Two records report more low-income units than total units. These were the local findings carried forward from P0. The same counts, service-year results, and unit checks matched the earlier BigQuery comparison.

| Source detail | Current record |
| --- | --- |
| BigQuery source/Raw table | `lucky-seis-732.HUD_LIHTC.projects`; queried successfully, with 55,345 nationwide rows |
| Cloud Storage input | `gs://lihtc-hud-data-seis732/projects.csv`; uploaded object address confirmed |
| Location | `US`, the dataset and specified processing location for the build |
| Fields needed for the question | `hud_id`, `proj_st`, `proj_cty`, `yr_pis`, `n_units`, `li_units`, `resyndication_cd` |
| Raw schema | 80 fields; the November 11 full name/order/STRING-type comparison returned zero schema issues |

The [P0 evidence](../evidence/p0-feasibility-results.md), earlier [source confirmation](p1-source-confirmation.md), and [ingestion checklist](ingestion-checklist.md) preserve the preceding source work. The [P2 build note](p2-build.md) is the current execution record and supersedes earlier pending-status notes about the archive checksum or cloud validation. The [comparison SQL](../sql/01_source_profile.sql) reproduces the P1 checks, while [SQL 02](../sql/02_ingest.sql) checks the current full schema and counts. The same cloud names are used throughout.

**Checking the grain.** For one release, I expect trimmed, nonblank `hud_id` to identify one project record. If I retain several releases, the identifier becomes `(release_key, hud_id)`. I check all Minnesota records before applying year or unit rules, so those rules cannot hide duplicate IDs.

| Minnesota grain check | Expected from P0 | Observed in BigQuery |
| --- | ---: | ---: |
| Source records | 1,144 | 1,144 |
| Rows with a missing or blank `hud_id` | 0 | 0 |
| Distinct nonblank `hud_id` values | 1,144 | 1,144 |
| Repeated nonblank ID groups | 0 | 0 |
| Excess rows in repeated groups | 0 | 0 |

This result supports one project record per ID in this release. It does not establish that every ID refers to different physical housing. I will keep resyndication information and count reported project activity. If a later source has repeated IDs within a release, I will investigate their meaning before choosing a selection or aggregation rule.

The executed count and comparison queries are saved as statements 4 and 5 in [BigQuery profiling SQL](../sql/01_source_profile.sql). I reported 55,345 nationwide rows and 1,144 Minnesota rows, followed by MATCH for all 14 comparison rows. The grain observations above come from that report. The [load evidence](../evidence/p1-load-validation.md) contains the full comparison table. The [local archive checker](../tools/profile_hud_local.py) remains available for checking the source file itself.

**Execution progress, updated November 11.** The original P1 observations were recorded October 28. I have now supplied the following BigQuery result screenshots:

| Step | Observed result | UTC timestamp |
| --- | --- | --- |
| Raw verification, SQL 02 | 55,345 nationwide records; 1,144 Minnesota records and distinct nonblank IDs; zero missing Minnesota IDs; 80 fields and zero full-schema issues | 2026-11-11 21:36:49.162310 |
| Curated build, SQL 03 | 1,144 project records and distinct IDs; 1,143 valid-year records; one unknown/outside-year record; 1,141 valid-year unit-eligible records and two unit-excluded records | 2026-11-11 22:07:26.670323 |
| Acceptance, SQL 04 | PASS for Curated grain/relationships and PASS for year scope/eligible-unit meaning; the joins preserved 1,144 records | 2026-11-11 22:18:10.049263 |

These observations support the declared grain through the implemented Curated joins, not only in Raw. Detailed rules, results, and the field trace are in [P2](p2-build.md). The actual archive checksum is recorded. A separate CSV hash, exact acquisition date for the P2 run, job IDs, and byte counts remain unrecorded; I have not invented them.

## 2. Define the model and predict a history consequence

**Business process:** Reviewing where LIHTC project activity was reported and how that activity varies by placed-in-service year.

**Fact-table type:** A source-release snapshot fact. It represents the project records in a published source release, rather than individual housing transactions.

**Grain:** One row represents one Minnesota HUD project record, identified by `hud_id`, in one verified source release.

![Minnesota LIHTC model](model.svg)

The [model diagram](model.svg) shows one fact table and three dimensions. These Curated objects were built in P2 in `lucky-seis-732.HUD_LIHTC`. The diagram remains consistent with the implementation, so no model redesign was needed.

| Object | Key and main content |
| --- | --- |
| `fact_project_activity` | `activity_key`; unique `(release_key, hud_id)`; city, year, and release keys; `project_record_count = 1`; `units_eligible`; nullable `reported_total_units` and `reported_low_income_units`; service-year status and the original resyndication code |
| `dim_city` | `city_key`; state and normalized reported city label, with an unknown member |
| `dim_service_year` | `service_year_key`; year and decade. Key `0` holds unknown or outside-scope years |
| `dim_release` | `release_key`; archive checksum, source URL, selected member/sheet, acquisition date, coverage label, and transformation-rule version |

I keep `hud_id` as the source identifier. The release key is the reported actual archive SHA-256, which matches P0. P2 implements the activity key as a deterministic hash of the JSON-encoded release/ID pair, and the city key as a hash of the JSON-encoded state/normalized-city pair. Encoding the pairs avoids ambiguous concatenation. The year key uses the integer year, with `0` reserved for the unknown member. Each fact must join to exactly one member of each dimension; the P2 relationship check passed.

**My main modeling choice.** P2 retains all 1,144 Minnesota records. Unknown years and questionable units are flagged instead of silently removing the project record. A record with unusable units still contributes one project record, but both unit measures are NULL. To use its units, both values must parse successfully, total units must be positive, and low-income units must be between zero and total units. The instructor supported this distinction in the P1 feedback, and the P2 eligibility check passed.

**How the model answers my question.** I will select one release, filter Minnesota records to service years 1987–2024, and group them by reported city. The output will show project-record counts, eligible reported low-income units, and counts of records included or excluded from the unit measure. Grouping the same fact by service year answers the supporting question. The following analytical query illustrates that path through the Curated objects now built in P2. The persistent Serving output remains planned for P3:

```sql
SELECT
  c.normalized_city_label,
  SUM(f.project_record_count) AS reported_project_records,
  COUNTIF(f.units_eligible) AS unit_eligible_records,
  COUNTIF(NOT f.units_eligible) AS unit_excluded_records,
  SUM(f.reported_low_income_units) AS reported_low_income_units
FROM `lucky-seis-732.HUD_LIHTC.fact_project_activity` AS f
JOIN `lucky-seis-732.HUD_LIHTC.dim_city` AS c USING (city_key)
JOIN `lucky-seis-732.HUD_LIHTC.dim_service_year` AS y
  USING (service_year_key)
WHERE f.release_key =
  'e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288'
  AND c.state_code = 'MN'
  AND y.service_year BETWEEN 1987 AND 2024
GROUP BY c.normalized_city_label
ORDER BY reported_project_records DESC, c.normalized_city_label;
```

The checksum in the filter is the actual archive value reported in my recent query and used by the P2 build. It matches the P0 reference. This query is a model-to-question example; no city-ranking output from it is claimed in this note.

Service year is the analytical date role. Acquisition date records when the file was obtained. I will keep those meanings separate and will not substitute allocation year for service year. A year dimension fits the source's level of detail. Measures can be added across cities and service years within one release, but adding releases together would count recurring records again.

**How I will keep history.** HUD may correct a project's reported city in a later release. I will keep the earlier assignment fixed in its original release and store the correction in the new release. This preserves what each release reported. I chose this approach instead of a Type 1 overwrite or Type 2 effective dates that the source does not provide. The city dimension represents reported labels, not verified historical municipal boundaries.

**A small test for P3.** For a fictional project, assume 12 total units, 10 eligible low-income units, and service year 2010. Release A places it in `CITY A`; Release B corrects the label to `CITY B`.

| Contribution to the report | Release A | Release B |
| --- | --- | --- |
| CITY A | 1 project record; 10 low-income units | 0; 0 |
| CITY B | 0; 0 | 1 project record; 10 low-income units |
| Statewide | 1 project record; 10 low-income units | 1 project record; 10 low-income units |

By P3, I will implement or test this case and check that rerunning Release B leaves Release A unchanged. The example represents a reporting correction, not a physical move. If a second real release is unavailable, I will use a clearly labeled fictional change case.

## 3. Plan the build and its checks

The following layers carry the original P1 design forward. Raw and Curated are now implemented and checked in P2. Serving remains planned for P3.

| Layer | Full object name | Purpose and row meaning |
| --- | --- | --- |
| Raw | `lucky-seis-732.HUD_LIHTC.projects` | One imported HUD project record; preserve the all-state snapshot and its 80 STRING fields |
| Curated | `lucky-seis-732.HUD_LIHTC.dim_release` | One verified source release and its provenance |
| Curated | `lucky-seis-732.HUD_LIHTC.dim_city` | One normalized state/reported-city label, plus an unknown member |
| Curated | `lucky-seis-732.HUD_LIHTC.dim_service_year` | One analytical year, plus key `0` for unknown or outside-scope values |
| Curated | `lucky-seis-732.HUD_LIHTC.fact_project_activity` | One Minnesota project record per release, with typed measures and quality flags |
| Serving | `lucky-seis-732.HUD_LIHTC.serving_city_year_activity` | A view with one row per release, reported city, and valid service year; project counts, eligible unit sums, and unit-coverage counts |

**Build order:** Confirm the source and resources → load Raw → compare its fields and counts with the local profile → register the release and build dimensions → build and check the fact → create and check the Serving view → connect the dashboard.

Before replacing Raw with a later release, I will retain the earlier release's Curated facts and provenance. Rerunning the same snapshot should replace or upsert that release's facts, rather than append a second copy. The Serving view will expose the release key and label, and the dashboard will require one selected release. A view suits this small project because it reflects validated Curated data without a separate stored summary refresh. The [P2 build note](p2-build.md) now records the execution order and the observed results for SQL 02 → SQL 03 → SQL 04.

**Following one measure.** The path for low-income units is:

`li_units` in the workbook → Raw STRING → `SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC)` → compare with the similarly parsed `n_units` → populate both Curated unit measures only when the record is eligible → Serving `SUM(reported_low_income_units)` → dashboard label **Reported low-income units**.

If a group has no eligible unit records, its sum will stay NULL and appear as unavailable. I will not display it as zero. I will also keep `n_unitsr` and `li_unitr` separate rather than silently substituting them for the selected fields.

| Risk | My planned check and expected result | Where I will check it |
| --- | --- | --- |
| Repeated fact keys or a dimension join inflates project counts | Expect zero missing/repeated `(release_key, hud_id)` keys, duplicate dimension keys, and unmatched foreign keys. Dimension joins must leave the fact count and project-count sum unchanged. Expect 1,144 Minnesota facts for the pinned source before year filtering | Curated checks in P2; repeat after changes in P3 |
| Invalid units or inconsistent rules distort the city unit totals | Both unit measures must be NULL for every ineligible record. Eligible records must pass the unit rule. Reconcile Serving sums and eligible-record counts with an independent fact query using the same release/year filters; expect no differences. P2 measured the overlap: both unit-excluded records are in the valid-year cohort, leaving 1,141 eligible records for that unit measure | Curated and Serving checks in P2/P3 |
| Special year codes or mixed releases inflate the audience result | For the pinned input, expect 1,143 valid-year records and one record outside the reporting window. Reconcile city/year project totals with the eligible fact count for one release, and check that the dashboard selects exactly one release | Raw reconciliation, Serving checks, and dashboard review |

**Current check status.** P2 returned PASS for fact grain/relationships and for the Raw-to-Curated year and unit rules. The relationship check preserved 1,144 project records after the joins. Serving reconciliation, the dashboard's single-release filter, and the formal history/rerun tests remain for P3.

Even when those checks pass, repeated financing can still involve the same physical housing. I will preserve the resyndication code and keep unreported flags unknown. City normalization will initially trim spaces and standardize case. Combining different spellings will require evidence and a documented decision.

**Access and responsibility.** The traced unit count is publicly released project-level information and is low-risk for this aggregate output. The intended user is the Minnesota Housing analyst in my scenario. I am the project owner and steward. The dashboard will show aggregate counts and sums; street addresses and source identifiers are unnecessary for that output. I plan to keep Raw access with the course project team and instructor, and keep source extracts and credentials out of Git.

**Largest remaining limitation:** This source cannot reliably identify unique physical housing across financing rounds or measure current housing need. The product will provide a historical account of reported activity.

**P2 step now completed.** I recorded the archive checksum, registered the release, built the city/year dimensions and Minnesota fact, and ran the two acceptance checks. The results support continuing to P3.

**Next concrete step:** Build the release-specific city/year Serving view, reconcile it with Curated, and implement or test the bounded city-correction history case. The history consequence above remains a prediction to verify in P3.

## 4. Diagnose and revise the plan

**Response to instructor P1 feedback.** My instructor supported the way I defined the city totals: a project record may describe financing for existing housing, and an unusable unit value should not remove its project from the count. The feedback also supported my city-correction example because a later release can shift reported units between cities without changing the statewide total. The requested follow-up was to update this main plan with the completed Raw work and provide direct links to the diagram and comparison SQL.

| Feedback or decision | What I changed or retained |
| --- | --- |
| Reflect the completed Raw load and comparison | Updated the source and execution sections with the loaded table, matching profile, full-schema result, archive checksum, and actual verification time |
| Make the diagram and comparison code easy to find | Added direct links near the top of this plan to `model.svg`, `../sql/01_source_profile.sql`, and `../sql/02_ingest.sql` |
| Keep the documented meaning of city totals | Retained the reported-project-activity interpretation, all Minnesota project records, and separate unit eligibility |
| Preserve the release-history reasoning | Retained the source-release fact grain and the city-correction example; the actual history test remains for P3 |
| Show current build progress | Linked the P2 build note and added the Curated count and two observed PASS results, clearly dated after the original P1 plan |

**Main uncertainty.** Reported city labels may need careful reconciliation, and repeated financing still limits comparisons of physical housing stock. Passing the implemented checks does not resolve those interpretation limits.

**Changes made after P0 & P1 feedback.** I added an exact source record, a consistent cloud naming plan, and a comparison of the loaded table with the local profile. I also made the fact release-specific and kept the reported-activity interpretation throughout the model. These choices address my instructor's concerns about source consistency and counting existing housing more than once. The P1 feedback did not ask me to replace the grain, unit rules, or release-history design, so I kept those choices. No pipeline changes or new SQL executions were needed to make this documentation revision. The earlier reviewed commits remain part of the repository history.

**AI/tool note.** I used ChatGPT to help organize the plan, draft the SQL and local checker, and revise the wording. The figures come from the recorded P0 workbook profile.


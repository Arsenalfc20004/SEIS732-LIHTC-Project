# P1 Plan: Affordable Housing in Minnesota

My instructor has approved the HUD source with conditions. This plan builds on my P0 local profile. I still need to confirm the cloud resources, record the BigQuery load checks, and complete the M07 peer review. The tables and view described below are my proposed design.

## 1. Establish the question and check the source

I chose Minnesota to keep the project focused on one state and make the city comparisons manageable. My intended user is a Minnesota Housing program analyst reviewing the history of LIHTC project activity. The analyst could use the results to identify cities for closer review and prepare for planning discussions. This is an audience scenario for the course project; it does not represent a request or endorsement from Minnesota Housing.

**My main question:** Which Minnesota cities have the most reported LIHTC project records and reported low-income units for projects placed in service from 1987 through 2024?

**Supporting question:** How has the number of reported project records changed by placed-in-service year?

Each comparison will use one selected HUD release. I am studying the activity recorded in the database. These records alone cannot tell me how many unique new homes were created, how many units are vacant, or where current housing need is greatest.

**What changed after P0.** The source is now approved. I have narrowed the project to one main question and one supporting question. I have also chosen to keep each source release identifiable in the model. In response to my instructor's feedback, I will confirm the exact input, use consistent cloud names, and compare the loaded table with the local profile. P1 allows me to use the local grain check while the approved source is waiting to be loaded. Any deadline attached to the instructor's conditions still applies.

**The source I plan to use.** My P0 profile used HUD's [National LIHTC property-level database](https://www.huduser.gov/portal/datasets/lihtc/property.html), downloaded as [lihtcpub.zip](https://www.huduser.gov/lihtc/lihtcpub.zip). The source record identifies workbook `LIHTCPUB.xlsx`, worksheet `Data`, with 80 columns. Its recorded archive SHA-256 is:

```text
e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288
```

The dictionary is dated April 2026 and covers 1987–2024. HUD's page revision date, May 28, 2026, is recorded separately from the download date. The page lists a CSV, while the P0 archive profile recorded a workbook. I will check the actual archive before loading it and document a new profile if I use a different input.

One source row is a HUD project record in that release. The local P0 profile recorded 55,345 nationwide rows, including 1,144 Minnesota rows. Of the Minnesota records, 1,143 have service years in 1987–2024, and one uses the unknown-year code `9999`. Two records report more low-income units than total units. These are the local findings carried forward from P0.

| Source detail | My plan |
| --- | --- |
| BigQuery source/Raw table | `lucky-seis-732.HUD_LIHTC.projects`; load not yet confirmed |
| Cloud Storage input | `gs://lihtc-hud-data-seis732/projects.csv`; bucket availability and authorization still need confirmation |
| Location | `US` for the bucket, dataset, and jobs |
| Fields needed for the question | `hud_id`, `proj_st`, `proj_cty`, `yr_pis`, `n_units`, `li_units`, `resyndication_cd` |
| Raw field types | All 80 columns as STRING, preserving IDs and special codes |

The [P0 evidence](../evidence/p0-feasibility-results.md) contains the earlier findings. My [source confirmation](p1-source-confirmation.md) and [ingestion checklist](ingestion-checklist.md) describe the input and loading plan. If the authorized resource names differ, I will update them consistently before running the SQL.

**Checking the grain.** For one release, I expect trimmed, nonblank `hud_id` to identify one project record. If I retain several releases, the identifier becomes `(release_key, hud_id)`. I check all Minnesota records before applying year or unit rules, so those rules cannot hide duplicate IDs.

| Minnesota grain check | Expected | Observed in the P0 local profile |
| --- | ---: | ---: |
| Source records | 1,144 | 1,144 |
| Rows with a missing or blank `hud_id` | 0 | 0 |
| Distinct nonblank `hud_id` values | 1,144 | 1,144 |
| Repeated nonblank ID groups | 0 | 0 |
| Excess rows in repeated groups | 0 | 0 |

This result supports one project record per ID in this release. It does not establish that every ID refers to different physical housing. I will keep resyndication information and count reported project activity. If a later source has repeated IDs within a release, I will investigate their meaning before choosing a selection or aggregation rule.

The checks are reproducible using [BigQuery profiling SQL](../sql/01_source_profile.sql) or the [local archive checker](../tools/profile_hud_local.py). The table above reuses the P0 results. I will add the actual input verification and new local or BigQuery result beside it when those checks are completed.

**P1 execution record:** The source recheck and BigQuery grain result have not yet been recorded. A different archive will require a documented new baseline.

## 2. Define the model and predict a history consequence

**Business process:** Reviewing where LIHTC project activity was reported and how that activity varies by placed-in-service year.

**Fact-table type:** A source-release snapshot fact. It represents the project records in a published source release, rather than individual housing transactions.

**Grain:** One row represents one Minnesota HUD project record, identified by `hud_id`, in one verified source release.

![My proposed Minnesota LIHTC model](model.svg)

The [diagram](model.svg) shows one fact table and three dimensions. The planned objects use the `lucky-seis-732.HUD_LIHTC` dataset.

| Object | Key and main content |
| --- | --- |
| `fact_project_activity` | `activity_key`; unique `(release_key, hud_id)`; city, year, and release keys; `project_record_count = 1`; `units_eligible`; nullable `reported_total_units` and `reported_low_income_units`; service-year status and the original resyndication code |
| `dim_city` | `city_key`; state and normalized reported city label, with an unknown member |
| `dim_service_year` | `service_year_key`; year and decade. Key `0` holds unknown or outside-scope years |
| `dim_release` | `release_key`; archive checksum, source URL, selected member/sheet, acquisition date, coverage label, and transformation-rule version |

I will keep `hud_id` as the source identifier. The warehouse release key will be the verified archive SHA-256. The activity key will be a deterministic hash of the JSON-encoded release/ID pair, and the city key will be a hash of the JSON-encoded state/normalized-city pair. Encoding the pairs avoids ambiguous concatenation. The year key will use the integer year, with `0` reserved for the unknown member. Each fact must join to exactly one member of each dimension.

**My main modeling choice.** I will retain all 1,144 Minnesota records if the loaded source agrees with P0. Unknown years and questionable units will be flagged instead of silently removing the project record. A record with unusable units will still contribute one project record, but both unit measures will be NULL. To use its units, both values must parse successfully, total units must be positive, and low-income units must be between zero and total units.

**How the model answers my question.** I will select one release, filter Minnesota records to service years 1987–2024, and group them by reported city. The output will show project-record counts, eligible reported low-income units, and counts of records included or excluded from the unit measure. Grouping the same fact by service year answers the supporting question. This planned query will run after the Curated objects are built in P2:

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

I will use the following layers. P1 describes their design; their construction comes later.

| Layer | Planned full object name | Purpose and row meaning |
| --- | --- | --- |
| Raw | `lucky-seis-732.HUD_LIHTC.projects` | One imported HUD project record; preserve the all-state snapshot and its 80 STRING fields |
| Curated | `lucky-seis-732.HUD_LIHTC.dim_release` | One verified source release and its provenance |
| Curated | `lucky-seis-732.HUD_LIHTC.dim_city` | One normalized state/reported-city label, plus an unknown member |
| Curated | `lucky-seis-732.HUD_LIHTC.dim_service_year` | One analytical year, plus key `0` for unknown or outside-scope values |
| Curated | `lucky-seis-732.HUD_LIHTC.fact_project_activity` | One Minnesota project record per release, with typed measures and quality flags |
| Serving | `lucky-seis-732.HUD_LIHTC.serving_city_year_activity` | A view with one row per release, reported city, and valid service year; project counts, eligible unit sums, and unit-coverage counts |

**Build order:** Confirm the source and resources → load Raw → compare its fields and counts with the local profile → register the release and build dimensions → build and check the fact → create and check the Serving view → connect the dashboard.

Before replacing Raw with a later release, I will retain the earlier release's Curated facts and provenance. Rerunning the same snapshot should replace or upsert that release's facts, rather than append a second copy. The Serving view will expose the release key and label, and the dashboard will require one selected release. A view suits this small project because it reflects validated Curated data without a separate stored summary refresh. P2 will establish the final run order.

**Following one measure.** The path for low-income units is:

`li_units` in the workbook → Raw STRING → `SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC)` → compare with the similarly parsed `n_units` → populate both Curated unit measures only when the record is eligible → Serving `SUM(reported_low_income_units)` → dashboard label **Reported low-income units**.

If a group has no eligible unit records, its sum will stay NULL and appear as unavailable. I will not display it as zero. I will also keep `n_unitsr` and `li_unitr` separate rather than silently substituting them for the selected fields.

| Risk | My planned check and expected result | Where I will check it |
| --- | --- | --- |
| Repeated fact keys or a dimension join inflates project counts | Expect zero missing/repeated `(release_key, hud_id)` keys, duplicate dimension keys, and unmatched foreign keys. Dimension joins must leave the fact count and project-count sum unchanged. Expect 1,144 Minnesota facts for the pinned source before year filtering | Curated checks in P2; repeat after changes in P3 |
| Invalid units or inconsistent rules distort the city unit totals | Both unit measures must be NULL for every ineligible record. Eligible records must pass the unit rule. Reconcile Serving sums and eligible-record counts with an independent fact query using the same release/year filters; expect no differences. P0 has two inconsistent unit records overall, but their overlap with the valid-year cohort must be measured | Curated and Serving checks in P2/P3 |
| Special year codes or mixed releases inflate the audience result | For the pinned input, expect 1,143 valid-year records and one record outside the reporting window. Reconcile city/year project totals with the eligible fact count for one release, and check that the dashboard selects exactly one release | Raw reconciliation, Serving checks, and dashboard review |

Even if those checks pass, repeated financing can still involve the same physical housing. I will preserve the resyndication code and keep unreported flags unknown. City normalization will initially trim spaces and standardize case. Combining different spellings will require evidence and a documented decision.

**Access and responsibility.** The traced unit count is publicly released project-level information and is low-risk for this aggregate output. The intended user is the Minnesota Housing analyst in my scenario. I am the project owner and steward. The dashboard will show aggregate counts and sums; street addresses and source identifiers are unnecessary for that output. I plan to keep Raw access with the course project team and instructor, and keep source extracts and credentials out of Git.

**Largest remaining limitation:** This source cannot reliably identify unique physical housing across financing rounds or measure current housing need. The product will provide a historical account of reported activity.

**First P2 step:** If loading is still pending, confirm the actual archive and resource names, then load and reconcile Raw. After that, create `dim_release` and build the Minnesota fact at the checked grain, with the required dimension relationships.

## 4. Diagnose and revise the plan

Before M07, I will save this draft, diagram, and check code in my existing GitHub repository. I will bring the observed grain result and identify anything still unresolved about the source. New commits will record P1 progress while preserving the reviewed P0 version.

**Changes made after P0 feedback.** I added an exact source record, a consistent cloud naming plan, and a comparison of the loaded table with the local profile. I also made the fact release-specific and kept the reported-activity interpretation throughout the model. These choices address my instructor's concerns about source consistency and counting existing housing more than once.



**AI/tool note.** I used ChatGPT to help organize the plan, draft the SQL and local checker, and revise the wording. The figures come from the recorded P0 workbook profile. The checker was tested with fictional cases; those tests do not verify the actual HUD file. I will compare the checks on my selected input with the documented baseline and explain any differences. BigQuery results and peer feedback still need to be recorded. I am responsible for the model, code, interpretation, and claims in my submission.


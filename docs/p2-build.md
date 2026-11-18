**Execution status: Raw verification, Curated build, and both acceptance checks completed.** I ran SQL 02, SQL 03, and SQL 04 in BigQuery. Both acceptance checks returned PASS. The observations below are transcribed from my result; the archive checksum was reported separately. Serving and the formal rerun, changed-input, and history demonstrations remain for P3.

## 1. Establish the input and run ingestion

My intended user is a Minnesota Housing program analyst reviewing historical LIHTC activity. My primary question is: **Which Minnesota cities have the most reported LIHTC project records and reported low-income units for projects placed in service from 1987 through 2024?**

P2 builds the Raw-to-Curated path needed for that question. The city/year Serving view and dashboard remain for P3. I am retaining the [P1 model](p1-plan.md) and [diagram](model.svg), including the release-specific fact grain. I have not changed the source or counted project records as unique physical homes.

| Input or resource | My project record |
| --- | --- |
| Provider and source | HUD National LIHTC property-level database; [source page](https://www.huduser.gov/portal/datasets/lihtc/property.html) |
| Official archive | `https://www.huduser.gov/lihtc/lihtcpub.zip` |
| File identified in P0/P1 | `LIHTCPUB.xlsx`, worksheet `Data`; 80 fields; dictionary coverage 1987–2024 |
| Cloud Storage input | `gs://lihtc-hud-data-seis732/projects.csv` |
| Execution project | `lucky-seis-732` |
| BigQuery dataset | `HUD_LIHTC` |
| Raw table | `lucky-seis-732.HUD_LIHTC.projects` |
| Processing location | `US`, the dataset and specified processing location for these scripts |
| Curated subset | All records where `UPPER(TRIM(proj_st)) = 'MN'`; retain unknown years and invalid unit records with flags |
| Declared source selection | P0-matching HUD archive; `LIHTCPUB.xlsx`, worksheet `Data`, exported to the stated `projects.csv`. The source-confirmation flag was enabled for SQL 03 |
| Actual archive SHA-256 | `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288`; matches the P0 archive reference |
| Actual acquisition date | Not separately recorded for this P2 run; the checksum identifies the archive, and the verification/build/check times are recorded below |
| Feedback record | Instructor P1 feedback supported the project-count, unit-eligibility, and release-history choices. The requested progress update and direct diagram/SQL links are now included in the revised main P1 plan |

My instructor approved the external HUD source with conditions. I retained the source selection from P0/P1, reported an archive checksum matching P0, used consistent cloud names, and reconciled the loaded fields and counts with the local profile. The reported-activity interpretation is retained throughout the model. Source confirmation was declared when I enabled the SQL 03 guard; the SQL checks validate the loaded data rather than independently audit the manual workbook-to-CSV export. In the P1 feedback, the instructor asked for a documentation update rather than a change to the model or transformation rules. I updated the [main P1 plan](p1-plan.md) to reflect the completed Raw work and current build progress, with direct links to the model and comparison SQL. The grain and reported-activity interpretation remain unchanged.

**Source-to-Raw procedure.** I reuse the existing Raw table. To reproduce its load, select the `Data` sheet from the verified workbook and export a UTF-8 CSV with all 80 columns in their original order and one header row. Preserve text identifiers, blank values, and special year codes. Upload it to the stated Cloud Storage object. The optional recovery block in [02_ingest.sql](../sql/02_ingest.sql) defines all 80 fields as STRING and uses CSV format, UTF-8 encoding, one skipped header row, quoted newlines allowed, zero malformed records allowed, and `LOAD DATA OVERWRITE`. It replaces that designated Raw table rather than appending another copy. I do not reload a working table merely to create new evidence.

The active part of `02_ingest.sql` checks every Raw field name, position, and type, then returns input counts and a verification timestamp. One Raw row represents one HUD project record in the imported nationwide snapshot. Raw preserves the source codes and values before analytical typing or Minnesota filtering.

| Input observation | Previously reported in P1 | My current P2 result |
| --- | ---: | --- |
| Nationwide Raw records | 55,345 | 55,345 |
| Minnesota Raw records | 1,144 | 1,144 |
| Distinct nonblank Minnesota IDs | 1,144 | 1,144 |
| Missing Minnesota IDs | 0 | 0 |
| Declared fields / full schema issues | 80 fields; earlier checks confirmed STRING types | 80 / 0 |
| Last input verification, UTC | Earlier results recorded October 28, 2026 | 2026-11-11 21:36:49.162310 UTC |

**Observed Raw conclusion.** The nationwide and Minnesota counts agree with the previously reported P1 profile. All 1,144 Minnesota records have distinct nonblank IDs. The full schema check reports zero issues across 80 declared fields; SQL 02 compares their names, positions, and STRING types. This supports reusing Raw as the input to curation. The later SQL 04 checks verify the implemented Curated grain, relationships, and measure rules.

The HUD download URL and the uploaded object can change. Reproducing the identical input depends on retaining the original files outside Git and recording their identity. Matching counts alone do not prove byte-for-byte identity.

## 2. Build Curated at the intended grain

The implemented rules are in [03_curate.sql](../sql/03_curate.sql). **One fact row represents one Minnesota HUD project record in one verified source release.** The business key is `(release_key, hud_id)`, with whitespace trimmed from `hud_id`. The release key is the verified archive SHA-256. A deterministic hash of the release/ID pair becomes `activity_key`; the source ID remains available separately.

| Curated object | One row represents |
| --- | --- |
| `lucky-seis-732.HUD_LIHTC.fact_project_activity` | One Minnesota project record per verified release |
| `lucky-seis-732.HUD_LIHTC.dim_city` | One state/normalized reported-city label, including an unknown member |
| `lucky-seis-732.HUD_LIHTC.dim_service_year` | One service year from 1987–2024, plus key `0` for unknown or outside-scope years |
| `lucky-seis-732.HUD_LIHTC.dim_release` | One verified source archive and its provenance, rule version, and build timestamps |

I retain every Minnesota project record. Missing or repeated trimmed IDs stop the build; I do not remove them through arbitrary deduplication. P1 reported no such ID problems. This source therefore needs a uniqueness check rather than the latest-capture rule used in our Craigslist lab.

City labels are trimmed and converted to uppercase. A blank city maps to the unknown member, while differently spelled labels remain distinct. This supports transparent city comparisons without claiming that labels represent verified municipal boundaries.

Service years use `SAFE_CAST` to INT64. Years in 1987–2024 map to their year key. Codes `9999` and `8888`, missing or invalid years, and other outside-window years map to key `0`, with separate status labels. Their records remain in the fact for reconciliation. The eventual audience query will filter on the year dimension.

Unit fields use `SAFE_CAST` to NUMERIC. A record contributes units only when total units are positive and low-income units are nonnegative and do not exceed total units. Both Curated unit measures are NULL when that rule fails. The record still contributes `project_record_count = 1`. A genuine zero low-income-unit value is retained when it passes the rule. Blank or invalid numeric text remains distinguishable through `unit_status`. I preserve `resyndication_cd`, with a blank value left unknown, and do not substitute `n_unitsr` or `li_unitr` for the selected measures.

| Curated observation | Expected for the P1 input | My P2 result |
| --- | --- | --- |
| Fact records / distinct IDs | 1,144 / 1,144 | 1,144 / 1,144 |
| Valid-year records | 1,143 | 1,143 |
| Unknown or outside-year records | 1 | 1 |
| Unit-eligible / unit-excluded records, all years | Measure now; retain all project records | 1,142 eligible / 2 excluded |
| Unit-eligible / unit-excluded records, valid years | Measure the overlap; do not infer it by subtracting two from 1,143 | 1,141 eligible / 2 excluded |
| Build time and release key | Actual execution values | 2026-11-11 22:07:26.670323 UTC; release key `e07acee706174b276f89596d614ac5699efa9848659e5834fdfb5198fa0a7288` |

**Observed count explanation.** The nationwide-to-Curated difference is 54,201 records because the fact covers Minnesota rather than all states. Minnesota Raw and Curated both contain 1,144 records, with 1,144 distinct Curated HUD IDs. The build retained the one unknown/outside-year record for reconciliation. It classified 1,142 records as unit-eligible and two as unit-excluded across all years. Within the 1,143 valid-year records, 1,141 are unit-eligible and two are excluded, so both exclusions occur in the reporting-year cohort. These records remain in project counts. Check 1 passed with 1,144 records after the dimension joins and a project-count sum of 1,144. Check 2 passed the field-rule checks and the independent Raw-to-Curated count and unit-sum reconciliation.

**My field trace.** The source workbook's `li_units` becomes Raw `projects.li_units` as STRING. Curation parses it with `SAFE_CAST(NULLIF(TRIM(li_units), '') AS NUMERIC)` and evaluates it with the similarly parsed `n_units`. Only eligible records populate `fact_project_activity.reported_low_income_units`; otherwise both unit measures are NULL.

| Observed trace evidence | Result and source |
| --- | --- |
| Curated records within service years 1987–2024 | 1,143; SQL 03 build result |
| Valid-year records eligible to contribute unit measures | 1,141; SQL 03 build result |
| Valid-year records excluded from unit measures but retained in project counts | 2; SQL 03 build result |
| Independent Raw/Curated eligibility, mapping, and unit-sum reconciliation | PASS; SQL 04 Check 2 |

The count of 1,141 supplies the compact observed evidence for the field trace. Check 2 independently recomputed eligibility from Raw and required equality with the Curated counts and both unit sums. Its PASS result supports that reconciliation. The long JSON values were clipped in the supplied screenshot, so I have not transcribed an exact unit total that is not visible. **Planned audience step:** group one selected release by reported city and service year, then sum eligible reported low-income units alongside project and unit-coverage counts. A group with no eligible unit records will remain unavailable rather than being displayed as zero. This field is public project-level information; the intended output is aggregate, and source rows and credentials stay out of Git.

## 3. Run and interpret two acceptance checks

[04_acceptance.sql](../sql/04_acceptance.sql) evaluates the implemented fact and dimension relationships. The final result grid contains two acceptance rows and a `field_trace` JSON column with the compact measure-trace evidence. The trace is repeated on both rows; I only need to record it once. The checks do not create a persistent Serving object.

| Risk and affected result | Check code | Expected result and why | Observed result | Interpretation or action |
| --- | --- | --- | --- | --- |
| A repeated fact key, unmatched dimension key, or duplicate dimension row inflates or loses project records | [SQL 04, Check 1](../sql/04_acceptance.sql) | Minnesota Raw = Curated = joined row count = joined project-count sum; all key, relationship, and count-rule violations zero. Expected pinned-input count: 1,144 | **PASS**. Raw records: 1,144; Curated records: 1,144; records after joins: 1,144; joined project-count sum: 1,144 | The implemented joins preserved the project grain. The passing condition detected no missing/repeated keys, unmatched relationships, or project-count-rule violations |
| Invalid units, a wrong city assignment, or an incorrect year mapping changes the meaning of city/year comparisons | [SQL 04, Check 2](../sql/04_acceptance.sql) | Zero eligibility, measure, city, or year mapping errors. Independently calculated Raw and Curated eligible-record counts and unit sums must agree for the same 1987–2024 cohort | **PASS**. The displayed metrics show zero missing/unexpected IDs, eligibility-flag errors, unit-measure errors, service-year mapping errors, and city mapping errors. The passing condition also requires Raw/Curated count and unit-sum equality | The implemented year and unit rules support the intended reporting cohort. Invalid units remain outside both unit measures, while their project records remain available for project counts and reconciliation |

**Acceptance run time:** 2026-11-11 22:18:10.049263 UTC, shown on both result rows. **Material unresolved data issue:** None detected by these two implemented checks. Their scope is limited to the key, relationship, mapping, eligibility, and reconciliation conditions in SQL 04.

These checks concern reported project records and their analytical measures. They cannot establish unique physical housing across financing rounds, current affordability, vacancies, or unmet housing need.

## 4. Make the run reproducible and record the next step

The prerequisites are approved course resources, access to the named source and dataset, the verified original archive/CSV, and resolution of applicable source/P1 conditions. I use GoogleSQL and the US job location throughout.

| Order | Step and code | What it changes | Result I retain before continuing |
| --- | --- | --- | --- |
| 1 | Confirm the input file and archive checksum; record source/P1 conditions above | Documentation only | Exact archive/workbook/sheet, actual checksum, and acquisition date if known |
| 2 | Reuse Raw and run [02_ingest.sql](../sql/02_ingest.sql) | Active code reads Raw and makes only a temporary schema-check table. The separate optional recovery block replaces Raw if deliberately enabled | `P2_RAW_VERIFICATION` counts, schema result, and UTC time. Stop if the schema or expected input differs |
| 3 | Verify the recorded input and prefilled checksum in [03_curate.sql](../sql/03_curate.sql), then run the whole script; `v_source_confirmed = TRUE` records the declaration used for this build | Creates absent Curated tables; inserts missing city/year/release members; replaces facts only for the selected release within a transaction; updates that release's last-build time | `P2_CURATED_BUILD` counts, release key, and build time. Stop on a failed assertion or job |
| 4 | Run [04_acceptance.sql](../sql/04_acceptance.sql) | Reads permanent objects and creates temporary check tables | Both acceptance rows, their metrics, and the `field_trace` values; resolve REVIEW results and save the recheck |
| 5 | Complete this note, add the P2 README link, and commit | Repository files only | Commit URL containing the code and actual summarized results |

Each script must run as a whole because its temporary tables and variables are used by later statements. `04_acceptance.sql` selects the only registered release for this input URI; if more than one exists later, I must set an explicit release key. I will save these P2 result summaries before replacing Raw or testing another input. Earlier Curated releases are retained. P3 will provide the formal same-input rerun and changed-input evidence; repeatable code alone is not that demonstration.

The recorded sequence is SQL 02 → SQL 03 → SQL 04. The result timestamps follow that order, and each named result set is recorded above. SQL 02 reused Raw, SQL 03 built the release-specific Curated facts and dimensions, and SQL 04 returned the two acceptance results. The saved configuration includes the reported archive checksum and the source-confirmation flag used for the successful build. The earlier local parsing and fictional-case checks were preparation; my BigQuery screenshots provide the actual P2 execution evidence.

**Main limitation.** A HUD project record does not reliably distinguish unique physical units across repeated financing. My city comparisons will describe reported activity, with unit eligibility and coverage visible.

**First P3 step.** Build `lucky-seis-732.HUD_LIHTC.serving_city_year_activity` from the accepted Curated objects, selecting one release and valid service years. Then reconcile its counts and unit measures, demonstrate same-input and changed-input behavior, and test the release-history case from P1.

**AI/tool accountability.** I used ChatGPT to help adapt the P1 design into SQL, organize this note, and review the rules. I remain responsible for the source declaration, interpretation, and code.

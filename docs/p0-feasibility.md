
# P0 Feasibility Proposal: Affordable Housing in Minnesota
This proposal requests approval to use HUD's official download as an external source. Local source profiling is complete; instructor approval and the proposed BigQuery load are pending.

## 1. Working title
Affordable Housing in Minnesota: A Case Study Using HUD LIHTC Data

## 2. Audience and need
My intended user is a Minnesota Housing program analyst reviewing the history of affordable-housing projects supported by the Low-Income Housing Tax Credit (LIHTC) program. The analyst needs to compare where projects are located, how recorded project activity has changed over time, and how many reported units are classified as low-income.
A dashboard would put these comparisons in one place. The analyst could use it to select cities for closer review and explain the project history behind a planning discussion. This is a proposed audience scenario; no endorsement from Minnesota Housing is claimed.
The project will describe historical LIHTC records. It will not claim to measure current housing shortages, vacancies, or property risk, because those questions need additional evidence.

## 3. Proposed analytical product and questions
I plan to create a dashboard connected with city comparisons, a project-count trend, and a summary of reported units. Minnesota will be the case study, using records with placed-in-service years from 1987 through 2024.

The dashboard will answer:

1. Which Minnesota cities have the most recorded LIHTC projects and reported low-income units?
2. How has the number of recorded projects placed in service changed over time in Minnesota?
3. What share of reported project units is classified as low-income, and how does that share differ across Minnesota cities?
For the third question, both unit totals will use the same eligible project records. This share describes units in the LIHTC records, not all housing in a city. Reported project activity also does not establish the number of unique new physical units.

## 4. Source identification and access
The source is the HUD National Low-Income Housing Tax Credit Database, property-level data, provided by the U.S. Department of Housing and Urban Development.
- HUD source page (https://www.huduser.gov/portal/datasets/lihtc/property.html)
- Official download (https://www.huduser.gov/lihtc/lihtcpub.zip)
- Minnesota Housing program context (https://www.mnhousing.gov/home/rental-housing/housing-development-and-capital-programs/housing-tax-credits)

The official archive was downloaded and profiled. It is about 29.4 MB. The main file, LIHTCPUB.xlsx, contains a Data sheet with 80 columns. The observed archive includes Excel and Access files and a data dictionary dated April 2026. No CSV was included, so conversion is part of the ingestion plan. Only the main project workbook will be used; the separate building-address workbook has a different row meaning.
I could not find an accessible HUD LIHTC dataset in BigQuery Public Data from my course environment. The official download is accessible, so I am requesting approval for the external-source route before P1. HUD publishes the database for public access. No separate license file was included in the archive, so public availability is the use-rights evidence submitted for review. I will credit HUD and the release, and keep source rows and extracts out of Git.

After approval, the plan is to convert the workbook to UTF-8 CSV, upload it to an authorized Cloud Storage bucket, and load Lucky SEIS 732.seis732_lihtc.projects. The proposed bucket name is lihtc-hud-data-lucky; its availability and course permissions still need confirmation. The actual project, bucket, and region will be recorded after setup.

The raw schema will preserve all 80 source columns as STRING, including IDs and special year codes. Numeric fields will be converted for analysis. The scripts, schema, and ingestion checklist are included in the repository. These cloud objects are proposed, not already created.

## 5. Quick source profile   
The results below come from local profiling of the official workbook. They are not BigQuery query results. The source has ~55,345 records nationwide, including ~1,144 in Minnesota.
Minnesota check	Observed result
Project records	~1,144
Distinct nonblank hud_id values	~1,144
Missing IDs / duplicate-ID groups	0 / 0
Records with service years from 1987 through 2024	~1,143
Missing total / low-income unit counts	0 / 0
Low-income units greater than total units	2
Blank city labels	0
City labels after trimming and uppercasing 266 distinct labels

One row represents a HUD project record in this downloaded release. `hud_id` is unique in the file, but that does not establish unique physical properties across financing rounds. Multiple snapshots would need a release-plus-project-ID key.

Minnesota's usable service years span 1987-2024. One record uses `yr_pis = 9999`, indicating confirmed placed-in-service status with a missing year. That code will be preserved and excluded from the initial trend analysis. The raw field is a year, not a full transaction date.

The main fields are `hud_id`, `proj_st`, `proj_cty`, `yr_pis`, `n_units`, `li_units`, `fips2020`, and `resyndication_cd`. City spelling and postal-city meanings need review. There are 174 Minnesota tract codes containing `X` placeholders. Thirty-four records are flagged as resyndicated, while 681 have an unreported flag; a blank flag will not be treated as "No."

HUD updates the database and can revise earlier records. The initial product uses one snapshot, with a later course change case if needed. The selected source describes projects rather than individual tenants, and the dashboard will show aggregate results.

The source provenance and local results are documented in `evidence/p0-feasibility-results.md`. After approval and loading, I will run `sql/00_feasibility.sql`, check estimated bytes before each query, and compare the imported counts with the local profile.

## 6. Need-to-source fit

| Proposed question | Needed fields or concepts | Candidate source object | Why the source appears sufficient | Gap or assumption to test in P1 |
| --- | --- | --- | --- | --- |
| Cities with the most recorded projects and low-income units | State, city, project ID, valid service year, low-income units | `LIHTCPUB.xlsx`, `Data` | Minnesota has 1,144 records with complete IDs and city labels | Standardize cities and decide how repeated financing affects unit totals |
| Recorded project counts over time | State, project ID, service year | Same main sheet | 1,143 Minnesota records have usable years from 1987 through 2024 | Choose year or decade views and keep unknown years separate |
| Low-income share of reported project units by city | City, total units, low-income units | Same main sheet | Both unit fields are populated for Minnesota records | Use matching eligible records and resolve the two inconsistent unit records |

## 7. Feasibility risks and response

1. **External-source approval and loading.** The official file is accessible and locally profiled, but an accessible public BigQuery dataset was not found in the course environment. I will submit the source and ingestion plan for approval before P1, then reconcile the loaded schema and counts.
2. **Repeated physical units.** Unique project IDs do not guarantee unique physical properties across financing rounds. I will preserve the resyndication flag and describe sums as reported project activity. I will resolve the counting policy before presenting unit totals.
3. **Data quality and interpretation.** Minnesota has one unknown service year and two inconsistent unit records. City names also need review. I will separate unknown years, flag inconsistent units, standardize city labels, and use the same records for both parts of a unit-share calculation.

**Fallback:** If unit measures cannot be used reliably, I will narrow the dashboard to project-record counts by Minnesota city and service year using the same source. If the external source is not approved, I will select an accessible public BigQuery source and verify its fit before P1.

## 8. First P1 decision

My first decision will be how repeated financing rounds should affect unit counts. The starting grain is one HUD project record per downloaded release. I need to decide whether unit measures describe all recorded activity or a clearly defined subset, and explain that choice before reporting totals.

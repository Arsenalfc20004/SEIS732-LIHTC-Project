P0 Feasibility Proposal: Affordable Housing in Minnesota
This proposal requests approval to use HUD's official download as an external source. Local source profiling is complete; instructor approval and the proposed BigQuery load are pending.
1. Working title
Affordable Housing in Minnesota: A Case Study Using HUD LIHTC Data
2. Audience and need
My intended user is a Minnesota Housing program analyst reviewing the history of affordable-housing projects supported by the Low-Income Housing Tax Credit (LIHTC) program. The analyst needs to compare where projects are located, how recorded project activity has changed over time, and how many reported units are classified as low-income.
A dashboard would put these comparisons in one place. The analyst could use it to select cities for closer review and explain the project history behind a planning discussion. This is a proposed audience scenario; no endorsement from Minnesota Housing is claimed.
The project will describe historical LIHTC records. It will not claim to measure current housing shortages, vacancies, or property risk, because those questions need additional evidence.
3. Proposed analytical product and questions
I plan to create a dashboard connected with city comparisons, a project-count trend, and a summary of reported units. Minnesota will be the case study, using records with placed-in-service years from 1987 through 2024.
The dashboard will answer:
1. Which Minnesota cities have the most recorded LIHTC projects and reported low-income units?
2. How has the number of recorded projects placed in service changed over time in Minnesota?
3. What share of reported project units is classified as low-income, and how does that share differ across Minnesota cities?
For the third question, both unit totals will use the same eligible project records. This share describes units in the LIHTC records, not all housing in a city. Reported project activity also does not establish the number of unique new physical units.
4. Source identification and access
The source is the HUD National Low-Income Housing Tax Credit Database, property-level data, provided by the U.S. Department of Housing and Urban Development.
- HUD source page
- Official download
- Minnesota Housing program context
The official archive was downloaded and profiled. It is about 29.4 MB. The main file, LIHTCPUB.xlsx, contains a Data sheet with 80 columns. The observed archive includes Excel and Access files and a data dictionary dated April 2026. No CSV was included, so conversion is part of the ingestion plan. Only the main project workbook will be used; the separate building-address workbook has a different row meaning.
I could not find an accessible HUD LIHTC dataset in BigQuery Public Data from my course environment. The official download is accessible, so I am requesting approval for the external-source route before P1. HUD publishes the database for public access. No separate license file was included in the archive, so public availability is the use-rights evidence submitted for review. I will credit HUD and the release, and keep source rows and extracts out of Git.
After approval, the plan is to convert the workbook to UTF-8 CSV, upload it to an authorized Cloud Storage bucket, and load Lucky SEIS 732.seis732_lihtc.projects. The proposed bucket name is lihtc-hud-data-lucky; its availability and course permissions still need confirmation. The actual project, bucket, and region will be recorded after setup.
The raw schema will preserve all 80 source columns as STRING, including IDs and special year codes. Numeric fields will be converted for analysis. The scripts, schema, and ingestion checklist are included in the repository. These cloud objects are proposed, not already created.
5. Quick source profile
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

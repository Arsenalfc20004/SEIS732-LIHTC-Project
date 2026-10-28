# Affordable Housing in Minnesota

This is my SEIS 732 individual data-product project for P0-P4. I am using Minnesota as a case study to explore the history and geographic distribution of affordable-housing projects in HUD's Low-Income Housing Tax Credit (LIHTC) database.

My intended user is a Minnesota Housing program analyst reviewing where LIHTC projects are located, how recorded project activity has changed over time, and how reported low-income units are distributed. I plan to build a BigQuery model and a Looker Studio dashboard for that historical review.

## Current stage: P0 feasibility

The official HUD workbook was profiled locally. It contains 55,345 project records nationwide, including 1,144 in Minnesota. The proposal and evidence summarize the source checks, limitations, and next modeling decision.

I could not find an accessible HUD LIHTC dataset in BigQuery Public Data from my course environment. I am requesting approval to use HUD's official download as an external source. The Cloud Storage upload and BigQuery load are planned after that approval.

## Planned cloud destination

My proposed raw table is `SEIS-HUD_LIHTC.Projects`, with the CSV at `gs://lihtc-hud-data-seis732/projects.csv`. I plan to use the `US` multi-region for the bucket and dataset. These names and the location remain subject to course authorization and availability. I will update them consistently if the approved resources differ.

## Project files

| File | Purpose |
| --- | --- |
| [P0 feasibility proposal](docs/p0-feasibility.md) | Audience, questions, source fit, evidence, risks, and first P1 decision |
| [Ingestion checklist](docs/ingestion-checklist.md) | Proposed download, conversion, Cloud Storage, and BigQuery loading process |
| [Feasibility SQL](sql/00_feasibility.sql) | Reproducible schema, count, key, year, geography, and unit checks after loading |
| [Feasibility results](evidence/p0-feasibility-results.md) | Compact local source evidence and the status of cloud validation |
| [External-source request](docs/external-source-request.md) | Request for instructor approval before P1 |

The root `.gitignore` excludes downloaded data, extracts, local settings, and credentials. Keep source rows and the HUD workbook outside Git; submit code and aggregate evidence.

## Submission

These seven repository files are the P0 submission package.


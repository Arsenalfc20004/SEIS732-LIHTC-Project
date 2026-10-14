# Affordable Housing in Minnesota

This repository contains my SEIS 732 individual data-product project for P0-P4. I am using Minnesota as a case study to explore the history of affordable-housing projects in the U.S. Department of Housing and Urban Development (HUD) Low-Income Housing Tax Credit (LIHTC) database.

My intended user is a Minnesota Housing program analyst reviewing where LIHTC projects are located, how recorded project activity has changed, and how reported low-income units are distributed. I plan to build a BigQuery model and a dashboard to support that historical review.

## Current scope: P0 feasibility

The official HUD workbook contains 55,345 project records nationwide, including 1,144 in Minnesota. The initial profile was completed locally using the supplied script. The BigQuery load will follow instructor approval.

I could not find an accessible HUD LIHTC dataset in BigQuery Public Data from my course environment, so I am requesting approval to use HUD's official download as an external source. After approval, the proposed process is to convert the main workbook to CSV, upload it to Cloud Storage, and load it into BigQuery.

The package also includes supporting scripts, the raw schema, and the aggregate profile JSON for reproducibility.

## P0 files

- [Feasibility proposal](docs/p0-feasibility.md)
- [Ingestion checklist](docs/ingestion-checklist.md)
- [Feasibility SQL](sql/00_feasibility.sql)
- [Summarized evidence](evidence/p0-feasibility-results.md)
- [External-source request](docs/hud-source-approval-request.md)

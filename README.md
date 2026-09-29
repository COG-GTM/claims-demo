[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.5.x&color=orange)

# The Tuva Project Demo

This is a dbt project that loads a 1,000 patient synthetic claims and clinical dataset and runs the Tuva package.  When you run the project it loads the synthetic data to your warehouse and transforms it into the Tuva data model.

## 🔌 Database Support

The project officially supports the following data warehouses:
- BigQuery
- Databricks 
- DuckDB (community supported)
- Redshift
- Snowflake
- Microsoft Fabric

## ✅ How to get started

### Pre-requisites
1. You have [dbt](https://www.getdbt.com/) installed and configured (i.e. connected to your data warehouse). If you have not installed dbt, [here](https://docs.getdbt.com/docs/get-started-dbt) are instructions for doing so.
2. You have created a database for the output of this project to be written in your data warehouse.

### Getting Started
Complete the following steps to configure the project to run in your environment.

1. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) this repo to your local machine or environment.
2. Update the `dbt_project.yml` file i.e. add the dbt profile connected to your data warehouse.
3. Run `dbt deps` to install the Tuva Project package. 
4. Run `dbt build` to run the entire project with the built-in sample data.

## Eligibility data quality

`models/eligibility_data_quality/` flags member eligibility spans that overlap or leave gaps within the same `person_id` / `member_id` / `payer` / `plan` / `data_source`:

- `eligibility_dq__span_issues`: one row per overlapping or gapped span.
- `eligibility_dq__summary`: one row per check with flagged counts and a `pass` / `warn` / `error` status; feeds the `eligibility_data_quality_scorecard` exposure.
- `tests/eligibility_data_quality/`: overlaps fail the build (`error`); gaps longer than `eligibility_gap_tolerance_days` (default 45) warn.

Run just these checks with `dbt build --select tag:eligibility_data_quality`.

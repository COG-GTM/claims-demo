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
## Eligibility / member-months mart

`models/eligibility_mart/` builds a member-months and eligibility summary mart directly from the `eligibility` seed (schema `eligibility_mart`):

- `eligibility_mart__enrollment_spans` – cleaned spans with overlapping, duplicate and contiguous spans merged per person / payer / plan.
- `eligibility_mart__member_months` – one row per person / payer / plan / month with any coverage, with covered days and a pro-rated fraction for partial months.
- `eligibility_mart__eligibility_summary` – one row per person / payer / plan with span, gap and member-month totals.

Assumptions are documented in `models/eligibility_mart/eligibility_mart.md` (rendered in dbt docs). Build it with `dbt build -s tag:eligibility_mart`.

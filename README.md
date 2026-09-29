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
## 🩺 Risk adjustment member months

`models/risk_adjustment` adds an HCC-style member-month model on top of Tuva's `core.member_months` and `core.condition`:

- `risk_adjustment__condition_category_map` – illustrative HCC-like condition categories keyed by ICD-10-CM prefix, with hierarchy groups and relative factors (defined in `macros/risk_adjustment/risk_adjustment_condition_categories.sql`; loosely modeled on CMS-HCC V24, not an official mapping).
- `risk_adjustment__member_month_conditions` – one row per member month and condition category, attached when a matching diagnosis was recorded within the trailing `risk_adjustment_lookback_months` (default 12) months, after hierarchies are applied.
- `risk_adjustment__member_month_risk` – one row per member month with a 0/1 flag per category, a category count, and a summed condition risk score.

Run it and its tests with `dbt build --select +risk_adjustment__member_month_risk`, or just the unit tests with `dbt test --select test_type:unit,tag:risk_adjustment`.

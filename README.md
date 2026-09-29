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
## 📊 Demo Marts

In addition to the Tuva Project data marts, this project builds the following demo-specific marts into the `demo_marts` schema.

### `chronic_conditions_prevalence`

Annual chronic condition prevalence for the enrolled claims population, built on the Tuva chronic conditions grouper (`chronic_conditions__tuva_chronic_conditions_long`) and member months (`core__member_months`).

- **Grain:** one row per `prevalence_year` and `condition` (zero-filled for conditions with no cases in a year).
- **Denominator:** `eligible_members` — distinct members with at least one member month in the year.
- **Numerator:** `members_with_condition` — enrolled members whose first diagnosis for the condition is on or before the end of the year. Chronic conditions are treated as persistent once diagnosed.
- **Also includes:** `newly_diagnosed_members` (first diagnosis in the year), `prevalence_rate`, `prevalence_per_1000`, and `prevalence_rank` within the year.

Build and test it (along with its upstream dependencies) with:

```
dbt build --select +chronic_conditions_prevalence
```

Tests include column-level generic tests, a dbt unit test covering the carry-forward/incidence logic, and singular tests in `tests/` that reconcile the mart to member months and the condition grouper. Full model and column documentation is available via `dbt docs generate`.

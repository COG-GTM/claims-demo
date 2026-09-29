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
## 🩺 Demo models

### `int_chronic_conditions`
[`models/intermediate/int_chronic_conditions.sql`](models/intermediate/int_chronic_conditions.sql) builds one row per member per chronic condition by matching ICD-10-CM diagnoses in `core__condition` against the Tuva chronic condition grouper (`chronic_conditions__tuva_chronic_conditions_hierarchy`). A member qualifies for a condition when they have a dated ICD-10-CM diagnosis whose code is listed for that condition, on at least `chronic_conditions_min_diagnosis_dates` distinct dates (default `1`).

The full qualification rules, including the code categories behind each of the 41 conditions, are documented in [`models/intermediate/int_chronic_conditions.md`](models/intermediate/int_chronic_conditions.md) and render in `dbt docs`. Run the model and its tests with:

```
dbt build --select int_chronic_conditions
```

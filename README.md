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
## 🚑 ED Utilization Mart

This project adds an emergency department utilization mart on top of the Tuva
core data model (`models/ed_utilization`):

| Model | Schema.table | Grain |
|---|---|---|
| `ed_utilization__member_month_visits` | `ed_utilization.member_month_visits` | one row per `core.member_months` row, with ED visits that started that month |
| `ed_utilization__visits_per_1000` | `ed_utilization.visits_per_1000` | month x payer x plan x data source, with `member_months`, `ed_visits`, `ed_visits_per_1000_member_months` |

- **Numerator:** `core.encounter` rows with `encounter_type = 'emergency department'`, by month of `encounter_start_date`.
- **Denominator:** `core.member_months`. ED visits in unenrolled months are excluded.
- **Rate:** `ed_visits * 1000 / member_months`. To roll up (e.g. to year or payer), sum `ed_visits` and `member_months` first, then recompute the rate.

Build and test just this mart (and its upstream Tuva models) with:

```
dbt build --select +ed_utilization__visits_per_1000 tag:ed_utilization
```

Tests include column tests, dbt unit tests for attribution and rate logic, and
singular reconciliation tests against `core.member_months` and `core.encounter`
(`tests/ed_utilization`). Full definitions are in the dbt docs for the models.

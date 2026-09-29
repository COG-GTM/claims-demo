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

## 🏥 Inpatient Length of Stay & Cost Mart

`models/inpatient_los` adds an inpatient length-of-stay (LOS) and cost mart with
outlier flagging on top of Tuva `core.encounter` (`encounter_type = 'acute inpatient'`):

| Model | Schema.table | Grain |
|---|---|---|
| `inpatient_los__encounters` | `inpatient_los.encounters` | one row per acute inpatient encounter, with LOS, DRG peer group and paid / allowed / charge amounts |
| `inpatient_los__peer_group_stats` | `inpatient_los.peer_group_stats` | peer group (DRG or all acute inpatient) x metric (`length_of_stay`, `paid_amount`), with nearest-rank quartiles and Tukey fences |
| `inpatient_los__encounter_outliers` | `inpatient_los.encounter_outliers` | one row per encounter, with the peer group and fences used and LOS / cost high and low outlier flags |
| `inpatient_los__drg_summary` | `inpatient_los.drg_summary` | one row per DRG, with ALOS and average paid (with and without high outliers) and outlier counts |

- **Outlier rule:** a value is a high outlier when `> Q3 + k * IQR` and a low outlier when `< Q1 - k * IQR` (strict), with `k = var('inpatient_los_outlier_iqr_multiplier', 1.5)`.
- **Peer groups:** each encounter is compared with its DRG when that DRG has at least `var('inpatient_los_min_peer_group_size', 10)` encounters, otherwise with all acute inpatient encounters. LOS and cost (`paid_amount`) are evaluated independently.

Build and test just this mart (and its upstream Tuva models) with:

```
dbt build --select +inpatient_los__drg_summary tag:inpatient_los
```

Tests include dbt unit tests for the quartile / fence and outlier-flag logic,
column tests, and singular tests (`tests/inpatient_los`) that check every flag
against its fence and reconcile counts and paid amounts back to `core.encounter`.

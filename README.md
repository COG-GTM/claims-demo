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
## 🔁 Readmissions mart

`models/readmissions_mart/` adds a demo readmissions mart on top of the Tuva `readmissions` data mart. It applies the Tuva / CMS Hospital-Wide Readmission index-admission logic with one explicit flag per exclusion rule, then flags 30-day all-cause and unplanned readmissions for every index admission.

| model | grain |
| --- | --- |
| `readmissions_mart__encounter` | acute inpatient encounter, with `exclusion_*_flag` columns and `index_exclusion_reason` |
| `readmissions_mart__index_admission` | index admission, with `readmit_30_flag`, `unplanned_readmit_30_flag`, `days_to_readmit` |
| `readmissions_mart__monthly_summary` | index discharge month, with `unplanned_readmit_30_rate` |
| `readmissions_mart__exclusion_summary` | index status / exclusion reason, with encounter counts |

### Index admission exclusion rules

An acute inpatient encounter is an index admission only if none of these apply. `index_exclusion_reason` reports the first match in this order:

1. **Data quality** – Tuva `disqualified_encounter_flag = 1` (missing/invalid dates, discharge disposition, primary diagnosis, CCS category or DRG, or overlapping encounters). These encounters also cannot count as readmissions.
2. **Died during admission** – discharge disposition `20`.
3. **Left against medical advice** – discharge disposition `07`.
4. **Transferred to another acute care hospital** – discharge disposition `02`.
5. **Excluded diagnosis category** – primary-diagnosis CCS category is medical treatment of cancer, rehabilitation, or psychiatric (Tuva `readmissions__exclusion_ccs_diagnosis_category` value set).
6. **Insufficient 30-day lookforward** – discharged less than 30 days before the latest discharge date in the data.

A **30-day readmission** is the patient's next non-disqualified acute inpatient admission starting 0–30 days (inclusive) after the index discharge; an admission that starts before the index discharge is treated as an overlap, not a readmission. It is **unplanned** when Tuva's CMS planned-readmission algorithm sets `planned_flag = 0` on the readmission.

Run it with `dbt build --select +tag:readmissions_mart`. Tests include dbt unit tests for each exclusion rule and the 30-day window, and singular tests in `tests/readmissions_mart/` that reconcile the mart with Tuva's own `index_admission_flag` and readmission counts.

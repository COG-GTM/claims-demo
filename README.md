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

## 📊 Risk Adjustment Summary Mart

In addition to the Tuva package outputs, this demo builds a small HCC-style
risk adjustment mart in the `risk_adjustment` schema (`models/risk_adjustment`):

| Model | Grain |
| --- | --- |
| `risk_adjustment__member_year_summary` | person, payer, calendar year (every enrolled member year, including zero-HCC years) |
| `risk_adjustment__member_year_hccs` | person, payer, calendar year, post-hierarchy HCC |
| `risk_adjustment__int_member_years` | person, payer, calendar year enrollment spine |

It maps `core.condition` ICD-10-CM codes to CMS-HCCs, applies the CMS
hierarchy per member year, and sums a reference coefficient into a
`raw_disease_score`. It is a population-analytics rollup, **not** a CMS RAF;
the full assumptions are documented in `models/risk_adjustment/risk_adjustment.md`
and in the dbt docs site.

Optional vars:

```yaml
vars:
  risk_adjustment_model_version: CMS-HCC-V28   # or CMS-HCC-V24
  risk_adjustment_mapping_year: 2026           # defaults to latest crosswalk year
```

Once the Tuva core models exist, build and test only this mart with
`dbt build --select tag:risk_adjustment`.

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

## 🌱 Synthetic seed data versions

The CSVs in `seeds/` are header/schema templates only. On `dbt seed`/`dbt build` each
seed's `+post-hook` calls `the_tuva_project.load_seed()`, which loads the real rows from
a versioned folder in the public bucket
`s3://tuva-public-resources/versioned_tuva_synthetic_data/`.

Two vars in `dbt_project.yml` control the pins:

| Var | Value | Applies to |
| --- | --- | --- |
| `tuva_synthetic_data_version` | `0.15.0` | appointment, immunization, lab_result, medical_claim, observation, pharmacy_claim, provider_attribution |
| `tuva_synthetic_data_eligibility_version` | `0.16.0` | eligibility |

Rationale:

- Published folders are `0.9.0`, `0.10.0`, `0.12.0`–`0.16.0`, and `0.16.1`. Only
  `0.15.0` and earlier contain the full set of seed files; `0.16.0` and `0.16.1`
  contain `eligibility.csv` alone. The split pin is therefore required, not accidental —
  every non-eligibility seed must stay on `0.15.0` until a later folder republishes them.
- `eligibility` is pinned to `0.16.0` because that file adds the `hospice_flag`,
  `institutional_snp_flag`, `long_term_institutional_flag`, and `enrollment_status`
  columns required by `the_tuva_project` >= 0.16.
- `eligibility` is intentionally **not** moved to `0.16.1`. `load_seed` loads CSVs
  **positionally** on every warehouse (Databricks maps `_c0..._cN` onto the seed table's
  columns; Snowflake/Redshift/Fabric `COPY INTO` and BigQuery `LOAD DATA` are likewise
  ordinal). `0.16.1` reorders the trailing columns to
  `...,enrollment_status,hospice_flag,institutional_snp_flag,long_term_institutional_flag`,
  which no longer matches the header of `seeds/eligibility.csv`, so those four columns
  would be silently loaded into the wrong fields (and the integer flags would fail to
  cast). Moving to `0.16.1` requires reordering `seeds/eligibility.csv` and the
  `column_types` block in `seeds/_seeds.yml` in the same commit.

To test a different data drop without editing the project, override at run time:

```bash
dbt build --vars '{tuva_synthetic_data_eligibility_version: 0.16.1}'
```
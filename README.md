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

### `marts.claims_by_provider`
One row per provider NPI with total spend, claim counts, and distinct member counts, built directly from the demo `medical_claim` and `pharmacy_claim` input-layer seeds.

| Column | Definition |
| --- | --- |
| `provider_npi` | Medical: `rendering_npi`, falling back to `billing_npi`. Pharmacy: `prescribing_provider_npi`. |
| `total_paid_amount` / `total_allowed_amount` | Sum of line-level `paid_amount` / `allowed_amount`. |
| `medical_paid_amount` / `pharmacy_paid_amount` | Paid amount split by claim source. |
| `claim_count` | Distinct medical `claim_id`s + distinct pharmacy `claim_id`s (claim level, not line level). |
| `medical_claim_count` / `pharmacy_claim_count` | Distinct claims by source. |
| `distinct_member_count` | Distinct `person_id`s across both sources. |

Claim lines with no attributable NPI are excluded. In the bundled synthetic data, pharmacy claims have no prescribing or dispensing NPI, so pharmacy spend is not attributed to any provider.

Build and test just this mart with:
```
dbt build --select +claims_by_provider assert_claims_by_provider_reconciles_to_source
```

Tests include column-level `not_null`/`unique`/range checks, a dbt unit test covering the aggregation logic, and a singular test (`tests/assert_claims_by_provider_reconciles_to_source.sql`) that reconciles mart spend back to the source claim lines.

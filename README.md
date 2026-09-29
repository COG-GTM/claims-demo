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

## 🏥 Provider-Network Leakage Mart

A small mart on top of Tuva `core__medical_claim` and `core__patient` showing in- versus out-of-network medical spend by member cohort (built in the `network_leakage` schema, tagged `network_leakage`):

| Model | Grain | Purpose |
|---|---|---|
| `network_leakage__claim_line` (view) | medical claim line | Maps `in_network_flag` to `in_network` / `out_of_network` / `unknown` and attaches cohort attributes evaluated at the service date: service year, payer, plan, age band, sex. |
| `network_leakage__member_cohort_summary` | service year × payer × plan × age band × sex | Members, members with any out-of-network use, claim lines, in / out / unknown paid and allowed, leakage rate (paid and allowed), unknown-network share, and out-of-network paid per member. |

Run it with:

```bash
dbt build --select +network_leakage__member_cohort_summary
```

Tests: schema and unit tests live in `models/network_leakage/`; reconciliation tests (mart totals tie back to `core__medical_claim`, in + out + unknown = total per cohort) live in `tests/network_leakage/`.

Notes:
- `leakage_rate_paid = out_of_network_paid / (in_network_paid + out_of_network_paid)`. Lines with a null `in_network_flag` are excluded from the rate and reported via `unknown_network_paid_share` instead of being assumed in-network.
- Age bands (`0-17`, `18-44`, `45-64`, `65-74`, `75-84`, `85+`) use age at service (days / 365.25), not Tuva's `core__patient.age_group`, which is as of the dbt run date.
- Medical claims only; pharmacy claims are out of scope. Null paid / allowed amounts are treated as 0.
- The bundled synthetic `medical_claim` data has `in_network_flag = 1` on every line, so the demo build shows 0% leakage; the out-of-network and unknown paths are exercised by the unit tests.

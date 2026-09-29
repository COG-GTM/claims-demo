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
## ⏩ Incremental materialization

The three largest input-layer models (by row count in the demo data) are overridden in this project and materialized as `incremental` instead of the Tuva package's default views. The package versions are disabled in `dbt_project.yml`, following the same pattern as `input_layer__provider_attribution`.

| Model | Source rows (demo) | Partition column | Unique key |
|---|---|---|---|
| `input_layer__medical_claim` | ~168k | `claim_end_date` | `claim_id`, `claim_line_number`, `data_source` |
| `input_layer__observation` | ~150k | `observation_date` | `observation_id` |
| `input_layer__lab_result` | ~79k | `result_datetime` (by date) | `lab_result_id` |

### Partitioning strategy

- **Partition key:** each model is partitioned on the event date the rows naturally arrive by. For medical claims this is `claim_end_date`, which is closer to when a claim is adjudicated and delivered than `claim_start_date`. The unique key is the grain enforced by the Tuva input-layer tests, so a row that changes date is replaced rather than duplicated.
- **Incremental window:** on an incremental run the model re-selects every source row whose partition date is on or after `max(partition date already loaded) - incremental_lookback_days` (default `90`, set in `dbt_project.yml`, overridable with `--vars`). Rows in that window are replaced by unique key, which picks up newly arrived rows and late corrections (adjustments, re-sent files) without rescanning older history. The filter lives in `macros/incremental_partition.sql` (`incremental_lookback_filter`).
- **Strategy by warehouse:** `delete+insert` on DuckDB, Snowflake, Redshift, and Fabric; `merge` on BigQuery and Databricks (`incremental_strategy` macro). The target is physically partitioned by month on BigQuery (`partition_by`) and clustered on the partition column on Snowflake (`cluster_by`).
- **Limitations:** changes to rows older than the lookback window and rows deleted at the source are not propagated by an incremental run. Run `dbt run --full-refresh --select input_layer__medical_claim input_layer__observation input_layer__lab_result` after a historical restatement, after changing a partition or unique key, or on a periodic schedule (e.g. weekly).

### Verifying incremental vs. full refresh

`scripts/verify_incremental_parity.py` checks on DuckDB that an incremental run gives the same result as a full refresh. It loads an earlier version of each source (the most recent 45 days withheld), then loads the final source (withheld rows plus corrections to about 10% of the rows 46-60 days back), runs incrementally, and diffs the result against a full refresh of the final source with `EXCEPT ALL` in both directions. It then runs incrementally again to check that a re-run changes nothing. The seed tables are restored afterwards.

```bash
dbt seed
DBT_PROFILES_DIR=integration_tests/profiles/duckdb \
DBT_MOTHERDUCK_CI_PATH=/path/to/demo.duckdb \
python scripts/verify_incremental_parity.py
```

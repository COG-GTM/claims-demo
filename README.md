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

### Databricks

#### Prerequisites
- A SQL Warehouse (or all-purpose cluster) and its `http_path`, the workspace host, and a personal access token.
- A Unity Catalog catalog you can write to. dbt creates the `input_layer`, `reference_data` and `terminology`
  schemas inside it (see `macros/generate_schema_name.sql`, which uses custom schema names verbatim), plus the
  schema configured as `schema:` in your profile for everything else.
- The seed `+post-hook`s in `dbt_project.yml` call `the_tuva_project.load_seed(...)`, which issues a
  `COPY INTO ... FROM 's3://tuva-public-resources/...'` on the warehouse. The workspace must be able to reach
  that public S3 bucket. If your workspace blocks anonymous S3 reads, either register the bucket as a Unity
  Catalog external location with a storage credential, or export `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  and `AWS_SESSION_TOKEN` before running dbt — the Databricks `load_seed` macro adds an inline
  `WITH (CREDENTIAL (...))` clause when `AWS_SESSION_TOKEN` is set.

#### Adapter
Install `dbt-databricks` (it pulls in a matching `dbt-core`). CI pins `dbt-core==1.10.15` with the latest
`dbt-databricks`; that combination is validated by `.github/workflows/dbt_ci_modes.yml`.

```bash
python -m venv .venv && source .venv/bin/activate
pip install "dbt-core==1.10.15" dbt-databricks certifi
```

#### Profile
`dbt_project.yml` uses `profile: default`. Add a `default` profile to `~/.dbt/profiles.yml` (do not commit it):

```yaml
default:
  target: dev
  outputs:
    dev:
      type: databricks
      host: <workspace-host>            # e.g. adb-1234567890.11.azuredatabricks.net
      http_path: /sql/1.0/warehouses/<warehouse-id>
      token: <personal-access-token>
      catalog: <unity-catalog-catalog>  # becomes target.database
      schema: default
      threads: 8
      connect_timeout: 60
      connect_retries: 3
```

`integration_tests/profiles/databricks/profiles.yml` is the CI-only equivalent driven by the
`DBT_DATABRICKS_CI_*` environment variables; use it as a reference, not for local runs.

#### Run sequence

```bash
dbt debug     # verifies host/http_path/token and catalog access
dbt deps      # installs the_tuva_project + dbt_utils
dbt seed      # creates the seed tables and loads the synthetic CSVs from S3
dbt build     # runs the full Tuva data model and its tests
dbt test      # re-runs tests only
```

Seeds must be loaded before models: `dbt run` alone (the CI "run" mode) requires the baseline schemas to
already exist, which `macros/ci/assert_ci_seed_baseline_ready.sql` checks using `target.database` — on
Databricks that resolves to the profile's `catalog`.
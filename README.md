[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.10.15&color=orange)

# The Tuva Project Demo

This is a dbt project that loads a 1,000 patient synthetic claims and clinical dataset and runs the Tuva package.  When you run the project it loads the synthetic data to your warehouse and transforms it into the Tuva data model.

CI runs this project on dbt-core 1.10.15 (see [`.github/workflows/dbt_ci_modes.yml`](.github/workflows/dbt_ci_modes.yml)); we recommend running locally on the same version.

## 🔌 Database Support

Databricks is the primary documented warehouse for this demo. The project also supports the following alternatives:
- BigQuery
- DuckDB (community supported)
- Redshift
- Snowflake
- Microsoft Fabric

## ✅ How to get started (Databricks)

### Pre-requisites
1. dbt-core 1.10.15 and the Databricks adapter installed:
   ```bash
   pip install dbt-core==1.10.15 dbt-databricks
   ```
   If you have not installed dbt before, [here](https://docs.getdbt.com/docs/get-started-dbt) are instructions for doing so.
2. A Databricks SQL warehouse or all-purpose cluster you can connect to, and the Unity Catalog catalog + schema you want the project to write to. You need the workspace host, the warehouse/cluster HTTP path, and a personal access token (or another supported auth method).

### Configure your profile
Add a `default` profile to `~/.dbt/profiles.yml` (the project's `profile:` is `default`):

```yaml
default:
  target: dev
  outputs:
    dev:
      type: databricks
      host: <workspace-host>            # e.g. adb-1234567890123456.7.azuredatabricks.net
      http_path: <sql-warehouse-http-path>  # e.g. /sql/1.0/warehouses/abc123def456
      token: <personal-access-token>
      catalog: <unity-catalog-name>
      schema: <target-schema>
      threads: 8
      connect_timeout: 60
      connect_retries: 3
```

See the [dbt-databricks setup docs](https://docs.getdbt.com/docs/core/connect-data-platform/databricks-setup) for the full list of connection options (OAuth, compute overrides, etc.). The CI profile used by this repo is a good reference: [`integration_tests/profiles/databricks/profiles.yml`](integration_tests/profiles/databricks/profiles.yml).

### Run the project

1. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) this repo to your local machine or environment.
2. Run `dbt debug` to confirm the connection to Databricks.
3. Run `dbt deps` to install the Tuva Project package.
4. Run `dbt build` to run the entire project with the built-in sample data.

## 🧩 Other warehouses

The same steps apply for BigQuery, DuckDB, Redshift, Snowflake, and Microsoft Fabric — install the matching adapter (e.g. `pip install dbt-core==1.10.15 dbt-snowflake`) and point the `default` profile at that warehouse. Example CI profiles for every supported warehouse live in [`integration_tests/profiles/`](integration_tests/profiles).

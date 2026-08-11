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

#### Example: Databricks profile

The project uses the `default` profile (see `profile:` in `dbt_project.yml`). Below is a copy-pasteable
`~/.dbt/profiles.yml` for Databricks with Unity Catalog and a serverless SQL warehouse. It requires the
[`dbt-databricks`](https://docs.getdbt.com/docs/core/connect-data-platform/databricks-setup) adapter
(`pip install dbt-databricks`).

```yaml
default:
  target: dev
  outputs:
    dev:
      type: databricks
      # Workspace hostname only - no https:// prefix and no trailing slash
      host: adb-1234567890123456.7.azuredatabricks.net
      # SQL Warehouses > your warehouse > Connection details > HTTP path
      http_path: /sql/1.0/warehouses/abc123def456ghi7
      # Never commit a token: export DATABRICKS_TOKEN=dapi... in your shell
      token: "{{ env_var('DATABRICKS_TOKEN') }}"
      # Unity Catalog three-level namespace: <catalog>.<schema>.<table>
      catalog: tuva_demo
      schema: dbt_your_name
      threads: 8
      connect_timeout: 60
      connect_retries: 3
```

Notes:
- `catalog` + `schema` give the Unity Catalog three-level namespace; the project writes into
  `<catalog>.<schema>` and its Tuva sub-schemas. Your principal needs `USE CATALOG`, `USE SCHEMA`
  and `CREATE TABLE`/`CREATE VIEW` on the target catalog and schema.
- A serverless SQL warehouse works well here; its `http_path` always looks like
  `/sql/1.0/warehouses/<warehouse-id>`. An all-purpose cluster uses
  `/sql/protocolv1/o/<workspace-id>/<cluster-id>` instead.
- The CI profile in `integration_tests/profiles/databricks/profiles.yml` uses the same fields but
  reads every value from environment variables; the `dev` target above only keeps the token in an
  env var so no credentials end up in source control.

Verify the connection before running the project:

```bash
export DATABRICKS_TOKEN=dapi...   # personal access token or service principal token
dbt debug                         # add --target dev if dev is not your default target
```

`dbt debug` checks the profile is valid and that dbt can open a connection to the warehouse. Once all
checks pass, run `dbt deps` and `dbt build`.
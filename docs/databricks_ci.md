# Databricks CI profile (Unity Catalog)

The Databricks CI target lives in
[`integration_tests/profiles/databricks/profiles.yml`](../integration_tests/profiles/databricks/profiles.yml)
and is used by the `Demo CI` workflow
([`.github/workflows/dbt_ci_modes.yml`](../.github/workflows/dbt_ci_modes.yml))
when the `databricks` target is selected (`/ci run-databricks`, `/ci build-databricks`,
or the `all` target).

## Unity Catalog namespace

Unity Catalog uses a three-level namespace: `<catalog>.<schema>.<table>`.

- `catalog` is set from `DBT_DATABRICKS_CI_CATALOG` and is the top level of the namespace.
  Without it the adapter falls back to `hive_metastore`, i.e. the legacy two-level namespace.
- `schema` is the *fallback* schema only. Almost every model in this project sets a custom
  schema (`input_layer`, `core`, `terminology`, `reference_data`, ...) which
  [`macros/generate_schema_name.sql`](../macros/generate_schema_name.sql) uses verbatim (no
  `<target_schema>_<custom_schema>` prefixing). It defaults to `default` and can be
  overridden with `DBT_DATABRICKS_CI_SCHEMA`.

The service principal / PAT owner needs, on the CI catalog: `USE CATALOG`, `CREATE SCHEMA`,
and `USE SCHEMA` + `CREATE TABLE` + `MODIFY`/`SELECT` on the schemas above.

## `http_path` for a serverless SQL warehouse

Serverless and pro/classic SQL warehouses all use the same shape:

```
/sql/1.0/warehouses/<warehouse-id>
```

Copy it from the warehouse's **Connection details** tab (it is not a
`/sql/protocolv1/o/<workspace-id>/<cluster-id>` all-purpose-cluster path). Serverless is
recommended for CI: it starts in seconds, so the job does not pay a cluster-spin-up cost.

## Threads and retry settings

| Setting | Value | Why |
| --- | --- | --- |
| `threads` | 8 | Unchanged. A SQL warehouse cluster admits ~10 concurrent queries before queueing, so 8 saturates one cluster of a 2X-Small serverless warehouse; raise only together with warehouse size / scaling. |
| `connect_timeout` | 120 | Covers a cold serverless warehouse resuming at the start of a CI job. |
| `connect_retries` / `retry_all` | 3 / `true` | Retries transient session/connection failures (warehouse resuming, brief 503s), not just the narrow default set. |
| `connection_parameters._retry_stop_after_attempts_count` | 10 | Adapter default is 30; a bad host or warehouse id would otherwise hang the job for many minutes before failing. |
| `connection_parameters._retry_delay_max` | 30 | Caps backoff between those attempts (adapter default 60s). |

## Required CI secrets

Set as **GitHub Actions repository secrets** (Settings → Secrets and variables → Actions →
Repository secrets). They are mapped to environment variables in the `run_dbt` job's `env:`
block in `.github/workflows/dbt_ci_modes.yml`; the profile reads them via `env_var()`.
Never commit values.

| Secret / env var | Required | Example value | Notes |
| --- | --- | --- | --- |
| `DBT_DATABRICKS_CI_HOST` | yes | `dbc-1234abcd-5678.cloud.databricks.com` | Workspace hostname only — no `https://`, no trailing slash. |
| `DBT_DATABRICKS_CI_HTTP_PATH` | yes | `/sql/1.0/warehouses/abc123def4567890` | Serverless SQL warehouse path (see above). |
| `DBT_DATABRICKS_CI_TOKEN` | yes | `dapi…` | Personal access token for the CI service principal. Rotate on the workspace's token expiry schedule. |
| `DBT_DATABRICKS_CI_CATALOG` | yes | `tuva_ci` | Unity Catalog catalog dedicated to CI. |
| `DBT_DATABRICKS_CI_SCHEMA` | no | `default` | Fallback schema for nodes without a custom schema. Defaults to `default`; to use it, add `DBT_DATABRICKS_CI_SCHEMA: ${{ secrets.DBT_DATABRICKS_CI_SCHEMA }}` to the workflow `env:` block. |

## Verifying locally

```bash
export DBT_DATABRICKS_CI_HOST=... DBT_DATABRICKS_CI_HTTP_PATH=... \
       DBT_DATABRICKS_CI_TOKEN=... DBT_DATABRICKS_CI_CATALOG=...
dbt deps  --project-dir . --profiles-dir ./integration_tests/profiles/databricks
dbt debug --project-dir . --profiles-dir ./integration_tests/profiles/databricks
dbt build --full-refresh --project-dir . --profiles-dir ./integration_tests/profiles/databricks
```

`dbt debug` prints the resolved `catalog` and `schema`, which is the quickest check that the
three-level namespace is wired up correctly.

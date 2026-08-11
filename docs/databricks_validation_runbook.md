# Databricks end-to-end validation runbook

How to run and verify a full `dbt build --full-refresh` of this demo project against a
Databricks SQL warehouse, and how to confirm every model materialized as Delta in the
target Unity Catalog.

Everything here is driven by
[`integration_tests/scripts/validate_databricks_build.sh`](../integration_tests/scripts/validate_databricks_build.sh)
and the `assert_databricks_delta_relations` macro in
[`macros/validation/`](../macros/validation/assert_databricks_delta_relations.sql).

## 1. Prerequisites

| Requirement | Value |
| --- | --- |
| Python | 3.10 (the version CI uses) |
| dbt-core | `1.10.15` (pinned in `.github/workflows/dbt_ci_modes.yml`) |
| Adapter | `dbt-databricks` (installed together with `dbt-spark`) |
| Warehouse | A running Databricks SQL warehouse (or all-purpose cluster) with Unity Catalog |
| Privileges | `USE CATALOG`, `CREATE SCHEMA` on the target catalog; `CREATE TABLE`/`MODIFY` on the schemas it creates |
| Network | Outbound HTTPS to `<workspace>.cloud.databricks.com` (or `*.azuredatabricks.net`), plus public S3 for seed post-hooks |

The seed post-hooks in `dbt_project.yml` call `the_tuva_project.load_seed(...)`, which
pulls CSVs from the public `tuva-public-resources` S3 bucket. The warehouse — not your
laptop — performs that read, so the workspace must be able to reach public S3.

## 2. Credentials

Four values are required. The profile at
`integration_tests/profiles/databricks/profiles.yml` reads the `*_CI_*` names; the
script also accepts the shorter names and maps them.

| Script variable | Profile / CI variable | Example |
| --- | --- | --- |
| `DBT_DATABRICKS_HOST` | `DBT_DATABRICKS_CI_HOST` | `adb-1234567890123456.7.azuredatabricks.net` (no scheme) |
| `DBT_DATABRICKS_HTTP_PATH` | `DBT_DATABRICKS_CI_HTTP_PATH` | `/sql/1.0/warehouses/abc123def456` |
| `DBT_DATABRICKS_TOKEN` | `DBT_DATABRICKS_CI_TOKEN` | `dapi...` personal access token |
| `DBT_DATABRICKS_CATALOG` | `DBT_DATABRICKS_CI_CATALOG` | `tuva_demo` |

Host and HTTP path come from the warehouse's **Connection details** tab in the
Databricks UI. In GitHub they are repository secrets of the same `*_CI_*` names.

## 3. Run it

```bash
export DBT_DATABRICKS_HOST=...
export DBT_DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/...
export DBT_DATABRICKS_TOKEN=dapi...
export DBT_DATABRICKS_CATALOG=tuva_demo

INSTALL_DEPS=1 integration_tests/scripts/validate_databricks_build.sh
```

The script runs, in order:

1. `dbt deps`
2. `dbt debug` — connection check
3. `dbt build --full-refresh`
4. `dbt run-operation assert_databricks_delta_relations`

`INSTALL_DEPS=1` pip-installs `dbt-core==1.10.15`, `dbt-databricks` and `certifi` first
(omit it if your environment already has them). `SKIP_BUILD=1` substitutes `dbt parse`
for the build and only re-runs the Delta assertion against relations that already
exist — useful for re-checking a catalog without rebuilding it.

To run the same thing through CI instead, trigger the `Demo CI` workflow via
`workflow_dispatch` with `operation=build`, `target=databricks` (or comment
`/ci build-databricks` on the PR).

## 4. Expected output

`dbt deps` (~5s) installs five packages:

```
Installing tuva-health/the_tuva_project        Installed from version 0.17.2
Installing dbt-labs/dbt_utils                  Installed from version 1.4.1
Installing metaplane/dbt_expectations           Installed from version 0.10.10
Installing https://github.com/tuva-health/dbt-data-reliability.git
Installing godatadriven/dbt_date                Installed from version 0.19.0
```

`dbt deps` also prints `Updates available for packages: ['tuva-health/the_tuva_project']`
— expected, `packages.yml` pins `>=0.17.0,<0.18.0`.

`dbt parse` / `dbt build` reports the project size:

```
Found 922 models, 120 seeds, 4 operations, 1053 data tests, 2036 macros
```

`dbt build --full-refresh` materializes (counts from `dbt list` on this revision):

| Materialization | Models |
| --- | --- |
| `table` | 674 |
| `view` | 198 |
| `ephemeral` | 35 |
| `incremental` | 15 |

Plus 120 seeds. Expect roughly 45–90 minutes on a Small/Medium warehouse with
`threads: 8` (the profile's setting); the seed post-hooks that `COPY INTO` synthetic
data from S3 dominate the first phase.

No model sets `file_format`, so all of them inherit the dbt-databricks default of
`delta` — that default is exactly what step 4 verifies rather than assumes.

The final assertion prints:

```
Checked <n> materialized relations in catalog <catalog>
Delta relations: <n>
Non-delta relations: 0
Missing relations: 0
```

It reads `<catalog>.information_schema.tables` once per catalog (not one `describe
detail` per relation) and compares that against every enabled `table` / `incremental` /
`snapshot` / seed node in the manifest. A node fails if its relation is absent, is a
`VIEW`, or reports a `data_source_format` other than `delta`. Model-level `view` and
`ephemeral` materializations are skipped — they have no storage format.

If `dbt build` fails, the assertion still runs (so you can see what did materialize) and
the script then exits with the build's exit code.

## 5. Known warnings (not failures)

| Message | Why |
| --- | --- |
| `order_by_clause is not supported for listagg on Spark/Databricks` | dbt_utils' `listagg` on Spark; emitted ~8x at parse time. |
| `MissingArgumentsPropertyInGenericTestDeprecation` (10 occurrences) | dbt 1.10 deprecation raised by package YAML, not this project. |
| `WARNING:thrift.transport.sslcompat:using legacy validation callback` | Emitted by `dbt-databricks` on import. |
| `Your version of dbt-core is out of date` | The 1.10.15 pin is intentional (matches CI). |

## 6. Failure modes

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Env var required but not provided: 'DBT_DATABRICKS_CI_HOST'` | Credential not exported | The script pre-checks all four and exits `2` listing what is missing. |
| `Failed to resolve '<host>'` / connection retries | Wrong host, or no outbound network to the workspace | Host must have no `https://` prefix and no trailing slash. |
| `403` / `Invalid access token` on `dbt debug` | Expired or wrong-workspace PAT | Reissue the token in the same workspace as the HTTP path. |
| Long hang on the first query | SQL warehouse is stopped and cold-starting | Start the warehouse first; `connect_timeout: 60` with 3 retries is already set in the profile. |
| `Catalog '<x>' does not exist` / `PERMISSION_DENIED` | Catalog missing or grants missing | Create the catalog and grant `USE CATALOG` + `CREATE SCHEMA` to the token's principal. |
| Seed post-hooks fail reading `tuva-public-resources` | Workspace cannot reach public S3 | Allow egress, or stage the CSVs into a volume and adjust `load_seed`. |
| `CI baseline seed schemas are not ready for run-only mode` | `dbt run` used before a full build | Run a build (`/ci build-databricks`) so `input_layer`, `reference_data`, `terminology` exist. |
| Assertion reports `MISSING: ...` | Build partially failed, or `--full-refresh` was not used | Re-run the failed selection, then `SKIP_BUILD=1` to re-assert. |
| Assertion reports `NOT DELTA: ... (format=parquet)` | A `file_format` override, or a pre-existing non-Delta table of the same name | Drop the stale relation and rebuild, or remove the override. |

## 7. What has been verified offline

Without a live workspace, the following were confirmed on this revision using
`dbt-core==1.10.15` + `dbt-databricks==1.11.0` (dbt-spark 1.9.3):

- `dbt deps` succeeds and resolves the five packages listed above.
- `dbt parse` (including `--no-partial-parse`) succeeds with the databricks profile and
  placeholder credentials — the project and the new macro compile cleanly for this
  adapter.
- `dbt list` enumerates 924 model nodes with the materialization split in §4 and no
  `file_format` overrides.
- The script's credential pre-flight exits `2` with an actionable message.

Still unverified, and requiring a live Databricks workspace: `dbt debug`,
`dbt build --full-refresh`, the runtime behaviour of
`assert_databricks_delta_relations` (including that Unity Catalog exposes
`data_source_format` on `information_schema.tables`), and the wall-clock estimate in §4.
`dbt compile` is also not runnable offline — it opens a connection for introspection.

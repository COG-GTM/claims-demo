[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.10.x&color=orange)

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
1. You have [dbt](https://www.getdbt.com/) installed and configured (i.e. connected to your data warehouse). If you have not installed dbt, [here](https://docs.getdbt.com/docs/get-started-dbt) are instructions for doing so. The Tuva package (`>=0.17.0,<0.18.0`) requires dbt-core `>=1.10`.
2. You have created a database for the output of this project to be written in your data warehouse.
3. Your warehouse can reach the public `s3://tuva-public-resources` bucket: seed CSVs in `seeds/` are header-only, and the real synthetic data is loaded from S3 by `post-hook`s in `dbt_project.yml`.

### Getting Started
Complete the following steps to configure the project to run in your environment.

1. [Clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) this repo to your local machine or environment.
2. Create (or point `--profiles-dir` at) a dbt profile named `default` connected to your data warehouse. Example profiles live in `integration_tests/profiles/<warehouse>/profiles.yml`.
3. Run `dbt deps --no-version-check` to install the Tuva Project package (see [Known issues](#-known-issues) for why the flag is needed).
4. Run `dbt build` to run the entire project with the built-in sample data.

### Local quickstart: DuckDB (verified)
These are the exact steps and versions verified end to end from a clean checkout on Ubuntu 22.04 (Python 3.10.12, 8 vCPU / 32 GB RAM). No warehouse or credentials are required.

| Component | Version |
| --- | --- |
| Python | 3.10 (matches CI) |
| dbt-core | 1.10.15 (matches CI) |
| dbt-duckdb | 1.10.1 (pulls duckdb 1.5.6) |
| the_tuva_project | 0.17.2 (resolved from `>=0.17.0,<0.18.0`) |
| dbt_utils / dbt_expectations / dbt_date | 1.4.1 / 0.10.10 / 0.21.0 |

```bash
git clone https://github.com/COG-GTM/claims-demo.git
cd claims-demo

python3.10 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install "dbt-core==1.10.15" "dbt-duckdb==1.10.1"

# Use the bundled DuckDB profile; the `local` target writes to ./claims_demo.duckdb
# (override the file with DBT_DUCKDB_PATH=/path/to/file.duckdb).
export DBT_PROFILES_DIR=./integration_tests/profiles/duckdb

dbt deps --no-version-check
dbt debug --target local
dbt build --target local
```

Notes:
- DuckDB reads the seed data from `s3://tuva-public-resources` anonymously via its `httpfs` extension, which it auto-installs on first use, so the machine needs outbound internet access.
- Expect `dbt build` to take roughly 30 minutes (28m44s on the reference machine; a few `core`/`claims_preprocessing` models take 4-8 minutes each) and to finish with `PASS=2001 WARN=63 ERROR=0`. The warnings are data-quality tests on the synthetic data and are expected. The resulting DuckDB file is about 2.7 GB.
- The `ci` target in the same profile is for MotherDuck and requires `DBT_MOTHERDUCK_CI_PATH`; use `--target local` for a local file.
- Inspect results with the DuckDB CLI or Python, e.g. `python -c "import duckdb; print(duckdb.connect('claims_demo.duckdb').sql('select count(*) from core.medical_claim'))"`.

## ⚠️ Known issues
- **`dbt deps` crashes without `--no-version-check`.** The dbt Hub entry for `tuva-health/the_tuva_project` version `1.0.0` publishes `require_dbt_version` as a single string (`">=1.10.5,<3.0.0"`) instead of a list. dbt-core (verified on 1.10.15, same code in 1.11.x) parses every published version while checking compatibility and fails with `SemverError: ">=1.10.5,<3.0.0" is not a valid semantic version.` before resolving anything. `--no-version-check` skips that check; the `packages.yml` range still pins Tuva to 0.17.x. This also affects the CI workflow, which runs plain `dbt deps`.
- **Package versions float.** `packages.yml` allows any `dbt_utils >=0.9.2`, and Tuva pulls `dbt_expectations`/`dbt_date` with loose ranges; `package-lock.yml` is gitignored, so fresh installs can resolve different versions than the table above.

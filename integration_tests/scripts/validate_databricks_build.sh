#!/usr/bin/env bash
#
# End-to-end validation build for the Databricks target.
#
# Runs `dbt deps` + `dbt build --full-refresh` against a Databricks SQL warehouse
# and then asserts that every materialized relation landed as Delta in the target
# Unity Catalog.
#
# Usage:
#   export DBT_DATABRICKS_HOST=adb-1234567890.7.azuredatabricks.net
#   export DBT_DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/abc123def456
#   export DBT_DATABRICKS_TOKEN=dapi...
#   export DBT_DATABRICKS_CATALOG=tuva_demo
#   integration_tests/scripts/validate_databricks_build.sh
#
# The CI-style variable names (DBT_DATABRICKS_CI_*) are also accepted and take
# precedence, so this script can be run unchanged inside the Demo CI workflow.
#
# Options (environment variables):
#   DBT_CORE_VERSION   dbt-core version to install when INSTALL_DEPS=1 (default 1.10.15)
#   INSTALL_DEPS       1 to pip install dbt-core/dbt-databricks first (default 0)
#   SKIP_BUILD         1 to skip `dbt build` and only re-run the Delta assertion

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILES_DIR="${PROJECT_DIR}/integration_tests/profiles/databricks"
DBT_CORE_VERSION="${DBT_CORE_VERSION:-1.10.15}"
INSTALL_DEPS="${INSTALL_DEPS:-0}"
SKIP_BUILD="${SKIP_BUILD:-0}"

# Map the plain variable names onto the CI names the profile reads.
export DBT_DATABRICKS_CI_HOST="${DBT_DATABRICKS_CI_HOST:-${DBT_DATABRICKS_HOST:-}}"
export DBT_DATABRICKS_CI_HTTP_PATH="${DBT_DATABRICKS_CI_HTTP_PATH:-${DBT_DATABRICKS_HTTP_PATH:-}}"
export DBT_DATABRICKS_CI_TOKEN="${DBT_DATABRICKS_CI_TOKEN:-${DBT_DATABRICKS_TOKEN:-}}"
export DBT_DATABRICKS_CI_CATALOG="${DBT_DATABRICKS_CI_CATALOG:-${DBT_DATABRICKS_CATALOG:-}}"

# A plain string, not an array: expanding an empty array under `set -u` is an
# error in bash < 4.4 (e.g. stock macOS bash 3.2).
missing=""
for var in DBT_DATABRICKS_CI_HOST DBT_DATABRICKS_CI_HTTP_PATH DBT_DATABRICKS_CI_TOKEN DBT_DATABRICKS_CI_CATALOG; do
  if [[ -z "${!var}" ]]; then
    missing="${missing}${missing:+ }${var}"
  fi
done

if [[ -n "${missing}" ]]; then
  echo "ERROR: missing required credentials: ${missing}" >&2
  echo "Set DBT_DATABRICKS_HOST / HTTP_PATH / TOKEN / CATALOG (or the *_CI_* equivalents)." >&2
  exit 2
fi

echo "==> Validating Databricks build"
echo "    project : ${PROJECT_DIR}"
echo "    profiles: ${PROFILES_DIR}"
echo "    host    : ${DBT_DATABRICKS_CI_HOST}"
echo "    catalog : ${DBT_DATABRICKS_CI_CATALOG}"

if [[ "${INSTALL_DEPS}" == "1" ]]; then
  echo "==> Installing dbt-core==${DBT_CORE_VERSION} and dbt-databricks"
  python -m pip install --upgrade pip
  python -m pip install "dbt-core==${DBT_CORE_VERSION}" dbt-databricks certifi
fi

dbt_run() {
  dbt "$@" --project-dir "${PROJECT_DIR}" --profiles-dir "${PROFILES_DIR}"
}

echo "==> dbt deps"
dbt_run deps

echo "==> dbt debug (connection check)"
dbt_run debug

build_status=0
if [[ "${SKIP_BUILD}" == "1" ]]; then
  echo "==> Skipping dbt build (SKIP_BUILD=1); parsing project instead"
  dbt_run parse
else
  echo "==> dbt build --full-refresh"
  # Keep going so the Delta assertion still reports on what did materialize.
  dbt_run build --full-refresh || build_status=$?
fi

echo "==> Asserting every materialized relation is Delta"
assert_status=0
dbt_run run-operation assert_databricks_delta_relations || assert_status=$?

if (( build_status != 0 )); then
  echo "ERROR: dbt build --full-refresh failed (exit ${build_status}); see the assertion output above for what materialized." >&2
  exit "${build_status}"
fi

if (( assert_status != 0 )); then
  echo "ERROR: Delta assertion failed (exit ${assert_status})." >&2
  exit "${assert_status}"
fi

echo "==> Databricks validation completed successfully"

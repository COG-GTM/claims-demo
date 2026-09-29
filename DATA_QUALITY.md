# Input layer freshness and data-quality checks

The demo input layer (the eight seeds in `seeds/`, loaded into the `input_layer`
schema from `tuva-public-resources` by `load_seed` post-hooks) runs two kinds of checks:

| Check | Defined in | Run by | What happens when it fails |
|---|---|---|---|
| Data-quality tests (`tag:seed_dq`) | `seeds/_seeds.yml`, `tests/generic/` | `dbt build`, `dbt test` | The test errors, and `dbt build` **skips every model downstream of that seed** |
| Source freshness | `models/_sources.yml` (`input_layer_seeds`) | `dbt source freshness` | `WARN` / `ERROR STALE` per table; exit code is non-zero on error |

## Running the checks

```bash
dbt seed                              # load the input layer
dbt test --select tag:seed_dq         # data-quality tests only
dbt source freshness                  # how old the loaded data is
dbt build                             # seeds, then their tests, then Tuva (stops on bad seeds)
```

To see the rows behind a failing test, rerun it with `--store-failures`, or run
the compiled SQL printed in the error (under `target/compiled/.../tests/`) yourself.
Each test query returns the rows that break the rule, so `FAIL 12` means 12 bad rows (or groups).

## Interpreting a failure

Test names follow the pattern `<test>_<seed>_<column>_...`. Named tests use
`<seed>__<rule>`. The table below maps each failure type to what it means and what to do next.

| Failing test | What it means | Likely cause / next step |
|---|---|---|
| `min_row_count_<seed>_<n>` | The seed has fewer than `n` rows. `0` means the S3 load did not replace the header-only CSV | Check the seed's `load_seed` post-hook in `dbt_project.yml` (bucket path, version folder, file name) and the `dbt seed` log line `rows: N` |
| `not_null_<seed>_<column>` | Required column has nulls | Column is misaligned or missing in the source file (header changed between dataset versions), or the column is now optional upstream |
| `unique_<seed>_<id>` / `dbt_utils_unique_combination_of_columns_...` | Duplicate primary key or grain rows | The file was loaded twice (for example, two files matching the `load_seed` pattern `name.csv*`) or the upstream grain changed |
| `relationships_<seed>_person_id__...ref_eligibility_` | Rows reference a `person_id` that isn't in `eligibility` | Seeds are pinned to different dataset versions (`eligibility` is on 0.16.0, the rest on 0.15.0). Align the versions in `dbt_project.yml` |
| `accepted_values_<seed>_<column>__...` | An unexpected code value (such as `F` instead of `female`) | Upstream normalization changed. Map the value or extend the accepted list only if Tuva supports it |
| `<seed>__*_after_start`, `*_non_negative`, `*_positive` | Row-level logical errors (end before start, negative charge/allowed amounts, and so on) | Malformed or shifted rows. Check date formats and column order in the source file |
| `provider_attribution_source__year_month_is_yyyymm` | `year_month` isn't a `YYYYMM` string | Date format changed (for example, `2018-06`). Provider attribution joins on this key and would silently drop rows |
| `<seed>__<column>_covers_reporting_period` | The latest date in claims/eligibility is more than `input_layer_max_coverage_lag_days` (31) days before `quality_measures_period_end` | The data is **stale relative to the configured reporting period**. Quality measures and the HCC data mart would run on incomplete data. Load a newer dataset or move `quality_measures_period_end` / `cms_hcc_payment_year` back |

Negative `paid_amount` values are allowed on purpose, because the synthetic claims contain reversals.

### Source freshness results

`dbt source freshness` compares `max(ingest_datetime)` on each seed with the current time:

- `PASS`: data was ingested within `input_layer_freshness_warn_after_count` periods.
- `WARN`: older than the warn threshold (default 365 days). The demo dataset is a static,
  versioned snapshot, so this warning means the snapshot is over a year old and a newer
  `versioned_tuva_synthetic_data` version is probably available. It doesn't block anything.
- `ERROR STALE`: older than the error threshold (default 730 days). The command exits non-zero.
  Bump the dataset version in the `load_seed` post-hooks and rerun `dbt seed`.
- `ERROR` (runtime, not `STALE`): the table or `ingest_datetime` column is missing. Run `dbt seed` first.

`provider_attribution_source` has no ingest timestamp, so freshness isn't checked for it.

## Tuning

All thresholds are vars in `dbt_project.yml` and can be overridden per run:

```bash
# Treat the input layer as a daily feed
dbt source freshness --vars '{input_layer_freshness_warn_after_count: 24, input_layer_freshness_error_after_count: 48, input_layer_freshness_period: hour}'
```

All `seed_dq` tests default to `severity: error` (set in `dbt_project.yml` under
`data_tests:`). To downgrade an individual test while you investigate it, add
`config: {severity: warn}` to that test in `seeds/_seeds.yml`.

# Seed data profiling

`profile_seeds` is a dbt run-operation that profiles every seed in this project
(the synthetic claims/clinical input layer) and appends the results to two
warehouse tables. It is scheduled daily by
`.github/workflows/seed_profiling.yml` and can be run by hand at any time.

## Running it

Seeds must already be loaded (`dbt seed` or `dbt build`).

```bash
# all seeds, top 10 values per column
dbt run-operation profile_seeds

# a subset, top 5 values per column
dbt run-operation profile_seeds --args '{seeds: [medical_claim, eligibility], top_n: 5}'

# skip seeds that have not been loaded instead of failing
dbt run-operation profile_seeds --args '{allow_missing: true}'

# write to a different schema (default: data_profiling)
dbt run-operation profile_seeds --vars '{seed_profile_schema: my_profiling}'
```

| Argument        | Default | Meaning                                                              |
| --------------- | ------- | -------------------------------------------------------------------- |
| `seeds`         | all     | List of seed names to profile. Unknown names fail the run.           |
| `top_n`         | `10`    | How many of the most frequent values to keep per column.             |
| `allow_missing` | `false` | Log (instead of fail on) seeds whose table does not exist yet.        |

Missing seed tables are checked before anything is written, so a failed run
does not leave a partial profile behind.

### Schedule

`Seed Profiling` (`.github/workflows/seed_profiling.yml`) runs daily at 06:00
UTC against the Snowflake CI target, using the same secrets and profiles as the
demo CI (`integration_tests/profiles/<warehouse>`). Use **Run workflow**
(`workflow_dispatch`) to profile another warehouse or change `top_n`.

To schedule it in dbt Cloud instead, add a job with the single command
`dbt run-operation profile_seeds`.

## Output tables

Both tables live in `<target database>.data_profiling` (override with the
`seed_profile_schema` var) and are **append-only**: each run adds rows tagged
with a new `profile_run_id` (the dbt `invocation_id`) and `profiled_at` (UTC
run start). Tables are created on the first run. Column-level descriptions are
in `models/_seed_profiling.yml` (the `seed_profiling` source) and show up in
`dbt docs`.

### `seed_profile_columns` — one row per run / seed / column

| Column            | Meaning                                                                 |
| ----------------- | ----------------------------------------------------------------------- |
| `seed_name`, `relation_name`, `column_name`, `column_position`, `data_type` | What was profiled. |
| `row_count`       | Rows in the table (identical for every column of the seed in a run).    |
| `non_null_count`, `null_count` | Non-null / null rows for the column.                      |
| `null_rate`       | `null_count / row_count`. `1.0` = column is entirely empty.            |
| `distinct_count`  | Distinct non-null values.                                               |
| `distinct_rate`   | `distinct_count / non_null_count`. `1.0` = every value unique (an ID).   |
| `min_value`, `max_value` | Min / max using the column's native ordering, cast to text.      |

### `seed_profile_value_distribution` — top-N values per run / seed / column

| Column           | Meaning                                                         |
| ---------------- | --------------------------------------------------------------- |
| `value_rank`     | `1` = most frequent. Ties broken by `column_value`.             |
| `column_value`   | The value cast to text. `NULL` is counted as its own bucket.    |
| `frequency`      | Rows with this value.                                           |
| `frequency_rate` | `frequency / row_count` (null bucket included in the denominator). |

## How to read it

Always filter to a single run; otherwise every metric is repeated once per run.

```sql
-- latest profile, emptiest columns first
select seed_name, column_name, row_count, null_rate, distinct_count, min_value, max_value
from data_profiling.seed_profile_columns
where profiled_at = (select max(profiled_at) from data_profiling.seed_profile_columns)
order by null_rate desc, seed_name, column_position;
```

Ready-made versions of this and a value-distribution query are in
`analyses/seed_profile_latest.sql` and
`analyses/seed_profile_value_distribution_latest.sql`
(`dbt compile -s seed_profile_latest` or `dbt show -s seed_profile_latest`).

Things to look for:

- **`null_rate = 1`** — the column is never populated in the demo data (for
  example `appointment.encounter_id`). Downstream Tuva marts that depend on it
  will be empty.
- **`null_rate` between 0 and 1** — optional fields, e.g.
  `eligibility.death_date` is ~97% null because most members are alive.
- **`distinct_count = 1`** — a constant column (e.g. `eligibility.payer` is
  always `medicare`). The value distribution will show a single value with
  `frequency_rate = 1`.
- **`distinct_rate = 1`** — a unique key. Its value distribution is not
  informative (every value has `frequency = 1`); skip it.
- **Low `distinct_count`** — categorical columns. Read
  `seed_profile_value_distribution` to see the mix, e.g. `eligibility.gender`
  ≈ 61% female / 39% male.
- **`min_value` / `max_value`** — sanity-check date ranges (the demo data covers
  2016–2018) and numeric ranges. Text columns compare lexicographically, so
  numeric-looking IDs stored as text (e.g. `person_id`) sort as strings.

### Comparing runs

Because the tables are append-only you can diff two runs to detect drift after
a seed version bump in `dbt_project.yml`:

```sql
with runs as (
    select profile_run_id, max(profiled_at) as profiled_at,
           row_number() over (order by max(profiled_at) desc) as run_rank
    from data_profiling.seed_profile_columns
    group by profile_run_id
)
select cur.seed_name, cur.column_name,
       prev.row_count as prev_rows, cur.row_count as cur_rows,
       prev.null_rate as prev_null_rate, cur.null_rate as cur_null_rate
from data_profiling.seed_profile_columns cur
join runs rc on cur.profile_run_id = rc.profile_run_id and rc.run_rank = 1
join data_profiling.seed_profile_columns prev
  on prev.seed_name = cur.seed_name and prev.column_name = cur.column_name
join runs rp on prev.profile_run_id = rp.profile_run_id and rp.run_rank = 2
where cur.row_count <> prev.row_count or cur.null_rate <> prev.null_rate;
```

### Notes and limits

- Values in `min_value`, `max_value`, and `column_value` are truncated to 255
  characters so the output fits Redshift's default `varchar`.
- Min/max are skipped (null) for boolean columns.
- Each column is profiled with its own scan of the seed table. That is cheap
  for the demo data (~170k rows in the largest seed) but should be revisited
  before pointing this at large tables.
- History is never pruned; delete old `profile_run_id`s manually if needed.

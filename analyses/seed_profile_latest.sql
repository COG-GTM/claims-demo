-- Column profile from the most recent profile_seeds run, highest null rates first.
select
    seed_name,
    column_name,
    data_type,
    row_count,
    null_count,
    null_rate,
    distinct_count,
    distinct_rate,
    min_value,
    max_value
from {{ source('seed_profiling', 'seed_profile_columns') }}
where profiled_at = (
    select max(profiled_at) from {{ source('seed_profiling', 'seed_profile_columns') }}
)
order by null_rate desc, seed_name, column_position

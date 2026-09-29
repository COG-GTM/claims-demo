-- Top values for low-cardinality columns (<= 50 distinct values) from the most recent profile_seeds run.
select
    v.seed_name,
    v.column_name,
    v.value_rank,
    v.column_value,
    v.frequency,
    v.frequency_rate
from {{ source('seed_profiling', 'seed_profile_value_distribution') }} as v
inner join {{ source('seed_profiling', 'seed_profile_columns') }} as c
    on v.profile_run_id = c.profile_run_id
    and v.seed_name = c.seed_name
    and v.column_name = c.column_name
where c.distinct_count <= 50
    and v.profiled_at = (
        select max(profiled_at) from {{ source('seed_profiling', 'seed_profile_value_distribution') }}
    )
order by v.seed_name, c.column_position, v.value_rank

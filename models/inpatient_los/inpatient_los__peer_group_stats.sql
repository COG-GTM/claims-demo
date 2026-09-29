{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

{%- set iqr_multiplier = var('inpatient_los_outlier_iqr_multiplier', 1.5) -%}
{%- set metrics = ['length_of_stay', 'paid_amount'] -%}

with encounters as (
    select * from {{ ref('inpatient_los__encounters') }}
)

, metric_values as (
{%- for metric in metrics %}
    select
          'drg' as peer_group_level
        , 1 as peer_group_priority
        , drg_peer_group_id as peer_group_id
        , '{{ metric }}' as metric_name
        , cast({{ metric }} as {{ dbt.type_numeric() }}) as metric_value
    from encounters
    where drg_peer_group_id is not null
      and {{ metric }} is not null

    union all

    select
          'all_acute_inpatient' as peer_group_level
        , 2 as peer_group_priority
        , 'all_acute_inpatient' as peer_group_id
        , '{{ metric }}' as metric_name
        , cast({{ metric }} as {{ dbt.type_numeric() }}) as metric_value
    from encounters
    where {{ metric }} is not null
    {%- if not loop.last %}

    union all
    {% endif -%}
{% endfor %}
)

, ranked as (
    select
          peer_group_level
        , peer_group_priority
        , peer_group_id
        , metric_name
        , metric_value
        , row_number() over (
            partition by peer_group_level, peer_group_id, metric_name
            order by metric_value
          ) as value_rank
        , count(*) over (
            partition by peer_group_level, peer_group_id, metric_name
          ) as observation_count
    from metric_values
)

/* Nearest-rank quantiles: the smallest value whose rank is >= p * n. */
, quartiles as (
    select
          peer_group_level
        , peer_group_priority
        , peer_group_id
        , metric_name
        , observation_count
        , min(metric_value) as min_value
        , max(metric_value) as max_value
        , avg(metric_value) as mean_value
        , min(case when value_rank >= 0.25 * observation_count then metric_value end) as q1_value
        , min(case when value_rank >= 0.50 * observation_count then metric_value end) as median_value
        , min(case when value_rank >= 0.75 * observation_count then metric_value end) as q3_value
    from ranked
    group by
          peer_group_level
        , peer_group_priority
        , peer_group_id
        , metric_name
        , observation_count
)

select
      peer_group_level
    , peer_group_priority
    , peer_group_id
    , metric_name
    , observation_count
    , min_value
    , max_value
    , mean_value
    , q1_value
    , median_value
    , q3_value
    , q3_value - q1_value as iqr_value
    , q1_value - {{ iqr_multiplier }} * (q3_value - q1_value) as lower_fence
    , q3_value + {{ iqr_multiplier }} * (q3_value - q1_value) as upper_fence
from quartiles

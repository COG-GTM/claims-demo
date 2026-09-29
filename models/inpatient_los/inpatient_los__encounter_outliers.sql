{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

{%- set min_peer_group_size = var('inpatient_los_min_peer_group_size', 10) -%}
{%- set metrics = {'length_of_stay': 'los', 'paid_amount': 'cost'} -%}

with encounters as (
    select * from {{ ref('inpatient_los__encounters') }}
)

, peer_group_stats as (
    select * from {{ ref('inpatient_los__peer_group_stats') }}
    where observation_count >= {{ min_peer_group_size }}
)
{% for metric, prefix in metrics.items() %}
/*
  Benchmark each encounter against its DRG peer group when that group is large
  enough, otherwise against all acute inpatient encounters.
*/
, {{ prefix }}_peer as (
    select
          encounter_id
        , peer_group_level
        , peer_group_id
        , observation_count
        , median_value
        , lower_fence
        , upper_fence
    from (
        select
              enc.encounter_id
            , stats.peer_group_level
            , stats.peer_group_id
            , stats.observation_count
            , stats.median_value
            , stats.lower_fence
            , stats.upper_fence
            , row_number() over (
                partition by enc.encounter_id
                order by stats.peer_group_priority
              ) as peer_group_rank
        from encounters as enc
        inner join peer_group_stats as stats
            on stats.metric_name = '{{ metric }}'
            and (
                (stats.peer_group_level = 'drg' and stats.peer_group_id = enc.drg_peer_group_id)
                or stats.peer_group_level = 'all_acute_inpatient'
            )
        where enc.{{ metric }} is not null
    ) as candidates
    where peer_group_rank = 1
)
{% endfor %}

, flagged as (
    select
          enc.*
        , los.peer_group_level as los_peer_group_level
        , los.peer_group_id as los_peer_group_id
        , los.observation_count as los_peer_group_size
        , los.median_value as los_peer_median
        , los.lower_fence as los_lower_fence
        , los.upper_fence as los_upper_fence
        , case when enc.length_of_stay > los.upper_fence then 1 else 0 end as los_high_outlier_flag
        , case when enc.length_of_stay < los.lower_fence then 1 else 0 end as los_low_outlier_flag
        , cost.peer_group_level as cost_peer_group_level
        , cost.peer_group_id as cost_peer_group_id
        , cost.observation_count as cost_peer_group_size
        , cost.median_value as cost_peer_median
        , cost.lower_fence as cost_lower_fence
        , cost.upper_fence as cost_upper_fence
        , case when enc.paid_amount > cost.upper_fence then 1 else 0 end as cost_high_outlier_flag
        , case when enc.paid_amount < cost.lower_fence then 1 else 0 end as cost_low_outlier_flag
    from encounters as enc
    left outer join los_peer as los
        on enc.encounter_id = los.encounter_id
    left outer join cost_peer as cost
        on enc.encounter_id = cost.encounter_id
)

select
      *
    , case
        when los_high_outlier_flag + los_low_outlier_flag + cost_high_outlier_flag + cost_low_outlier_flag > 0
            then 1
        else 0
      end as outlier_flag
    , case
        when (los_high_outlier_flag + los_low_outlier_flag) > 0
         and (cost_high_outlier_flag + cost_low_outlier_flag) > 0
            then 'los and cost'
        when (los_high_outlier_flag + los_low_outlier_flag) > 0
            then 'los only'
        when (cost_high_outlier_flag + cost_low_outlier_flag) > 0
            then 'cost only'
        when los_peer_group_level is null and cost_peer_group_level is null
            then 'not evaluated'
        else 'not an outlier'
      end as outlier_category
from flagged

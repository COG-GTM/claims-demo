{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

with encounters as (
    select * from {{ ref('inpatient_los__encounter_outliers') }}
)

select
      coalesce(drg_peer_group_id, 'unknown') as drg_peer_group_id
    , max(drg_code_type) as drg_code_type
    , max(drg_code) as drg_code
    , max(drg_description) as drg_description
    , count(*) as encounter_count
    , count(distinct person_id) as patient_count
    , sum(length_of_stay) as total_inpatient_days
    , avg(cast(length_of_stay as {{ dbt.type_numeric() }})) as avg_length_of_stay
    , avg(case when los_high_outlier_flag = 0 then cast(length_of_stay as {{ dbt.type_numeric() }}) end)
        as avg_length_of_stay_excl_high_outliers
    , max(length_of_stay) as max_length_of_stay
    , sum(paid_amount) as total_paid_amount
    , avg(paid_amount) as avg_paid_amount
    , avg(case when cost_high_outlier_flag = 0 then paid_amount end)
        as avg_paid_amount_excl_high_outliers
    , sum(allowed_amount) as total_allowed_amount
    , avg(allowed_amount) as avg_allowed_amount
    , sum(los_high_outlier_flag) as los_high_outlier_count
    , sum(los_low_outlier_flag) as los_low_outlier_count
    , sum(cost_high_outlier_flag) as cost_high_outlier_count
    , sum(cost_low_outlier_flag) as cost_low_outlier_count
    , sum(outlier_flag) as outlier_encounter_count
    , cast(sum(outlier_flag) as {{ dbt.type_numeric() }}) / count(*) as outlier_rate
    , sum(case when outlier_flag = 1 then paid_amount else 0 end) as outlier_paid_amount
from encounters
group by coalesce(drg_peer_group_id, 'unknown')

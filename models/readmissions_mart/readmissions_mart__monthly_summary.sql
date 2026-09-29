{{ config(
     enabled = var('readmissions_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool
   )
}}

with index_admission as (
    select
          cast({{ dbt.date_trunc('month', 'discharge_date') }} as date) as discharge_month
        , readmit_30_flag
        , unplanned_readmit_30_flag
    from {{ ref('readmissions_mart__index_admission') }}
)

select
      discharge_month
    , count(*) as index_admission_count
    , sum(readmit_30_flag) as readmit_30_count
    , sum(unplanned_readmit_30_flag) as unplanned_readmit_30_count
    , cast(sum(unplanned_readmit_30_flag) as {{ dbt.type_float() }})
        / cast(count(*) as {{ dbt.type_float() }}) as unplanned_readmit_30_rate
from index_admission
group by discharge_month

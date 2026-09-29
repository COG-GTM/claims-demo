{{ config(
     enabled = var('readmissions_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool
   )
}}

select
      coalesce(index_exclusion_reason, 'index admission') as index_status
    , count(*) as encounter_count
from {{ ref('readmissions_mart__encounter') }}
group by coalesce(index_exclusion_reason, 'index admission')

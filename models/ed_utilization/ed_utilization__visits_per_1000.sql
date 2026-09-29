{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

select
      year_month
    , payer
    , {{ the_tuva_project.quote_column('plan') }}
    , data_source
    , count(*) as member_months
    , sum(ed_visits) as ed_visits
    , cast(sum(ed_visits) as {{ dbt.type_numeric() }}) * 1000
        / count(*) as ed_visits_per_1000_member_months
from {{ ref('ed_utilization__member_month_visits') }}
group by
      year_month
    , payer
    , {{ the_tuva_project.quote_column('plan') }}
    , data_source

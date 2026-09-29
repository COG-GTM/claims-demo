{{ config(
     schema = 'risk_adjustment',
     tags = ['tuva_demo', 'risk_adjustment'],
     enabled = var('claims_enabled', False) | as_bool
   )
}}

with member_months as (

    select
          person_id
        , payer
        , cast(substring(cast(year_month as {{ dbt.type_string() }}), 1, 4) as {{ dbt.type_int() }}) as member_year
        , cast(year_month as {{ dbt.type_string() }}) as year_month
    from {{ ref('core__member_months') }}

)

select
      cast(person_id as {{ dbt.type_string() }}) as person_id
    , cast(payer as {{ dbt.type_string() }}) as payer
    , member_year
    , cast(count(distinct year_month) as {{ dbt.type_int() }}) as member_months
    , min(year_month) as first_year_month
    , max(year_month) as last_year_month
from member_months
group by
      person_id
    , payer
    , member_year

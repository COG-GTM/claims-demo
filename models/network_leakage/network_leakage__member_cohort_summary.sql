{{ config(materialized='table') }}

with claim_line as (
    select * from {{ ref('network_leakage__claim_line') }}
)

, cohort as (
    select
          service_year
        , payer
        , plan_name
        , age_band
        , sex
        , count(*) as claim_line_count
        , count(distinct person_id) as member_count
        , count(distinct case when network_status = 'out_of_network' then person_id end)
            as out_of_network_member_count
        , sum(case when network_status = 'in_network' then paid_amount else 0 end)
            as in_network_paid_amount
        , sum(case when network_status = 'out_of_network' then paid_amount else 0 end)
            as out_of_network_paid_amount
        , sum(case when network_status = 'unknown' then paid_amount else 0 end)
            as unknown_network_paid_amount
        , sum(paid_amount) as total_paid_amount
        , sum(case when network_status = 'in_network' then allowed_amount else 0 end)
            as in_network_allowed_amount
        , sum(case when network_status = 'out_of_network' then allowed_amount else 0 end)
            as out_of_network_allowed_amount
        , sum(allowed_amount) as total_allowed_amount
        , sum(case when network_status = 'out_of_network' then 1 else 0 end)
            as out_of_network_claim_line_count
    from claim_line
    group by
          service_year
        , payer
        , plan_name
        , age_band
        , sex
)

select
      service_year
    , payer
    , plan_name
    , age_band
    , sex
    , member_count
    , out_of_network_member_count
    , claim_line_count
    , out_of_network_claim_line_count
    , in_network_paid_amount
    , out_of_network_paid_amount
    , unknown_network_paid_amount
    , total_paid_amount
    , in_network_allowed_amount
    , out_of_network_allowed_amount
    , total_allowed_amount
    , cast(out_of_network_paid_amount as {{ dbt.type_numeric() }})
        / nullif(in_network_paid_amount + out_of_network_paid_amount, 0) as leakage_rate_paid
    , cast(out_of_network_allowed_amount as {{ dbt.type_numeric() }})
        / nullif(in_network_allowed_amount + out_of_network_allowed_amount, 0) as leakage_rate_allowed
    , cast(unknown_network_paid_amount as {{ dbt.type_numeric() }})
        / nullif(total_paid_amount, 0) as unknown_network_paid_share
    , cast(out_of_network_paid_amount as {{ dbt.type_numeric() }})
        / nullif(member_count, 0) as out_of_network_paid_per_member
from cohort

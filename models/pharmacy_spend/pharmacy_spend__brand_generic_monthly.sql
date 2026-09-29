{{ config(materialized='table') }}

with by_category as (
    select
          dispensing_month
        , brand_generic_category
        , count(*) as claim_line_count
        , count(distinct person_id) as person_count
        , sum(paid_amount) as paid_amount
        , sum(allowed_amount) as allowed_amount
        , sum(quantity) as quantity
        , sum(days_supply) as days_supply
        , sum(case when generic_available_flag = 1 then paid_amount else 0 end)
            as brand_with_generic_available_paid_amount
        , sum(generic_opportunity_amount) as generic_opportunity_amount
    from {{ ref('pharmacy_spend__claim_line') }}
    group by
          dispensing_month
        , brand_generic_category
)

, month_totals as (
    select
          dispensing_month
        , sum(paid_amount) as month_paid_amount
        , sum(claim_line_count) as month_claim_line_count
    from by_category
    group by dispensing_month
)

select
      c.dispensing_month
    , c.brand_generic_category
    , c.claim_line_count
    , c.person_count
    , c.paid_amount
    , c.allowed_amount
    , c.quantity
    , c.days_supply
    , c.brand_with_generic_available_paid_amount
    , c.generic_opportunity_amount
    , c.paid_amount / nullif(c.claim_line_count, 0) as paid_per_claim_line
    , c.paid_amount / nullif(c.days_supply, 0) as paid_per_day_supply
    , c.paid_amount / nullif(t.month_paid_amount, 0) as share_of_month_paid
    , cast(c.claim_line_count as {{ dbt.type_numeric() }})
        / nullif(t.month_claim_line_count, 0) as share_of_month_claim_lines
from by_category as c
inner join month_totals as t
    on c.dispensing_month = t.dispensing_month

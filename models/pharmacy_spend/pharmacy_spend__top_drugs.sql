{{ config(materialized='table') }}

with drug_totals as (
    select
          drug_key
        , max(drug_name) as drug_name
        , count(*) as claim_line_count
        , count(distinct person_id) as person_count
        , sum(paid_amount) as paid_amount
        , sum(allowed_amount) as allowed_amount
        , sum(quantity) as quantity
        , sum(days_supply) as days_supply
        , sum(case when brand_generic_category = 'brand' then paid_amount else 0 end) as brand_paid_amount
        , sum(case when brand_generic_category = 'generic' then paid_amount else 0 end) as generic_paid_amount
        , sum(case when brand_generic_category = 'unmapped' then paid_amount else 0 end) as unmapped_paid_amount
        , sum(case when brand_generic_category = 'brand' then 1 else 0 end) as brand_claim_line_count
        , sum(case when brand_generic_category = 'generic' then 1 else 0 end) as generic_claim_line_count
        , sum(generic_opportunity_amount) as generic_opportunity_amount
    from {{ ref('pharmacy_spend__claim_line') }}
    group by drug_key
)

, overall as (
    select sum(paid_amount) as total_paid_amount
    from drug_totals
)

, ranked as (
    select
          d.*
        , d.paid_amount / nullif(o.total_paid_amount, 0) as share_of_total_paid
        , row_number() over (
            order by d.paid_amount desc, d.claim_line_count desc, d.drug_key
          ) as spend_rank
    from drug_totals as d
    cross join overall as o
)

select
      spend_rank
    , drug_key
    , drug_name
    , claim_line_count
    , person_count
    , paid_amount
    , allowed_amount
    , quantity
    , days_supply
    , brand_paid_amount
    , generic_paid_amount
    , unmapped_paid_amount
    , brand_claim_line_count
    , generic_claim_line_count
    , cast(generic_claim_line_count as {{ dbt.type_numeric() }})
        / nullif(brand_claim_line_count + generic_claim_line_count, 0) as generic_dispensing_rate
    , generic_opportunity_amount
    , paid_amount / nullif(claim_line_count, 0) as paid_per_claim_line
    , share_of_total_paid
    , sum(share_of_total_paid) over (
        order by spend_rank
        rows between unbounded preceding and current row
      ) as cumulative_share_of_total_paid
    , case when spend_rank <= {{ var('pharmacy_spend_top_n', 25) }} then 1 else 0 end as is_top_n
from ranked

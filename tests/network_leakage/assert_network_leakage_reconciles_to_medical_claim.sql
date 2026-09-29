-- Cohort summary spend and line counts tie back to core__medical_claim.
with source as (
    select
          count(*) as claim_line_count
        , sum(coalesce(paid_amount, 0)) as paid_amount
        , sum(coalesce(allowed_amount, 0)) as allowed_amount
    from {{ ref('core__medical_claim') }}
)

, mart as (
    select
          sum(claim_line_count) as claim_line_count
        , sum(total_paid_amount) as paid_amount
        , sum(total_allowed_amount) as allowed_amount
    from {{ ref('network_leakage__member_cohort_summary') }}
)

select *
from source
cross join mart
where source.claim_line_count <> mart.claim_line_count
   or abs(source.paid_amount - mart.paid_amount) > 0.01
   or abs(source.allowed_amount - mart.allowed_amount) > 0.01

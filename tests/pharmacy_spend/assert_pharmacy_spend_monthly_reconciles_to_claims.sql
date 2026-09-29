-- Monthly brand/generic mart must account for every paid dollar in the claim-line base.
with mart as (
    select sum(paid_amount) as paid_amount, sum(claim_line_count) as claim_line_count
    from {{ ref('pharmacy_spend__brand_generic_monthly') }}
)

, base as (
    select sum(coalesce(paid_amount, 0)) as paid_amount, count(*) as claim_line_count
    from {{ ref('pharmacy__pharmacy_claim_expanded') }}
)

select mart.*, base.paid_amount as base_paid_amount, base.claim_line_count as base_claim_line_count
from mart
cross join base
where abs(coalesce(mart.paid_amount, 0) - coalesce(base.paid_amount, 0)) > 0.01
   or coalesce(mart.claim_line_count, 0) <> coalesce(base.claim_line_count, 0)

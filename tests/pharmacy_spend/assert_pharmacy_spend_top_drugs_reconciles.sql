-- Drug rollup must reconcile to the claim-line base, and brand + generic + unmapped must equal total per drug.
with split_mismatch as (
    select drug_key
    from {{ ref('pharmacy_spend__top_drugs') }}
    where abs(paid_amount - (brand_paid_amount + generic_paid_amount + unmapped_paid_amount)) > 0.01
)

, total_mismatch as (
    select 'total' as drug_key
    from (select sum(paid_amount) as paid_amount from {{ ref('pharmacy_spend__top_drugs') }}) as mart
    cross join (select sum(paid_amount) as paid_amount from {{ ref('pharmacy_spend__claim_line') }}) as base
    where abs(coalesce(mart.paid_amount, 0) - coalesce(base.paid_amount, 0)) > 0.01
)

select drug_key from split_mismatch
union all
select drug_key from total_mismatch

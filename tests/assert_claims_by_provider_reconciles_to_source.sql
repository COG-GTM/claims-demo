-- Total paid in claims_by_provider must equal paid on all source claim lines
-- that have an attributable provider NPI.
with source_paid as (

    select sum(paid_amount) as paid_amount
    from (
        select paid_amount
        from {{ ref('medical_claim') }}
        where coalesce(rendering_npi, billing_npi) is not null

        union all

        select paid_amount
        from {{ ref('pharmacy_claim') }}
        where prescribing_provider_npi is not null
    ) as attributed_lines

),

mart_paid as (

    select sum(total_paid_amount) as paid_amount
    from {{ ref('claims_by_provider') }}

)

select
      source_paid.paid_amount as source_paid_amount
    , mart_paid.paid_amount as mart_paid_amount
from source_paid
cross join mart_paid
where abs(coalesce(source_paid.paid_amount, 0) - coalesce(mart_paid.paid_amount, 0)) > 0.01

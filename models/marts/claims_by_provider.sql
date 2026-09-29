{{ config(
    schema='marts',
    materialized='table',
    tags=['tuva_demo']
) }}

with medical_claims as (

    select
          coalesce(rendering_npi, billing_npi) as provider_npi
        , claim_id
        , person_id
        , paid_amount
        , allowed_amount
    from {{ ref('medical_claim') }}

),

pharmacy_claims as (

    select
          prescribing_provider_npi as provider_npi
        , claim_id
        , person_id
        , paid_amount
        , allowed_amount
    from {{ ref('pharmacy_claim') }}

),

claim_lines as (

    select
          provider_npi
        , 'medical' as claim_source
        , claim_id
        , person_id
        , paid_amount
        , allowed_amount
    from medical_claims
    where provider_npi is not null

    union all

    select
          provider_npi
        , 'pharmacy' as claim_source
        , claim_id
        , person_id
        , paid_amount
        , allowed_amount
    from pharmacy_claims
    where provider_npi is not null

)

select
      provider_npi
    , cast(coalesce(sum(paid_amount), 0) as {{ dbt.type_numeric() }}) as total_paid_amount
    , cast(coalesce(sum(allowed_amount), 0) as {{ dbt.type_numeric() }}) as total_allowed_amount
    , cast(coalesce(sum(case when claim_source = 'medical' then paid_amount end), 0) as {{ dbt.type_numeric() }}) as medical_paid_amount
    , cast(coalesce(sum(case when claim_source = 'pharmacy' then paid_amount end), 0) as {{ dbt.type_numeric() }}) as pharmacy_paid_amount
    , count(distinct case when claim_source = 'medical' then claim_id end)
      + count(distinct case when claim_source = 'pharmacy' then claim_id end) as claim_count
    , count(distinct case when claim_source = 'medical' then claim_id end) as medical_claim_count
    , count(distinct case when claim_source = 'pharmacy' then claim_id end) as pharmacy_claim_count
    , count(distinct person_id) as distinct_member_count
from claim_lines
group by provider_npi

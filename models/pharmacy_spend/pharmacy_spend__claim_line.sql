{{ config(materialized='view') }}

select
      data_source
    , claim_id
    , claim_line_number
    , person_id
    , cast({{ dbt.date_trunc('month', 'dispensing_date') }} as date) as dispensing_month
    , ndc_code
    , rxcui
    , coalesce(generic_rxcui, rxcui, ndc_code) as drug_key
    , coalesce(generic_rxcui_description, ingredient_name, ndc_description, ndc_code, 'unknown') as drug_name
    , ingredient_name
    , brand_name
    , case
        when brand_vs_generic = 'generic' then 'generic'
        when brand_vs_generic = 'brand' then 'brand'
        else 'unmapped'
      end as brand_generic_category
    , case
        when generic_available = 'brand_with_generic_available' then 1
        else 0
      end as generic_available_flag
    , coalesce(paid_amount, 0) as paid_amount
    , coalesce(allowed_amount, 0) as allowed_amount
    , coalesce(quantity, 0) as quantity
    , coalesce(days_supply, 0) as days_supply
    , coalesce(generic_available_total_opportunity, 0) as generic_opportunity_amount
from {{ ref('pharmacy__pharmacy_claim_expanded') }}

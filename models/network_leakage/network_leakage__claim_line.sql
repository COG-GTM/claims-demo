{{ config(materialized='view') }}

with medical_claim as (
    select
          data_source
        , claim_id
        , claim_line_number
        , claim_type
        , person_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }} as plan_name
        , coalesce(claim_start_date, claim_line_start_date, claim_end_date) as service_date
        , in_network_flag
        , coalesce(paid_amount, 0) as paid_amount
        , coalesce(allowed_amount, 0) as allowed_amount
    from {{ ref('core__medical_claim') }}
)

, patient as (
    select
          person_id
        , sex
        , birth_date
    from {{ ref('core__patient') }}
)

, joined as (
    select
          medical_claim.data_source
        , medical_claim.claim_id
        , medical_claim.claim_line_number
        , medical_claim.claim_type
        , medical_claim.person_id
        , medical_claim.payer
        , medical_claim.plan_name
        , medical_claim.service_date
        {% if target.type == 'fabric' %}
        , year(medical_claim.service_date) as service_year
        {% else %}
        , cast(extract(year from medical_claim.service_date) as {{ dbt.type_int() }}) as service_year
        {% endif %}
        , coalesce(patient.sex, 'unknown') as sex
        , cast(
            floor({{ dbt.datediff('patient.birth_date', 'medical_claim.service_date', 'day') }} / 365.25)
            as {{ dbt.type_int() }}
          ) as age_at_service
        , case
            when medical_claim.in_network_flag = 1 then 'in_network'
            when medical_claim.in_network_flag = 0 then 'out_of_network'
            else 'unknown'
          end as network_status
        , medical_claim.paid_amount
        , medical_claim.allowed_amount
    from medical_claim
    left join patient
        on medical_claim.person_id = patient.person_id
)

select
      data_source
    , claim_id
    , claim_line_number
    , claim_type
    , person_id
    , payer
    , plan_name
    , service_date
    , service_year
    , sex
    , age_at_service
    , case
        when age_at_service is null then 'unknown'
        when age_at_service < 18 then '0-17'
        when age_at_service < 45 then '18-44'
        when age_at_service < 65 then '45-64'
        when age_at_service < 75 then '65-74'
        when age_at_service < 85 then '75-84'
        else '85+'
      end as age_band
    , network_status
    , paid_amount
    , allowed_amount
from joined

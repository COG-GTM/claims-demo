{{ config(
     schema = 'risk_adjustment',
     tags = ['tuva_demo', 'risk_adjustment'],
     enabled = var('claims_enabled', False) | as_bool
   )
}}
/*
    One row per member (person_id + payer) and calendar year with at least
    one enrolled month. Members with no HCCs are retained with zero counts.
*/

with member_years as (

    select
          person_id
        , payer
        , member_year
        , member_months
        , first_year_month
        , last_year_month
    from {{ ref('risk_adjustment__int_member_years') }}

)

, hcc_rollup as (

    select
          person_id
        , payer
        , member_year
        , count(*) as hcc_count
        , sum(coalesce(reference_coefficient, 0)) as raw_disease_score
        , sum(supporting_diagnosis_count) as supporting_diagnosis_count
    from {{ ref('risk_adjustment__member_year_hccs') }}
    group by
          person_id
        , payer
        , member_year

)

select
      member_years.person_id
    , member_years.payer
    , member_years.member_year
    , cast('{{ var('risk_adjustment_model_version', 'CMS-HCC-V28') }}' as {{ dbt.type_string() }}) as model_version
    , member_years.member_months
    , member_years.first_year_month
    , member_years.last_year_month
    , cast(coalesce(hcc_rollup.hcc_count, 0) as {{ dbt.type_int() }}) as hcc_count
    , cast(coalesce(hcc_rollup.supporting_diagnosis_count, 0) as {{ dbt.type_int() }}) as supporting_diagnosis_count
    , cast(coalesce(hcc_rollup.raw_disease_score, 0) as {{ dbt.type_numeric() }}) as raw_disease_score
    , cast(case
        when coalesce(hcc_rollup.hcc_count, 0) = 0 then '0'
        when hcc_rollup.hcc_count = 1 then '1'
        when hcc_rollup.hcc_count <= 3 then '2-3'
        when hcc_rollup.hcc_count <= 5 then '4-5'
        else '6+'
      end as {{ dbt.type_string() }}) as hcc_count_band
from member_years
    left outer join hcc_rollup
        on member_years.person_id = hcc_rollup.person_id
        and member_years.payer = hcc_rollup.payer
        and member_years.member_year = hcc_rollup.member_year

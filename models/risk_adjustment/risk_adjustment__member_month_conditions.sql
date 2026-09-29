{{ config(
    schema='risk_adjustment',
    materialized='table',
    tags=['tuva_demo', 'risk_adjustment']
) }}

with member_months as (

    select
          member_month_key
        , person_id
        , member_id
        , year_month
        , payer
        , {{ the_tuva_project.quote_column('plan') }} as plan_name
        , data_source
        , cast(
            {{ dbt.concat([
                "substring(year_month, 1, 4)",
                "'-'",
                "substring(year_month, 5, 2)",
                "'-01'"
            ]) }}
            as date
          ) as month_start_date
    from {{ ref('core__member_months') }}

),

category_map as (

    select
          icd_10_cm_prefix
        , condition_category
        , condition_category_description
        , hierarchy_group
        , hierarchy_rank
        , relative_factor
    from {{ ref('risk_adjustment__condition_category_map') }}

),

diagnoses as (

    select
          person_id
        , normalized_code
        , recorded_date
        , cast({{ dbt.date_trunc('month', 'recorded_date') }} as date) as diagnosis_month_start_date
    from {{ ref('core__condition') }}
    where normalized_code_type = 'icd-10-cm'
      and normalized_code is not null
      and recorded_date is not null
      and person_id is not null

),

person_category_months as (

    select
          diagnoses.person_id
        , category_map.condition_category
        , category_map.condition_category_description
        , category_map.hierarchy_group
        , category_map.hierarchy_rank
        , category_map.relative_factor
        , diagnoses.diagnosis_month_start_date
        , max(diagnoses.recorded_date) as most_recent_diagnosis_date
        , count(*) as diagnosis_count
    from diagnoses
    inner join category_map
      on diagnoses.normalized_code like {{ dbt.concat(["category_map.icd_10_cm_prefix", "'%'"]) }}
    group by
          diagnoses.person_id
        , category_map.condition_category
        , category_map.condition_category_description
        , category_map.hierarchy_group
        , category_map.hierarchy_rank
        , category_map.relative_factor
        , diagnoses.diagnosis_month_start_date

),

member_month_categories as (

    select
          member_months.member_month_key
        , member_months.person_id
        , member_months.member_id
        , member_months.year_month
        , member_months.payer
        , member_months.plan_name
        , member_months.data_source
        , person_category_months.condition_category
        , person_category_months.condition_category_description
        , person_category_months.hierarchy_group
        , person_category_months.hierarchy_rank
        , person_category_months.relative_factor
        , max(person_category_months.most_recent_diagnosis_date) as most_recent_diagnosis_date
        , sum(person_category_months.diagnosis_count) as diagnosis_count
    from member_months
    inner join person_category_months
      on member_months.person_id = person_category_months.person_id
     and person_category_months.diagnosis_month_start_date
         between {{ risk_adjustment_lookback_start_date('member_months.month_start_date') }}
             and member_months.month_start_date
    group by
          member_months.member_month_key
        , member_months.person_id
        , member_months.member_id
        , member_months.year_month
        , member_months.payer
        , member_months.plan_name
        , member_months.data_source
        , person_category_months.condition_category
        , person_category_months.condition_category_description
        , person_category_months.hierarchy_group
        , person_category_months.hierarchy_rank
        , person_category_months.relative_factor

),

hierarchy_applied as (

    select
          member_month_categories.*
        , row_number() over (
            partition by member_month_key, hierarchy_group
            order by hierarchy_rank, condition_category
          ) as hierarchy_row_num
    from member_month_categories

)

select
      member_month_key
    , person_id
    , member_id
    , year_month
    , payer
    , plan_name as {{ the_tuva_project.quote_column('plan') }}
    , data_source
    , condition_category
    , condition_category_description
    , hierarchy_group
    , hierarchy_rank
    , relative_factor
    , most_recent_diagnosis_date
    , cast(diagnosis_count as {{ dbt.type_int() }}) as diagnosis_count
    , cast({{ risk_adjustment_lookback_months() }} as {{ dbt.type_int() }}) as lookback_months
from hierarchy_applied
where hierarchy_row_num = 1

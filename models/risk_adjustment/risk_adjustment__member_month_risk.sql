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
    from {{ ref('core__member_months') }}

),

member_month_conditions as (

    select
          member_month_key
        , condition_category
        , relative_factor
    from {{ ref('risk_adjustment__member_month_conditions') }}

)

select
      member_months.member_month_key
    , member_months.person_id
    , member_months.member_id
    , member_months.year_month
    , member_months.payer
    , member_months.plan_name as {{ the_tuva_project.quote_column('plan') }}
    , member_months.data_source
{%- for category in risk_adjustment_condition_categories() %}
    , cast(max(case when member_month_conditions.condition_category = '{{ category.category }}' then 1 else 0 end) as {{ dbt.type_int() }}) as {{ category.category }}_flag
{%- endfor %}
    , cast(count(member_month_conditions.condition_category) as {{ dbt.type_int() }}) as condition_category_count
    , cast(coalesce(sum(member_month_conditions.relative_factor), 0) as {{ dbt.type_numeric() }}) as condition_risk_score
from member_months
left join member_month_conditions
  on member_months.member_month_key = member_month_conditions.member_month_key
group by
      member_months.member_month_key
    , member_months.person_id
    , member_months.member_id
    , member_months.year_month
    , member_months.payer
    , member_months.plan_name
    , member_months.data_source

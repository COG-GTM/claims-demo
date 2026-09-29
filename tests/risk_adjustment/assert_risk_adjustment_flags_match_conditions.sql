{{ config(tags=['risk_adjustment']) }}
-- Flags must be 0/1 and reconcile with the long-form conditions model.
with conditions as (

    select
          member_month_key
        , count(*) as condition_category_count
        , sum(relative_factor) as condition_risk_score
    from {{ ref('risk_adjustment__member_month_conditions') }}
    group by member_month_key

),

risk as (

    select
          member_month_key
        , condition_category_count
        , condition_risk_score
        , 0
        {%- for category in risk_adjustment_condition_categories() %}
          + {{ category.category }}_flag
        {%- endfor %} as flag_total
        , case when
        {%- for category in risk_adjustment_condition_categories() %}
            {{ category.category }}_flag not in (0, 1){% if not loop.last %} or{% endif %}
        {%- endfor %}
          then 1 else 0 end as has_invalid_flag
    from {{ ref('risk_adjustment__member_month_risk') }}

)

select
      risk.member_month_key
    , risk.condition_category_count
    , risk.flag_total
    , risk.condition_risk_score
    , conditions.condition_risk_score as expected_condition_risk_score
from risk
left join conditions
  on risk.member_month_key = conditions.member_month_key
where risk.has_invalid_flag = 1
   or risk.flag_total <> risk.condition_category_count
   or risk.condition_category_count <> coalesce(conditions.condition_category_count, 0)
   or abs(risk.condition_risk_score - coalesce(conditions.condition_risk_score, 0)) > 0.0001

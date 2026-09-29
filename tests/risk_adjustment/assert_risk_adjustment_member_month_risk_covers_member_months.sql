{{ config(tags=['risk_adjustment']) }}
-- Every core member month must appear in the risk model, including months without conditions.
select
      coalesce(member_months.member_month_key, member_month_risk.member_month_key) as member_month_key
    , member_months.member_month_key as core_member_month_key
    , member_month_risk.member_month_key as risk_member_month_key
from {{ ref('core__member_months') }} as member_months
full outer join {{ ref('risk_adjustment__member_month_risk') }} as member_month_risk
  on member_months.member_month_key = member_month_risk.member_month_key
where member_months.member_month_key is null
   or member_month_risk.member_month_key is null

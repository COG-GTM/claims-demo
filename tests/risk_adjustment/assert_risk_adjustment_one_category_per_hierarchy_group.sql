{{ config(tags=['risk_adjustment']) }}
-- After hierarchies are applied a member month can hold at most one category per hierarchy group.
select
      member_month_key
    , hierarchy_group
    , count(*) as category_count
from {{ ref('risk_adjustment__member_month_conditions') }}
group by
      member_month_key
    , hierarchy_group
having count(*) > 1

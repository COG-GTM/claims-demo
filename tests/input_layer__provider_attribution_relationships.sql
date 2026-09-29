-- Relationship checks for input_layer__provider_attribution, equivalent to
-- dbt `relationships` tests on person_id and member_id -> eligibility.

select
      'person_id' as failing_column
    , attribution.person_id
    , attribution.member_id
from {{ ref('input_layer__provider_attribution') }} as attribution
left join {{ ref('eligibility') }} as eligibility
  on attribution.person_id = eligibility.person_id
where attribution.person_id is not null
  and eligibility.person_id is null

union all

select
      'member_id' as failing_column
    , attribution.person_id
    , attribution.member_id
from {{ ref('input_layer__provider_attribution') }} as attribution
left join {{ ref('eligibility') }} as eligibility
  on attribution.member_id = eligibility.member_id
where attribution.member_id is not null
  and eligibility.member_id is null

-- Numerators must never exceed their denominators.
select *
from {{ ref('chronic_conditions_prevalence') }}
where members_with_condition > eligible_members
   or newly_diagnosed_members > members_with_condition

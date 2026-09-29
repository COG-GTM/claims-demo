-- A member's first qualifying diagnosis cannot be after their last one.
select *
from {{ ref('int_chronic_conditions') }}
where first_diagnosis_date > last_diagnosis_date

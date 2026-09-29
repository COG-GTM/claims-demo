-- Every member-condition row must satisfy the documented qualification rule:
-- the first qualifying code belongs to that condition in the Tuva grouper, and
-- the member has at least `chronic_conditions_min_diagnosis_dates` qualifying dates.
select icc.*
from {{ ref('int_chronic_conditions') }} as icc
left join {{ ref('chronic_conditions__tuva_chronic_conditions_hierarchy') }} as grp
    on icc.first_qualifying_icd_10_cm_code = grp.icd_10_cm_code
    and icc.condition = grp.condition
    and icc.condition_family = grp.condition_family
where grp.icd_10_cm_code is null
   or icc.diagnosis_date_count < {{ var('chronic_conditions_min_diagnosis_dates', 1) | int }}
   or icc.distinct_icd_10_cm_code_count < 1

-- Every member with a dated ICD-10-CM diagnosis in the Tuva grouper must appear
-- for that condition (when the minimum-date threshold is the default of 1).
{{ config(enabled = (var('chronic_conditions_min_diagnosis_dates', 1) | int) == 1) }}

with expected as (
    select distinct
          cond.person_id
        , grp.condition
    from {{ ref('core__condition') }} as cond
    inner join {{ ref('chronic_conditions__tuva_chronic_conditions_hierarchy') }} as grp
        on cond.normalized_code = grp.icd_10_cm_code
    where cond.normalized_code_type = 'icd-10-cm'
      and cond.recorded_date is not null
)

select expected.*
from expected
left join {{ ref('int_chronic_conditions') }} as icc
    on expected.person_id = icc.person_id
    and expected.condition = icc.condition
where icc.person_id is null

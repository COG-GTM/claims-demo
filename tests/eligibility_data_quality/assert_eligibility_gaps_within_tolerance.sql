{{ config(severity='warn', tags=['tuva_demo', 'eligibility_data_quality']) }}

select *
from {{ ref('eligibility_dq__span_issues') }}
where issue_type = 'gap'
  and exceeds_tolerance_flag = 1

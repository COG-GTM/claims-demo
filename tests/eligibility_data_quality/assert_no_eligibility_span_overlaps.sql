{{ config(severity='error', tags=['tuva_demo', 'eligibility_data_quality']) }}

select *
from {{ ref('eligibility_dq__span_issues') }}
where issue_type = 'overlap'

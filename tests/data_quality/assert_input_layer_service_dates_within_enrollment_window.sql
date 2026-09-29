{{ config(severity='warn', tags=['tuva_demo', 'data_quality']) }}

-- Service dates outside the eligibility window cannot be attached to member months,
-- so they drop out of (or distort) any rate-based trend.
select *
from {{ ref('data_quality__input_layer_date_freshness') }}
where date_role = 'service'
  and source_table <> 'eligibility'
  and (
        days_min_date_before_enrollment_window > 0
     or days_max_date_after_enrollment_window > 0
  )

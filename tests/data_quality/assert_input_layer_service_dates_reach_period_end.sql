{{ config(severity='error', tags=['tuva_demo', 'data_quality']) }}

-- Service-date columns must be populated and reach the configured analysis period end.
-- Fails when the seeds and the period vars (quality_measures_period_end / cms_hcc_payment_year) drift apart.
select *
from {{ ref('data_quality__input_layer_date_freshness') }}
where date_role = 'service'
  and period_coverage_status in ('missing', 'short_of_period_end')

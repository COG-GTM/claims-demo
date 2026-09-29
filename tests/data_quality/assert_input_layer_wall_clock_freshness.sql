{{ config(severity='warn', tags=['tuva_demo', 'data_quality']) }}

-- Service and ingest dates older than data_freshness_stale_after_days relative to as_of_date.
-- Always warns on the static synthetic dataset; intended to fail loudly once real feeds are wired in.
select *
from {{ ref('data_quality__input_layer_date_freshness') }}
where date_role in ('service', 'ingest')
  and wall_clock_status <> 'fresh'

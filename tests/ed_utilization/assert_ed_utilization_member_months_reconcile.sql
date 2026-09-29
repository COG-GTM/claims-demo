{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool,
     tags = ['ed_utilization']
   )
}}

-- Denominator must match core.member_months exactly.
with mart as (
    select sum(member_months) as member_months
    from {{ ref('ed_utilization__visits_per_1000') }}
)

, core as (
    select count(*) as member_months
    from {{ ref('the_tuva_project', 'core__member_months') }}
)

select
      mart.member_months as mart_member_months
    , core.member_months as core_member_months
from mart
cross join core
where coalesce(mart.member_months, 0) <> core.member_months

{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool,
     tags = ['ed_utilization']
   )
}}

-- Numerator must equal ED encounters in core.encounter that fall in an
-- enrolled month, counted once per concurrent member month (payer/plan).
with calendar as (
    select
          full_date
        , {{ dbt.concat([
              "cast(year as " ~ dbt.type_string() ~ ")",
              dbt.right(dbt.concat(["'0'", "cast(month as " ~ dbt.type_string() ~ ")"]), 2)
          ]) }} as year_month
    from {{ ref('the_tuva_project', 'reference_data__calendar') }}
)

, mm_per_person_month as (
    select
          person_id
        , year_month
        , data_source
        , count(*) as concurrent_member_months
    from {{ ref('the_tuva_project', 'core__member_months') }}
    group by
          person_id
        , year_month
        , data_source
)

, expected as (
    select sum(mm.concurrent_member_months) as expected_ed_visits
    from {{ ref('the_tuva_project', 'core__encounter') }} as enc
    inner join calendar as cal
        on enc.encounter_start_date = cal.full_date
    inner join mm_per_person_month as mm
        on enc.person_id = mm.person_id
        and cal.year_month = mm.year_month
        and enc.data_source = mm.data_source
    where enc.encounter_type = 'emergency department'
)

, mart as (
    select sum(ed_visits) as ed_visits
    from {{ ref('ed_utilization__visits_per_1000') }}
)

select
      mart.ed_visits
    , expected.expected_ed_visits
from mart
cross join expected
where coalesce(mart.ed_visits, 0) <> coalesce(expected.expected_ed_visits, 0)

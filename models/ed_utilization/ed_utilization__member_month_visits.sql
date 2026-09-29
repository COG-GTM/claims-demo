{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

with calendar as (
    select
          full_date
        , {{ dbt.concat([
              "cast(year as " ~ dbt.type_string() ~ ")",
              dbt.right(dbt.concat(["'0'", "cast(month as " ~ dbt.type_string() ~ ")"]), 2)
          ]) }} as year_month
    from {{ ref('the_tuva_project', 'reference_data__calendar') }}
)

, ed_visits as (
    select
          enc.person_id
        , enc.data_source
        , cal.year_month
        , count(distinct enc.encounter_id) as ed_visits
    from {{ ref('the_tuva_project', 'core__encounter') }} as enc
    inner join calendar as cal
        on enc.encounter_start_date = cal.full_date
    where enc.encounter_type = 'emergency department'
    group by
          enc.person_id
        , enc.data_source
        , cal.year_month
)

select
      mm.member_month_key
    , mm.person_id
    , mm.member_id
    , mm.year_month
    , mm.payer
    , mm.{{ the_tuva_project.quote_column('plan') }}
    , mm.data_source
    , coalesce(ed.ed_visits, 0) as ed_visits
from {{ ref('the_tuva_project', 'core__member_months') }} as mm
left outer join ed_visits as ed
    on mm.person_id = ed.person_id
    and mm.year_month = ed.year_month
    and mm.data_source = ed.data_source

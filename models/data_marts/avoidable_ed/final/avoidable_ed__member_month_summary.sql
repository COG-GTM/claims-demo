{{ config(
     enabled = var('avoidable_ed_enabled', var('ed_classification_enabled', var('claims_enabled', var('tuva_marts_enabled', False)))) | as_bool
   )
}}

{%- set avoidable_classifications = var('avoidable_ed_classifications', ['noner', 'epct', 'edcnpa']) -%}
{%- set avoidable_list -%}
    ('{{ avoidable_classifications | join("', '") }}')
{%- endset -%}

with ed_visits as (

    select
          person_id
        , year_month
        , count(distinct encounter_id) as ed_visits
        , sum(coalesce(paid_amount, 0)) as ed_paid_amount
        , sum(coalesce(allowed_amount, 0)) as ed_allowed_amount
    from {{ ref('avoidable_ed__stg_ed_encounter') }}
    group by
          person_id
        , year_month

),

classified_visits as (

    select
          person_id
        , year_month
        , count(distinct encounter_id) as classified_ed_visits
        , count(distinct case when classification in {{ avoidable_list }} then encounter_id end) as avoidable_ed_visits
        , count(distinct case when classification = 'noner' then encounter_id end) as non_emergent_ed_visits
        , count(distinct case when classification = 'epct' then encounter_id end) as primary_care_treatable_ed_visits
        , count(distinct case when classification = 'edcnpa' then encounter_id end) as preventable_ed_visits
        , sum(case when classification in {{ avoidable_list }} then coalesce(paid_amount, 0) else 0 end) as avoidable_ed_paid_amount
        , sum(case when classification in {{ avoidable_list }} then coalesce(allowed_amount, 0) else 0 end) as avoidable_ed_allowed_amount
    from {{ ref('avoidable_ed__stg_ed_classification') }}
    group by
          person_id
        , year_month

),

member_months as (

    select
          person_id
        , year_month
    from {{ ref('avoidable_ed__stg_member_months') }}

),

person_month_spine as (

    select person_id, year_month from member_months
    union
    select person_id, year_month from ed_visits

)

select
      spine.person_id
    , spine.year_month
    , case when member_months.person_id is not null then 1 else 0 end as enrolled_flag
    , coalesce(ed_visits.ed_visits, 0) as ed_visits
    , coalesce(classified_visits.classified_ed_visits, 0) as classified_ed_visits
    , coalesce(classified_visits.avoidable_ed_visits, 0) as avoidable_ed_visits
    , coalesce(classified_visits.non_emergent_ed_visits, 0) as non_emergent_ed_visits
    , coalesce(classified_visits.primary_care_treatable_ed_visits, 0) as primary_care_treatable_ed_visits
    , coalesce(classified_visits.preventable_ed_visits, 0) as preventable_ed_visits
    , case when coalesce(classified_visits.avoidable_ed_visits, 0) > 0 then 1 else 0 end as avoidable_ed_visit_flag
    , coalesce(ed_visits.ed_paid_amount, 0) as ed_paid_amount
    , coalesce(ed_visits.ed_allowed_amount, 0) as ed_allowed_amount
    , coalesce(classified_visits.avoidable_ed_paid_amount, 0) as avoidable_ed_paid_amount
    , coalesce(classified_visits.avoidable_ed_allowed_amount, 0) as avoidable_ed_allowed_amount
    , cast('{{ var('tuva_last_run', run_started_at.astimezone(modules.pytz.timezone("UTC"))) }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from person_month_spine as spine
left outer join member_months
    on spine.person_id = member_months.person_id
    and spine.year_month = member_months.year_month
left outer join ed_visits
    on spine.person_id = ed_visits.person_id
    and spine.year_month = ed_visits.year_month
left outer join classified_visits
    on spine.person_id = classified_visits.person_id
    and spine.year_month = classified_visits.year_month

/*
    Denominator patients removed from the eligible population. Exclusion events with a null
    lookback_months count from any point in history through the performance period end; those
    with a lookback (e.g. hospice, lookback 0) must fall inside that window.

    Unilateral mastectomies only exclude from BCS when both a left and a right mastectomy are
    found (together equivalent to a bilateral mastectomy).
*/

with exclusion_events as (

    select
          denominator.person_id
        , denominator.measure_id
        , events.event_date
        , events.concept_name
    from {{ ref('preventive_care__int_denominator') }} as denominator
    inner join {{ ref('preventive_care__int_coded_events') }} as events
        on denominator.person_id = events.person_id
        and denominator.measure_id = events.measure_id
    where events.value_set_type = 'exclusion'
        and events.event_date <= denominator.performance_period_end
        and (
            events.lookback_months is null
            or {{ dbt.datediff('events.event_date', 'denominator.performance_period_begin', 'month') }} <= events.lookback_months
        )

)

, single_event_exclusions as (

    select
          person_id
        , measure_id
        , event_date
        , concept_name
    from exclusion_events
    where concept_name not in ('unilateral mastectomy left', 'unilateral mastectomy right')

)

, left_and_right_mastectomy as (

    select
          person_id
        , measure_id
        , max(event_date) as event_date
        , 'bilateral mastectomy (left and right unilateral)' as concept_name
    from exclusion_events
    where concept_name in ('unilateral mastectomy left', 'unilateral mastectomy right')
    group by
          person_id
        , measure_id
    having count(distinct concept_name) = 2

)

, all_exclusions as (

    select * from single_event_exclusions
    union all
    select * from left_and_right_mastectomy

)

, ranked as (

    select
          person_id
        , measure_id
        , event_date
        , concept_name
        , row_number() over (
            partition by person_id, measure_id
            order by event_date desc, concept_name
          ) as exclusion_rank
    from all_exclusions

)

select
      cast(person_id as {{ dbt.type_string() }}) as person_id
    , cast(measure_id as {{ dbt.type_string() }}) as measure_id
    , cast(event_date as date) as exclusion_date
    , cast(concept_name as {{ dbt.type_string() }}) as exclusion_reason
    , cast(1 as integer) as exclusion_flag
from ranked
where exclusion_rank = 1

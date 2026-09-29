/*
    Denominator patients with a qualifying screening event. An event qualifies when it falls
    between the concept's lookback start (lookback_months before the performance period begin)
    and the performance period end, and the patient met the concept's minimum age on the event
    date. The most recent qualifying event is kept as evidence.
*/

with qualifying_events as (

    select
          denominator.person_id
        , denominator.measure_id
        , events.event_date
        , events.concept_name
    from {{ ref('preventive_care__int_denominator') }} as denominator
    inner join {{ ref('preventive_care__int_coded_events') }} as events
        on denominator.person_id = events.person_id
        and denominator.measure_id = events.measure_id
    where events.value_set_type = 'numerator'
        and events.event_date <= denominator.performance_period_end
        and {{ dbt.datediff('events.event_date', 'denominator.performance_period_begin', 'month') }} <= events.lookback_months
        and (
            events.min_age_at_event is null
            or {{ preventive_care_age('denominator.birth_date', 'events.event_date') }} >= events.min_age_at_event
        )

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
          ) as event_rank
    from qualifying_events

)

select
      cast(person_id as {{ dbt.type_string() }}) as person_id
    , cast(measure_id as {{ dbt.type_string() }}) as measure_id
    , cast(event_date as date) as numerator_evidence_date
    , cast(concept_name as {{ dbt.type_string() }}) as numerator_reason
    , cast(1 as integer) as numerator_flag
from ranked
where event_rank = 1

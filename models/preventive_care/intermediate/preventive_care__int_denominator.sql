/*
    Initial population per measure: living patients whose age at the end of the performance
    period and sex meet the measure criteria, and who were continuously enrolled during the
    performance period (at most preventive_care_max_enrollment_gap_days uncovered days).
*/

with performance_period as (

    select
          performance_period_begin
        , performance_period_end
    from {{ ref('preventive_care__int_performance_period') }}

)

, patients as (

    select
          patient.person_id
        , lower(patient.sex) as sex
        , patient.birth_date
        , {{ preventive_care_age('patient.birth_date', 'performance_period.performance_period_end') }} as age
    from {{ ref('core__patient') }} as patient
    cross join performance_period
    where patient.birth_date is not null
        and (
            patient.death_date is null
            or patient.death_date > performance_period.performance_period_end
        )

)

, enrollment_spans as (

    select distinct
          eligibility.person_id
        , case
            when eligibility.enrollment_start_date < performance_period.performance_period_begin
                then performance_period.performance_period_begin
            else eligibility.enrollment_start_date
          end as span_start
        , case
            when eligibility.enrollment_end_date is null
                or eligibility.enrollment_end_date > performance_period.performance_period_end
                then performance_period.performance_period_end
            else eligibility.enrollment_end_date
          end as span_end
    from {{ ref('core__eligibility') }} as eligibility
    cross join performance_period
    where eligibility.enrollment_start_date <= performance_period.performance_period_end
        and (
            eligibility.enrollment_end_date is null
            or eligibility.enrollment_end_date >= performance_period.performance_period_begin
        )

)

, continuously_enrolled as (

    select
          enrollment_spans.person_id
    from enrollment_spans
    cross join performance_period
    group by
          enrollment_spans.person_id
        , performance_period.performance_period_begin
        , performance_period.performance_period_end
    having sum({{ dbt.datediff('enrollment_spans.span_start', 'enrollment_spans.span_end', 'day') }} + 1)
        >= {{ dbt.datediff('performance_period.performance_period_begin', 'performance_period.performance_period_end', 'day') }} + 1
            - {{ var('preventive_care_max_enrollment_gap_days', 45) }}

)

select
      cast(patients.person_id as {{ dbt.type_string() }}) as person_id
    , cast(measures.measure_id as {{ dbt.type_string() }}) as measure_id
    , cast(patients.birth_date as date) as birth_date
    , cast(patients.age as integer) as age
    , cast(patients.sex as {{ dbt.type_string() }}) as sex
    , cast(performance_period.performance_period_begin as date) as performance_period_begin
    , cast(performance_period.performance_period_end as date) as performance_period_end
    , cast(1 as integer) as denominator_flag
from patients
inner join continuously_enrolled
    on patients.person_id = continuously_enrolled.person_id
cross join performance_period
inner join {{ ref('preventive_care__measures') }} as measures
    on patients.age between measures.min_age and measures.max_age
    and (measures.required_sex is null or patients.sex = measures.required_sex)

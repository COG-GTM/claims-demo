/*
    One row per denominator patient per measure. Excluded patients keep their numerator
    evidence for reference but never count toward the numerator.
*/

select
      denominator.person_id
    , denominator.measure_id
    , measures.measure_name
    , denominator.performance_period_begin
    , denominator.performance_period_end
    , denominator.age
    , denominator.sex
    , denominator.denominator_flag
    , cast(coalesce(exclusions.exclusion_flag, 0) as integer) as exclusion_flag
    , exclusions.exclusion_reason
    , exclusions.exclusion_date
    , cast(
        case
            when exclusions.exclusion_flag = 1 then 0
            else coalesce(numerator.numerator_flag, 0)
        end as integer
      ) as numerator_flag
    , numerator.numerator_reason
    , numerator.numerator_evidence_date
    , cast(
        case
            when exclusions.exclusion_flag = 1 then 'excluded'
            when numerator.numerator_flag = 1 then 'met'
            else 'not met'
        end as {{ dbt.type_string() }}
      ) as performance_status
    , cast('{{ var('tuva_last_run', run_started_at.astimezone(modules.pytz.timezone('UTC'))) }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from {{ ref('preventive_care__int_denominator') }} as denominator
inner join {{ ref('preventive_care__measures') }} as measures
    on denominator.measure_id = measures.measure_id
left join {{ ref('preventive_care__int_exclusions') }} as exclusions
    on denominator.person_id = exclusions.person_id
    and denominator.measure_id = exclusions.measure_id
left join {{ ref('preventive_care__int_numerator') }} as numerator
    on denominator.person_id = numerator.person_id
    and denominator.measure_id = numerator.measure_id

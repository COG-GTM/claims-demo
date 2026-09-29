/*
    Measure-level results. performance_rate = numerator_count / eligible_population_count,
    where the eligible population is the denominator minus exclusions.
*/

with performance_period as (

    select
          performance_period_begin
        , performance_period_end
    from {{ ref('preventive_care__int_performance_period') }}

)

, counts as (

    select
          measure_id
        , count(*) as denominator_count
        , sum(exclusion_flag) as exclusion_count
        , sum(numerator_flag) as numerator_count
    from {{ ref('preventive_care__patient_measures') }}
    group by measure_id

)

, measure_counts as (

    select
          measures.measure_id
        , measures.measure_name
        , measures.reference_specification
        , performance_period.performance_period_begin
        , performance_period.performance_period_end
        , coalesce(counts.denominator_count, 0) as denominator_count
        , coalesce(counts.exclusion_count, 0) as exclusion_count
        , coalesce(counts.denominator_count, 0) - coalesce(counts.exclusion_count, 0) as eligible_population_count
        , coalesce(counts.numerator_count, 0) as numerator_count
    from {{ ref('preventive_care__measures') }} as measures
    cross join performance_period
    left join counts
        on measures.measure_id = counts.measure_id

)

select
      measure_id
    , measure_name
    , reference_specification
    , performance_period_begin
    , performance_period_end
    , cast(denominator_count as integer) as denominator_count
    , cast(exclusion_count as integer) as exclusion_count
    , cast(eligible_population_count as integer) as eligible_population_count
    , cast(numerator_count as integer) as numerator_count
    , cast(
        round(
            cast(numerator_count as {{ dbt.type_numeric() }})
            / nullif(cast(eligible_population_count as {{ dbt.type_numeric() }}), 0)
        , 4)
        as {{ dbt.type_numeric() }}
      ) as performance_rate
    , cast('{{ var('tuva_last_run', run_started_at.astimezone(modules.pytz.timezone('UTC'))) }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from measure_counts

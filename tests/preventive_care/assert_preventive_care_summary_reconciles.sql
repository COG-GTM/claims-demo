/*
    Measure-level counts must reconcile with patient-level results and stay internally
    consistent: exclusions and numerator never exceed the denominator / eligible population,
    and the performance rate is between 0 and 1.
*/

with patient_counts as (

    select
          measure_id
        , count(*) as denominator_count
        , sum(exclusion_flag) as exclusion_count
        , sum(numerator_flag) as numerator_count
    from {{ ref('preventive_care__patient_measures') }}
    group by measure_id

)

select
      summary.measure_id
    , summary.denominator_count
    , summary.exclusion_count
    , summary.eligible_population_count
    , summary.numerator_count
    , summary.performance_rate
from {{ ref('preventive_care__summary') }} as summary
left join patient_counts
    on summary.measure_id = patient_counts.measure_id
where summary.denominator_count <> coalesce(patient_counts.denominator_count, 0)
    or summary.exclusion_count <> coalesce(patient_counts.exclusion_count, 0)
    or summary.numerator_count <> coalesce(patient_counts.numerator_count, 0)
    or summary.exclusion_count > summary.denominator_count
    or summary.eligible_population_count <> summary.denominator_count - summary.exclusion_count
    or summary.numerator_count > summary.eligible_population_count
    or summary.performance_rate < 0
    or summary.performance_rate > 1
    or (summary.eligible_population_count > 0 and summary.performance_rate is null)

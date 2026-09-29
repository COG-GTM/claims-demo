-- Every condition produced by the Tuva chronic conditions grouper must be reported for every year.
with years as (
    select distinct prevalence_year
    from {{ ref('chronic_conditions_prevalence') }}
)

, grouper_conditions as (
    select distinct condition
    from {{ ref('chronic_conditions__tuva_chronic_conditions_long') }}
)

select
      years.prevalence_year
    , grouper_conditions.condition
from years
cross join grouper_conditions
left join {{ ref('chronic_conditions_prevalence') }} as prevalence
    on years.prevalence_year = prevalence.prevalence_year
    and grouper_conditions.condition = prevalence.condition
where prevalence.condition is null

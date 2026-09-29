-- eligible_members must equal the distinct enrolled members for each year in core__member_months.
with expected as (
    select
          cast(substring(year_month, 1, 4) as {{ dbt.type_int() }}) as prevalence_year
        , count(distinct person_id) as eligible_members
    from {{ ref('core__member_months') }}
    group by cast(substring(year_month, 1, 4) as {{ dbt.type_int() }})
)

, actual as (
    select distinct
          prevalence_year
        , eligible_members
    from {{ ref('chronic_conditions_prevalence') }}
)

select
      coalesce(expected.prevalence_year, actual.prevalence_year) as prevalence_year
    , expected.eligible_members as expected_eligible_members
    , actual.eligible_members as actual_eligible_members
from expected
full outer join actual
    on expected.prevalence_year = actual.prevalence_year
    and expected.eligible_members = actual.eligible_members
where expected.prevalence_year is null
   or actual.prevalence_year is null

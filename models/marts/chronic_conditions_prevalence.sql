{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

with enrolled_member_years as (
    select distinct
          person_id
        , cast(substring(year_month, 1, 4) as {{ dbt.type_int() }}) as prevalence_year
    from {{ ref('core__member_months') }}
)

, eligible_members as (
    select
          prevalence_year
        , count(distinct person_id) as eligible_members
    from enrolled_member_years
    group by prevalence_year
)

, grouped_conditions as (
    select
          person_id
        , condition
        {% if target.type == 'fabric' %}
        , cast(year(first_diagnosis_date) as {{ dbt.type_int() }}) as first_diagnosis_year
        {% else %}
        , cast(extract(year from first_diagnosis_date) as {{ dbt.type_int() }}) as first_diagnosis_year
        {% endif %}
    from {{ ref('chronic_conditions__tuva_chronic_conditions_long') }}
)

, condition_member_counts as (
    select
          enrolled_member_years.prevalence_year
        , grouped_conditions.condition
        , count(distinct grouped_conditions.person_id) as members_with_condition
        , count(distinct case
            when grouped_conditions.first_diagnosis_year = enrolled_member_years.prevalence_year
            then grouped_conditions.person_id
          end) as newly_diagnosed_members
    from grouped_conditions
    inner join enrolled_member_years
        on grouped_conditions.person_id = enrolled_member_years.person_id
        and grouped_conditions.first_diagnosis_year <= enrolled_member_years.prevalence_year
    group by
          enrolled_member_years.prevalence_year
        , grouped_conditions.condition
)

, condition_list as (
    select distinct condition
    from grouped_conditions
)

, prevalence as (
    select
          eligible_members.prevalence_year
        , condition_list.condition
        , eligible_members.eligible_members
        , coalesce(condition_member_counts.members_with_condition, 0) as members_with_condition
        , coalesce(condition_member_counts.newly_diagnosed_members, 0) as newly_diagnosed_members
    from eligible_members
    cross join condition_list
    left join condition_member_counts
        on eligible_members.prevalence_year = condition_member_counts.prevalence_year
        and condition_list.condition = condition_member_counts.condition
)

select
      prevalence_year
    , condition
    , eligible_members
    , members_with_condition
    , newly_diagnosed_members
    , round(
        cast(members_with_condition as {{ dbt.type_numeric() }})
        / cast(eligible_members as {{ dbt.type_numeric() }})
      , 6) as prevalence_rate
    , round(
        cast(members_with_condition as {{ dbt.type_numeric() }}) * 1000
        / cast(eligible_members as {{ dbt.type_numeric() }})
      , 2) as prevalence_per_1000
    , dense_rank() over (
        partition by prevalence_year
        order by members_with_condition desc
      ) as prevalence_rank
    , cast('{{ var('tuva_last_run', run_started_at.astimezone(modules.pytz.timezone('UTC'))) }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from prevalence

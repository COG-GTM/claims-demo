with source as (

    select
          cast(data_source as {{ dbt.type_string() }}) as data_source
        , cast(person_id as {{ dbt.type_string() }}) as person_id
        , cast(member_id as {{ dbt.type_string() }}) as member_id
        , cast(payer as {{ dbt.type_string() }}) as payer
        , cast({{ the_tuva_project.quote_column('plan') }} as {{ dbt.type_string() }}) as {{ the_tuva_project.quote_column('plan') }}
        , cast(enrollment_start_date as date) as enrollment_start_date
        , cast(enrollment_end_date as date) as enrollment_end_date
        , cast(death_date as date) as death_date
    from {{ ref('eligibility') }}
    where person_id is not null
      and enrollment_start_date is not null

)

, as_of as (

    select coalesce(max(enrollment_end_date), max(enrollment_start_date)) as as_of_date
    from source

)

, bounded as (

    select
          source.data_source
        , source.person_id
        , source.member_id
        , source.payer
        , source.{{ the_tuva_project.quote_column('plan') }}
        , source.enrollment_start_date as span_start_date
        , case
            when source.death_date is not null
             and source.death_date < coalesce(source.enrollment_end_date, as_of.as_of_date)
                then source.death_date
            else coalesce(source.enrollment_end_date, as_of.as_of_date)
          end as span_end_date
        , case when source.enrollment_end_date is null then 1 else 0 end as open_ended_flag
        , case
            when source.death_date is not null
             and source.death_date < coalesce(source.enrollment_end_date, as_of.as_of_date)
                then 1
            else 0
          end as death_truncated_flag
    from source
    cross join as_of

)

, valid as (

    select *
    from bounded
    where span_end_date >= span_start_date

)

, ordered as (

    select
          valid.*
        , max(span_end_date) over (
            partition by data_source, person_id, payer, {{ the_tuva_project.quote_column('plan') }}
            order by span_start_date, span_end_date
            rows between unbounded preceding and 1 preceding
          ) as prior_max_end_date
    from valid

)

, flagged as (

    select
          ordered.*
        , case
            when prior_max_end_date is null then 1
            when span_start_date > cast({{ dbt.dateadd('day', 1, 'prior_max_end_date') }} as date) then 1
            else 0
          end as new_span_flag
    from ordered

)

, numbered as (

    select
          flagged.*
        , sum(new_span_flag) over (
            partition by data_source, person_id, payer, {{ the_tuva_project.quote_column('plan') }}
            order by span_start_date, span_end_date
            rows between unbounded preceding and current row
          ) as enrollment_span_number
    from flagged

)

select
      data_source
    , person_id
    , max(member_id) as member_id
    , payer
    , {{ the_tuva_project.quote_column('plan') }}
    , enrollment_span_number
    , min(span_start_date) as enrollment_start_date
    , max(span_end_date) as enrollment_end_date
    , count(*) as source_span_count
    , max(open_ended_flag) as open_ended_flag
    , max(death_truncated_flag) as death_truncated_flag
from numbered
group by
      data_source
    , person_id
    , payer
    , {{ the_tuva_project.quote_column('plan') }}
    , enrollment_span_number

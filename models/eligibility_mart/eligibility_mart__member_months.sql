with spans as (

    select *
    from {{ ref('eligibility_mart__enrollment_spans') }}

)

, months as (

    select distinct
          replace(year_month, '-', '') as year_month
        , first_day_of_month
        , last_day_of_month
    from {{ ref('reference_data__calendar') }}

)

, span_months as (

    select
          spans.data_source
        , spans.person_id
        , spans.member_id
        , spans.payer
        , spans.{{ the_tuva_project.quote_column('plan') }}
        , months.year_month
        , months.first_day_of_month
        , months.last_day_of_month
        , case
            when spans.enrollment_start_date > months.first_day_of_month then spans.enrollment_start_date
            else months.first_day_of_month
          end as covered_start_date
        , case
            when spans.enrollment_end_date < months.last_day_of_month then spans.enrollment_end_date
            else months.last_day_of_month
          end as covered_end_date
    from spans
    inner join months
        on spans.enrollment_start_date <= months.last_day_of_month
       and spans.enrollment_end_date >= months.first_day_of_month

)

, aggregated as (

    select
          data_source
        , person_id
        , max(member_id) as member_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }}
        , year_month
        , first_day_of_month
        , last_day_of_month
        , min(covered_start_date) as first_covered_date
        , max(covered_end_date) as last_covered_date
        , sum({{ dbt.datediff('covered_start_date', 'covered_end_date', 'day') }} + 1) as covered_days
    from span_months
    group by
          data_source
        , person_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }}
        , year_month
        , first_day_of_month
        , last_day_of_month

)

, measured as (

    select
          aggregated.*
        , {{ dbt.datediff('first_day_of_month', 'last_day_of_month', 'day') }} + 1 as days_in_month
    from aggregated

)

select
      data_source
    , person_id
    , member_id
    , payer
    , {{ the_tuva_project.quote_column('plan') }}
    , year_month
    , first_day_of_month
    , last_day_of_month
    , first_covered_date
    , last_covered_date
    , covered_days
    , days_in_month
    , cast(covered_days as {{ dbt.type_float() }}) / days_in_month as member_month_fraction
    , case when covered_days = days_in_month then 1 else 0 end as full_month_flag
    , case when first_covered_date = first_day_of_month then 1 else 0 end as enrolled_first_of_month_flag
    , 1 as member_month
from measured

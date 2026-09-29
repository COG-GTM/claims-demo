with spans as (

    select
          data_source
        , person_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }}
        , max(member_id) as member_id
        , min(enrollment_start_date) as first_enrollment_date
        , max(enrollment_end_date) as last_enrollment_date
        , count(*) as enrollment_span_count
        , sum(source_span_count) as source_span_count
        , sum({{ dbt.datediff('enrollment_start_date', 'enrollment_end_date', 'day') }} + 1) as covered_days
        , max(open_ended_flag) as open_ended_flag
        , max(death_truncated_flag) as death_truncated_flag
    from {{ ref('eligibility_mart__enrollment_spans') }}
    group by
          data_source
        , person_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }}

)

, member_months as (

    select
          data_source
        , person_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }}
        , min(year_month) as first_year_month
        , max(year_month) as last_year_month
        , sum(member_month) as member_months
        , sum(full_month_flag) as full_member_months
        , sum(member_month) - sum(full_month_flag) as partial_member_months
        , sum(member_month_fraction) as prorated_member_months
    from {{ ref('eligibility_mart__member_months') }}
    group by
          data_source
        , person_id
        , payer
        , {{ the_tuva_project.quote_column('plan') }}

)

select
      spans.data_source
    , spans.person_id
    , spans.member_id
    , spans.payer
    , spans.{{ the_tuva_project.quote_column('plan') }}
    , spans.first_enrollment_date
    , spans.last_enrollment_date
    , member_months.first_year_month
    , member_months.last_year_month
    , spans.source_span_count
    , spans.enrollment_span_count
    , spans.enrollment_span_count - 1 as coverage_gap_count
    , case when spans.enrollment_span_count = 1 then 1 else 0 end as continuous_enrollment_flag
    , spans.covered_days
    , member_months.member_months
    , member_months.full_member_months
    , member_months.partial_member_months
    , member_months.prorated_member_months
    , spans.open_ended_flag
    , spans.death_truncated_flag
from spans
inner join member_months
    on spans.data_source = member_months.data_source
   and spans.person_id = member_months.person_id
   and spans.payer = member_months.payer
   and spans.{{ the_tuva_project.quote_column('plan') }} = member_months.{{ the_tuva_project.quote_column('plan') }}

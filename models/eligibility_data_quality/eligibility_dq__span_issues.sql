{{ config(materialized='table') }}

with spans as (

    select
          person_id
        , member_id
        , payer
        , plan
        , data_source
        , enrollment_start_date
        , enrollment_end_date
    from {{ ref('eligibility') }}
    where enrollment_start_date is not null
      and enrollment_end_date is not null

)

, sequenced as (

    select
          person_id
        , member_id
        , payer
        , plan
        , data_source
        , enrollment_start_date
        , enrollment_end_date
        , max(enrollment_end_date) over (
            partition by person_id, member_id, payer, plan, data_source
            order by enrollment_start_date, enrollment_end_date
            rows between unbounded preceding and 1 preceding
          ) as prior_max_end_date
    from spans

)

, classified as (

    select
          person_id
        , member_id
        , payer
        , plan
        , data_source
        , enrollment_start_date
        , enrollment_end_date
        , prior_max_end_date
        , case
            when enrollment_start_date <= prior_max_end_date then 'overlap'
            else 'gap'
          end as issue_type
        , case
            when enrollment_start_date > prior_max_end_date then
                {{ dbt.datediff('prior_max_end_date', 'enrollment_start_date', 'day') }} - 1
            when enrollment_end_date < prior_max_end_date then
                {{ dbt.datediff('enrollment_start_date', 'enrollment_end_date', 'day') }} + 1
            else
                {{ dbt.datediff('enrollment_start_date', 'prior_max_end_date', 'day') }} + 1
          end as issue_days
    from sequenced
    where prior_max_end_date is not null

)

select
      person_id
    , member_id
    , payer
    , plan
    , data_source
    , enrollment_start_date
    , enrollment_end_date
    , prior_max_end_date
    , issue_type
    , issue_days
    , case
        when issue_type = 'overlap' then 1
        when issue_days > {{ var('eligibility_gap_tolerance_days', 45) }} then 1
        else 0
      end as exceeds_tolerance_flag
from classified
where issue_days > 0

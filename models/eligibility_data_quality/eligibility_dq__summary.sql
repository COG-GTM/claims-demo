{{ config(materialized='table') }}

with checks as (

    select 'eligibility_span_overlap' as check_name, 'overlap' as issue_type, 'error' as severity
    union all
    select 'eligibility_span_gap', 'gap', 'warn'

)

, members as (

    select count(distinct person_id) as members_evaluated
    from {{ ref('eligibility') }}

)

, issues as (

    select
          issue_type
        , count(*) as spans_flagged
        , count(distinct person_id) as members_flagged
        , sum(exceeds_tolerance_flag) as spans_exceeding_tolerance
        , count(distinct case when exceeds_tolerance_flag = 1 then person_id end) as members_exceeding_tolerance
        , sum(issue_days) as total_issue_days
        , max(issue_days) as max_issue_days
    from {{ ref('eligibility_dq__span_issues') }}
    group by issue_type

)

select
      checks.check_name
    , checks.issue_type
    , checks.severity
    , case when checks.issue_type = 'gap' then {{ var('eligibility_gap_tolerance_days', 45) }} else 0 end as tolerance_days
    , members.members_evaluated
    , coalesce(issues.spans_flagged, 0) as spans_flagged
    , coalesce(issues.members_flagged, 0) as members_flagged
    , coalesce(issues.spans_exceeding_tolerance, 0) as spans_exceeding_tolerance
    , coalesce(issues.members_exceeding_tolerance, 0) as members_exceeding_tolerance
    , coalesce(issues.total_issue_days, 0) as total_issue_days
    , coalesce(issues.max_issue_days, 0) as max_issue_days
    , case
        when coalesce(issues.spans_exceeding_tolerance, 0) = 0 then 'pass'
        else checks.severity
      end as check_status
    , {{ dbt.current_timestamp() }} as evaluated_at
from checks
cross join members
left join issues
    on checks.issue_type = issues.issue_type

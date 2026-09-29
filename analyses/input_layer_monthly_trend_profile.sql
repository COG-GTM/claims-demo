-- Monthly volume vs. enrolled members across the input layer.
-- Used in docs/data_freshness.md to show how the synthetic date distribution shapes trend analysis.
-- Compile with `dbt compile --select input_layer_monthly_trend_profile` and run the SQL in target/compiled.

with months as (

    select distinct
          cast(first_day_of_month as date) as month_start
        , cast(last_day_of_month as date) as month_end
    from {{ ref('reference_data__calendar') }}
    where full_date between cast('2014-01-01' as date) and cast('{{ var('quality_measures_period_end') }}' as date)

),

member_months as (

    select
          months.month_start
        , count(distinct eligibility.person_id) as enrolled_members
    from months
    inner join {{ ref('eligibility') }} as eligibility
        on eligibility.enrollment_start_date <= months.month_end
       and eligibility.enrollment_end_date >= months.month_start
    group by months.month_start

),

medical as (

    select
          cast({{ dbt.date_trunc('month', 'claim_end_date') }} as date) as month_start
        , count(distinct claim_id) as medical_claims
        , sum(paid_amount) as medical_paid
    from {{ ref('medical_claim') }}
    group by 1

),

pharmacy as (

    select
          cast({{ dbt.date_trunc('month', 'dispensing_date') }} as date) as month_start
        , count(distinct claim_id) as pharmacy_claims
        , sum(paid_amount) as pharmacy_paid
    from {{ ref('pharmacy_claim') }}
    group by 1

),

labs as (

    select
          cast({{ dbt.date_trunc('month', 'collection_datetime') }} as date) as month_start
        , count(*) as lab_results
    from {{ ref('lab_result') }}
    group by 1

),

observations as (

    select
          cast({{ dbt.date_trunc('month', 'observation_date') }} as date) as month_start
        , count(*) as observations
    from {{ ref('observation') }}
    group by 1

)

select
      months.month_start
    , coalesce(member_months.enrolled_members, 0) as enrolled_members
    , coalesce(medical.medical_claims, 0) as medical_claims
    , coalesce(medical.medical_paid, 0) as medical_paid
    , coalesce(pharmacy.pharmacy_claims, 0) as pharmacy_claims
    , coalesce(pharmacy.pharmacy_paid, 0) as pharmacy_paid
    , coalesce(labs.lab_results, 0) as lab_results
    , coalesce(observations.observations, 0) as observations
    , case when member_months.enrolled_members > 0
        then 1000.0 * medical.medical_claims / member_months.enrolled_members
      end as medical_claims_per_1000_members
    , case when member_months.enrolled_members > 0
        then medical.medical_paid / member_months.enrolled_members
      end as medical_paid_pmpm
from (select distinct month_start from months) as months
left join member_months on months.month_start = member_months.month_start
left join medical on months.month_start = medical.month_start
left join pharmacy on months.month_start = pharmacy.month_start
left join labs on months.month_start = labs.month_start
left join observations on months.month_start = observations.month_start
where months.month_start >= cast('2014-09-01' as date)
order by months.month_start

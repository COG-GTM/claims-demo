{{ config(
     tags = ['tuva_demo', 'risk_adjustment'],
     enabled = var('claims_enabled', False) | as_bool
   )
}}
-- Fails for any member year whose summary counts or score disagree with the HCC detail.
with detail as (

    select
          person_id
        , payer
        , member_year
        , count(*) as hcc_count
        , sum(coalesce(reference_coefficient, 0)) as raw_disease_score
    from {{ ref('risk_adjustment__member_year_hccs') }}
    group by
          person_id
        , payer
        , member_year

)

select
      summary.person_id
    , summary.payer
    , summary.member_year
    , summary.hcc_count
    , detail.hcc_count as detail_hcc_count
    , summary.raw_disease_score
    , detail.raw_disease_score as detail_raw_disease_score
from {{ ref('risk_adjustment__member_year_summary') }} as summary
    left outer join detail
        on summary.person_id = detail.person_id
        and summary.payer = detail.payer
        and summary.member_year = detail.member_year
where summary.hcc_count <> coalesce(detail.hcc_count, 0)
    or abs(summary.raw_disease_score - coalesce(detail.raw_disease_score, 0)) > 0.0001

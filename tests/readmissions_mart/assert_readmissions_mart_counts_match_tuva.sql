-- 30-day readmission counts for mart index admissions must match Tuva's
-- readmission summary for the same encounters, counting only Tuva
-- readmissions that start on or after the index discharge date.
with mart as (
    select
          sum(readmit_30_flag) as readmit_30_count
        , sum(unplanned_readmit_30_flag) as unplanned_readmit_30_count
    from {{ ref('readmissions_mart__index_admission') }}
)

, tuva as (
    select
          sum(case when s.days_to_readmit >= 0 then s.readmit_30_flag else 0 end) as readmit_30_count
        , sum(case when s.days_to_readmit >= 0 then s.unplanned_readmit_30_flag else 0 end) as unplanned_readmit_30_count
    from {{ ref('readmissions__readmission_summary') }} as s
    inner join {{ ref('readmissions_mart__index_admission') }} as i
        on s.encounter_id = i.encounter_id
)

select mart.*, tuva.readmit_30_count as tuva_readmit_30_count, tuva.unplanned_readmit_30_count as tuva_unplanned_readmit_30_count
from mart
cross join tuva
where mart.readmit_30_count <> tuva.readmit_30_count
   or mart.unplanned_readmit_30_count <> tuva.unplanned_readmit_30_count

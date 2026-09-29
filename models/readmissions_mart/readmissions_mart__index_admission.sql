{{ config(
     enabled = var('readmissions_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool
   )
}}

with qualified_encounter as (
    select
          encounter_id
        , person_id
        , admit_date
        , discharge_date
        , discharge_disposition_code
        , facility_id
        , drg_code
        , paid_amount
        , length_of_stay
        , planned_flag
        , specialty_cohort
        , diagnosis_ccs
        , index_admission_flag
        , data_source
        , row_number() over (
            partition by person_id
            order by admit_date, discharge_date, encounter_id
          ) as encounter_seq
    from {{ ref('readmissions_mart__encounter') }}
    where exclusion_data_quality_flag = 0
)

, paired as (
    select
          idx.encounter_id
        , idx.person_id
        , idx.admit_date
        , idx.discharge_date
        , idx.discharge_disposition_code
        , idx.facility_id
        , idx.drg_code
        , idx.paid_amount
        , idx.length_of_stay
        , idx.specialty_cohort
        , idx.diagnosis_ccs
        , nxt.encounter_id as next_encounter_id
        , nxt.admit_date as next_admit_date
        , nxt.discharge_date as next_discharge_date
        , nxt.planned_flag as next_planned_flag
        , nxt.diagnosis_ccs as next_diagnosis_ccs
        , nxt.paid_amount as next_paid_amount
        , {{ dbt.datediff('idx.discharge_date', 'nxt.admit_date', 'day') }} as days_to_next_admit
        , idx.data_source
    from qualified_encounter as idx
    left outer join qualified_encounter as nxt
        on idx.person_id = nxt.person_id
        and idx.encounter_seq + 1 = nxt.encounter_seq
    where idx.index_admission_flag = 1
)

, paired_with_window as (
    select
          paired.*
        , case when days_to_next_admit between 0 and 30 then 1 else 0 end as in_window_flag
    from paired
)

select
      encounter_id
    , person_id
    , admit_date
    , discharge_date
    , discharge_disposition_code
    , facility_id
    , drg_code
    , paid_amount
    , length_of_stay
    , specialty_cohort
    , diagnosis_ccs
    , in_window_flag as readmit_30_flag
    , case when in_window_flag = 1 and next_planned_flag = 0 then 1 else 0 end as unplanned_readmit_30_flag
    , case when in_window_flag = 1 then next_encounter_id end as readmission_encounter_id
    , case when in_window_flag = 1 then next_admit_date end as readmission_admit_date
    , case when in_window_flag = 1 then next_discharge_date end as readmission_discharge_date
    , case when in_window_flag = 1 then days_to_next_admit end as days_to_readmit
    , case when in_window_flag = 1 then next_planned_flag end as readmission_planned_flag
    , case when in_window_flag = 1 then next_diagnosis_ccs end as readmission_diagnosis_ccs
    , case when in_window_flag = 1 then next_paid_amount end as readmission_paid_amount
    , data_source
from paired_with_window

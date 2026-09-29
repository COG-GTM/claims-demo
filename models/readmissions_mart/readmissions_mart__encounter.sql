{{ config(
     enabled = var('readmissions_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool
   )
}}

with encounter as (
    select
          encounter_id
        , person_id
        , admit_date
        , discharge_date
        , discharge_disposition_code
        , facility_id
        , drg_code_type
        , drg_code
        , paid_amount
        , length_of_stay
        , planned_flag
        , specialty_cohort
        , diagnosis_ccs
        , disqualified_encounter_flag
        , data_source
    from {{ ref('readmissions__encounter_augmented') }}
)

, exclusion_ccs as (
    select distinct
          ccs_diagnosis_category
        , exclusion_category
    from {{ ref('readmissions__exclusion_ccs_diagnosis_category') }}
)

, lookforward_cutoff as (
    select {{ dbt.dateadd(datepart='day', interval=-30, from_date_or_timestamp='max(discharge_date)') }} as last_eligible_discharge_date
    from encounter
)

, flagged as (
    select
          e.encounter_id
        , e.person_id
        , e.admit_date
        , e.discharge_date
        , e.discharge_disposition_code
        , e.facility_id
        , e.drg_code_type
        , e.drg_code
        , e.paid_amount
        , e.length_of_stay
        , e.planned_flag
        , e.specialty_cohort
        , e.diagnosis_ccs
        , x.exclusion_category as exclusion_ccs_category
        , e.disqualified_encounter_flag as exclusion_data_quality_flag
        , case when e.discharge_disposition_code = '20' then 1 else 0 end as exclusion_died_flag
        , case when e.discharge_disposition_code = '07' then 1 else 0 end as exclusion_left_ama_flag
        , case when e.discharge_disposition_code = '02' then 1 else 0 end as exclusion_acute_transfer_flag
        , case when x.ccs_diagnosis_category is not null then 1 else 0 end as exclusion_diagnosis_category_flag
        , case
            when e.discharge_date is null then 1
            when e.discharge_date > c.last_eligible_discharge_date then 1
            else 0
          end as exclusion_insufficient_lookforward_flag
        , e.data_source
    from encounter as e
    cross join lookforward_cutoff as c
    left outer join exclusion_ccs as x
        on e.diagnosis_ccs = x.ccs_diagnosis_category
)

select
      encounter_id
    , person_id
    , admit_date
    , discharge_date
    , discharge_disposition_code
    , facility_id
    , drg_code_type
    , drg_code
    , paid_amount
    , length_of_stay
    , planned_flag
    , specialty_cohort
    , diagnosis_ccs
    , exclusion_ccs_category
    , exclusion_data_quality_flag
    , exclusion_died_flag
    , exclusion_left_ama_flag
    , exclusion_acute_transfer_flag
    , exclusion_diagnosis_category_flag
    , exclusion_insufficient_lookforward_flag
    , case
        when exclusion_data_quality_flag = 1 then 'data quality'
        when exclusion_died_flag = 1 then 'died during admission'
        when exclusion_left_ama_flag = 1 then 'left against medical advice'
        when exclusion_acute_transfer_flag = 1 then 'transferred to acute care'
        when exclusion_diagnosis_category_flag = 1 then 'excluded diagnosis category'
        when exclusion_insufficient_lookforward_flag = 1 then 'insufficient 30-day lookforward'
      end as index_exclusion_reason
    , case
        when exclusion_data_quality_flag = 0
         and exclusion_died_flag = 0
         and exclusion_left_ama_flag = 0
         and exclusion_acute_transfer_flag = 0
         and exclusion_diagnosis_category_flag = 0
         and exclusion_insufficient_lookforward_flag = 0
        then 1
        else 0
      end as index_admission_flag
    , data_source
from flagged

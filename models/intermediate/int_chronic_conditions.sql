{{ config(
     enabled = var('tuva_chronic_conditions_enabled', var('claims_enabled', var('clinical_enabled', var('tuva_marts_enabled', False)))) | as_bool
   )
}}

{%- set min_diagnosis_dates = var('chronic_conditions_min_diagnosis_dates', 1) | int -%}

with icd_10_cm_diagnoses as (
    select
          person_id
        , claim_id
        , encounter_id
        , recorded_date
        , normalized_code
    from {{ ref('core__condition') }}
    where normalized_code_type = 'icd-10-cm'
      and normalized_code is not null
      and recorded_date is not null
)

, condition_grouper as (
    select
          condition_family
        , condition
        , icd_10_cm_code
    from {{ ref('chronic_conditions__tuva_chronic_conditions_hierarchy') }}
)

, qualifying_diagnoses as (
    select
          dx.person_id
        , grp.condition_family
        , grp.condition
        , dx.normalized_code as icd_10_cm_code
        , dx.recorded_date
        , dx.claim_id
        , dx.encounter_id
    from icd_10_cm_diagnoses as dx
    inner join condition_grouper as grp
        on dx.normalized_code = grp.icd_10_cm_code
)

, first_qualifying_diagnosis as (
    select
          person_id
        , condition
        , icd_10_cm_code
        , row_number() over (
            partition by person_id, condition
            order by recorded_date, icd_10_cm_code
          ) as diagnosis_order
    from qualifying_diagnoses
)

, member_conditions as (
    select
          person_id
        , condition_family
        , condition
        , min(recorded_date) as first_diagnosis_date
        , max(recorded_date) as last_diagnosis_date
        , count(distinct recorded_date) as diagnosis_date_count
        , count(distinct icd_10_cm_code) as distinct_icd_10_cm_code_count
        , count(distinct claim_id) as claim_count
        , count(distinct encounter_id) as encounter_count
    from qualifying_diagnoses
    group by
          person_id
        , condition_family
        , condition
)

select
      mc.person_id
    , mc.condition_family
    , mc.condition
    , mc.first_diagnosis_date
    , mc.last_diagnosis_date
    , fqd.icd_10_cm_code as first_qualifying_icd_10_cm_code
    , mc.diagnosis_date_count
    , mc.distinct_icd_10_cm_code_count
    , mc.claim_count
    , mc.encounter_count
from member_conditions as mc
inner join first_qualifying_diagnosis as fqd
    on mc.person_id = fqd.person_id
    and mc.condition = fqd.condition
    and fqd.diagnosis_order = 1
where mc.diagnosis_date_count >= {{ min_diagnosis_dates }}

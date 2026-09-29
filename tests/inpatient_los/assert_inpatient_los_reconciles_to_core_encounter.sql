{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

-- Encounter counts and paid amounts must reconcile from core.encounter
-- through the encounter-grain mart to the DRG summary.
with core_encounters as (
    select
          count(*) as encounter_count
        , coalesce(sum(paid_amount), 0) as paid_amount
    from {{ ref('the_tuva_project', 'core__encounter') }}
    where encounter_type = 'acute inpatient'
)

, encounter_mart as (
    select
          count(*) as encounter_count
        , coalesce(sum(paid_amount), 0) as paid_amount
    from {{ ref('inpatient_los__encounter_outliers') }}
)

, drg_summary as (
    select
          coalesce(sum(encounter_count), 0) as encounter_count
        , coalesce(sum(total_paid_amount), 0) as paid_amount
    from {{ ref('inpatient_los__drg_summary') }}
)

select
      core_encounters.encounter_count as core_encounter_count
    , encounter_mart.encounter_count as mart_encounter_count
    , drg_summary.encounter_count as summary_encounter_count
    , core_encounters.paid_amount as core_paid_amount
    , encounter_mart.paid_amount as mart_paid_amount
    , drg_summary.paid_amount as summary_paid_amount
from core_encounters
cross join encounter_mart
cross join drg_summary
where core_encounters.encounter_count <> encounter_mart.encounter_count
   or encounter_mart.encounter_count <> drg_summary.encounter_count
   or abs(core_encounters.paid_amount - encounter_mart.paid_amount) > 0.01
   or abs(encounter_mart.paid_amount - drg_summary.paid_amount) > 0.01

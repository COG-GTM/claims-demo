{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

with acute_inpatient as (
    select
          encounter_id
        , person_id
        , data_source
        , encounter_start_date
        , encounter_end_date
        , length_of_stay
        , drg_code_type
        , drg_code
        , drg_description
        , facility_id
        , facility_name
        , admit_type_code
        , admit_type_description
        , discharge_disposition_code
        , discharge_disposition_description
        , cast(paid_amount as {{ dbt.type_numeric() }}) as paid_amount
        , cast(allowed_amount as {{ dbt.type_numeric() }}) as allowed_amount
        , cast(charge_amount as {{ dbt.type_numeric() }}) as charge_amount
    from {{ ref('the_tuva_project', 'core__encounter') }}
    where encounter_type = 'acute inpatient'
)

select
      encounter_id
    , person_id
    , data_source
    , encounter_start_date as admission_date
    , encounter_end_date as discharge_date
    , length_of_stay
    , drg_code_type
    , drg_code
    , drg_description
    , case
        when drg_code is not null
            then {{ dbt.concat(["coalesce(drg_code_type, 'unknown')", "':'", "drg_code"]) }}
      end as drg_peer_group_id
    , facility_id
    , facility_name
    , admit_type_code
    , admit_type_description
    , discharge_disposition_code
    , discharge_disposition_description
    , paid_amount
    , allowed_amount
    , charge_amount
    , case
        when length_of_stay > 0
            then paid_amount / length_of_stay
      end as paid_amount_per_day
from acute_inpatient

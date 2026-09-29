/*
    Every dated clinical code for a person, from claims lines (HCPCS and revenue codes),
    procedures and conditions, mapped to the preventive care value set concepts it belongs to.
    Code types and codes are normalized to the value set conventions (lowercase code system,
    'cpt' folded into 'hcpcs', ICD codes without dots).
*/

with medical_claim_hcpcs as (

    select
          person_id
        , coalesce(claim_line_start_date, claim_start_date, claim_end_date) as event_date
        , 'hcpcs' as code_system
        , hcpcs_code as code
        , 'medical_claim' as event_source
    from {{ ref('core__medical_claim') }}
    where hcpcs_code is not null

)

, medical_claim_revenue_center as (

    select
          person_id
        , coalesce(claim_line_start_date, claim_start_date, claim_end_date) as event_date
        , 'revenue_center' as code_system
        , revenue_center_code as code
        , 'medical_claim' as event_source
    from {{ ref('core__medical_claim') }}
    where revenue_center_code is not null

)

, procedures as (

    select
          person_id
        , procedure_date as event_date
        , lower(coalesce(normalized_code_type, source_code_type)) as code_system
        , coalesce(normalized_code, source_code) as code
        , 'procedure' as event_source
    from {{ ref('core__procedure') }}

)

, conditions as (

    select
          person_id
        , coalesce(recorded_date, onset_date) as event_date
        , lower(coalesce(normalized_code_type, source_code_type)) as code_system
        , coalesce(normalized_code, source_code) as code
        , 'condition' as event_source
    from {{ ref('core__condition') }}

)

, all_events as (

    select * from medical_claim_hcpcs
    union all
    select * from medical_claim_revenue_center
    union all
    select * from procedures
    union all
    select * from conditions

)

, normalized_events as (

    select
          person_id
        , event_date
        , case when code_system = 'cpt' then 'hcpcs' else code_system end as code_system
        , upper(replace(code, '.', '')) as code
        , event_source
    from all_events
    where person_id is not null
        and event_date is not null
        and code is not null

)

select distinct
      cast(normalized_events.person_id as {{ dbt.type_string() }}) as person_id
    , cast(normalized_events.event_date as date) as event_date
    , cast(value_sets.measure_id as {{ dbt.type_string() }}) as measure_id
    , cast(value_sets.value_set_type as {{ dbt.type_string() }}) as value_set_type
    , cast(value_sets.concept_name as {{ dbt.type_string() }}) as concept_name
    , cast(value_sets.lookback_months as integer) as lookback_months
    , cast(value_sets.min_age_at_event as integer) as min_age_at_event
    , cast(normalized_events.event_source as {{ dbt.type_string() }}) as event_source
from normalized_events
inner join {{ ref('preventive_care__value_sets') }} as value_sets
    on normalized_events.code_system = value_sets.code_system
    and normalized_events.code = value_sets.code

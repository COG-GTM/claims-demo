with medical_claim as (
    select * from {{ ref('medical_claim') }}
)

{% set procedure_numbers = range(1, 26) %}

{% for n in procedure_numbers %}
select
      {{ dbt_utils.generate_surrogate_key(['claim_id', 'claim_line_number', "'" ~ n ~ "'"]) }} as procedure_id
    , person_id
    , cast(null as {{ dbt.type_string() }}) as patient_id
    , cast(null as {{ dbt.type_string() }}) as encounter_id
    , claim_id
    , procedure_date_{{ n }} as procedure_date
    , procedure_code_type as source_code_type
    , procedure_code_{{ n }} as source_code
    , cast(null as {{ dbt.type_string() }}) as source_description
    , cast(null as {{ dbt.type_string() }}) as normalized_code_type
    , cast(null as {{ dbt.type_string() }}) as normalized_code
    , cast(null as {{ dbt.type_string() }}) as normalized_description
    , cast(null as {{ dbt.type_string() }}) as modifier_1
    , cast(null as {{ dbt.type_string() }}) as modifier_2
    , cast(null as {{ dbt.type_string() }}) as modifier_3
    , cast(null as {{ dbt.type_string() }}) as modifier_4
    , cast(null as {{ dbt.type_string() }}) as modifier_5
    , rendering_npi as practitioner_id
    , data_source
    , file_name
    , ingest_datetime
    , cast(null as {{ dbt.type_timestamp() }}) as tuva_last_run
from medical_claim
where procedure_code_{{ n }} is not null
{% if not loop.last %}union all{% endif %}
{% endfor %}

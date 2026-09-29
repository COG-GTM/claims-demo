{%- set measures = preventive_care_measure_definitions() -%}

with measures as (

{% for measure in measures %}
    select
          '{{ measure.measure_id }}' as measure_id
        , '{{ measure.measure_name }}' as measure_name
        , '{{ measure.description }}' as measure_description
        , '{{ measure.steward }}' as steward
        , '{{ measure.reference_specification }}' as reference_specification
        , {{ measure.min_age }} as min_age
        , {{ measure.max_age }} as max_age
        , {{ "'" ~ measure.required_sex ~ "'" if measure.required_sex is not none else 'null' }} as required_sex
    {%- if not loop.last %}

    union all
    {% endif %}
{% endfor %}

)

select
      cast(measure_id as {{ dbt.type_string() }}) as measure_id
    , cast(measure_name as {{ dbt.type_string() }}) as measure_name
    , cast(measure_description as {{ dbt.type_string() }}) as measure_description
    , cast(steward as {{ dbt.type_string() }}) as steward
    , cast(reference_specification as {{ dbt.type_string() }}) as reference_specification
    , cast(min_age as integer) as min_age
    , cast(max_age as integer) as max_age
    , cast(required_sex as {{ dbt.type_string() }}) as required_sex
from measures

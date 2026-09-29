{%- set rows = [] -%}
{%- for measure in preventive_care_measure_definitions() -%}
    {%- for concept in measure.concepts -%}
        {%- for code_system, codes in concept.codes.items() -%}
            {%- for code in codes -%}
                {%- do rows.append({
                    'measure_id': measure.measure_id,
                    'value_set_type': concept.value_set_type,
                    'concept_name': concept.concept_name,
                    'code_system': code_system,
                    'code': code,
                    'lookback_months': concept.lookback_months,
                    'min_age_at_event': concept.min_age_at_event
                }) -%}
            {%- endfor -%}
        {%- endfor -%}
    {%- endfor -%}
{%- endfor -%}

with value_sets as (

{% for row in rows %}
    select
          '{{ row.measure_id }}' as measure_id
        , '{{ row.value_set_type }}' as value_set_type
        , '{{ row.concept_name }}' as concept_name
        , '{{ row.code_system }}' as code_system
        , '{{ row.code }}' as code
        , {{ row.lookback_months if row.lookback_months is not none else 'null' }} as lookback_months
        , {{ row.min_age_at_event if row.min_age_at_event is not none else 'null' }} as min_age_at_event
    {%- if not loop.last %}
    union all
    {%- endif %}
{% endfor %}

)

select
      cast(measure_id as {{ dbt.type_string() }}) as measure_id
    , cast(value_set_type as {{ dbt.type_string() }}) as value_set_type
    , cast(concept_name as {{ dbt.type_string() }}) as concept_name
    , cast(code_system as {{ dbt.type_string() }}) as code_system
    , cast(code as {{ dbt.type_string() }}) as code
    , cast(lookback_months as integer) as lookback_months
    , cast(min_age_at_event as integer) as min_age_at_event
from value_sets

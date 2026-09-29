{#
    Age in completed years of a person born on birth_date as of as_of_date.
#}
{% macro preventive_care_age(birth_date, as_of_date) -%}
    (
        {{ preventive_care_date_part('year', as_of_date) }} - {{ preventive_care_date_part('year', birth_date) }}
        - case
            when {{ preventive_care_date_part('month', as_of_date) }} * 100 + {{ preventive_care_date_part('day', as_of_date) }}
                < {{ preventive_care_date_part('month', birth_date) }} * 100 + {{ preventive_care_date_part('day', birth_date) }}
                then 1
            else 0
          end
    )
{%- endmacro %}


{% macro preventive_care_date_part(date_part, date_expression) -%}
    {{ return(adapter.dispatch('preventive_care_date_part')(date_part, date_expression)) }}
{%- endmacro %}

{% macro default__preventive_care_date_part(date_part, date_expression) -%}
    extract({{ date_part }} from {{ date_expression }})
{%- endmacro %}

{% macro fabric__preventive_care_date_part(date_part, date_expression) -%}
    datepart({{ date_part }}, {{ date_expression }})
{%- endmacro %}

{{ config(
     enabled = var('avoidable_ed_enabled', var('ed_classification_enabled', var('claims_enabled', var('tuva_marts_enabled', False)))) | as_bool
   )
}}

select
      encounter_id
    , person_id
    {% if target.type == 'fabric' %}
    , cast(
        year(encounter_end_date) * 100
        + month(encounter_end_date)
        as {{ dbt.type_string() }}
      ) as year_month
    {% else %}
    , cast(
        cast(
            extract(year from encounter_end_date) * 100
            + extract(month from encounter_end_date)
            as {{ dbt.type_int() }}
        ) as {{ dbt.type_string() }}
      ) as year_month
    {% endif %}
    , paid_amount
    , allowed_amount
from {{ ref('the_tuva_project', 'core__encounter') }}
where encounter_type = 'emergency department'

{{ config(
    schema='risk_adjustment',
    tags=['tuva_demo', 'risk_adjustment']
) }}

{% set rows = [] %}
{% for category in risk_adjustment_condition_categories() %}
    {% for prefix in category['icd_10_cm_prefixes'] %}
        {% do rows.append({'prefix': prefix, 'category': category}) %}
    {% endfor %}
{% endfor %}

{% for row in rows %}
select
      cast('{{ row.prefix }}' as {{ dbt.type_string() }}) as icd_10_cm_prefix
    , cast('{{ row.category.category }}' as {{ dbt.type_string() }}) as condition_category
    , cast('{{ row.category.description }}' as {{ dbt.type_string() }}) as condition_category_description
    , cast('{{ row.category.hierarchy_group }}' as {{ dbt.type_string() }}) as hierarchy_group
    , cast({{ row.category.hierarchy_rank }} as {{ dbt.type_int() }}) as hierarchy_rank
    , cast({{ row.category.relative_factor }} as {{ dbt.type_numeric() }}) as relative_factor
{% if not loop.last %}union all{% endif %}
{% endfor %}

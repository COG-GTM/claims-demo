{% macro assert_databricks_delta_relations(fail_on_missing=true) %}

    {% if not execute %}
        {{ return('') }}
    {% endif %}

    {% if target.type != 'databricks' %}
        {% do exceptions.raise_compiler_error(
            "assert_databricks_delta_relations only supports the databricks adapter (target.type is '"
            ~ target.type ~ "')."
        ) %}
    {% endif %}

    {% set materialized_types = ['table', 'incremental', 'snapshot', 'seed'] %}
    {% set checked = [] %}
    {% set missing = [] %}
    {% set non_delta = [] %}

    {% for node in graph.nodes.values() %}
        {% if node.resource_type in ['model', 'seed', 'snapshot']
              and node.config.enabled
              and node.config.materialized in materialized_types %}

            {% set relation = adapter.get_relation(
                database=node.database,
                schema=node.schema,
                identifier=node.alias
            ) %}

            {% if relation is none %}
                {% do missing.append(node.database ~ '.' ~ node.schema ~ '.' ~ node.alias) %}
            {% else %}
                {% set detail = run_query('describe detail ' ~ relation) %}
                {% set format = detail.columns['format'].values()[0] | lower %}
                {% do checked.append(relation | string) %}
                {% if format != 'delta' %}
                    {% do non_delta.append(relation ~ ' (format=' ~ format ~ ')') %}
                {% endif %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {% do log('Checked ' ~ checked | length ~ ' materialized relations in catalog ' ~ target.database, info=true) %}
    {% do log('Delta relations: ' ~ (checked | length - non_delta | length), info=true) %}
    {% do log('Non-delta relations: ' ~ non_delta | length, info=true) %}
    {% do log('Missing relations: ' ~ missing | length, info=true) %}

    {% for item in non_delta %}
        {% do log('  NOT DELTA: ' ~ item, info=true) %}
    {% endfor %}
    {% for item in missing %}
        {% do log('  MISSING: ' ~ item, info=true) %}
    {% endfor %}

    {% if non_delta | length > 0 or (fail_on_missing and missing | length > 0) %}
        {% do exceptions.raise_compiler_error(
            'Databricks validation failed: '
            ~ non_delta | length ~ ' relation(s) are not Delta, '
            ~ missing | length ~ ' relation(s) missing.'
        ) %}
    {% endif %}

{% endmacro %}

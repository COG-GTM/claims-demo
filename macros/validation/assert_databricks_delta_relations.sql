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
    {% set expected = [] %}
    {% set catalogs = [] %}

    {% for node in graph.nodes.values() %}
        {% if node.resource_type in ['model', 'seed', 'snapshot']
              and node.config.enabled
              and node.config.materialized in materialized_types %}
            {% do expected.append({
                'catalog': node.database | lower,
                'schema': node.schema | lower,
                'name': node.alias | lower
            }) %}
            {% if node.database | lower not in catalogs %}
                {% do catalogs.append(node.database | lower) %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {# One information_schema query per catalog rather than one describe per relation. #}
    {% set actual = {} %}
    {% for catalog in catalogs %}
        {% set results = run_query(
            "select lower(table_schema) as table_schema, lower(table_name) as table_name, "
            ~ "lower(table_type) as table_type, lower(coalesce(data_source_format, 'unknown')) as data_source_format "
            ~ "from " ~ adapter.quote(catalog) ~ ".information_schema.tables"
        ) %}
        {% for row in results.rows %}
            {% do actual.update({
                catalog ~ '.' ~ row[0] ~ '.' ~ row[1]: {'table_type': row[2], 'format': row[3]}
            }) %}
        {% endfor %}
    {% endfor %}

    {% set missing = [] %}
    {% set non_delta = [] %}
    {% set delta_count = namespace(value=0) %}

    {% for item in expected %}
        {% set key = item['catalog'] ~ '.' ~ item['schema'] ~ '.' ~ item['name'] %}
        {% set found = actual.get(key) %}
        {% if found is none %}
            {% do missing.append(key) %}
        {% elif found['table_type'] == 'view' %}
            {% do non_delta.append(key ~ ' (materialized as a view)') %}
        {% elif found['format'] != 'delta' %}
            {% do non_delta.append(key ~ ' (format=' ~ found['format'] ~ ')') %}
        {% else %}
            {% set delta_count.value = delta_count.value + 1 %}
        {% endif %}
    {% endfor %}

    {% do log('Expected materialized relations: ' ~ expected | length, info=true) %}
    {% do log('Delta relations: ' ~ delta_count.value, info=true) %}
    {% do log('Non-delta relations: ' ~ non_delta | length, info=true) %}
    {% do log('Missing relations: ' ~ missing | length, info=true) %}

    {% for entry in non_delta %}
        {% do log('  NOT DELTA: ' ~ entry, info=true) %}
    {% endfor %}
    {% for entry in missing %}
        {% do log('  MISSING: ' ~ entry, info=true) %}
    {% endfor %}

    {% if non_delta | length > 0 or (fail_on_missing and missing | length > 0) %}
        {% do exceptions.raise_compiler_error(
            'Databricks validation failed: '
            ~ non_delta | length ~ ' relation(s) are not Delta, '
            ~ missing | length ~ ' relation(s) missing.'
        ) %}
    {% endif %}

{% endmacro %}

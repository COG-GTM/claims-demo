{#
    Profiles the seeds in this project and appends the results to two tables in
    the `seed_profile_schema` schema (default: `data_profiling`):

      seed_profile_columns            one row per run / seed / column
      seed_profile_value_distribution top-N most frequent values per run / seed / column

    Usage:
      dbt run-operation profile_seeds
      dbt run-operation profile_seeds --args '{seeds: [medical_claim, eligibility], top_n: 5}'

    See docs/seed_profiling.md for how to read the output.
#}

{% macro profile_seeds(seeds=none, top_n=10, allow_missing=false) %}

    {% if not execute %}
        {{ return('') }}
    {% endif %}

    {% set profile_schema = var('seed_profile_schema', 'data_profiling') %}
    {% set top_n = top_n | int %}
    {% set run_meta = {
        'profile_run_id': invocation_id,
        'profiled_at': run_started_at.strftime('%Y-%m-%d %H:%M:%S')
    } %}

    {% set seed_nodes = [] %}
    {% for node in graph.nodes.values()
        if node.resource_type == 'seed' and node.package_name == project_name %}
        {% if seeds is none or node.name in seeds %}
            {% do seed_nodes.append(node) %}
        {% endif %}
    {% endfor %}

    {% if seeds is not none %}
        {% set found = seed_nodes | map(attribute='name') | list %}
        {% set unknown = seeds | reject('in', found) | list %}
        {% if unknown | length > 0 %}
            {% do exceptions.raise_compiler_error(
                "profile_seeds: unknown seed(s): " ~ (unknown | join(', '))
            ) %}
        {% endif %}
    {% endif %}

    {% set columns_relation = api.Relation.create(
        database=target.database, schema=profile_schema, identifier='seed_profile_columns'
    ) %}
    {% set values_relation = api.Relation.create(
        database=target.database, schema=profile_schema, identifier='seed_profile_value_distribution'
    ) %}

    {% set targets = [] %}
    {% set missing = [] %}
    {% for node in seed_nodes | sort(attribute='name') %}
        {% set relation = adapter.get_relation(
            database=node.database, schema=node.schema, identifier=node.alias
        ) %}
        {% if relation is none %}
            {% do missing.append(node.schema ~ '.' ~ node.alias) %}
        {% else %}
            {% do targets.append((node, relation)) %}
        {% endif %}
    {% endfor %}

    {% if missing | length > 0 %}
        {% set message = "profile_seeds: seed relation(s) not found (run `dbt seed` first): " ~ (missing | join(', ')) %}
        {% if allow_missing %}
            {{ log(message, info=true) }}
        {% else %}
            {% do exceptions.raise_compiler_error(message) %}
        {% endif %}
    {% endif %}

    {% do adapter.create_schema(columns_relation) %}
    {% do _seed_profile_ensure_table(columns_relation, _seed_profile_columns_ddl()) %}
    {% do _seed_profile_ensure_table(values_relation, _seed_profile_values_ddl()) %}

    {% set profiled = [] %}
    {% for node, relation in targets %}
        {% set columns = adapter.get_columns_in_relation(relation) %}
        {% if columns | length > 0 %}
            {% do run_query(_seed_profile_insert_sql(
                columns_relation,
                _seed_profile_columns_ddl(),
                _seed_profile_column_stats_sql(node, relation, columns, run_meta)
            )) %}
            {% do run_query(_seed_profile_insert_sql(
                values_relation,
                _seed_profile_values_ddl(),
                _seed_profile_value_distribution_sql(node, relation, columns, run_meta, top_n)
            )) %}
            {% do adapter.commit() %}
            {% do profiled.append(node.name) %}
            {{ log("profile_seeds: profiled " ~ node.name ~ " (" ~ (columns | length) ~ " columns)", info=true) }}
        {% endif %}
    {% endfor %}

    {{ log(
        "profile_seeds: run " ~ run_meta['profile_run_id'] ~ " wrote " ~ (profiled | length)
        ~ " seed profile(s) to " ~ columns_relation ~ " and " ~ values_relation,
        info=true
    ) }}

{% endmacro %}


{% macro _seed_profile_columns_ddl() %}
    {% set s = dbt.type_string() %}
    {% set i = dbt.type_bigint() %}
    {% set f = dbt.type_float() %}
    {{ return([
        ('profile_run_id', s),
        ('profiled_at', dbt.type_timestamp()),
        ('seed_name', s),
        ('relation_name', s),
        ('column_name', s),
        ('column_position', i),
        ('data_type', s),
        ('row_count', i),
        ('non_null_count', i),
        ('null_count', i),
        ('null_rate', f),
        ('distinct_count', i),
        ('distinct_rate', f),
        ('min_value', s),
        ('max_value', s)
    ]) }}
{% endmacro %}


{% macro _seed_profile_values_ddl() %}
    {% set s = dbt.type_string() %}
    {% set i = dbt.type_bigint() %}
    {{ return([
        ('profile_run_id', s),
        ('profiled_at', dbt.type_timestamp()),
        ('seed_name', s),
        ('column_name', s),
        ('value_rank', i),
        ('column_value', s),
        ('frequency', i),
        ('frequency_rate', dbt.type_float())
    ]) }}
{% endmacro %}


{% macro _seed_profile_ensure_table(relation, ddl) %}
    {% set existing = adapter.get_relation(
        database=relation.database, schema=relation.schema, identifier=relation.identifier
    ) %}
    {% if existing is none %}
        {% set sql %}
            create table {{ relation }} (
            {%- for name, data_type in ddl %}
                {{ name }} {{ data_type }}{{ "," if not loop.last }}
            {%- endfor %}
            )
        {% endset %}
        {% do run_query(sql) %}
        {% do adapter.commit() %}
        {{ log("profile_seeds: created " ~ relation, info=true) }}
    {% endif %}
{% endmacro %}


{% macro _seed_profile_insert_sql(relation, ddl, select_sql) %}
    {% set column_list = ddl | map(attribute=0) | join(', ') %}
    {{ return("insert into " ~ relation ~ " (" ~ column_list ~ ")\n" ~ select_sql) }}
{% endmacro %}


{% macro _seed_profile_literal(value) %}
    {{ return("cast('" ~ (value | string | replace("'", "''")) ~ "' as " ~ dbt.type_string() ~ ")") }}
{% endmacro %}


{% macro _seed_profile_to_text(expression) %}
    {{ return("left(cast(" ~ expression ~ " as " ~ dbt.type_string() ~ "), 255)") }}
{% endmacro %}


{% macro _seed_profile_supports_min_max(column) %}
    {% set data_type = column.data_type | lower %}
    {{ return(not (data_type.startswith('bool') or data_type == 'bit')) }}
{% endmacro %}


{% macro _seed_profile_column_stats_sql(node, relation, columns, run_meta) %}
    {% set f = dbt.type_float() %}
    {% set selects = [] %}
    {% for column in columns %}
        {% set col = adapter.quote(column.name) %}
        {% set select_sql %}
            select
                {{ _seed_profile_literal(run_meta['profile_run_id']) }} as profile_run_id,
                cast('{{ run_meta['profiled_at'] }}' as {{ dbt.type_timestamp() }}) as profiled_at,
                {{ _seed_profile_literal(node.name) }} as seed_name,
                {{ _seed_profile_literal(node.schema ~ '.' ~ node.alias) }} as relation_name,
                {{ _seed_profile_literal(column.name | lower) }} as column_name,
                cast({{ loop.index }} as {{ dbt.type_bigint() }}) as column_position,
                {{ _seed_profile_literal(column.data_type) }} as data_type,
                count(*) as row_count,
                count({{ col }}) as non_null_count,
                count(*) - count({{ col }}) as null_count,
                case when count(*) = 0 then null
                    else cast(count(*) - count({{ col }}) as {{ f }}) / cast(count(*) as {{ f }})
                end as null_rate,
                count(distinct {{ col }}) as distinct_count,
                case when count({{ col }}) = 0 then null
                    else cast(count(distinct {{ col }}) as {{ f }}) / cast(count({{ col }}) as {{ f }})
                end as distinct_rate,
            {%- if _seed_profile_supports_min_max(column) %}
                {{ _seed_profile_to_text('min(' ~ col ~ ')') }} as min_value,
                {{ _seed_profile_to_text('max(' ~ col ~ ')') }} as max_value
            {%- else %}
                cast(null as {{ dbt.type_string() }}) as min_value,
                cast(null as {{ dbt.type_string() }}) as max_value
            {%- endif %}
            from {{ relation }}
        {% endset %}
        {% do selects.append(select_sql) %}
    {% endfor %}
    {{ return(selects | join('\nunion all\n')) }}
{% endmacro %}


{% macro _seed_profile_value_distribution_sql(node, relation, columns, run_meta, top_n) %}
    {% set f = dbt.type_float() %}
    {% set selects = [] %}
    {% for column in columns %}
        {% set select_sql %}
            select
                {{ _seed_profile_literal(run_meta['profile_run_id']) }} as profile_run_id,
                cast('{{ run_meta['profiled_at'] }}' as {{ dbt.type_timestamp() }}) as profiled_at,
                {{ _seed_profile_literal(node.name) }} as seed_name,
                {{ _seed_profile_literal(column.name | lower) }} as column_name,
                cast(ranked.value_rank as {{ dbt.type_bigint() }}) as value_rank,
                ranked.column_value,
                ranked.frequency,
                cast(ranked.frequency as {{ f }}) / cast(ranked.total_rows as {{ f }}) as frequency_rate
            from (
                select
                    column_value,
                    count(*) as frequency,
                    sum(count(*)) over () as total_rows,
                    row_number() over (order by count(*) desc, column_value) as value_rank
                from (
                    select {{ _seed_profile_to_text(adapter.quote(column.name)) }} as column_value
                    from {{ relation }}
                ) as source_values
                group by column_value
            ) as ranked
            where ranked.value_rank <= {{ top_n }}
        {% endset %}
        {% do selects.append(select_sql) %}
    {% endfor %}
    {{ return(selects | join('\nunion all\n')) }}
{% endmacro %}

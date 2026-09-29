{#
    Helpers for the incremental input-layer models.

    Each incremental model declares a partition column (the event date the rows
    are naturally ordered by) and a row-level unique key. On an incremental run
    the model re-selects every source row whose partition date falls inside a
    lookback window ending at the latest partition date already loaded, and
    replaces those rows in the target by unique key. See README.md
    ("Incremental materialization") for the full strategy.
#}

{% macro incremental_strategy() -%}
    {%- if target.type in ('bigquery', 'databricks') -%}
        merge
    {%- else -%}
        delete+insert
    {%- endif -%}
{%- endmacro %}


{% macro incremental_lookback_filter(partition_column, lookback_days=none) -%}
    {%- if is_incremental() -%}
        {%- set days = (lookback_days if lookback_days is not none else var('incremental_lookback_days', 90)) | int -%}
        {%- set latest_loaded -%}
            coalesce(max(cast({{ partition_column }} as date)), cast('1900-01-01' as date))
        {%- endset %}
    where cast({{ partition_column }} as date) >= (
        select cast({{ dbt.dateadd('day', -1 * days, latest_loaded) }} as date)
        from {{ this }}
    )
    {%- endif -%}
{%- endmacro %}

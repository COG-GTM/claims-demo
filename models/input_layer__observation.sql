{{ config(
    enabled=var('clinical_enabled', var('tuva_marts_enabled', False)) | as_bool,
    schema='input_layer',
    tags=['tuva_demo'],
    materialized='incremental',
    incremental_strategy=incremental_strategy(),
    unique_key='observation_id',
    on_schema_change='append_new_columns',
    partition_by={'field': 'observation_date', 'data_type': 'date', 'granularity': 'month'} if target.type == 'bigquery' else none,
    cluster_by=['observation_date'] if target.type == 'snowflake' else none
) }}

select *
from {{ ref('observation') }}
{{ incremental_lookback_filter('observation_date') }}

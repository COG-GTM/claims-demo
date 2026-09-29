{{ config(
    enabled=var('clinical_enabled', var('tuva_marts_enabled', False)) | as_bool,
    schema='input_layer',
    tags=['tuva_demo'],
    materialized='incremental',
    incremental_strategy=incremental_strategy(),
    unique_key='lab_result_id',
    on_schema_change='append_new_columns',
    partition_by={'field': 'result_datetime', 'data_type': 'timestamp', 'granularity': 'month'} if target.type == 'bigquery' else none,
    cluster_by=['result_datetime'] if target.type == 'snowflake' else none
) }}

select *
from {{ ref('lab_result') }}
{{ incremental_lookback_filter('result_datetime') }}

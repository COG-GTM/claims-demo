{{ config(
    enabled=var('claims_preprocessing_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool,
    schema='input_layer',
    tags=['tuva_demo'],
    materialized='incremental',
    incremental_strategy=incremental_strategy(),
    unique_key=['claim_id', 'claim_line_number', 'data_source'],
    on_schema_change='append_new_columns',
    partition_by={'field': 'claim_end_date', 'data_type': 'date', 'granularity': 'month'} if target.type == 'bigquery' else none,
    cluster_by=['claim_end_date'] if target.type == 'snowflake' else none
) }}

select *
from {{ ref('medical_claim') }}
{{ incremental_lookback_filter('claim_end_date') }}

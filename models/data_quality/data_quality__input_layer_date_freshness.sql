{{ config(
    schema='data_quality',
    materialized='table',
    tags=['tuva_demo', 'data_quality']
) }}

{#-
    One row per (input layer table, date column). date_role:
      service      - when care was delivered / coverage was in force; drives trend and period coverage checks
      adjudication - when the claim was paid
      file         - the source file / feed period the row arrived in
      ingest       - when the row was loaded into the warehouse
-#}
{%- set date_columns = [
    {'table': 'medical_claim',  'column': 'claim_start_date',      'role': 'service'},
    {'table': 'medical_claim',  'column': 'claim_end_date',        'role': 'service'},
    {'table': 'medical_claim',  'column': 'paid_date',             'role': 'adjudication'},
    {'table': 'medical_claim',  'column': 'file_date',             'role': 'file'},
    {'table': 'medical_claim',  'column': 'ingest_datetime',       'role': 'ingest'},
    {'table': 'pharmacy_claim', 'column': 'dispensing_date',       'role': 'service'},
    {'table': 'pharmacy_claim', 'column': 'paid_date',             'role': 'adjudication'},
    {'table': 'pharmacy_claim', 'column': 'file_date',             'role': 'file'},
    {'table': 'pharmacy_claim', 'column': 'ingest_datetime',       'role': 'ingest'},
    {'table': 'eligibility',    'column': 'enrollment_start_date', 'role': 'service'},
    {'table': 'eligibility',    'column': 'enrollment_end_date',   'role': 'service'},
    {'table': 'eligibility',    'column': 'file_date',             'role': 'file'},
    {'table': 'eligibility',    'column': 'ingest_datetime',       'role': 'ingest'},
    {'table': 'lab_result',     'column': 'collection_datetime',   'role': 'service'},
    {'table': 'lab_result',     'column': 'ingest_datetime',       'role': 'ingest'},
    {'table': 'observation',    'column': 'observation_date',      'role': 'service'},
    {'table': 'observation',    'column': 'ingest_datetime',       'role': 'ingest'},
    {'table': 'immunization',   'column': 'occurrence_date',       'role': 'service'},
    {'table': 'immunization',   'column': 'ingest_datetime',       'role': 'ingest'},
    {'table': 'appointment',    'column': 'start_datetime',        'role': 'service'},
    {'table': 'appointment',    'column': 'ingest_datetime',       'role': 'ingest'}
] -%}

{%- set period_end = var('data_freshness_period_end', var('quality_measures_period_end')) -%}
{%- set as_of_date = var('data_freshness_as_of_date', none) -%}

with column_profile as (

{% for date_column in date_columns %}
    select
          cast('{{ date_column.table }}' as {{ dbt.type_string() }}) as source_table
        , cast('{{ date_column.column }}' as {{ dbt.type_string() }}) as date_column
        , cast('{{ date_column.role }}' as {{ dbt.type_string() }}) as date_role
        , count(*) as row_count
        , count({{ date_column.column }}) as non_null_count
        , min(cast({{ date_column.column }} as date)) as min_date
        , max(cast({{ date_column.column }} as date)) as max_date
    from {{ ref(date_column.table) }}
    {% if not loop.last %}union all{% endif %}
{% endfor %}

),

enrollment_window as (

    select
          min(cast(enrollment_start_date as date)) as enrollment_window_start
        , max(cast(enrollment_end_date as date)) as enrollment_window_end
    from {{ ref('eligibility') }}

),

anchored as (

    select
          column_profile.*
        , max(case when column_profile.date_role = 'ingest' then column_profile.max_date end)
            over (partition by column_profile.source_table) as table_max_ingest_date
        , enrollment_window.enrollment_window_start
        , enrollment_window.enrollment_window_end
        , cast('{{ period_end }}' as date) as analysis_period_end
        {% if as_of_date is not none -%}
        , cast('{{ as_of_date }}' as date) as as_of_date
        {%- else -%}
        , cast({{ dbt.current_timestamp() }} as date) as as_of_date
        {%- endif %}
    from column_profile
    cross join enrollment_window

),

elapsed as (

    select
          anchored.*
        , {{ dbt.datediff('max_date', 'as_of_date', 'day') }} as days_since_max_date
        , {{ dbt.datediff('max_date', 'analysis_period_end', 'day') }} as days_max_date_before_period_end
        , {{ dbt.datediff('max_date', 'table_max_ingest_date', 'day') }} as days_max_date_to_ingest
        , {{ dbt.datediff('min_date', 'enrollment_window_start', 'day') }} as days_min_date_before_enrollment_window
        , {{ dbt.datediff('enrollment_window_end', 'max_date', 'day') }} as days_max_date_after_enrollment_window
    from anchored

)

select
      source_table
    , date_column
    , date_role
    , row_count
    , non_null_count
    , min_date
    , max_date
    , table_max_ingest_date
    , enrollment_window_start
    , enrollment_window_end
    , analysis_period_end
    , as_of_date
    , days_since_max_date
    , days_max_date_before_period_end
    , days_max_date_to_ingest
    , days_min_date_before_enrollment_window
    , days_max_date_after_enrollment_window
    , case
        when non_null_count = 0 then 'missing'
        when days_since_max_date > {{ var('data_freshness_stale_after_days', 90) }} then 'stale'
        else 'fresh'
      end as wall_clock_status
    , case
        when date_role = 'ingest' then 'not_applicable'
        when non_null_count = 0 then 'missing'
        when days_max_date_before_period_end > {{ var('data_freshness_max_days_short_of_period_end', 31) }} then 'short_of_period_end'
        when days_max_date_before_period_end < 0 then 'extends_past_period_end'
        else 'covers_period_end'
      end as period_coverage_status
from elapsed

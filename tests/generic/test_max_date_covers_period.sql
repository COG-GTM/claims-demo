{#
    Fails when the latest value in `column_name` ends more than `max_lag_days`
    before `period_end` (YYYY-MM-DD), i.e. the data does not cover the
    configured analysis period.
#}
{% test max_date_covers_period(model, column_name, period_end, max_lag_days=31) %}

{%- set period_end_date = modules.datetime.datetime.strptime(period_end | string, '%Y-%m-%d').date() -%}
{%- set threshold_date = period_end_date - modules.datetime.timedelta(days=max_lag_days | int) -%}

select max_value
from (
    select max({{ column_name }}) as max_value
    from {{ model }}
) as coverage
where max_value is null
   or max_value < cast('{{ threshold_date }}' as date)

{% endtest %}

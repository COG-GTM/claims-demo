/*
    Twelve-month performance period ending on the quality_measures_period_end var
    (shared with the Tuva quality measures mart), or the end of the current year when unset.
*/

with period_end as (

    select
        {% if var('quality_measures_period_end', False) == False -%}
        cast({{ dbt.last_day(dbt.current_timestamp(), 'year') }} as date)
        {%- else -%}
        cast('{{ var('quality_measures_period_end') }}' as date)
        {%- endif %} as performance_period_end

)

select
      cast(
        {{ dbt.dateadd('day', 1, dbt.dateadd('year', -1, 'performance_period_end')) }}
        as date
      ) as performance_period_begin
    , performance_period_end
from period_end

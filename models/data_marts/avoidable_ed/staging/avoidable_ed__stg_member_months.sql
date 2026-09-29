{{ config(
     enabled = var('avoidable_ed_enabled', var('ed_classification_enabled', var('claims_enabled', var('tuva_marts_enabled', False)))) | as_bool
   )
}}

select distinct
      person_id
    , cast(year_month as {{ dbt.type_string() }}) as year_month
from {{ ref('the_tuva_project', 'core__member_months') }}

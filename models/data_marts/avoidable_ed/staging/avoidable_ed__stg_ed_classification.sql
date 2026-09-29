{{ config(
     enabled = var('avoidable_ed_enabled', var('ed_classification_enabled', var('claims_enabled', var('tuva_marts_enabled', False)))) | as_bool
   )
}}

select
      summary.encounter_id
    , summary.person_id
    , cast(summary.year_month as {{ dbt.type_string() }}) as year_month
    , categories.classification
    , summary.ed_classification_description
    , summary.paid_amount
    , summary.allowed_amount
from {{ ref('the_tuva_project', 'ed_classification__summary') }} as summary
inner join {{ ref('the_tuva_project', 'ed_classification__categories') }} as categories
    on summary.ed_classification_description = categories.classification_name

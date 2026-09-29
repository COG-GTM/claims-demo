{{ config(tags=['risk_adjustment']) }}
-- Within a hierarchy group no prefix may overlap another, so each code maps to one category per group.
select
      broader.icd_10_cm_prefix as broader_prefix
    , broader.condition_category as broader_category
    , narrower.icd_10_cm_prefix as narrower_prefix
    , narrower.condition_category as narrower_category
from {{ ref('risk_adjustment__condition_category_map') }} as broader
inner join {{ ref('risk_adjustment__condition_category_map') }} as narrower
  on broader.hierarchy_group = narrower.hierarchy_group
 and narrower.icd_10_cm_prefix like {{ dbt.concat(["broader.icd_10_cm_prefix", "'%'"]) }}
 and not (
        broader.icd_10_cm_prefix = narrower.icd_10_cm_prefix
    and broader.condition_category = narrower.condition_category
 )

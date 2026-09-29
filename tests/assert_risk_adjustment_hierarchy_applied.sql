{{ config(
     tags = ['tuva_demo', 'risk_adjustment'],
     enabled = var('claims_enabled', False) | as_bool
   )
}}
-- Fails for any member year that retains both a parent HCC and an HCC it excludes.
select
      child.person_id
    , child.payer
    , child.member_year
    , parent.hcc_code as parent_hcc_code
    , child.hcc_code as excluded_hcc_code
from {{ ref('risk_adjustment__member_year_hccs') }} as child
    inner join {{ ref('cms_hcc__disease_hierarchy') }} as hierarchy
        on child.model_version = hierarchy.model_version
        and child.hcc_code = hierarchy.hccs_to_exclude
    inner join {{ ref('risk_adjustment__member_year_hccs') }} as parent
        on child.person_id = parent.person_id
        and child.payer = parent.payer
        and child.member_year = parent.member_year
        and parent.hcc_code = hierarchy.hcc_code

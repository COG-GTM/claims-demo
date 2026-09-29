{{ config(
     schema = 'risk_adjustment',
     tags = ['tuva_demo', 'risk_adjustment'],
     enabled = var('claims_enabled', False) | as_bool
   )
}}
/*
    One row per member (person_id + payer), calendar year, and HCC that
    survives the CMS-HCC hierarchy. See the risk_adjustment_assumptions doc
    block for the methodology and simplifications.
*/

{%- set model_version = var('risk_adjustment_model_version', 'CMS-HCC-V28') -%}
{%- set hcc_column = 'cms_hcc_v28' if model_version == 'CMS-HCC-V28' else 'cms_hcc_v24' -%}

with member_years as (

    select
          person_id
        , payer
        , member_year
    from {{ ref('risk_adjustment__int_member_years') }}

)

, mapping_year as (

    select
        {% if var('risk_adjustment_mapping_year', none) is not none -%}
          cast({{ var('risk_adjustment_mapping_year') }} as {{ dbt.type_int() }}) as payment_year
        {%- else -%}
          max(payment_year) as payment_year
        {%- endif %}
    from {{ ref('cms_hcc__icd_10_cm_mappings') }}

)

, icd_to_hcc as (

    select
          mappings.diagnosis_code
        , cast(mappings.{{ hcc_column }} as {{ dbt.type_string() }}) as hcc_code
        , mappings.payment_year as mapping_year
    from {{ ref('cms_hcc__icd_10_cm_mappings') }} as mappings
        inner join mapping_year
            on mappings.payment_year = mapping_year.payment_year
    where mappings.{{ hcc_column }}_flag = 'Yes'

)

, conditions as (

    select
          person_id
        , payer
        , normalized_code as diagnosis_code
        , recorded_date
        , {% if target.type == 'fabric' -%}
            year(recorded_date)
          {%- else -%}
            extract(year from recorded_date)
          {%- endif %} as condition_year
    from {{ ref('core__condition') }}
    where normalized_code_type = 'icd-10-cm'
        and recorded_date is not null

)

, mapped as (

    select
          member_years.person_id
        , member_years.payer
        , member_years.member_year
        , icd_to_hcc.hcc_code
        , icd_to_hcc.mapping_year
        , conditions.diagnosis_code
        , conditions.recorded_date
    from conditions
        inner join member_years
            on conditions.person_id = member_years.person_id
            and conditions.payer = member_years.payer
            and conditions.condition_year = member_years.member_year
        inner join icd_to_hcc
            on conditions.diagnosis_code = icd_to_hcc.diagnosis_code

)

, pre_hierarchy as (

    select
          person_id
        , payer
        , member_year
        , hcc_code
        , mapping_year
        , count(distinct diagnosis_code) as supporting_diagnosis_count
        , min(recorded_date) as first_recorded_date
        , max(recorded_date) as last_recorded_date
    from mapped
    group by
          person_id
        , payer
        , member_year
        , hcc_code
        , mapping_year

)

, hierarchy as (

    select
          hcc_code
        , hccs_to_exclude
    from {{ ref('cms_hcc__disease_hierarchy') }}
    where model_version = '{{ model_version }}'

)

, suppressed as (

    select distinct
          lower_hcc.person_id
        , lower_hcc.payer
        , lower_hcc.member_year
        , lower_hcc.hcc_code
    from pre_hierarchy as lower_hcc
        inner join hierarchy
            on lower_hcc.hcc_code = hierarchy.hccs_to_exclude
        inner join pre_hierarchy as higher_hcc
            on lower_hcc.person_id = higher_hcc.person_id
            and lower_hcc.payer = higher_hcc.payer
            and lower_hcc.member_year = higher_hcc.member_year
            and hierarchy.hcc_code = higher_hcc.hcc_code

)

, reference_factors as (

    select
          hcc_code
        , description
        , coefficient
    from {{ ref('cms_hcc__disease_factors') }}
    where model_version = '{{ model_version }}'
        and factor_type = 'Disease'
        and enrollment_status = 'Continuing'
        and medicaid_status = 'No'
        and dual_status = 'Non'
        and orec = 'Aged'
        and institutional_status = 'No'

)

select
      cast(pre_hierarchy.person_id as {{ dbt.type_string() }}) as person_id
    , cast(pre_hierarchy.payer as {{ dbt.type_string() }}) as payer
    , cast(pre_hierarchy.member_year as {{ dbt.type_int() }}) as member_year
    , cast('{{ model_version }}' as {{ dbt.type_string() }}) as model_version
    , cast(pre_hierarchy.mapping_year as {{ dbt.type_int() }}) as mapping_year
    , cast(pre_hierarchy.hcc_code as {{ dbt.type_string() }}) as hcc_code
    , cast(reference_factors.description as {{ dbt.type_string() }}) as hcc_description
    , cast(reference_factors.coefficient as {{ dbt.type_numeric() }}) as reference_coefficient
    , cast(pre_hierarchy.supporting_diagnosis_count as {{ dbt.type_int() }}) as supporting_diagnosis_count
    , cast(pre_hierarchy.first_recorded_date as date) as first_recorded_date
    , cast(pre_hierarchy.last_recorded_date as date) as last_recorded_date
from pre_hierarchy
    left outer join suppressed
        on pre_hierarchy.person_id = suppressed.person_id
        and pre_hierarchy.payer = suppressed.payer
        and pre_hierarchy.member_year = suppressed.member_year
        and pre_hierarchy.hcc_code = suppressed.hcc_code
    left outer join reference_factors
        on pre_hierarchy.hcc_code = reference_factors.hcc_code
where suppressed.hcc_code is null

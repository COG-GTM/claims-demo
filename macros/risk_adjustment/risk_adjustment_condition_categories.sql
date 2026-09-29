{#
    HCC-like condition categories used by the risk_adjustment models.

    This is a simplified, illustrative subset loosely modeled on CMS-HCC V24
    community factors. It is not an official CMS mapping: ICD-10-CM codes are
    matched by prefix and relative factors are for demo purposes only.

    Within a hierarchy_group only the category with the lowest hierarchy_rank
    is kept for a member month (e.g. diabetes with complications trumps
    diabetes without complications).
#}
{% macro risk_adjustment_condition_categories() %}
    {{ return([
        {'category': 'diabetes_with_complications', 'description': 'Diabetes with acute or chronic complications', 'hierarchy_group': 'diabetes', 'hierarchy_rank': 1, 'relative_factor': 0.302,
         'icd_10_cm_prefixes': ['E100', 'E101', 'E102', 'E103', 'E104', 'E105', 'E106', 'E107', 'E108', 'E110', 'E111', 'E112', 'E113', 'E114', 'E115', 'E116', 'E117', 'E118', 'E130', 'E131', 'E132', 'E133', 'E134', 'E135', 'E136', 'E137', 'E138']},
        {'category': 'diabetes_without_complications', 'description': 'Diabetes without complication', 'hierarchy_group': 'diabetes', 'hierarchy_rank': 2, 'relative_factor': 0.105,
         'icd_10_cm_prefixes': ['E109', 'E119', 'E139']},
        {'category': 'morbid_obesity', 'description': 'Morbid obesity', 'hierarchy_group': 'morbid_obesity', 'hierarchy_rank': 1, 'relative_factor': 0.250,
         'icd_10_cm_prefixes': ['E6601', 'E662', 'Z6841', 'Z6842', 'Z6843', 'Z6844', 'Z6845']},
        {'category': 'metastatic_cancer', 'description': 'Metastatic cancer and acute leukemia', 'hierarchy_group': 'cancer', 'hierarchy_rank': 1, 'relative_factor': 2.659,
         'icd_10_cm_prefixes': ['C77', 'C78', 'C79', 'C80']},
        {'category': 'lung_and_severe_cancer', 'description': 'Lung and other severe cancers', 'hierarchy_group': 'cancer', 'hierarchy_rank': 2, 'relative_factor': 1.024,
         'icd_10_cm_prefixes': ['C25', 'C33', 'C34']},
        {'category': 'breast_prostate_cancer', 'description': 'Breast, prostate, and other cancers', 'hierarchy_group': 'cancer', 'hierarchy_rank': 3, 'relative_factor': 0.150,
         'icd_10_cm_prefixes': ['C50', 'C61']},
        {'category': 'rheumatoid_arthritis', 'description': 'Rheumatoid arthritis and inflammatory connective tissue disease', 'hierarchy_group': 'rheumatoid_arthritis', 'hierarchy_rank': 1, 'relative_factor': 0.421,
         'icd_10_cm_prefixes': ['M05', 'M06']},
        {'category': 'major_depression_bipolar', 'description': 'Major depressive, bipolar, and paranoid disorders', 'hierarchy_group': 'major_depression_bipolar', 'hierarchy_rank': 1, 'relative_factor': 0.309,
         'icd_10_cm_prefixes': ['F31', 'F320', 'F321', 'F322', 'F323', 'F324', 'F325', 'F33']},
        {'category': 'heart_failure', 'description': 'Congestive heart failure', 'hierarchy_group': 'heart_failure', 'hierarchy_rank': 1, 'relative_factor': 0.331,
         'icd_10_cm_prefixes': ['I110', 'I130', 'I132', 'I50']},
        {'category': 'specified_arrhythmias', 'description': 'Specified heart arrhythmias', 'hierarchy_group': 'specified_arrhythmias', 'hierarchy_rank': 1, 'relative_factor': 0.268,
         'icd_10_cm_prefixes': ['I47', 'I48']},
        {'category': 'ischemic_stroke', 'description': 'Ischemic or unspecified stroke', 'hierarchy_group': 'ischemic_stroke', 'hierarchy_rank': 1, 'relative_factor': 0.230,
         'icd_10_cm_prefixes': ['I63']},
        {'category': 'vascular_disease', 'description': 'Vascular disease', 'hierarchy_group': 'vascular_disease', 'hierarchy_rank': 1, 'relative_factor': 0.288,
         'icd_10_cm_prefixes': ['I702', 'I7390', 'I74']},
        {'category': 'copd', 'description': 'Chronic obstructive pulmonary disease', 'hierarchy_group': 'copd', 'hierarchy_rank': 1, 'relative_factor': 0.335,
         'icd_10_cm_prefixes': ['J41', 'J42', 'J43', 'J44']},
        {'category': 'ckd_stage_5_esrd', 'description': 'Chronic kidney disease stage 5 or ESRD', 'hierarchy_group': 'chronic_kidney_disease', 'hierarchy_rank': 1, 'relative_factor': 0.289,
         'icd_10_cm_prefixes': ['N185', 'N186']},
        {'category': 'ckd_stage_4', 'description': 'Chronic kidney disease, severe (stage 4)', 'hierarchy_group': 'chronic_kidney_disease', 'hierarchy_rank': 2, 'relative_factor': 0.289,
         'icd_10_cm_prefixes': ['N184']},
        {'category': 'ckd_stage_3', 'description': 'Chronic kidney disease, moderate (stage 3)', 'hierarchy_group': 'chronic_kidney_disease', 'hierarchy_rank': 3, 'relative_factor': 0.069,
         'icd_10_cm_prefixes': ['N183']}
    ]) }}
{% endmacro %}

{% macro risk_adjustment_lookback_months() %}
    {{ return(var('risk_adjustment_lookback_months', 12) | int) }}
{% endmacro %}

{% macro risk_adjustment_lookback_start_date(month_start_date) %}
    {{ return(dbt.dateadd('month', -1 * (risk_adjustment_lookback_months() - 1), month_start_date)) }}
{% endmacro %}
